#!/bin/bash

# Script to show differences made to fire_department.rb over the last 5 days
# Usage: ./show_fire_department_changes.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE_PATH="fire_department.rb"
DAYS_BACK=5

echo "=========================================="
echo "Fire Department Changes - Last $DAYS_BACK Days"
echo "=========================================="
echo "File: $FILE_PATH"
echo "Date range: $(date -v-${DAYS_BACK}d '+%Y-%m-%d') to $(date '+%Y-%m-%d')"
echo "=========================================="
echo

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "❌ Error: $FILE_PATH not found in current directory"
    exit 1
fi

# Get commits from last 5 days that touched this file
SINCE_DATE=$(date -v-${DAYS_BACK}d '+%Y-%m-%d')
COMMITS=$(git log --since="$SINCE_DATE" --oneline --follow "$FILE_PATH" | cut -d' ' -f1)

if [ -z "$COMMITS" ]; then
    echo "📋 No commits found for $FILE_PATH in the last $DAYS_BACK days"
    exit 0
fi

# Count commits
COMMIT_COUNT=$(echo "$COMMITS" | wc -l | tr -d ' ')
echo "🔍 Found $COMMIT_COUNT commit(s) affecting $FILE_PATH:"
echo

# Process each commit
COMMIT_NUMBER=1
for commit in $COMMITS; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 COMMIT #$COMMIT_NUMBER: $commit"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get commit metadata
    COMMIT_INFO=$(git show --no-patch --format="Author: %an <%ae>%nDate: %ad%nMessage: %s" --date=format:'%Y-%m-%d %H:%M:%S' "$commit")
    echo "$COMMIT_INFO"
    echo
    
    # Check if this is the initial commit (file creation)
    PARENT_COUNT=$(git cat-file -p "$commit" | grep '^parent ' | wc -l | tr -d ' ')
    FILE_EXISTS_IN_PARENT=$(git ls-tree -r "${commit}^" 2>/dev/null | grep -q "$FILE_PATH" && echo "yes" || echo "no")
    
    if [ "$PARENT_COUNT" -eq 0 ] || [ "$FILE_EXISTS_IN_PARENT" = "no" ]; then
        echo "🆕 FILE CREATION - Initial version of $FILE_PATH"
        echo
        echo "📊 Statistics:"
        STATS=$(git show --numstat "$commit" -- "$FILE_PATH" 2>/dev/null | grep "$FILE_PATH")
        if [ -n "$STATS" ]; then
            LINES_ADDED=$(echo "$STATS" | awk '{print $1}')
            echo "   Lines added: $LINES_ADDED"
            echo "   Lines deleted: 0"
        else
            echo "   Lines added: (new file)"
        fi
        echo
        echo "📂 Full file content:"
        git show "$commit:$FILE_PATH" 2>/dev/null | head -50
        if [ $(git show "$commit:$FILE_PATH" 2>/dev/null | wc -l) -gt 50 ]; then
            echo "   ... (showing first 50 lines, file continues)"
        fi
    else
        echo "🔧 FILE MODIFICATION"
        echo
        
        # Show statistics
        STATS=$(git show --numstat "$commit" -- "$FILE_PATH" 2>/dev/null | grep "$FILE_PATH")
        if [ -n "$STATS" ]; then
            LINES_ADDED=$(echo "$STATS" | awk '{print $1}')
            LINES_DELETED=$(echo "$STATS" | awk '{print $2}')
            echo "📊 Statistics:"
            echo "   Lines added: $LINES_ADDED"
            echo "   Lines deleted: $LINES_DELETED"
            if [ "$LINES_ADDED" != "-" ] && [ "$LINES_DELETED" != "-" ]; then
                echo "   Net change: $((LINES_ADDED - LINES_DELETED))"
            fi
            echo
        fi
        
        # Show the actual diff
        echo "📋 Changes made:"
        git show "$commit" -- "$FILE_PATH" | sed '1,/^@@/d' | head -100
        
        # Check if diff was truncated
        TOTAL_DIFF_LINES=$(git show "$commit" -- "$FILE_PATH" | sed '1,/^@@/d' | wc -l)
        if [ "$TOTAL_DIFF_LINES" -gt 100 ]; then
            echo "   ... (showing first 100 lines of diff, $((TOTAL_DIFF_LINES - 100)) more lines)"
        fi
    fi
    
    echo
    echo "🔗 View full commit: git show $commit"
    echo
    
    ((COMMIT_NUMBER++))
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "File: $FILE_PATH"
echo "Commits analyzed: $COMMIT_COUNT"
echo "Time period: Last $DAYS_BACK days"
echo
echo "📈 Overall statistics across all commits:"
TOTAL_STATS=$(git log --since="$SINCE_DATE" --numstat --follow "$FILE_PATH" | grep "$FILE_PATH" | awk '{
    if ($1 != "-" && $2 != "-") {
        added+=$1; 
        deleted+=$2
    }
} END {
    printf "Added: %d, Deleted: %d, Net: %+d\n", added, deleted, added-deleted
}')
echo "   $TOTAL_STATS"
echo
echo "🔍 To see changes between any two commits:"
echo "   git diff <older_commit> <newer_commit> -- $FILE_PATH"
echo
echo "📜 To see complete history of this file:"
echo "   git log --follow --patch -- $FILE_PATH"
echo
echo "✨ Analysis complete!"