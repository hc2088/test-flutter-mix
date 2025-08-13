// 返回最长无重复子串内容和长度
Map<String, dynamic> longestUniqueSubstring(String s) {
  int left = 0;
  int maxLen = 0;
  int maxStart = 0;
  Map<String, int> lastIndex = {};

  for (int right = 0; right < s.length; right++) {
    String c = s[right];
    if (lastIndex.containsKey(c) && lastIndex[c]! >= left) {
      left = lastIndex[c]! + 1;
    }
    lastIndex[c] = right;

    int curLen = right - left + 1;
    if (curLen > maxLen) {
      maxLen = curLen;
      maxStart = left;
    }
  }

  String substring = s.substring(maxStart, maxStart + maxLen);
  return {'length': maxLen, 'substring': substring};
}

void main() {
  var res = longestUniqueSubstring("abcabcbb");
  print("最长无重复子串: ${res['substring']}, 长度: ${res['length']}");
}
