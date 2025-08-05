import 'dart:isolate';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// 计算指定范围内素数的耗时任务函数（在新 isolate 中执行）
void findPrimes(SendPort sendPort) {
  // 接收参数：用 ReceivePort 先接收起始和结束值
  final port = ReceivePort();
  sendPort.send(port.sendPort);

  port.listen((message) {
    final data = message as List<int>;
    final start = data[0];
    final end = data[1];

    List<int> primes = [];
    for (int i = start; i <= end; i++) {
      if (_isPrime(i)) primes.add(i);
    }
    // 计算完成后发送回主 isolate
    sendPort.send(primes);
    port.close();
  });
}

bool _isPrime(int n) {
  if (n <= 1) return false;
  for (int i = 2; i <= n ~/ 2; i++) {
    if (n % i == 0) return false;
  }
  return true;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<int> _primes = [];
  bool _isComputing = false;

  Future<void> _startIsolate() async {
    setState(() {
      _isComputing = true;
      _primes = [];
    });

    ReceivePort receivePort = ReceivePort();

    // 启动新 isolate，传入 receivePort.sendPort
    Isolate.spawn(findPrimes, receivePort.sendPort);

    // 第一次接收是 isolate 的 SendPort，用于向 isolate 发送参数
    SendPort? isolateSendPort;

    await for (var message in receivePort) {
      if (message is SendPort) {
        // 接收到 isolate 端的 sendPort，发送计算范围参数
        isolateSendPort = message;
        isolateSendPort.send([2, 5000000]); // 计算2到5万之间的素数
      } else if (message is List<int>) {
        // 接收到计算结果，关闭接收端，更新UI
        setState(() {
          _primes = message;
          _isComputing = false;
        });
        receivePort.close();
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Isolate 计算素数示例')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _isComputing ? null : _startIsolate,
                child: _isComputing
                    ? const Text('计算中...')
                    : const Text('开始计算2-50000的素数'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _primes.isEmpty
                    ? const Center(child: Text('结果会显示在这里'))
                    : ListView.builder(
                  itemCount: _primes.length,
                  itemBuilder: (context, index) {
                    return Text('${_primes[index]}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
