# Flutter Pigeon 插件手把手：从 wakelock_plus 到一个可跑 Demo

## 1. 先看 wakelock_plus 的 `messages.g.h/.m` 是怎么来的

你看的这两个文件：

- `/Users/huchu/.pub-cache/hosted/pub.flutter-io.cn/wakelock_plus-1.3.2/ios/wakelock_plus/Sources/wakelock_plus/include/wakelock_plus/messages.g.h`
- `/Users/huchu/.pub-cache/hosted/pub.flutter-io.cn/wakelock_plus-1.3.2/ios/wakelock_plus/Sources/wakelock_plus/messages.g.m`

不是作者手写的，而是 Pigeon 生成的。源头在：

```text
/Users/huchu/.pub-cache/hosted/pub.flutter-io.cn/wakelock_plus-1.3.2/pigeons/messages.dart
```

关键配置是：

```dart
@ConfigurePigeon(PigeonOptions(
  dartOut: '../wakelock_plus_platform_interface/lib/messages.g.dart',
  objcHeaderOut:
      'ios/wakelock_plus/Sources/wakelock_plus/include/wakelock_plus/messages.g.h',
  objcSourceOut: 'ios/wakelock_plus/Sources/wakelock_plus/messages.g.m',
  objcOptions: ObjcOptions(
    prefix: 'WAKELOCKPLUS',
    headerIncludePath: './include/wakelock_plus/messages.g.h',
  ),
  kotlinOut:
      'android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/WakelockPlusMessages.g.kt',
))
@HostApi(dartHostTestHandler: 'TestWakelockPlusApi')
abstract class WakelockPlusApi {
  void toggle(ToggleMessage msg);

  IsEnabledMessage isEnabled();
}
```

`pubspec.yaml` 里也写了生成命令提示：

```yaml
dev_dependencies:
  pigeon: ^25.3.0 # dart run pigeon --input "pigeons/messages.dart"
```

所以生成链路是：

```text
pigeons/messages.dart
  -> Dart 调用端 messages.g.dart
  -> iOS messages.g.h / messages.g.m
  -> Android WakelockPlusMessages.g.kt
```

## 2. 为什么注册代码看起来这么复杂

`wakelock_plus` 的 iOS 注册代码是：

```objc
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  WakelockPlusPlugin* instance = [[WakelockPlusPlugin alloc] init];
  SetUpWAKELOCKPLUSWakelockPlusApi(registrar.messenger, instance);
}
```

这段代码其实只做两件事：

1. 创建原生插件对象 `instance`。
2. 把这个对象交给 Pigeon 生成的 `SetUp...Api` 函数，让生成代码去注册 `BasicMessageChannel`。

复杂的部分被 Pigeon 生成到了 `messages.g.m` 里。以 `toggle` 为例，生成代码会：

- 创建 channel：`dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle`
- 使用自定义 codec 编解码 `ToggleMessage`
- 收到 Dart 消息后调用 Objective-C 方法 `toggleMsg:error:`
- 把返回值或 `FlutterError` 包装回 Dart

也就是说，手写 MethodChannel 时你要自己维护 channel 名、参数 Map、返回格式、错误格式；Pigeon 把这些重复代码生成出来，所以注册时只需要一行 `SetUp...Api(...)`。

## 3. Pigeon 的核心概念

Pigeon 不是运行时框架，而是代码生成器。你写一个 Dart 接口定义文件，它生成两边都认识的协议代码。

常用注解：

- `@HostApi()`：Flutter 调原生。比如读取设备信息、打开系统页面、调用 SDK。
- `@FlutterApi()`：原生调 Flutter。比如原生回调 Dart、推送事件。
- `@ConfigurePigeon(PigeonOptions(...))`：配置生成文件路径和语言选项。

常用模型：

```dart
class DeviceInfoRequest {
  String? prefix;
}

class DeviceInfoReply {
  String? platform;
  String? osVersion;
  String? model;
  String? message;
}
```

Pigeon 支持常见平台通道类型：`bool`、`int`、`double`、`String`、`Uint8List`、`List<T>`、`Map<K, V>`、枚举、自定义 class 等。复杂对象会被生成成 Dart class、ObjC class、Kotlin data class。

## 4. Demo 插件目录

我已经在当前工程下放了一个插件 demo：

```text
pigeon_demo_plugin/
  pigeons/messages.dart
  lib/pigeon_demo_plugin.dart
  lib/src/messages.g.dart
  ios/Classes/PigeonDemoPlugin.h
  ios/Classes/PigeonDemoPlugin.m
  ios/Classes/messages.g.h
  ios/Classes/messages.g.m
  android/src/main/kotlin/com/example/pigeon_demo_plugin/PigeonDemoPlugin.kt
  android/src/main/kotlin/com/example/pigeon_demo_plugin/Messages.g.kt
```

Demo 做了两个原生调用：

- `getDeviceInfo`：Flutter 调 iOS/Android，读取平台、系统版本、设备型号。
- `increment`：Flutter 把计数值传给原生，原生加 1 后返回。

Pigeon 源文件在：

```text
pigeon_demo_plugin/pigeons/messages.dart
```

核心内容：

```dart
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  objcHeaderOut: 'ios/Classes/messages.g.h',
  objcSourceOut: 'ios/Classes/messages.g.m',
  objcOptions: ObjcOptions(
    prefix: 'PGN',
    headerIncludePath: 'messages.g.h',
  ),
  kotlinOut:
      'android/src/main/kotlin/com/example/pigeon_demo_plugin/Messages.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.example.pigeon_demo_plugin',
    errorClassName: 'PigeonDemoFlutterError',
  ),
))
@HostApi()
abstract class NativeDemoApi {
  DeviceInfoReply getDeviceInfo(DeviceInfoRequest request);

  CounterReply increment(CounterRequest request);
}
```

注意：Pigeon 不允许 API 类名以 `Pigeon` 开头，所以这里用的是 `NativeDemoApi`。

## 5. 生成代码命令

进入插件目录：

```sh
cd /Users/huchu/Desktop/test-flutter-mix/flutter_study/pigeon_demo_plugin
dart pub get
dart run pigeon --input pigeons/messages.dart
```

只要你改了 `pigeons/messages.dart`，就重新跑一次 `dart run pigeon --input pigeons/messages.dart`。

生成文件不要手改，因为下一次生成会覆盖它们。应该改的是：

- `pigeons/messages.dart`：协议定义
- `ios/Classes/PigeonDemoPlugin.m`：iOS 实现
- `android/src/main/kotlin/com/example/pigeon_demo_plugin/PigeonDemoPlugin.kt`：Android 实现
- `lib/pigeon_demo_plugin.dart`：给业务层用的 Dart 包装

## 6. iOS 端怎么接生成接口

生成的 `ios/Classes/messages.g.h` 里会有：

```objc
@protocol PGNNativeDemoApi
- (nullable PGNDeviceInfoReply *)getDeviceInfoRequest:(PGNDeviceInfoRequest *)request
                                                error:(FlutterError *_Nullable *_Nonnull)error;
- (nullable PGNCounterReply *)incrementRequest:(PGNCounterRequest *)request
                                         error:(FlutterError *_Nullable *_Nonnull)error;
@end

extern void SetUpPGNNativeDemoApi(id<FlutterBinaryMessenger> binaryMessenger,
                                  NSObject<PGNNativeDemoApi> *_Nullable api);
```

所以手写插件只要实现这个协议：

```objc
@interface PigeonDemoPlugin () <PGNNativeDemoApi>
@end

@implementation PigeonDemoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  PigeonDemoPlugin* instance = [[PigeonDemoPlugin alloc] init];
  SetUpPGNNativeDemoApi(registrar.messenger, instance);
}
@end
```

这和 `wakelock_plus` 的 `SetUpWAKELOCKPLUSWakelockPlusApi(registrar.messenger, instance)` 是同一种模式。

## 7. Android 端怎么接生成接口

生成的 Kotlin 文件里会有：

```kotlin
interface NativeDemoApi {
  fun getDeviceInfo(request: DeviceInfoRequest): DeviceInfoReply
  fun increment(request: CounterRequest): CounterReply

  companion object {
    fun setUp(binaryMessenger: BinaryMessenger, api: NativeDemoApi?)
  }
}
```

插件实现：

```kotlin
class PigeonDemoPlugin : FlutterPlugin, NativeDemoApi {
  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    NativeDemoApi.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    NativeDemoApi.setUp(binding.binaryMessenger, null)
  }
}
```

这对应 iOS 的 `SetUp...Api`，只是 Kotlin 里是 `NativeDemoApi.setUp(...)`。

## 8. 集成到当前 Flutter App

当前目录缺少根 `pubspec.yaml`，所以我没有直接改工程依赖，避免误造一个不完整配置。恢复或创建根 `pubspec.yaml` 后，加上本地 path 依赖：

```yaml
dependencies:
  pigeon_demo_plugin:
    path: pigeon_demo_plugin
```

然后执行：

```sh
flutter pub get
```

我已经把 App 侧 demo 放在：

```text
lib/pigeon_demo/pigeon_demo_main.dart
lib/pigeon_demo/pigeon_demo_page.dart
```

可以临时把入口切到：

```dart
import 'pigeon_demo/pigeon_demo_main.dart' as pigeon_demo;

void main() => pigeon_demo.main();
```

或者在 IDE 里直接以 `lib/pigeon_demo/pigeon_demo_main.dart` 作为运行入口。

## 9. 调试 checklist

如果 Dart 调用时报：

```text
Unable to establish connection on channel
```

优先检查：

- App 的 `pubspec.yaml` 是否依赖了插件。
- 是否执行过 `flutter pub get`。
- iOS/Android 插件类是否在插件 `pubspec.yaml` 的 `flutter.plugin.platforms` 下声明。
- iOS 是否调用了 `SetUpPGNNativeDemoApi(registrar.messenger, instance)`。
- Android 是否调用了 `NativeDemoApi.setUp(binding.binaryMessenger, this)`。
- 改过 `pigeons/messages.dart` 后是否重新生成了所有端的 `messages.g.*`。

## 10. MethodChannel 和 Pigeon 的取舍

MethodChannel 适合很小的、临时的调用；Pigeon 适合插件、SDK 封装、多人维护和参数结构会演进的场景。

Pigeon 的收益：

- channel 名统一生成，不容易 Dart/原生写错。
- 参数和返回值有类型，不用到处手拆 Map。
- iOS/Android/Dart 同一份协议源头。
- 错误包装格式统一。
- 生成的测试 API 更容易 mock。

代价：

- 多一个生成步骤。
- 生成文件变多。
- 接口改名后要同步实现生成协议的方法名。

一句话：`wakelock_plus` 的注册代码看起来绕，是因为它把“通道注册、编解码、参数转换、错误返回”都交给 Pigeon 生成代码处理了；你手写的插件类只负责真正的业务逻辑。

## 11. Pigeon 底层到底用哪个通道

先给结论：

| 方案 | 底层/直接使用的 Flutter 通信机制 | 适合场景 |
| --- | --- | --- |
| `MethodChannel` | 直接基于 `BinaryMessenger` 发送方法调用消息 | 双向异步方法调用，常用于一次调用一次返回 |
| `EventChannel` | 直接基于 `BinaryMessenger` 做事件流订阅和分发 | Native 持续推送事件到 Flutter，比如传感器、下载进度、播放器状态 |
| `BasicMessageChannel` | 直接基于 `BinaryMessenger` 发送任意消息 | 双向消息、结构更自由、想自己控制消息格式 |
| `Pigeon @HostApi / @FlutterApi` | 生成代码里默认创建 `BasicMessageChannel` | 类型安全的 Flutter 和 Native 双向调用 |
| `Pigeon @EventChannelApi` | 生成代码里创建 `EventChannel` | 用 Pigeon 生成 Native 到 Flutter 的事件流代码 |
| `FFI` | 不走 Platform Channel，走 Dart VM 的 `dart:ffi` C ABI 调用 | 高频、同步、性能敏感的 native 函数调用 |

所以你问“Pigeon、Flutter 和 Native 通讯底层用的是 `MethodChannel`、`EventChannel`、`BasicMessageChannel` 还是 `FFI`”：  

**普通 Pigeon 接口，也就是 `@HostApi()` 和 `@FlutterApi()`，底层生成的是 `BasicMessageChannel`，不是 `MethodChannel`，也不是 `FFI`。**

当前 demo 的生成文件可以直接证明这一点。

Dart 端 `pigeon_demo_plugin/lib/src/messages.g.dart` 里，调用 `getDeviceInfo` 时创建的是：

```dart
final BasicMessageChannel<Object?> pigeonVar_channel =
    BasicMessageChannel<Object?>(
  pigeonVar_channelName,
  pigeonChannelCodec,
  binaryMessenger: pigeonVar_binaryMessenger,
);
```

Android 端 `pigeon_demo_plugin/android/src/main/kotlin/com/example/pigeon_demo_plugin/Messages.g.kt` 里，注册处理器时创建的是：

```kotlin
val channel = BasicMessageChannel<Any?>(
  binaryMessenger,
  "dev.flutter.pigeon.pigeon_demo_plugin.NativeDemoApi.getDeviceInfo$separatedMessageChannelSuffix",
  codec
)
```

iOS 端 `pigeon_demo_plugin/ios/Classes/messages.g.m` 里，注册处理器时创建的是：

```objc
FlutterBasicMessageChannel *channel =
  [[FlutterBasicMessageChannel alloc]
    initWithName:@"dev.flutter.pigeon.pigeon_demo_plugin.NativeDemoApi.getDeviceInfo"
    binaryMessenger:binaryMessenger
    codec:PGNGetMessagesCodec()];
```

注意这里有两个容易混的点。

第一，`BinaryMessenger` 不是一种和 `MethodChannel` 并列的 channel。它更像 Flutter 引擎提供的底层消息收发器，`MethodChannel`、`EventChannel`、`BasicMessageChannel` 都是建立在 `BinaryMessenger` 之上的封装。Pigeon 生成的 `SetUp...Api(registrar.messenger, instance)` 或 `NativeDemoApi.setUp(binding.binaryMessenger, this)`，传进去的就是这个底层 messenger。

第二，`MethodChannel` 也可以双向调用。Dart 可以 `invokeMethod` 调 Native，Native 也可以通过同一个 channel name 的 `MethodChannel` 调 Dart，只要另一端注册了 method call handler 就能收到。它和 `EventChannel` 的区别不在于“能不能双向”，而在于通信模型：`MethodChannel` 更像一次方法调用配一次结果；`EventChannel` 更像 Native 持续推送一串事件。

第三，`Pigeon` 本身不是一种运行时通道。它是代码生成器。你写 `pigeons/messages.dart`，它帮你生成 Dart、iOS、Android 等端的类型、codec、channel name、注册函数和错误包装。真正运行时收发消息的还是 Flutter 的 platform channel 体系。

可以把层级理解成：

```text
Dart API / Native API
  -> Pigeon 生成的类型安全包装代码
  -> BasicMessageChannel 或 EventChannel
  -> BinaryMessenger
  -> Flutter Engine
  -> Android/iOS/macOS/Windows/Linux Native
```

而 `FFI` 是另一条路：

```text
Dart
  -> dart:ffi
  -> DynamicLibrary / C ABI
  -> C/C++/Rust/Objective-C 暴露出来的 C 函数
```

`FFI` 不经过 `MethodChannel`、`EventChannel`、`BasicMessageChannel`，也不通过 `BinaryMessenger` 发 platform message。它更接近“Dart 直接调用 native 动态库函数”。所以在性能上适合高频、小粒度、同步计算类调用，但它不适合直接操作 Android `Activity`、iOS `UIViewController` 这种平台生命周期对象；这类系统能力通常还是用插件通道或 Pigeon 更自然。

一句话记忆：

```text
MethodChannel：双向异步方法调用，常见是一问一答。
EventChannel：Native 连续推事件给 Flutter。
BasicMessageChannel：更底层、更自由的消息通道。
Pigeon：代码生成器，普通 HostApi/FlutterApi 默认生成 BasicMessageChannel。
FFI：不走 Flutter channel，直接调 native 动态库函数。
```
