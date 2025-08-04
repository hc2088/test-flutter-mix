import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}
// 父 widget 向子 widget 传递约束
//
// 子 widget 根据约束 决定自身大小并向父返回

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: '局部刷新 Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Scaffold(
          // body: Container(
          //   width: 100,
          //   height: 100,
          //   color: Colors.red,
          // ),
          // body: Center(
          //   child: Container(
          //     color: Colors.red,
          //     width: double.infinity,
          //     height: double.infinity,
          //   ),
          // ),
          body: Container(
            alignment: Alignment.center,
            color: Colors.red,
            child: Text("Hello"),
          ),
        ));
  }
}
