import 'dart:async';
import 'dart:convert';

void main() {
  //test1();

  test2();
}

void test1() {
  // 创建 StreamController
  final controller = StreamController<int>();

  // 获取 EventSink
  EventSink<int> sink = controller.sink; //EventSink → “写入事件”

  // 监听 Stream
  controller.stream.listen((event) {
    //Stream → “订阅事件 / 读取事件”
    print('收到事件: $event');
  }, onDone: () {
    print('Stream 已关闭');
  });

  //EventSink 是向 Stream 发送事件的接口

  // 发送事件
  sink.add(1); //可以发送数据事件 (add)
  sink.add(2);
  sink.add(3);

  // 关闭 Sink
  sink.close(); //以关闭 Sink (close)
}

void test2() {
  // 模拟 SSE 字符串流
  final stream = Stream<String>.fromIterable([
    "data:{\"content\":\"hello\",\"isEnd\":false}",
    "",
    "data:{\"content\":\"world\",\"isEnd\":true}",
    "",
  ]);

  // 使用 SseTransformer 转换
  final sseStream = stream.transform(const SseTransformer());

  // 监听转换后的流
  sseStream.listen((msg) {
    print('收到 SSE 消息: $msg');
  });
}

class SseTransformer extends StreamTransformerBase<String, SseMessage> {
  const SseTransformer();

  @override
  Stream<SseMessage> bind(Stream<String> stream) {
    //将 EventSink<String> 转换为 EventSink<SseMessage>

    return Stream.eventTransformed(stream, (sink) => SseEventSink(sink));
  }
}

class SseEventSink implements EventSink<String> {
  //责任链模式
  //事件传递
  //_eventSink 作为下游节点
  final EventSink<SseMessage> _eventSink;

  String _data = "";

  SseEventSink(this._eventSink);

  @override
  void add(String event) {
    //装饰器模式
    //增强对象功能
    //对 _eventSink 增加解析逻辑，但保持原接口一致
    if (event.startsWith("data:")) {
      _data = event.substring(5);
      return;
    }
    if (event.isEmpty) {
      //适配器模式
      //接口转换、隐藏实现细节
      //将 EventSink<String> 转换为 EventSink<SseMessage>
      _eventSink.add(SseMessage.fromJson(_data));
      _data = "";
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _eventSink.close();
  }
}

class SseMessage {
  final String content;
  final bool isEnd;

  const SseMessage({
    required this.content,
    required this.isEnd,
  });

  static SseMessage fromJson(String e) {
    Map<String, dynamic> map = jsonDecode(e);
    return SseMessage(
      content: map['content'],
      isEnd: map['isEnd'] ?? false,
    );
  }

  @override
  String toString() {
    return 'SseMessage content $content isEnd $isEnd';
  }
}
