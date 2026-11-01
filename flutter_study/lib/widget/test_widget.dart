import 'package:flutter/material.dart';

void main() async {
  runApp(const TestWidget1());
}

class TestWidget1 extends StatefulWidget {
  const TestWidget1({super.key});

  @override
  State<TestWidget1> createState() => _TestWidget1State();
}

class _TestWidget1State extends State<TestWidget1> {
  late int i;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    i = 0;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: TestWidget3(
            title: "$i",
          ),
        ),
        floatingActionButton: IconButton(
            onPressed: () {
              i++;
              setState(() {});
            },
            icon: Icon(Icons.add)),
      ),
    );
  }
}

class TestWidget2 extends StatelessWidget {
  String title;

  TestWidget2({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    print("TestWidget2: build");
    return Center(
      child: Column(
        children: [
          Text(
            "6666:$title",
          ),
        ],
      ),
    );
  }
}

class TestWidget3 extends StatefulWidget {
  String title;

  TestWidget3({super.key, required this.title});

  @override
  State<TestWidget3> createState() => _TestWidget3State();
}

class _TestWidget3State extends State<TestWidget3> {
  String? str;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    str = "99999:${widget.title}";
  }

  @override
  void didUpdateWidget(covariant TestWidget3 oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    print("_TestWidget3State didUpdateWidget: str=$str");
    if (widget.title != oldWidget.title) {
      str = "99999:${widget.title}";
    }
  }

  @override
  Widget build(BuildContext context) {
    print('_TestWidget3State build');
    return Center(
      child: Column(
        children: [
          Text('7777:$str'),
          Text('8888:${widget.title}'),
        ],
      ),
    );
  }
}
