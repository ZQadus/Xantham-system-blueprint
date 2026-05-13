#!/bin/bash
# CORTANA SAFETY GATE
# Blocks destructive commands and prompts Zaki for approval via Telegram.
# Exit 0 = allow. Exit 2 = block (message sent to Claude via stderr).
# Also emits structured JSON on stdout for newer Claude Code versions:
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow|deny","permissionDecisionReason":"..."}}
# Exit codes remain authoritative — JSON is advisory / future-proofing.
#
# APPROVAL FLOW:
# 1. Hook blocks a dangerous command
# 2. Claude sees the block reason and asks Zaki on Telegram
# 3. Zaki says "yes" / "approved"
# 4. Claude writes the command to ${CLAUDE_PROJECT_DIR:-$PWD}/data/approved.txt
# 5. Claude retries the command
# 6. Hook sees it's pre-approved, allows it, removes the approval

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // empty')

# === STRUCTURED OUTPUT HELPER ===
# Emits JSON on stdout for modern Claude Code hook protocol, without disturbing
# the stderr reason string (which existing versions of Claude Code read).
emit_decision() {
  local decision="$1"  # "allow" or "deny"
  local reason="${2:-}"
  if [ -n "$reason" ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":%s}}\n' \
      "$decision" "$(printf '%s' "$reason" | jq -Rs .)"
  else
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s"}}\n' "$decision"
  fi
}

# Nothing to inspect
if [ -z "$COMMAND" ] && [ -z "$FILE_PATH" ]; then
  emit_decision "allow"
  exit 0
fi

TIMESTAMP=$(date -Iseconds)
LOG_FILE="${CLAUDE_PROJECT_DIR:-$PWD}/logs/safety-gate.log"
APPROVAL_FILE="${CLAUDE_PROJECT_DIR:-$PWD}/data/approved.txt"
APPROVAL_TTL_DAYS=30

# Ensure approval file exists
touch "$APPROVAL_FILE"

# === TTL PRUNE + TIMESTAMP BACKFILL ===
# Approval file format (new): "<epoch_seconds>|<command>" per line.
# Legacy lines without the "<epoch>|" prefix are treated as written-now on first
# sight (they get 30 days from now). Lines older than APPROVAL_TTL_DAYS are
# dropped so stale approvals from previous sessions can't quietly green-light a
# destructive op later.
if [ -s "$APPROVAL_FILE" ]; then
  NOW_EPOCH=$(date +%s)
  TTL_SECONDS=$((APPROVAL_TTL_DAYS * 86400))
  awk -F'|' -v now="$NOW_EPOCH" -v ttl="$TTL_SECONDS" '
    NF >= 2 && $1 ~ /^[0-9]+$/ {
      # Timestamped entry. Drop if expired. Rejoin command in case it contained pipes.
      ts = $1
      cmd = $2
      for (i = 3; i <= NF; i++) cmd = cmd "|" $i
      if (now - ts < ttl) {
        printf "%s|%s\n", ts, cmd
      }
      next
    }
    NF > 0 {
      # Legacy entry without timestamp — stamp with now.
      printf "%s|%s\n", now, $0
    }
  ' "$APPROVAL_FILE" > "$APPROVAL_FILE.prune" && mv "$APPROVAL_FILE.prune" "$APPROVAL_FILE"
fi

# === CHECK FOR PRE-APPROVAL ===
# If Zaki already approved this exact command, let it through and clear it
CHECK_STRING="$COMMAND$FILE_PATH"
if awk -F'|' -v cmd="$CHECK_STRING" '
  NF >= 2 && $1 ~ /^[0-9]+$/ {
    c = $2
    for (i = 3; i <= NF; i++) c = c "|" $i
    if (c == cmd) { found = 1; exit }
  }
  NF > 0 && $0 == cmd { found = 1; exit }
  END { exit !found }
' "$APPROVAL_FILE" 2>/dev/null; then
  # Remove ONE matching approval entry (one-time-use, first-match). Both
  # the project and global gates run per Bash call, so each call consumes
  # one entry. Multiple identical entries (one per gate) keep duplicates
  # so the second gate still finds a match. Match either new or legacy
  # format. Fixed 2026-04-22 after batch rm consumed both entries in one pass.
  awk -F'|' -v cmd="$CHECK_STRING" '
    !consumed && NF >= 2 && $1 ~ /^[0-9]+$/ {
      c = $2
      for (i = 3; i <= NF; i++) c = c "|" $i
      if (c == cmd) { consumed = 1; next }
      print; next
    }
    !consumed && $0 == cmd { consumed = 1; next }
    { print }
  ' "$APPROVAL_FILE" > "$APPROVAL_FILE.tmp" && mv "$APPROVAL_FILE.tmp" "$APPROVAL_FILE"
  echo "[$TIMESTAMP] APPROVED (pre-approved by Zaki): $CHECK_STRING" >> "$LOG_FILE"
  emit_decision "allow" "Pre-approved by Zaki (one-time use, consumed)"
  exit 0
fi

# === HELPER: block with approval instructions ===
block() {
  local REASON="$1"
  local CATEGORY="$2"
  local MSG="BLOCKED: $REASON. Ask Zaki for approval on Telegram. If he approves, write the exact command to ${CLAUDE_PROJECT_DIR:-$PWD}/data/approved.txt (one command per line) then retry."
  echo "$MSG" >&2
  echo "[$TIMESTAMP] BLOCKED ($CATEGORY): ${COMMAND}${FILE_PATH}" >> "$LOG_FILE"
  emit_decision "deny" "$MSG"
  exit 2
}

# === HELPER: hard block (not even Zaki-approval opens the gate) ===
hard_block() {
  local REASON="$1"
  local CATEGORY="$2"
  local MSG="HARD BLOCKED: $REASON. This cannot be approved through the hook. Run manually in Terminal if you genuinely need this."
  echo "$MSG" >&2
  echo "[$TIMESTAMP] HARD BLOCKED ($CATEGORY): $COMMAND" >> "$LOG_FILE"
  emit_decision "deny" "$MSG"
  exit 2
}

# === CATEGORY 1: ALWAYS BLOCKED (no approval possible) ===
# These are so catastrophic or history-destroying that even with approval,
# we don't allow them through the hook. Zaki must run them manually in Terminal.

# Delete home / root filesystem
if echo "$COMMAND" | grep -qEi 'rm\s+-(rf|fr)\s+(/|~|\$HOME)\s*$'; then
  hard_block "This would delete your entire home directory or root filesystem" "catastrophic"
fi

# Disk formatting / partition ops
if echo "$COMMAND" | grep -qEi '(mkfs\.|dd\s+if=|fdisk|diskutil\s+erase)'; then
  hard_block "Disk formatting / partition operation" "disk"
fi

# Git history rewrites — these are almost never recoverable
if echo "$COMMAND" | grep -qEi 'git\s+filter-(branch|repo)'; then
  hard_block "git filter-branch/filter-repo permanently rewrites history — unrecoverable if pushed" "git-filter"
fi

if echo "$COMMAND" | grep -qEi '(git\s+update-ref\s+-d|git\s+reflog\s+expire|git\s+gc\s+.*--prune=now|git\s+gc\s+.*--aggressive)'; then
  hard_block "Permanent reflog / ref cleanup — makes it impossible to recover lost commits" "git-reflog"
fi

# Force push to protected branches: main, master, production, prod, release, develop
# Any push with --force / -f / --force-with-lease targeting one of these branches
# is a hard block. This is what destroys shared history irrecoverably.
if echo "$COMMAND" | grep -qEi 'git\s+push(\s+[^-]\S*)*\s+(--force|-f|--force-with-lease)(\s|=|$)' || \
   echo "$COMMAND" | grep -qEi 'git\s+push\s+.*(--force|-f|--force-with-lease).*\s+(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
  # Only hard-block if the target branch is main/master/production/prod/release/develop OR unspecified (defaults to current branch which might be main)
  if echo "$COMMAND" | grep -qEi '(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
    hard_block "Force push to protected branch (main/master/production/prod/release/develop) — this destroys shared history. Never allowed via the hook." "git-force-push-protected"
  fi
fi

# === CATEGORY 2: BLOCKED UNTIL ZAKI APPROVES ===

# --- File deletion ---
# Only match `rm` as a standalone command (not inside words like "form", "arm", "term").
# `(^|\s)` ensures rm is at start of command or after whitespace.
#
# The "recursive or forced" category is now ONLY for recursive deletions
# (flag bundle contains r/R). `rm -f single-file` still gets blocked below
# as plain "file deletion" — different label, still requires approval, but
# doesn't misclassify a single-file delete as a recursive blast (Kai #K2).
#
# CLI-subcommand whitelist: `vercel env rm`, `gh secret rm`, `gh env rm`,
# `docker {image,volume,network,container} rm`, `docker rm` (container) —
# these are API / resource removals, not filesystem deletions. Skip the rm
# check entirely when we detect these shapes.
if echo "$COMMAND" | grep -qE '\b(vercel\s+(env|domains|alias)\s+(rm|remove)|gh\s+(secret|variable|env|release|label|repo|ssh-key|gpg-key|auth\s+token)\s+(rm|remove|delete)|docker\s+(image|volume|network|container)?\s*rm|npm\s+rm|yarn\s+remove|pnpm\s+rm|bun\s+remove|brew\s+(uninstall|rm)|git\s+rm)\b'; then
  :  # CLI resource removal — not filesystem delete, skip rm check
elif echo "$COMMAND" | grep -qE '(^|\s)rm\s+-[A-Za-z]*[rR][A-Za-z]*(\s|$)'; then
  block "Recursive file deletion detected" "rm-rf"
elif echo "$COMMAND" | grep -qE '(^|\s)rm\s'; then
  block "File deletion detected" "rm"
fi
# `/bin/rm` style invocation
if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)(/usr)?/bin/rm\s'; then
  block "File deletion via /bin/rm detected" "rm-path"
fi

# --- Database destructors ---
# IMPORTANT: skip these checks entirely if the command is a git commit
# (commit messages legitimately reference destructive ops in post-mortems).
# Heredoc content is just text from a shell perspective; the actual command
# is `git commit -m ...`, which is non-destructive.
SKIP_DB_CHECKS=0
if echo "$COMMAND" | grep -qE '^[[:space:]]*git[[:space:]]+(commit|tag|log|show|diff|blame)([[:space:]]|$)'; then
  SKIP_DB_CHECKS=1
fi
# Also skip if it's clearly an echo/printf/cat printing the dangerous string.
if echo "$COMMAND" | grep -qE '^[[:space:]]*(echo|printf|cat)([[:space:]]|$)'; then
  SKIP_DB_CHECKS=1
fi

if [ "$SKIP_DB_CHECKS" = "0" ]; then
  if echo "$COMMAND" | grep -qEi '(DROP\s+(TABLE|DATABASE|SCHEMA|USER|ROLE|INDEX|VIEW|TRIGGER|FUNCTION)|TRUNCATE\s+TABLE)'; then
    block "Destructive database operation (DROP/TRUNCATE)" "sql-drop"
  fi

  # DELETE without WHERE OR with WHERE 1=1 / WHERE true
  if echo "$COMMAND" | grep -qEi 'DELETE\s+FROM\s+\w+\s*[;$]'; then
    block "DELETE FROM without WHERE clause, this deletes ALL rows" "sql-delete"
  fi
  if echo "$COMMAND" | grep -qEi 'DELETE\s+FROM\s+\w+\s+WHERE\s+(1\s*=\s*1|true|TRUE)'; then
    block "DELETE FROM with always-true WHERE clause, this deletes ALL rows" "sql-delete-always-true"
  fi

  # ALTER TABLE DROP COLUMN (loses column data permanently)
  if echo "$COMMAND" | grep -qEi 'ALTER\s+TABLE\s+\w+\s+DROP\s+COLUMN'; then
    block "ALTER TABLE DROP COLUMN permanently loses that column's data" "sql-drop-column"
  fi

  # Postgres CLI tools
  if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)dropdb(\s|$)'; then
    block "dropdb command deletes an entire Postgres database" "pg-dropdb"
  fi
  if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)dropuser(\s|$)'; then
    block "dropuser command deletes a Postgres user/role" "pg-dropuser"
  fi
  if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)pg_drop_replication_slot'; then
    block "pg_drop_replication_slot drops replication state" "pg-drop-replication"
  fi

  # MySQL CLI tools
  if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)mysqladmin\s+drop'; then
    block "mysqladmin drop deletes a MySQL database" "mysql-drop"
  fi

  # MongoDB destructive ops
  if echo "$COMMAND" | grep -qEi '\.dropDatabase\(\)|\.drop\(\)|\.deleteMany\s*\(\s*\{\s*\}'; then
    block "MongoDB destructive operation (dropDatabase/drop/deleteMany with empty filter)" "mongo-drop"
  fi

  # Prisma destructive CLI flags (added 2026-05-13 after TixPredict prod data wipe)
  if echo "$COMMAND" | grep -qEi '(prisma|prisma-cli)\s+migrate\s+reset'; then
    block "prisma migrate reset wipes ALL database rows. Run on a non-prod branch or back up first." "prisma-migrate-reset"
  fi
  if echo "$COMMAND" | grep -qEi 'prisma.*--force-reset'; then
    block "Prisma --force-reset wipes ALL database rows" "prisma-force-reset"
  fi
  if echo "$COMMAND" | grep -qEi 'prisma\s+db\s+push.*--accept-data-loss'; then
    block "prisma db push --accept-data-loss drops columns with data" "prisma-accept-data-loss"
  fi
  if echo "$COMMAND" | grep -qEi 'prisma\s+migrate\s+resolve.*--rolled-back'; then
    block "prisma migrate resolve --rolled-back rewrites migration history" "prisma-rolled-back"
  fi

  # Supabase CLI destructive ops
  if echo "$COMMAND" | grep -qEi 'supabase\s+db\s+reset'; then
    block "supabase db reset wipes the entire local/remote database" "supabase-db-reset"
  fi
  if echo "$COMMAND" | grep -qEi 'supabase\s+storage.*rm\s'; then
    block "supabase storage rm deletes storage bucket contents" "supabase-storage-rm"
  fi

  # Neon CLI destructive ops
  if echo "$COMMAND" | grep -qEi 'neon(ctl)?\s+(branches?\s+delete|projects?\s+delete|databases?\s+delete)'; then
    block "Neon CLI delete operation removes a branch/project/database" "neon-delete"
  fi

  # Cloudflare wrangler destructive ops
  if echo "$COMMAND" | grep -qE 'wrangler\s+(r2\s+bucket\s+delete|kv\s+namespace\s+delete|d1\s+delete|secret\s+delete)'; then
    block "wrangler delete operation removes a Cloudflare resource (r2/kv/d1/secret)" "wrangler-delete"
  fi
  if echo "$COMMAND" | grep -qE 'wrangler\s+d1\s+execute.*--remote.*DROP'; then
    block "wrangler d1 execute remote DROP wipes table data on production D1" "wrangler-d1-drop"
  fi

  # Vercel destructive ops on env / projects
  if echo "$COMMAND" | grep -qE 'vercel\s+(remove|rm)\s'; then
    block "vercel remove deletes a project or deployment permanently" "vercel-remove"
  fi
  if echo "$COMMAND" | grep -qE 'vercel\s+env\s+rm'; then
    block "vercel env rm removes an environment variable from production" "vercel-env-rm"
  fi

  # AWS destructive ops
  if echo "$COMMAND" | grep -qE 'aws\s+s3\s+rb\s+.*--force'; then
    block "aws s3 rb --force deletes an S3 bucket with all contents" "aws-s3-rb-force"
  fi
  if echo "$COMMAND" | grep -qE 'aws\s+rds\s+delete-db-(instance|cluster|snapshot)'; then
    block "aws rds delete operation removes a database instance/cluster/snapshot" "aws-rds-delete"
  fi
  if echo "$COMMAND" | grep -qE 'aws\s+dynamodb\s+delete-table'; then
    block "aws dynamodb delete-table removes a DynamoDB table" "aws-dynamodb-delete"
  fi
  if echo "$COMMAND" | grep -qE 'aws\s+ec2\s+terminate-instances'; then
    block "aws ec2 terminate-instances destroys EC2 instances permanently" "aws-ec2-terminate"
  fi

  # GCP destructive ops
  if echo "$COMMAND" | grep -qE 'gcloud\s+(projects\s+delete|sql\s+instances\s+delete)'; then
    block "gcloud delete operation removes a project or SQL instance" "gcloud-delete"
  fi

  # Terraform destructive ops
  if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)terraform\s+destroy'; then
    block "terraform destroy tears down infrastructure" "terraform-destroy"
  fi

  # Kubernetes destructive ops
  if echo "$COMMAND" | grep -qE 'kubectl\s+delete\s+(namespace|pv|pvc|deployment|statefulset)'; then
    block "kubectl delete operation removes critical Kubernetes resources" "kubectl-delete-critical"
  fi

  # Docker volume / image deletion
  if echo "$COMMAND" | grep -qE 'docker\s+(volume|system)\s+prune.*-f'; then
    block "docker volume/system prune -f removes ALL unused volumes/data" "docker-prune"
  fi

  # Redis FLUSHALL / FLUSHDB
  if echo "$COMMAND" | grep -qEi '(^|\s|;|&|\|)(redis-cli\s+)?(FLUSHALL|FLUSHDB)(\s|$)'; then
    block "Redis FLUSHALL/FLUSHDB wipes the cache" "redis-flush"
  fi
fi  # end SKIP_DB_CHECKS

# --- Git destructive operations ---
# Force push (any form, any branch that isn't main/master — those are hard-blocked above)
if echo "$COMMAND" | grep -qEi 'git\s+push(\s+\S+)*\s+(--force|-f)(\s|=|$)'; then
  block "Force push detected. If you actually need this, confirm the target branch isn't shared or critical." "git-force-push"
fi
if echo "$COMMAND" | grep -qEi 'git\s+push.*--force-with-lease'; then
  block "Force-push-with-lease detected. Safer than --force but still rewrites remote history." "git-force-lease"
fi

# Push with --mirror (rewrites everything on remote)
if echo "$COMMAND" | grep -qEi 'git\s+push\s+.*--mirror'; then
  block "git push --mirror can overwrite all remote refs" "git-mirror"
fi

# Push with --delete or :branch syntax (deletes remote branch)
if echo "$COMMAND" | grep -qEi 'git\s+push\s+.*(--delete|:[A-Za-z0-9._/-]+\s*$)'; then
  block "Deleting a remote branch via push" "git-push-delete"
fi

# Reset --hard (destroys uncommitted work AND can drop local commits)
if echo "$COMMAND" | grep -qEi 'git\s+reset\s+--hard'; then
  block "git reset --hard drops uncommitted work and can lose local commits" "git-reset-hard"
fi

# Branch force-delete
if echo "$COMMAND" | grep -qEi 'git\s+branch\s+(-D|--delete\s+--force|-[a-zA-Z]*D[a-zA-Z]*)\s'; then
  block "Force-deleting a branch (git branch -D)" "git-branch-force-delete"
fi

# Clean (removes untracked / ignored files)
if echo "$COMMAND" | grep -qEi 'git\s+clean\s+-[a-z]*f'; then
  block "git clean -f removes untracked files permanently" "git-clean"
fi

# Interactive rebase — can rewrite history arbitrarily
if echo "$COMMAND" | grep -qEi 'git\s+rebase\s+(-i|--interactive)'; then
  block "Interactive rebase can rewrite commits. Confirm the branch isn't shared." "git-rebase-i"
fi

# Rebase --onto (advanced, frequently destructive)
if echo "$COMMAND" | grep -qEi 'git\s+rebase\s+.*--onto'; then
  block "git rebase --onto rewrites history in non-obvious ways" "git-rebase-onto"
fi

# Amend — rewrites the last commit, dangerous if already pushed
if echo "$COMMAND" | grep -qEi 'git\s+commit\s+.*--amend'; then
  block "git commit --amend rewrites the last commit. If already pushed, this requires force-push to remote." "git-amend"
fi

# Checkout with -- or restore that wipes working copy
if echo "$COMMAND" | grep -qEi 'git\s+checkout\s+--\s+\.(\s|$)'; then
  block "git checkout -- . wipes all uncommitted changes" "git-checkout-wipe"
fi
if echo "$COMMAND" | grep -qEi 'git\s+(restore|checkout)\s+\.(\s|$)'; then
  block "git restore . / git checkout . wipes all uncommitted changes" "git-restore-wipe"
fi

# Stash drop / clear
if echo "$COMMAND" | grep -qEi 'git\s+stash\s+(drop|clear)'; then
  block "git stash drop/clear permanently discards stashed work" "git-stash-drop"
fi

# Worktree remove --force
if echo "$COMMAND" | grep -qEi 'git\s+worktree\s+remove\s+.*(-f|--force)'; then
  block "git worktree remove --force discards local changes in the worktree" "git-worktree-force"
fi

# --- Sudo ---
if echo "$COMMAND" | grep -qE '^\s*sudo\s'; then
  block "sudo command detected" "sudo"
fi

# === CATEGORY 3: PROTECTED FILES (approval required to edit) ===
if [ -n "$FILE_PATH" ]; then
  if echo "$FILE_PATH" | grep -qEi '(\.env|\.env\.|id_rsa|id_ed25519|\.ssh/|\.gnupg/)'; then
    block "Edit to secrets/credentials file ($FILE_PATH)" "secrets"
  fi
fi

# All clear
emit_decision "allow"
exit 0
