import 'package:flutter/material.dart';



class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool useVerificationCode = false;

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

            // === 使用 if-else 动态构建 ===
            if (useVerificationCode)
              TextField(
                decoration: InputDecoration(labelText: '验证码'),
              )
            else
              TextField(
                decoration: InputDecoration(labelText: '密码'),
                obscureText: true,
              ),

            SizedBox(height: 32),

            // === 使用 Visibility 控制显示 ===
            // 密码输入框
            Visibility(
              visible: !useVerificationCode,
              child: TextField(
                decoration: InputDecoration(labelText: '密码（Visibility）'),
                obscureText: true,
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
