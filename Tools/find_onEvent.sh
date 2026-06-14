#!/bin/bash
# sh find_onEvent.sh /Users/huchu/Documents/nook_client/lib

SEARCH_PATH=${1:-"."}
OUTPUT_FILE="onEvent_output_$(date +%Y%m%d_%H%M%S).txt"

echo "🔍 Searching for UmengCommonSdk.onEvent(...) under: $SEARCH_PATH"
echo "📄 Output file: $OUTPUT_FILE"
echo

# 清空或创建输出文件
echo "Search Path: $SEARCH_PATH" > "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "============================================" >> "$OUTPUT_FILE"

# 遍历 Dart 文件并进行多行匹配
for file in $(find "$SEARCH_PATH" -type f -name "*.dart"); do
  perl -0777 -ne '
    while ( /UmengCommonSdk\.onEvent\s*\((.*?)\)\s*;/sg ) {
      print "FILE: '"$file"'\n";
      print "-------- MATCH START --------\n";
      print "$&\n";
      print "--------- MATCH END ---------\n\n";
    }
  ' "$file" >> "$OUTPUT_FILE"
done

echo "✅ Done! Results are saved in $OUTPUT_FILE"
