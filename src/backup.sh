#!/bin/bash

# --- GitHub Backup Script ---

# For use with e.g. LaunchAgent
#export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

# For use without 'gh auth login'
#export GH_TOKEN='github_pat_ADD_YOUR_TOKEN'

ACCESS_LOG=/tmp/github_backup_access.log
ERROR_LOG=/tmp/github_backup_error.log  

# Empty logs
cat /dev/null > $ACCESS_LOG
cat /dev/null > $ERROR_LOG

# Check if target path is provided
if [ -z "$1" ]; then
    echo "Missing target path"
    echo "Usage: $0 /your/target/path"
    exit 1
fi

# Check authentication
GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null)

if [ -z "$GITHUB_USER" ]; then
    echo "Error: Not authenticated with GitHub CLI. Run 'gh auth login'."
    exit 1
fi

# Resolve absolute target directory (creates it if it doesn't exist)
TARGET_DIR=$(mkdir -p "$1" && cd "$1" && pwd)
COUNT_NEW=0
COUNT_UPDATED=0
COUNT_FAILED=0
STATE_FILE="$TARGET_DIR/.last_sync"
BACKUP_STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Load last backup date
if [ -f "$STATE_FILE" ]; then
    LAST_SYNC=$(cat "$STATE_FILE")
else
    LAST_SYNC="1970-01-01T00:00:00Z"
fi

echo "📦 Fetching own repositories for user \"$GITHUB_USER\" updated after \"$LAST_SYNC\"..."

# Fetch only non-forked repos updated since LAST_SYNC
REPOS=$(gh repo list --limit 1000 --json sshUrl,isFork,pushedAt --jq ".[] | select(.isFork == false and .pushedAt > \"${LAST_SYNC}\") | .sshUrl" | sort -f)

#if [ -z "$REPOS" ]; then
#    echo "No repositories found. Are you logged in with 'gh auth login'?"
#    exit 1
#fi

# Count total number of repositories to process
TOTAL_REPOS=$(echo "$REPOS" | wc -l | xargs)
CURRENT_INDEX=0

for URL in $REPOS; do
    ((CURRENT_INDEX++))
    echo
    REPO_NAME=$(basename "$URL" .git)
    # Bare mirror clone: all branches, tags and refs, no working copy
    FULL_PATH="$TARGET_DIR/$REPO_NAME.git"

    printf "[%${#TOTAL_REPOS}d/%d]" "$CURRENT_INDEX" "$TOTAL_REPOS"
    echo

    if [ -d "$FULL_PATH" ]; then
        echo "🔄 Update: $REPO_NAME"
        # git -C runs the command in the target directory
        # remote update mirrors all refs 1:1 (force-pushes included), --prune removes deleted refs
        if git -C "$FULL_PATH" remote update --prune; then
            ((COUNT_UPDATED++))
        else
            ((COUNT_FAILED++))
            echo "⚠️  WARNING: Update failed for $REPO_NAME."
        fi
    else
        echo "⬇️  Clone: $REPO_NAME"
        if git clone --mirror "$URL" "$FULL_PATH"; then
            ((COUNT_NEW++))
        else
            ((COUNT_FAILED++))
            echo "⚠️  WARNING: Clone failed for $REPO_NAME."
        fi
    fi
done

# Update timestamp only if all repositories were synced successfully,
# otherwise failed repositories would be skipped until their next push
if [ "$COUNT_FAILED" -eq 0 ]; then
    echo "$BACKUP_STARTED" > "$STATE_FILE"
fi

# Print summary
echo
echo "---------------------------------------"
if [ "$COUNT_FAILED" -eq 0 ]; then
    echo "✅ Sync complete!"
else
    echo "⚠️  Sync finished with errors"
fi
echo "⬇️  Cloned:           $COUNT_NEW"
echo "🔄 Updated:          $COUNT_UPDATED"
echo "❌ Failed:           $COUNT_FAILED"
echo "📁 Target directory: $TARGET_DIR"
echo "---------------------------------------"

if [ "$COUNT_FAILED" -gt 0 ]; then
    echo "⚠️  $COUNT_FAILED repositories failed. Timestamp not updated, they will be retried on the next run."
    exit 1
fi
