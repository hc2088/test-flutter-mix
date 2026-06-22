# Android 构建适配说明

## 适配基线

本次 Android 构建适配于 **2026 年 6 月 22 日** 完成，基于以下环境：

| 项目 | 版本 |
| --- | --- |
| Flutter | 3.38.5（stable） |
| Dart | 3.10.4 |
| Gradle | 8.14 |
| Android Gradle Plugin（AGP） | 8.11.1 |
| Kotlin Gradle Plugin | 2.2.20 |
| Java 运行环境 | OpenJDK 21 |
| Java/Kotlin 编译目标 | Java 17 |
| Android compileSdk | 36 |

Flutter SDK 的框架 revision 为
`f6ff1529fd6d8af5f706051d9251ac9231c83407`。

## 调整原因

项目原来使用 AGP 8.1.0 和 Gradle 8.3。Flutter 3.38.5 要求 AGP
不得低于 8.1.1，同时提示 Gradle 8.3 即将不再受支持，因此本次直接同步到
Flutter 3.38.5 项目模板使用的构建版本，避免只升级最低补丁版本后很快再次调整。

本地插件 `pigeon_demo_plugin` 原来也独立使用 AGP 8.1.0 和 Kotlin
1.8.22。为避免主工程和本地插件的构建工具链不一致，该插件已同步升级。

## 具体改动

- `android/gradle/wrapper/gradle-wrapper.properties`
  - Gradle 由 8.3 升级到 8.14。
- `android/settings.gradle`
  - AGP 由 8.1.0 升级到 8.11.1。
  - Kotlin Gradle Plugin 由 1.8.22 升级到 2.2.20。
- `android/app/build.gradle`
  - Java source/target compatibility 由 Java 8 调整到 Java 17。
  - Kotlin JVM target 由 Java 8 调整到 Java 17。
- `pigeon_demo_plugin/android/build.gradle`
  - AGP、Kotlin、Java/Kotlin 编译目标与主工程同步。
  - compileSdk 由 34 调整到 36。

## compileSdk、minSdk 和 targetSdk

主应用的三个 Android SDK 版本配置位于
`android/app/build.gradle`：

```gradle
android {
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
    }
}
```

当前没有直接写死数字，而是使用 Flutter SDK 提供的默认值。基于 Flutter
3.38.5，实际值为：

```text
compileSdk = 36
minSdk     = 24
targetSdk  = 36
```

三个配置的含义如下：

| 配置 | 当前值 | 含义 |
| --- | --- | --- |
| `compileSdk` | 36 | 编译时使用的 Android SDK API 版本，可以引用最高到 API 36 的接口 |
| `minSdk` | 24 | 应用允许安装和运行的最低 Android API 版本，即 Android 7.0 |
| `targetSdk` | 36 | 应用已经针对 API 36（Android 16）的系统行为和规则完成适配 |

一般应满足：

```text
minSdk <= targetSdk <= compileSdk
```

需要特别注意：

- 提高 `compileSdk` 不会自动提高最低支持的 Android 版本。
- 最低可安装版本只由 `minSdk` 决定。
- 提高 `targetSdk` 可能启用新版 Android 的权限、后台任务、通知、存储和
  安全行为规则，因此升级后需要做兼容性测试。
- 如果代码调用高于 `minSdk` 的 Android API，应先判断系统版本，或使用
  AndroidX 提供的兼容接口。

如果项目需要固定这些版本，也可以直接在
`android/app/build.gradle` 中写数字：

```gradle
android {
    compileSdk = 36

    defaultConfig {
        minSdk = 24
        targetSdk = 36
    }
}
```

本地插件的配置位于
`pigeon_demo_plugin/android/build.gradle`：

```gradle
android {
    compileSdk = 36

    defaultConfig {
        minSdk = 21
    }
}
```

插件通常不设置 `targetSdk`，最终运行时使用宿主 App 的 `targetSdk`。
插件的 `minSdk` 可以声明为 21，但整个应用最终可安装的最低版本仍需要满足
主应用及所有依赖的最低版本要求；当前主应用的实际 `minSdk` 是 24。

## 构建验证

本次改动已执行并通过：

```sh
cd android
./gradlew :app:compileDebugKotlin
./gradlew :app:assembleDebug
```

验证结果为 `BUILD SUCCESSFUL`，Debug APK 可正常生成。

日常运行可在项目根目录执行：

```sh
flutter pub get
flutter run
```

## 注意事项

- 建议通过 FVM 或其他版本管理工具固定 Flutter 3.38.5。
- 升级 Flutter 后，应重新核对新版本模板中的 Gradle、AGP 和 Kotlin
  推荐版本，再决定是否同步升级。
- 当前构建日志中可能出现部分第三方插件使用旧 Java 8 配置、
  AndroidManifest `package` 属性或 Gradle 弃用特性的警告；这些警告不影响
  当前 Debug APK 构建。
