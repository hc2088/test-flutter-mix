//Future 只关心“结果什么时候来”；
import 'dart:async';
import 'dart:io';



//Stream<T> async*  Stream是一个类型
//Iterable<T> sync*



Future<String> fetchUserName() async {
  await Future.delayed(const Duration(seconds: 2)); // 模拟网络延迟
  return '小胡胡';
}

//要“持续接收多个数据”，比如监听用户输入、Socket 消息、视频帧等。
Stream<int> numberStream() async* {
  for (int i = 1; i <= 3; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

void main() async {
  // test1();
  test2();
}

void test1() async {


  Stream<int> tickStream() async* {
    //stream:多次性的异步数据流
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration(seconds: 1));
      yield i;
    }
  }

  await for (var value in tickStream()) {
    print('Tick: $value');
  }

  //传统方式（回调、定时器、轮询等)
  int i = 0;
  Timer.periodic(const Duration(seconds: 1), (timer) {
    print('Tick: ${DateTime.now()}');
    i++;
    if (i >= 5) {
      timer.cancel();
    }
  });
}

void test2() {
  final controller = SimpleStreamController<String>();

  // 模拟 StreamBuilder 监听 stream
  controller.listen((data) {
    print('Listener received: $data');
  });

  controller.add('Hello');
  controller.add('World');

  final controller2 = SimpleBroadcastController<int>();

  controller2.listen((v) => print('Listener A: $v'));
  controller2.listen((v) => print('Listener B: $v'));

  controller2.add(1);
  controller2.add(2);
}

class SimpleBroadcastController<T> {
  final List<void Function(T data)> _listeners = [];

  void listen(void Function(T data) listener) {
    //多个监听
    _listeners.add(listener);
  }

  void add(T data) {
    print('Controller: add($data)');
    for (var listener in _listeners) {
      listener(data);
    }
  }
}

class SimpleStreamController<T> {
  void Function(T data)? _listener;

  /// 注册监听
  void listen(void Function(T data) listener) {
    _listener = listener;
  }

  /// 模拟 add，像 yield 一样发送数据
  void add(T data) {
    print('Controller: add($data)');
    _listener?.call(data);
  }
}

void test3() async {
  String name = await fetchUserName(); //await Future，什么时候来结果
  print('用户名是 $name');

  await for (var number in numberStream()) {
    //await Stream，要“持续接收多个数据”，比如监听用户输入、Socket 消息、视频帧等。
    print('收到数字: $number');
  }

  //生成器函数
  //同步用Iterable
  //添加*表明会有多个值返回
  Iterable<int> syncGenerator() sync* {
    print('Start');
    //使用 yield暂停函数
    yield 1;
    print('After yield 1');
    yield 2;
    print('After yield 2');
    yield 3;
    print('After yield 3');
    //所有 yield 执行完后自动 return
  }

  // 调用
  for (var value in syncGenerator()) {
    //.next,从上一次 yield 的位置恢复继续执行
    print('Get: $value');
  }
  //生成器函数
  //异步用Stream
  Stream<int> asyncGenerator() async* {
    print('Start');
    yield 1;
    print('After yield 1');
    await Future.delayed(Duration(seconds: 1));
    yield 2;
    print('After yield 2');
    await Future.delayed(Duration(seconds: 1));
    yield 3;
    print('After yield 3');
  }

  // 调用
  await for (var value in asyncGenerator()) {
    //await,从上一次 yield 的位置恢复继续执行。
    print('Get: $value');
  }
  //上述、使用yield发送
  //使用Stream监听， 使用StreamController发送

  // final controller = StreamController<int>();
  //
  // // 监听 stream，每当有新数据就处理
  // controller.stream.listen((value) {
  //   print('Get: $value');
  // });
  //
  // print('请输入数字（输入 exit 退出）：');
  //
  // // 不断读取用户输入
  // while (true) {
  //   final input = stdin.readLineSync();
  //   if (input == 'exit') break;
  //
  //   final number = int.tryParse(input ?? '');
  //   if (number != null) {
  //     controller.add(number); // 相当于 yield number
  //   } else {
  //     print('请输入合法数字或 exit');
  //   }
  // }
  //
  // await controller.close();
  // print('结束');
}
