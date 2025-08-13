import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hero简单示例")),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const DetailPage()));
          },
          child: const Hero(
            tag: 'avatar',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("详情页")),
      body: const Center(
        child: Hero(
          tag: 'avatar',
          child: CircleAvatar(
            radius: 120,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 120, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
