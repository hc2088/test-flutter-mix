import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: InheritedWidgetUpdateChildDemo());
  }
}

/// 用来观察 InheritedWidget 依赖登记和 Element.updateChild 更新流程的页面。
///
/// 建议按下方的 BREAKPOINT 注释在 IDE 中设置断点，然后点击“切换颜色”。
/// Flutter SDK 源码断点位于 packages/flutter/lib/src/widgets/framework.dart：
/// - updateChild：查看 child 和 newWidget；可用
///   newWidget.runtimeType.toString() == 'AppPalette' 缩小命中范围。
/// - InheritedElement.updated / notifyClients：查看 updateShouldNotify 后的通知过程。
/// - Element.didChangeDependencies：查看依赖者被标记为需要重建。
class InheritedWidgetUpdateChildDemo extends StatefulWidget {
  const InheritedWidgetUpdateChildDemo({super.key});

  @override
  State<InheritedWidgetUpdateChildDemo> createState() =>
      _InheritedWidgetUpdateChildDemoState();
}

class _InheritedWidgetUpdateChildDemoState
    extends State<InheritedWidgetUpdateChildDemo> {
  bool _useBlue = true;

  void _toggleColor() {
    // BREAKPOINT 1：setState 会让本 State 对应的 StatefulElement 变 dirty。
    setState(() {
      _useBlue = !_useBlue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _useBlue ? Colors.blue : Colors.deepOrange;
    debugPrint('[Demo] build，准备提供颜色：$color');

    return Scaffold(
      appBar: AppBar(title: const Text('InheritedWidget / updateChild')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _toggleColor,
              child: const Text('切换颜色'),
            ),
            const SizedBox(height: 24),
            AppPalette(
              color: color,
              // 保持这个 child Widget 实例不变。
              // InheritedElement 自己更新时，updateChild 可以发现 child 未变，
              // 而 ColorLabel 仍会因为依赖通知而重建。
              child: const ColorLabel(),
            ),
            const SizedBox(height: 12),
            const FixedLabel(),
          ],
        ),
      ),
    );
  }
}

/// 沿 Widget 树向下提供颜色。
class AppPalette extends InheritedWidget {
  const AppPalette({
    super.key,
    required this.color,
    required super.child,
  });

  final Color color;

  static AppPalette of(BuildContext context) {
    // BREAKPOINT 2：这里的 context 实际上就是调用者的 Element。
    // Flutter 找到最近的 AppPalette 对应的 InheritedElement，并登记依赖。
    final AppPalette? result =
        context.dependOnInheritedWidgetOfExactType<AppPalette>();
    assert(result != null, 'No AppPalette found above this context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppPalette oldWidget) {
    final bool shouldNotify = color != oldWidget.color;
    // BREAKPOINT 3：InheritedElement 更新配置后会走到这里。
    debugPrint(
      '[AppPalette] updateShouldNotify: '
      '${oldWidget.color} -> $color, notify=$shouldNotify',
    );
    return shouldNotify;
  }
}

/// 读取 AppPalette 的组件；它的 StatefulElement 会被登记为依赖者。
class ColorLabel extends StatefulWidget {
  const ColorLabel({super.key});

  @override
  State<ColorLabel> createState() => _ColorLabelState();
}

class _ColorLabelState extends State<ColorLabel> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // BREAKPOINT 4：首次挂载时会调用；AppPalette 通知依赖者时也会调用。
    // 此时 context 对应的还是同一个 StatefulElement。
    final AppPalette palette = AppPalette.of(context);
    debugPrint(
      '[ColorLabel] didChangeDependencies, '
      'Element=${identityHashCode(context)}, color=${palette.color}',
    );
  }

  @override
  Widget build(BuildContext context) {
    // BREAKPOINT 5：依赖更新后会再次 build，并读取到新颜色。
    final AppPalette palette = AppPalette.of(context);
    debugPrint(
      '[ColorLabel] build, '
      'Element=${identityHashCode(context)}, color=${palette.color}',
    );

    return Text(
      '我依赖 AppPalette，这行文字会变色',
      style: TextStyle(
        color: palette.color,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// 没有读取 AppPalette 的兄弟组件，用来对比依赖通知。
class FixedLabel extends StatelessWidget {
  const FixedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[FixedLabel] build：我没有依赖 AppPalette');
    return const Text('我没有读取 AppPalette');
  }
}
