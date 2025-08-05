// Dart Isolate 更像是轻量级的“进程”，而非“线程”。
//
// 适合用来做 CPU 密集型任务，避免阻塞主线程 UI 渲染。
//
// 通过消息传递实现通信，保证数据安全。


//
//
// 为什么说 Isolate 类似多进程？
// 内存独立：每个 Isolate 都有自己独立的内存空间，不能直接访问其他 Isolate 的内存，类似于不同进程之间的内存隔离。
//
// 通信方式：Isolate 之间通过消息传递（SendPort 和 ReceivePort）通信，而不是共享内存。这点和操作系统中进程间通信（IPC）很像。
//
// 线程安全：因为不共享内存，避免了传统多线程中因访问共享资源引发的数据竞争和死锁问题。



import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// 1. 计算函数（必须是顶层函数或静态函数）
/// 参数是一个 List<int>，第一个是开始值，第二个是结束值
List<int> findPrimesInRange(List<int> range) {
  final start = range[0];
  final end = range[1];
  List<int> primes = [];

  for (int i = start; i <= end; i++) {
    if (_isPrime(i)) {
      primes.add(i);
    }
  }
  return primes;
}

/// 2. 判断是否是素数
bool _isPrime(int n) {
  if (n < 2) return false;
  for (int i = 2; i <= sqrt(n).toInt(); i++) {
    if (n % i == 0) return false;
  }
  return true;
}

/// 3. UI 部分
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PrimeCalculatorPage(),
    );
  }
}

class PrimeCalculatorPage extends StatefulWidget {
  const PrimeCalculatorPage({super.key});
  @override
  State<PrimeCalculatorPage> createState() => _PrimeCalculatorPageState();
}

class _PrimeCalculatorPageState extends State<PrimeCalculatorPage> {
  List<int> _primes = [];
  bool _isComputing = false;

  /// 启动 compute 任务
  Future<void> _startCompute() async {
    setState(() {
      _isComputing = true;
      _primes = [];
    });

    // 启动计算任务
    final result = await compute(findPrimesInRange, [2, 5000000]);

    setState(() {
      _primes = result;
      _isComputing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compute() 素数计算示例')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isComputing ? null : _startCompute,
              child: _isComputing
                  ? const Text('计算中...')
                  : const Text('开始计算 2~50000 的素数'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _primes.isEmpty
                  ? const Center(child: Text('结果将显示在这里'))
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
    );
  }
}
