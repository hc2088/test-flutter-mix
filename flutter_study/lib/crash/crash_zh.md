|---|---|
| **选择平台：** | [iOS+](https://firebase.google.com/docs/crashlytics/ios/customize-crash-reports) [Android](https://firebase.google.com/docs/crashlytics/android/customize-crash-reports) [Flutter](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports) [Unity](https://firebase.google.com/docs/crashlytics/unity/customize-crash-reports) |

<br />

你可以在 Firebase 控制台的 **DevOps 与互动** > [**Crashlytics** 信息中心](https://console.firebase.google.com/project/_/crashlytics)中打开某个问题，查看详细的事件报告。你可以自定义这些报告，以便更好地了解应用中发生了什么，以及上报到 Crashlytics 的事件是在什么情况下发生的。

- 将[未捕获异常](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports#report-uncaught-exceptions)和[已捕获异常](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports#report-caught-exceptions)上报到 Crashlytics。

- 为应用添加埋点，记录[自定义键](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports#add-keys)、[自定义日志消息](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports#add-logs)和[用户标识](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports#set-user-ids)。

- 如果应用使用 Firebase Google Analytics SDK，就会自动获取[面包屑日志](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports#get-breadcrumb-logs)。这些日志可以帮助你了解用户在应用中发生 Crashlytics 事件之前执行了哪些操作。

- 关闭自动崩溃报告，并[启用用户主动选择上报](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports#enable-reporting)。请注意，默认情况下，Crashlytics 会为所有应用用户自动收集平台原生崩溃报告。

> [!NOTE]
> **注意：** 对于 Flutter 应用，致命错误报告会实时发送到 Crashlytics，无需用户重启应用。非致命错误报告会先写入磁盘，在下一次发生致命错误或应用重启时发送。

## 上报异常

## 上报未捕获异常

你可以通过将 `FlutterError.onError` 设置为 `FirebaseCrashlytics.instance.recordFlutterFatalError`，自动捕获 Flutter 框架中抛出的所有“致命”错误。如果还要捕获“非致命”异常，可以将 `FlutterError.onError` 设置为 `FirebaseCrashlytics.instance.recordFlutterError`：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  bool weWantFatalErrorRecording = true;
  FlutterError.onError = (errorDetails) {
    if (weWantFatalErrorRecording) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } else {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    }
  };

  runApp(MyApp());
}
```

### 异步错误

Flutter 框架不会捕获异步错误：

```dart
ElevatedButton(
  onPressed: () async {
    throw Error();
  }
  ...
)
```

要捕获这类错误，可以使用 `PlatformDispatcher.instance.onError` 处理器：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // 将未被 Flutter 框架处理的未捕获异步错误交给 Crashlytics。
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(MyApp());
}
```

### Flutter 上下文之外的错误

要捕获 Flutter 上下文之外发生的错误，可以为当前 `Isolate` 注册错误监听器：

```dart
Isolate.current.addErrorListener(RawReceivePort((pair) async {
  final List<dynamic> errorAndStacktrace = pair;
  await FirebaseCrashlytics.instance.recordError(
    errorAndStacktrace.first,
    errorAndStacktrace.last,
    fatal: true,
  );
}).sendPort);
```

## 上报已捕获异常

除了自动上报应用崩溃外，Crashlytics 还允许你记录非致命异常。这些异常会在下一次上报致命事件或应用重启时发送给你。

> [!NOTE]
> **注意：** Crashlytics 最多只保存最近记录的 8 个非致命异常。如果应用抛出的异常超过 8 个，较早的异常会被丢弃。每次发生致命异常后，这个计数都会重置，因为致命异常会触发报告发送。

可以在应用的 `catch` 代码块中使用 `recordError` 记录非致命异常。例如：

```dart
await FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: '一个非致命错误'
);

// 也可以使用：
await FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
```

你还可以通过 `information` 属性记录更多错误信息：

```dart
await FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: '一个非致命错误',
  information: ['错误的其他诊断信息', '版本 2.0'],
);
```

> [!WARNING]
> **警告：** 如果要在异常消息中加入唯一值（例如用户 ID 或时间戳），请使用[自定义键](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports#add-keys)，不要直接把该值拼进异常消息。直接添加可能导致多种问题，也可能使 Crashlytics 限制应用的错误报告。

这些异常会作为非致命问题显示在 Firebase 控制台的 **DevOps 与互动** > [**Crashlytics** 信息中心](https://console.firebase.google.com/project/_/crashlytics)中。问题摘要包含通常可从崩溃报告中获得的状态信息，以及按应用版本和硬件设备分类的数据。

Crashlytics 在专用后台线程上处理异常，以尽量减少对应用性能的影响。为了减少用户的网络流量，必要时 Crashlytics 会限制设备发送报告的数量。

## 添加自定义键

自定义键可以记录崩溃发生前应用的具体状态。你可以将任意键值对附加到崩溃报告中，然后在 Firebase 控制台的 **DevOps 与互动** > [**Crashlytics** 信息中心](https://console.firebase.google.com/project/_/crashlytics)中使用这些键搜索和筛选崩溃报告。

- 你可以在信息中心搜索与某个自定义键匹配的问题。

- 查看某个问题时，可以在每个事件的 **Keys** 子标签页中查看关联的自定义键，也可以通过页面顶部的 **Filter** 菜单按自定义键筛选事件。

> [!NOTE]
> **注意：** Crashlytics 最多支持 64 个键值对。达到上限后，后续值不会被保存。每个键值对的大小最多为 1 kB。

使用实例方法 `setCustomKey` 设置键值对。示例：

```dart
// 设置字符串类型的键。
FirebaseCrashlytics.instance.setCustomKey('str_key', 'hello');

// 设置布尔类型的键。
FirebaseCrashlytics.instance.setCustomKey("bool_key", true);

// 设置 int 类型的键。
FirebaseCrashlytics.instance.setCustomKey("int_key", 1);

// 设置 long 类型的键。
FirebaseCrashlytics.instance.setCustomKey("int_key", 1L);

// 设置 float 类型的键。
FirebaseCrashlytics.instance.setCustomKey("float_key", 1.0f);

// 设置 double 类型的键。
FirebaseCrashlytics.instance.setCustomKey("double_key", 1.0);
```

## 添加自定义日志消息

你可以在应用中添加 Crashlytics 自定义日志，为崩溃前发生的事件提供更多上下文。Crashlytics 会将日志与崩溃数据关联起来，并在你查看问题详情时显示在 **Logs** 标签页中。所有问题都可以在 Firebase 控制台的 **DevOps 与互动** > [**Crashlytics** 信息中心](https://console.firebase.google.com/project/_/crashlytics)查看。

> [!NOTE]
> **注意：** 为避免拖慢应用，Crashlytics 将日志大小限制为 64 kB。当某个会话的日志超过此限制时，较早的日志条目会被删除。

使用 `log` 帮助定位问题。例如：

```dart
FirebaseCrashlytics.instance.log("检测到希格斯玻色子！立即退出");
```

## 设置用户标识

诊断问题时，了解哪些用户遇到了某次崩溃通常很有帮助。Crashlytics 支持在崩溃报告中匿名标识用户。

要在报告中添加用户 ID，请为每位用户设置唯一标识符，可以使用 ID 数字、令牌或哈希值：

```dart
FirebaseCrashlytics.instance.setUserIdentifier("12345");
```

设置用户标识后，如果需要清除它，请将其重置为空字符串。清除用户标识不会删除已有的 Crashlytics 记录。如果需要删除与某个用户 ID 关联的记录，请[联系 Firebase 支持](https://firebase.google.com/support/troubleshooter/contact)。

## 获取面包屑日志

面包屑日志可以帮助你了解用户在发生崩溃、非致命错误或 ANR 事件之前与应用的交互情况。这些日志有助于重现和调试问题。

面包屑日志由 Google Analytics 提供。要获取面包屑日志，你需要为 Firebase 项目[启用 Google Analytics](https://support.google.com/firebase/answer/9289399#linkga)，并[在应用中添加 Firebase Google Analytics SDK](https://firebase.google.com/docs/analytics/get-started#add-sdk)。完成这些要求后，事件数据中会自动包含面包屑日志。查看问题详情时，可以在 **Logs** 标签页中查看这些日志；所有问题都可以在 Firebase 控制台的 **DevOps 与互动** > [**Crashlytics** 信息中心](https://console.firebase.google.com/project/_/crashlytics)查看。

Analytics SDK 会[自动记录 `screen_view` 事件](https://support.google.com/analytics/answer/9234069#screen_view)，因此面包屑日志可以列出崩溃、非致命错误或 ANR 事件发生前用户访问过的页面。`screen_view` 面包屑日志包含 `firebase_screen_class` 参数。

面包屑日志还会包含用户会话中手动记录的[自定义事件](https://firebase.google.com/docs/analytics/events)及其参数数据。这些数据有助于还原用户在事件发生前的一系列操作。

你可以[控制 Google Analytics 数据的收集和使用](https://firebase.google.com/docs/analytics/configure-data-collection)，其中包括用于生成面包屑日志的数据。

## 启用用户主动选择上报

> [!CAUTION]
> 如果关闭自动上报并启用用户主动选择上报，应用事件数量和无崩溃指标的准确性会降低，因此这些指标对应用整体稳定性的反映也会不够准确。[了解详情。](https://firebase.google.com/docs/crashlytics/crash-free-metrics#impact-of-data-collection-settings)

默认情况下，Crashlytics 会为所有应用用户自动收集崩溃报告。若要让用户更好地控制自己发送的数据，可以关闭自动收集，只在代码中选择上报时才将数据发送到 Crashlytics。

1. 在原生平台配置中关闭自动收集：

   **Apple 平台**

   在 `Info.plist` 文件中添加以下键：
   - 键：`FirebaseCrashlyticsCollectionEnabled`
   - 值：`false`

   **Android**

   在 `AndroidManifest.xml` 文件的 `application` 块中添加 `meta-data` 标签，以关闭自动收集：

   ```xml
   <meta-data
       android:name="firebase_crashlytics_collection_enabled"
       android:value="false" />
   ```

2. 在运行时调用 Crashlytics 数据收集设置，为选定用户启用收集。此设置会在应用后续启动时继续生效，因此 Crashlytics 会自动为该用户收集报告。

   ```dart
   FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
   ```

   如果用户之后选择退出数据收集，可以将 `false` 作为设置值。该设置会从用户下次启动应用时开始生效，并在该用户之后的所有启动中持续生效。

> [!NOTE]
> **注意：** 对某个用户关闭数据收集后，Crashlytics 会将崩溃信息保存在设备本地。如果之后重新启用数据收集，设备上保存的崩溃信息会发送到 Crashlytics 进行处理。

## 管理 Crash Insights 数据

Crash Insights 会将匿名化后的堆栈跟踪与其他 Firebase 应用的堆栈跟踪进行比较，帮助你判断当前问题是否属于更大范围的趋势，从而协助解决问题。对于许多问题，Crash Insights 还会提供调试崩溃所需的资源。

Crash Insights 使用汇总后的崩溃数据识别常见的稳定性趋势。如果你不希望共享应用数据，可以在 Firebase 控制台的 **DevOps 与互动** > [**Crashlytics** 信息中心](https://console.firebase.google.com/project/_/crashlytics)的问题列表顶部，打开 **Crash Insights** 菜单并选择退出。

> [!NOTE]
> **注意：** 停止共享数据也会导致你无法再查看问题洞察。设置变更最多可能需要 24 小时才会生效。

## 后续步骤

- [将数据导出到 BigQuery 或 Cloud Logging](https://firebase.google.com/docs/crashlytics/export-data-to-cloud)，以便进行高级分析并使用更多功能，例如查询数据、构建自定义信息中心和设置自定义提醒。
