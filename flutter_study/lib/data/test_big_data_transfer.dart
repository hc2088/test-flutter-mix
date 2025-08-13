import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NativePerformanceTestPage(),
    );
  }
}

class NativePerformanceTestPage extends StatefulWidget {
  @override
  _NativePerformanceTestPageState createState() =>
      _NativePerformanceTestPageState();
}

class _NativePerformanceTestPageState extends State<NativePerformanceTestPage> {
  static const platform = MethodChannel('test.bigdata.channel');

  String? _resultText = '';
  Widget? _imageWidget;

  Future<void> testUint8List() async {
    final sw = Stopwatch()..start();
    try {
      final Uint8List bytes = await platform.invokeMethod('getImageBytes');
      sw.stop();
      setState(() {
        _resultText = 'Uint8List 传输耗时：${sw.elapsedMilliseconds} ms';
        _imageWidget = Image.memory(bytes);
      });
    } catch (e) {
      setState(() {
        _resultText = 'Uint8List 传输错误：$e';
      });
    }
  }

  Future<void> testPath() async {
    final sw = Stopwatch()..start();
    try {
      final String path = await platform.invokeMethod('getImagePath');
      sw.stop();
      setState(() {
        _resultText = '路径传输耗时：${sw.elapsedMilliseconds} ms';
        _imageWidget = Image.file(File(path));
      });
    } catch (e) {
      setState(() {
        _resultText = '路径传输错误：$e';
      });
    }
  }

  Future<void> testTexture() async {
    final sw = Stopwatch()..start();
    try {
      final int textureId = await platform.invokeMethod('createTexture');
      sw.stop();
      setState(() {
        _resultText = 'Texture 传输耗时：${sw.elapsedMilliseconds} ms';
        _imageWidget = Texture(textureId: textureId);
      });
    } catch (e) {
      setState(() {
        _resultText = 'Texture 传输错误：$e';
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Native 图片传输性能测试')),
      body: Column(
        children: [
          ElevatedButton(
              onPressed: testUint8List, child: Text('测试 Uint8List 传输')),
          ElevatedButton(onPressed: testPath, child: Text('测试 路径传输')),
          ElevatedButton(onPressed: testTexture, child: Text('测试 Texture 传输')),
          SizedBox(height: 20),
          Text(_resultText ?? ''),
          Expanded(child: Center(child: _imageWidget ?? Container())),
        ],
      ),
    );
  }
}
