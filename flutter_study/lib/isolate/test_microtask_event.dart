import 'dart:async';

void main() {
  print('1. 同步代码');

  Future(() => print('2. Event queue 的 Future'));

  Future.microtask(() => print('3. Microtask 1'));
  scheduleMicrotask(() => print('4. Microtask 2'));

  Timer(Duration.zero, () => print('5. Timer (Event queue)')); //

  Future(() {
    print('6. Event queue 的 Future + then'); //  Future 的回调	事件队列
  }).then((_) => print('7. then 也是微任务')); // 下一轮微任务队列

  print('8. 同步代码结束');
}

/*
flutter: 1. 同步代码
flutter: 8. 同步代码结束
flutter: 3. Microtask 1
flutter: 4. Microtask 2
flutter: 2. Event queue 的 Future
flutter: 5. Timer (Event queue)
flutter: 6. Event queue 的 Future + then
flutter: 7. then 也是微任务？？
*/

//在 主 isolate 上异步“分段”执行大任务。
// 简要总结 Dart 事件循环机制：
// 事件循环结构：
//        1、同步任务：直接执行。
//
//        2、微任务队列（Microtask Queue）： 优先于事件队列执行。
//
//            包括：scheduleMicrotask()、Future.sync(...)、已经 resolve 的 Future.then(...)。
//
//        3、事件队列（Event Queue）：
//
//            包括：Future(...)（未立即 resolve 的）、Timer.run()、IO、点击事件等。
//
// 1、8 是同步任务，直接执行；
//
// 3、4 是微任务，下一步执行；
//
// 2、5、6 是事件队列任务；
//
// 7 是由 6 的 .then 产生的微任务，因此是最后一轮执行。
//
