# Pigeon Demo Plugin

This plugin is a compact demo for learning Pigeon.

Regenerate generated channel code:

```sh
dart pub get
dart run pigeon --input pigeons/messages.dart
```

Generated files:

- `lib/src/messages.g.dart`
- `ios/Classes/messages.g.h`
- `ios/Classes/messages.g.m`
- `android/src/main/kotlin/com/example/pigeon_demo_plugin/Messages.g.kt`

The hand-written native files implement the generated host API:

- `ios/Classes/PigeonDemoPlugin.m`
- `android/src/main/kotlin/com/example/pigeon_demo_plugin/PigeonDemoPlugin.kt`
