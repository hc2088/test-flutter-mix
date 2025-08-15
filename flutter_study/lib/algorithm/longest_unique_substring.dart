void main() {
  String s = "abcabcbb";
  var result = longestSubstringWithoutRepeat(s);
  print("最长无重复子串: '${result['substring']}', 长度: ${result['length']}");
}

Map<String, dynamic> longestSubstringWithoutRepeat(String s) {
  int start = 0; // 窗口起始位置
  int maxLen = 0;
  int maxStart = 0; // 记录最长子串的起始位置
  Map<String, int> lastSeen = {}; // 记录每个字符上一次出现的位置

  for (int end = 0; end < s.length; end++) {
    String ch = s[end];

    // 如果当前字符出现过，并且位置在当前窗口内，则移动 start
    if (lastSeen.containsKey(ch) && lastSeen[ch]! >= start) {
      start = lastSeen[ch]! + 1;
    }

    // 更新当前字符的位置
    lastSeen[ch] = end;

    // 判断是否为更长的子串
    if (end - start + 1 > maxLen) {
      maxLen = end - start + 1;
      maxStart = start;
    }
  }

  return {
    "substring": s.substring(maxStart, maxStart + maxLen),
    "length": maxLen
  };
}
