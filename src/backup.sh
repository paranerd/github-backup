#!/bin/bash

# --- GitHub Backup Script ---

# Check if target path is provided
if [ -z "$1" ]; then
    echo "Missing target path"
    echo "Usage: $0 /your/target/path
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
STATE_FILE="$TARGET_DIR/.last_sync"
BACKUP_STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Load last backup date
if [ -f "$STATE_FILE" ]; then
    LAST_SYNC=$(cat "$STATE_FILE")
else
    LAST_SYNC="1970-01-01T00:00:00Z"
fi

echo "📦 Fetching own repositories for user \"$GITHUB_USER\" updated after \"$BACKUP_STARTED\"..."

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
    FULL_PATH="$TARGET_DIR/$REPO_NAME"

    printf "[%${#TOTAL_REPOS}d/%d]" "$CURRENT_INDEX" "$TOTAL_REPOS"
    echo

    if [ -d "$FULL_PATH" ]; then
        echo "🔄 Update: $REPO_NAME"
        # git -C runs the command in the target directory
        if git -C "$FULL_PATH" pull; then
            ((COUNT_UPDATED++))
        else
            echo "⚠️  WARNING: Update failed for $REPO_NAME."
        fi
    else
        echo "⬇️  Clone: $REPO_NAME"
        if git clone "$URL" "$FULL_PATH"; then
            ((COUNT_NEW++))
        else
            echo "⚠️  WARNING: Clone failed for $REPO_NAME."
        fi
    fi
done

# Update timestamp
echo $BACKUP_STARTED > "$STATE_FILE"

# Print summary
echo
echo "---------------------------------------"
echo "✅ Sync complete!"
echo "⬇️  Cloned:           $COUNT_NEW"
echo "🔄 Updated:          $COUNT_UPDATED"
echo "📁 Target directory: $TARGET_DIR"
echo "---------------------------------------"
