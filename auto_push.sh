#!/bin/bash
#
# ------------------------------------------------------------
# Auto Git Push Script
# Author: Porkeat
# Description:
#   - Automatically updates "Last Updated" field in README.md
#   - Uses Cambodia timezone (Asia/Phnom_Penh)
#   - Commits all changes
#   - Pushes to the current Git branch
#
# Usage:
#   ./push.sh
#   ./push.sh "Your custom commit message"
#
# Date Format Example:
#   02 March 2026 - 10:15 AM
# ------------------------------------------------------------

# Use Cambodia timezone
export TZ="Asia/Phnom_Penh"

COMMIT_MESSAGE=${1:-"Update: $(date '+%d %B %Y - %I:%M %p')"}

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: This is not a Git repository."
    exit 1
fi

README_FILE="README.md"

# Easy-to-read date format
LAST_UPDATED=$(date '+%d %B %Y - %I:%M %p')

if [ -f "$README_FILE" ]; then
    if grep -q "Last Updated:" "$README_FILE"; then
        sed -i.bak "s|Last Updated:.*|Last Updated: $LAST_UPDATED|g" "$README_FILE"
        rm -f "$README_FILE.bak"
    fi
fi

git add .
git commit -m "$COMMIT_MESSAGE"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push origin "$CURRENT_BRANCH"

echo "✅ Pushed to $CURRENT_BRANCH at $LAST_UPDATED"