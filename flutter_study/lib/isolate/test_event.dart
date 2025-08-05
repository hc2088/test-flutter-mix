import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// 主函数不使用 compute/isolate，而是用事件队列分批计算
Future<List<int>> findPrimesByChunks(int start, int end) async {
  List<int> primes = [];
  const int chunkSize = 1000; // 每批处理1000个数字

  for (int chunkStart = start; chunkStart <= end; chunkStart += chunkSize) {
    int chunkEnd = min(chunkStart + chunkSize - 1, end);

    for (int i = chunkStart; i <= chunkEnd; i++) {
      if (_isPrime(i)) {
        primes.add(i);
      }
    }
    //await 会将“后面的代码”放到事件队列中等待执行，它不是微任务，而是事件任务。
    // 给 UI 渲染一个机会，放进事件队列
    /* 主 isolate 执行到 await 时，会“暂停”当前的 async 函数的执行。

  但它不会阻塞主线程，而是把后续逻辑（即 print("1111")）挂起，等待 future 完成后再重新调度回来。

  100000ms 是 100 秒，所以后续代码会延迟约 100 秒执行。*/
    await Future.delayed(Duration(milliseconds: 1));
    print("1111");
    scheduleMicrotask(() => print('22222'));
    /*
    *
    *
    * print('1');
      await Future.delayed(Duration(milliseconds: 1));
      print('2');
      看起来只是“暂停1毫秒”，但实际上它是：

      print('1') 立即执行。

      遇到 await Future.delayed(...)，当前任务挂起，控制权交回事件循环。

      Dart 会处理事件队列中其它已有的任务，比如：

        setState

        微任务队列（Future、Stream等）

        UI重绘

      1ms 后，这段挂起的函数会被重新调度进主事件队列，再继续执行 print('2')。
    *
    * 为什么这么做有意义？
    在某些情况中，你希望 先处理当前已排队的异步事件、UI刷新等，再继续执行逻辑，而不是直接“阻塞”地执行。
    *setState(() {
        _loading = true;
      });
      await Future.delayed(Duration(milliseconds: 1));
      // 此时UI已经有机会刷新 loading 动画了

      await _doHeavyWork();
      // loading动画已经出现，再执行重任务
      如果没有这 1ms，loading UI 可能不会及时刷新，直接卡住。
    *
    * */
  }

  return primes;
}

bool _isPrime(int n) {
  if (n < 2) return false;
  for (int i = 2; i <= sqrt(n).toInt(); i++) {
    if (n % i == 0) return false;
  }
  return true;
}

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

  Future<void> _startChunkedComputation() async {
    setState(() {
      _isComputing = true;
      _primes = [];
    });

    final result = await findPrimesByChunks(2, 5000000);

    setState(() {
      _primes = result;
      _isComputing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('事件队列异步计算素数')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isComputing ? null : _startChunkedComputation,
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
