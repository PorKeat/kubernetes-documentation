#!/bin/bash

COMMIT_MESSAGE=${1:-"Auto commit: $(date +'%Y-%m-%d %H:%M:%S')"}

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: This is not a Git repository."
    exit 1
fi

git add .

git commit -m "$COMMIT_MESSAGE"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push origin "$CURRENT_BRANCH"

echo "✅ Successfully pushed to $CURRENT_BRANCH with message: $COMMIT_MESSAGE"
