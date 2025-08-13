import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NativeImageTestPage(),
    );
  }
}

class NativeImageTestPage extends StatefulWidget {
  @override
  _NativeImageTestPageState createState() => _NativeImageTestPageState();
}

class _NativeImageTestPageState extends State<NativeImageTestPage> {
  static const MethodChannel _channel = MethodChannel('native.asset.channel');

  String? _resultText;
  Widget? _imageWidget;

  // 测试 Uint8List 传输
  Future<void> testUint8List() async {
    setState(() {
      _resultText = "加载中 (Uint8List)...";
      _imageWidget = null;
    });
    final start = DateTime.now();

    try {
      final Uint8List? data =
      await _channel.invokeMethod<Uint8List>('getNativeImage', '2.png');
      final duration = DateTime.now().difference(start);
      if (data != null && data.isNotEmpty) {
        setState(() {
          _resultText =
          "Uint8List 图片加载成功，大小: ${data.lengthInBytes} 字节\n耗时: ${duration.inMilliseconds} ms";
          _imageWidget = Image.memory(data);
        });
      } else {
        setState(() {
          _resultText = "Uint8List 图片数据为空\n耗时: ${duration.inMilliseconds} ms";
        });
      }
    } on PlatformException catch (e) {
      final duration = DateTime.now().difference(start);
      setState(() {
        _resultText = "Uint8List 图片加载失败: ${e.message}\n耗时: ${duration.inMilliseconds} ms";
      });
    }
  }

  // 测试路径传输
  Future<void> testPath() async {
    setState(() {
      _resultText = "加载中 (路径)...";
      _imageWidget = null;
    });
    final start = DateTime.now();

    try {
      final String? path =
      await _channel.invokeMethod<String>('getNativeImagePath', '2.png');
      final duration = DateTime.now().difference(start);

      if (path != null && path.isNotEmpty) {
        setState(() {
          _resultText = "路径图片加载成功: $path\n耗时: ${duration.inMilliseconds} ms";
          _imageWidget = Image.file(
            File(path),
            errorBuilder: (_, __, ___) => const Text('图片加载失败'),
          );
        });
      } else {
        setState(() {
          _resultText = "路径为空\n耗时: ${duration.inMilliseconds} ms";
        });
      }
    } on PlatformException catch (e) {
      final duration = DateTime.now().difference(start);
      setState(() {
        _resultText = "路径图片加载失败: ${e.message}\n耗时: ${duration.inMilliseconds} ms";
      });
    }
  }

  // 测试 Texture 传输
  int? _textureId;

  Future<void> testTexture() async {
    setState(() {
      _resultText = "加载中 (Texture)...";
      _imageWidget = null;
      _textureId = null;
    });
    final start = DateTime.now();

    try {
      final int? textureId = await _channel.invokeMethod<int>('createTexture');
      final duration = DateTime.now().difference(start);

      if (textureId != null && textureId >= 0) {
        setState(() {
          _resultText = "Texture 创建成功，id=$textureId\n耗时: ${duration.inMilliseconds} ms";
          _textureId = textureId;
          _imageWidget = Texture(textureId: textureId);
        });
      } else {
        setState(() {
          _resultText = "Texture 创建失败\n耗时: ${duration.inMilliseconds} ms";
        });
      }
    } on PlatformException catch (e) {
      final duration = DateTime.now().difference(start);
      setState(() {
        _resultText = "Texture 创建失败: ${e.message}\n耗时: ${duration.inMilliseconds} ms";
      });
    }
  }

  @override
  void dispose() {
    // 这里可调用 native 释放 texture 资源，如果有提供接口的话
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Image 测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
                onPressed: testUint8List, child: const Text('测试 Uint8List 传输')),
            ElevatedButton(onPressed: testPath, child: const Text('测试 路径传输')),
            ElevatedButton(
                onPressed: testTexture, child: const Text('测试 Texture 传输')),
            const SizedBox(height: 20),
            if (_resultText != null) Text(_resultText!),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: _imageWidget ?? Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
