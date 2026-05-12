#!/usr/bin/env perl
# Helper for banned-language-gate.sh — does the actual lint pass.
#
# Reads:
#   $ENV{LINT_TARGET}  the text to scan
#   $ENV{CACHE_FILE}   TSV cache produced by banned-language-gate.sh
#
# Writes (stdout, on hit only):
#   BLOCK\t<word>\t<snippet>\t<safe-alternative>\n
#
# Exit code is always 0 — caller decides allow/block based on stdout content.

use strict;
use warnings;
use utf8;
use Encode qw(decode_utf8);

my $target = decode_utf8($ENV{LINT_TARGET} // "");
my $cache  = $ENV{CACHE_FILE} // "";
exit 0 unless length $target;
exit 0 unless -f $cache;

# --- Load cache ---
my (@banned, @allow_lit, @allow_re);
my $section = "";
open(my $fh, "<:encoding(UTF-8)", $cache) or exit 0;
while (my $line = <$fh>) {
  chomp $line;
  if ($line =~ /^#BANNED$/)        { $section = "B"; next; }
  if ($line =~ /^#ALLOW_LITERAL$/) { $section = "L"; next; }
  if ($line =~ /^#ALLOW_REGEX$/)   { $section = "R"; next; }
  next unless length $line;
  if ($section eq "B") {
    my ($w, $alt) = split /\t/, $line, 2;
    push @banned, [$w, $alt // ""];
  } elsif ($section eq "L") {
    push @allow_lit, lc $line;
  } elsif ($section eq "R") {
    push @allow_re, $line;
  }
}
close $fh;

exit 0 unless @banned;

# --- Strip uninteresting regions so we only scan plain prose ---
my $scan = $target;

# Triple-backtick code blocks (use char-class to avoid confusing host shells).
my $bt = chr(0x60);
my $tri = $bt . $bt . $bt;
$scan =~ s/\Q$tri\E.*?\Q$tri\E/ /sg;
# Single-backtick inline code.
$scan =~ s/$bt\[\^$bt\\n\]*$bt/ /g;
# Note: above pattern is regex-as-string; build it explicitly to be safe.
{
  my $re = qr/$bt [^$bt\n]* $bt/x;
  $scan =~ s/$re/ /g;
}

# Markdown links [text](url) — keep the visible text, drop the URL.
$scan =~ s/\[([^\]]*)\]\([^)]*\)/$1/g;
# Bare URLs.
$scan =~ s{https?://\S+}{ }g;
# File paths (segments containing slash + recognisable extension).
$scan =~ s{[\w./\-]*/[\w.\-]+\.\w{1,6}}{ }g;
# YAML frontmatter blocks at start of a file.
$scan =~ s/\A---\n.*?\n---\n//s;
# Markdown table rows (used by the ban list itself to document the words).
$scan =~ s/^\s*\|.*\|\s*$/ /mg;
# Block-quote lines (>) — used to quote upstream content.
$scan =~ s/^\s*>.*$/ /mg;
# Double-quoted strings ("..." or smart-quoted) — ban-list / docs use these
# to enumerate banned words by name. Single quotes are too risky to strip
# wholesale (apostrophes), so we leave them.
$scan =~ s/"[^"\n]{0,200}"/ /g;
$scan =~ s/\x{201C}[^\x{201D}\n]{0,200}\x{201D}/ /g;

# Negation prefixes — collapse "no/not/non/never <word>" so the word doesn't
# match. Catches "not clinical", "no therapy", "never use FDA-approved".
$scan =~ s/\b(?:no|not|non-?|never|without|avoid|stop|skip|ignore|drop)\s+(\w[\w'-]*)/ NEG /ig;

# Allowlist literals — blast occurrences to whitespace before scanning.
for my $lit (@allow_lit) {
  next unless length $lit;
  my $q = quotemeta(decode_utf8($lit));
  $scan =~ s/$q/ /ig;
}

# Allowlist regex — same.
for my $re (@allow_re) {
  next unless length $re;
  eval { $scan =~ s/$re/ /ig; };
}

# --- Scan ---
my $em_dash = chr(0x2014);

for my $entry (@banned) {
  my ($word, $alt) = @$entry;
  next unless length $word;

  # Special case: em-dash literal.
  if ($word =~ /em\s*dash/i) {
    if ($scan =~ /(.{0,20})\Q$em_dash\E(.{0,20})/) {
      my $snip = $1 . $em_dash . $2;
      print_block("em dash (\x{2014})", $snip, $alt);
    }
    next;
  }

  my $w = $word;
  # ASCII-fold smart quotes that may have leaked in from the doc.
  $w =~ s/[\x{201C}\x{201D}]/"/g;
  $w =~ s/[\x{2018}\x{2019}]/'/g;

  # Skip rows that look like notes rather than words.
  next if $w =~ /^(any |welcome |download |join |what |\[|subscription tos)/i;
  next if $w =~ /three short sentences|every paragraph|every list|every heading/i;

  my $pat;
  if ($w =~ /\s/ || $w =~ /[^A-Za-z0-9'\-]/) {
    # Phrase. Loose boundary.
    my $q = quotemeta($w);
    $pat = qr/(?<![A-Za-z0-9])(.{0,20})($q)(.{0,20})/i;
  } else {
    # Single word. Strict word boundary.
    my $q = quotemeta($w);
    $pat = qr/\b(.{0,20}?)($q)(.{0,20}?)\b/i;
  }

  if ($scan =~ /$pat/) {
    my $snip = ($1 // "") . ($2 // "") . ($3 // "");
    print_block($w, $snip, $alt);
  }
}

exit 0;

sub print_block {
  my ($word, $snippet, $alt) = @_;
  $snippet =~ s/\s+/ /g;
  $snippet =~ s/^\s+|\s+$//g;
  $alt = "(rewrite — see compliance handbook)" unless length $alt;
  binmode STDOUT, ":encoding(UTF-8)";
  printf "BLOCK\t%s\t%s\t%s\n", $word, $snippet, $alt;
  exit 0;
}
