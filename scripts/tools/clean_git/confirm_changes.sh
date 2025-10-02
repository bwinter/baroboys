# In a test script
ORIG="$HOME/Desktop/Baroboys-backup"
CLEAN="$HOME/Desktop/Baroboys"

echo "🔍 Comparing only differing files..."
find "$ORIG" -type f | sed "s|$ORIG/||" | sort > /tmp/orig_files.txt
find "$CLEAN" -type f | sed "s|$CLEAN/||" | sort > /tmp/clean_files.txt

echo "-----------------------------------------------"
comm -3 /tmp/orig_files.txt /tmp/clean_files.txt
echo "-----------------------------------------------"
echo "✅ Shown above: files only in backup (left) or only in cleaned (right)."
