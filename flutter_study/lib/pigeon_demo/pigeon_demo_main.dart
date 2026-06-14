import 'package:flutter/material.dart';

import 'pigeon_demo_page.dart';

void main() {
  runApp(const PigeonDemoApp());
}

class PigeonDemoApp extends StatelessWidget {
  const PigeonDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PigeonDemoPage(),
    );
  }
}
