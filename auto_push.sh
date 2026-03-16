#!/bin/bash

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

# Update Last Updated in README.md
if [ -f "$README_FILE" ]; then
    if grep -q "Last Updated:" "$README_FILE"; then
        sed -i.bak "s|Last Updated:.*|Last Updated: $LAST_UPDATED|g" "$README_FILE"
        rm -f "$README_FILE.bak"
    fi
fi

# ----------------------------
# GitGuardian pre-commit scan
# ----------------------------
if ! command -v ggshield > /dev/null 2>&1; then
    echo "⚠️ GitGuardian CLI not installed. Skipping secret scan."
else
    ggshield secret scan pre-commit
    if [ $? -ne 0 ]; then
        echo "🚨 Secret detected! Push aborted by GitGuardian."
        exit 1
    fi
fi

# Add, commit, push
git add .
git commit -m "$COMMIT_MESSAGE"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push origin "$CURRENT_BRANCH"

echo "✅ Pushed to $CURRENT_BRANCH at $LAST_UPDATED"