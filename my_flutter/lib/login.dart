import 'package:flutter/material.dart';



class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool useVerificationCode = false;
  final _controller = TextEditingController();

  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登录页面 - 验证码 & 密码切换'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 用户名输入框
            TextField(
              decoration: InputDecoration(labelText: '用户名'),
            ),

            SizedBox(height: 16),
    //     现象回顾
    // 用 if-else 直接切换两个不同的 TextField，切换时输入框内容不会丢失。
    //
    // 用 Visibility 控制显示隐藏的 TextField，切换时输入框内容会清空。
    //

        // 方式切换按钮
            ElevatedButton(
              onPressed: () {
                setState(() {
                  useVerificationCode = !useVerificationCode;
                });
              },
              child: Text(useVerificationCode
                  ? '切换为密码登录'
                  : '切换为验证码登录'),
            ),

            SizedBox(height: 16),
            // Flutter 这个写法表示只会构建其中一个 TextField，另一个根本不存在于 widget 树中。
            //
            // 切换时，Flutter 会销毁之前的输入框 Widget，创建一个新的输入框 Widget。
            //
            // 关键是输入框的状态（TextEditingController）没有被复用，默认系统会帮你保持 TextField 的文本状态。
            //
            // 实际上，如果你没有显式给 TextField 绑定 controller，Flutter 会自动帮你维护一个临时的内部控制器，因而表现为“切换后内容没变”。
            // === 使用 if-else 动态构建 ===
            if (useVerificationCode)
              TextField(
                decoration: InputDecoration(labelText: '验证码'),
              )
            else
              TextField(
                decoration: InputDecoration(labelText: '密码'),

              ),

            SizedBox(height: 32),

            // === 使用 Visibility 控制显示 ===
            // 密码输入框

    // 这两个 TextField 都一直存在 widget 树里，只是根据 visible 显示或隐藏。
    //
    // 当你切换 visible，控件本身没有被销毁，而是隐藏了（Visibility 默认只是设置 Opacity 或 Offstage）。
    //
    // 但是 Flutter 会尝试回收隐藏 widget 的状态，特别是文本编辑状态会被清空。
    //

    // Visibility(
    //           visible: !useVerificationCode,
    //           child: TextField(
    //             decoration: InputDecoration(labelText: '密码（Visibility）'),
    //
    //           ),
    //         ),
            Visibility(
              visible: !useVerificationCode,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(labelText: '密码（Visibility）'),
              ),
            ),


            // 验证码输入框
            Visibility(
              visible: useVerificationCode,
              child: TextField(
                decoration: InputDecoration(labelText: '验证码（Visibility）'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//使用 if-else 切换不同的 TextField：
//dart
//复制
//编辑
//if (useVerificationCode)
//TextField(...)
//else
//TextField(...)
//这两个 TextField 是不同的 widget 实例，但是它们：
//
//类型是一样的，都是 TextField，没有显式的 key。
//
//Flutter diff 算法会根据 widget 类型和在树中的位置来复用 Element 和 State。
//
//因此：
//
//虽然前一个 TextField 被移除了，新的 TextField 被插入，
//
//但 Flutter 在同一位置检测到 widget 类型没变（都是 TextField），
//
//于是复用了旧的 Element 和 State，里面就保存了之前的 TextEditingController 和文本内容。
//
//这就是为什么你切换时文本没丢失。
//
//
// 如果你给 TextField 指定不同的 Key 或不同的类型
// 如果你给两者指定了不同的 Key，Flutter 就不会复用同一个 Element，会销毁旧 Element，创建新 Element，文本就不会保留。
//
// 如果 widget 类型变了，比如从 TextField 变成 TextFormField，也会创建新 Element。
//
// Visibility 控制时的行为
// Visibility 只是控制子 widget 是否显示，子 widget 并没有被销毁，只是 Offstage 或透明。
//
// 但是：
//
// Flutter 的 TextField 的内部状态（TextEditingController）默认是 由 TextField 自己创建和管理的临时 controller（如果你没自己传），
//
// 当 widget 仍存在时，状态保留；
//
// 但当 widget 被隐藏后，某些情况下（比如 Offstage widget）输入状态可能不会被继续维护，特别是系统键盘和焦点状态。
//
// 所以切换 Visibility 时，虽然 TextField 还在树里，但焦点和文本状态可能被重置，导致看起来内容丢失。





//
//     . 理论上为什么 Visibility 不会销毁 TextField？
// Visibility 只是把子 widget 包裹在一个 Offstage 或透明层里。
//
// StatefulWidget 的 State 对象只要在 widget 树中没被移除，就不会被销毁。
//
// 所以 TextField 的 State（_TextFieldState）是复用的，它内部的 TextEditingController 也应该是同一个。
//
// 2. 为什么输入框内容会丢失？（关键点）
// 这是因为 TextField 的内容除了 controller.text，还有 焦点状态、系统输入法（IME）缓存、selection 和 composing region。
//
// 当 TextField 被设置 Visibility(visible: false) 时，它会进入 Offstage 模式：
//
// RenderEditable 不会再参与布局和绘制。
//
// FocusNode 可能被系统回收或丢失焦点。
//
// 系统输入法（键盘）会收到一个 TextInput.detach() 的调用，Flutter 框架会告诉平台“这个输入连接被销毁了”。
//
// 在 Flutter 源码里，TextInput.detach() 会触发平台侧（iOS/Android）的输入通道把当前 TextInputClient 清空。
// 这时，虽然 TextEditingController.text 还在内存里，但是：
//
// 光标和 composing 区域被重置；
//
// 如果之前输入法正在进行联想输入，组合文本（composing text）会丢失；
//
// 某些情况下（特别是 iOS），输入法可能会重置整个文本缓存，看起来像是清空了输入框。
//
// 总结：
//
// controller.text 本身没丢，但 TextField 重新 attach 输入法时，状态不同步，看起来像内容被“清空”。
//
// 可以修改这种行为吗？
// 可以通过以下几种方法减少或避免这个问题：
//
// 方案 A：给 TextField 显式传入一个 TextEditingController
// dart
// 复制
// 编辑
// final _controller = TextEditingController();
//
// Visibility(
// visible: isVisible,
// child: TextField(
// controller: _controller,
// ),
// )
// 这样即使 TextField 被 detach/attach，输入内容还是保留在 _controller.text。
//
// 方案 B：使用 FocusNode 保持焦点
// dart
// 复制
// 编辑
// final _focusNode = FocusNode();
//
// Visibility(
// visible: isVisible,
// child: TextField(
// controller: _controller,
// focusNode: _focusNode,
// ),
// )
// 这样可以减少被系统回收焦点的情况，但不能完全避免。
//
// 方案 C：避免使用 Visibility，改用 Opacity 或 Offstage
// Opacity(opacity: 0.0, child: TextField(...))
//
// 这种方式不会 detach 输入连接，只是视觉上隐藏，输入状态不会丢失。
//
