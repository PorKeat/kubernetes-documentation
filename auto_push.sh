#!/bin/bash

export TZ="Asia/Phnom_Penh"

COMMIT_MESSAGE=${1:-"Auto commit: $(date '+%Y-%m-%d %H:%M:%S %Z')"}

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: This is not a Git repository."
    exit 1
fi

README_FILE="README.md"

LAST_COMMIT_DATE=$(date '+%Y-%m-%d %H:%M:%S %Z')

if [ -f "$README_FILE" ]; then
    if grep -q "Last Updated:" "$README_FILE"; then
        sed -i.bak "s|Last Updated:.*|Last Updated: $LAST_COMMIT_DATE|g" "$README_FILE"
        rm -f "$README_FILE.bak"
    fi
fi

git add .

git commit -m "$COMMIT_MESSAGE"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push origin "$CURRENT_BRANCH"

echo "✅ Successfully pushed to $CURRENT_BRANCH at $LAST_COMMIT_DATE"