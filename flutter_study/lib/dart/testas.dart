// | 写法      | 含义                                  | 类型不匹配时  | 值为 null 时                 |
// | ------- | ----------------------------------- | ------- | ------------------------- |
// | `as T`  | 强制转换为 `T`                           | **抛异常** | **抛异常**（如果 T 非可空）         |
// | `as T?` | 强制转换为 `T?`（可空）                      | **抛异常** | ✅ 返回 `null`               |

// as T? 和 as T! 都不会让类型不匹配变安全 —— 类型不对照样崩。

void main() {
  dynamic a = "Hello"; // String
  dynamic b = null; // null
  dynamic c = 123; // int

  print("===== Case 1: 类型匹配 =====");
  print((a as String)); // ✅
  print((a as String?)); // ✅

  print("\n===== Case 2: 值为 null =====");
  print((b as String?)); // ✅ null

  try {
    print((b as String)); // ❌ 抛异常
  } catch (e) {
    print("b as String 崩了: $e");
  }

  print("\n===== Case 3: 类型不匹配 =====");
  try {
    print((c as String)); // ❌ 崩
  } catch (e) {
    print("c as String 崩了: $e");
  }

  try {
    print((c as String?)); // ❌ 仍然崩
  } catch (e) {
    print("c as String? 崩了: $e");
  }
}
