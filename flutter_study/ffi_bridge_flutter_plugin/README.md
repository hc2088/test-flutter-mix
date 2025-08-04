## 使用 FFI 调用 `invokeCommonFuncSync` 的特点

```
 
Pointer<Utf8> Function(Pointer<Utf8>) invokeJSCommonFuncSync = dl
  .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>('invokeCommonFuncSync')
  .asFunction();
```

### 1. **直接调用 Native 层函数**

-   通过 `ffi`（Foreign Function Interface）调用的是一个 **C/C++ 或其他 native 编译语言** 实现的函数。
-   跳过了 Flutter 引擎的中间层，没有经过平台 channel。

### 2. **同步调用**

-   这个函数是同步的，调用时 Dart 会**阻塞当前线程**直到 native 函数返回。
-   比如你在 UI 线程中调用这个方法，UI 会被卡住直到 native 返回。

### 3. **线程管理全靠你自己**

-   没有 isolate 切换，也没有平台通道的调度器介入。
-   如果这个函数执行时间稍长，**必须放在 `compute()`、`Future.microtask` 或 Isolate 中处理**，否则会卡界面。

### 4. **性能更高，延迟更低**

-   没有 MethodChannel 的序列化/反序列化、消息队列、引擎调度等开销。
-   适合频繁或高性能的 native 通信，比如图像处理、加解密、数据压缩等。

* * *

## ✅ `MethodChannel` 调用的特点

```
 
final result = await methodChannel.invokeMethod('getSomeData');
```

### 1. **通过 Flutter 框架层与 Native 通信**

-   本质上是通过 Flutter Engine 与平台（如 iOS 的 `Objective-C/Swift`、Android 的 `Java/Kotlin`）进行异步通信。
-   内部涉及 **消息传递、序列化**，并通过 Dart 事件循环调度。

### 2. **异步调用**

-   所有 `MethodChannel` 方法默认是异步的（返回 `Future`）。
-   执行不会阻塞 UI，适合放在 UI 线程中调用。

### 3. **Flutter 自动管理线程切换**

-   平台端可以在主线程或子线程中执行代码（具体由 native 实现决定）。
-   Dart 层自然是异步感知，不用担心卡顿。

### 4. **开发友好，但性能不如 FFI**

-   接口抽象清晰，跨平台一致性强。
-   对性能要求高的调用（尤其是频繁短调用），MethodChannel 开销就会显得偏高。