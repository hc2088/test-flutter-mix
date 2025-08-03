import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CounterModel(),
      child: const MyApp(),
    ),
  );
}

class CounterModel extends ChangeNotifier {
  int count = 0;

  void increment() {
    count++;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterModel(),
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CounterDisplayFullwidget(),
                CounterDisplay(),
                CounterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
class CounterDisplayFullwidget extends StatefulWidget {
  const CounterDisplayFullwidget({super.key});

  @override
  State<CounterDisplayFullwidget> createState() => _CounterDisplayState();
}

class _CounterDisplayState extends State<CounterDisplayFullwidget> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("  initState");
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print("didChangeDependencies");
  }

  @override
  void didUpdateWidget(covariant CounterDisplayFullwidget oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget");
  }

  @override
  Widget build(BuildContext context) {
    print('CounterDisplay build');
    final count = context.watch<CounterModel>().count;
    return Text('Counter: $count');
  }
}

class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    print('CounterDisplay build');
    final count = context.watch<CounterModel>().count;
    return Text('Counter: $count');
  }
}

class CounterButton extends StatelessWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    print('CounterButton build');
    final counter = context.read<CounterModel>();
    return ElevatedButton(
      onPressed: counter.increment,
      child: const Text('Increment'),
    );
  }
}
