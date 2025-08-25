import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(GetMaterialApp(
    home: EntryPage(),
    // 确保使用 SmartManagement.full（默认），页面关闭后会自动删除控制器
    smartManagement: SmartManagement.full,
    getPages: [
      GetPage(name: '/home', page: () => HomePage()),
      GetPage(name: '/secondPage', page: () => SecondPage()),
    ],
  ));
}

class EntryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Entry Page')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              child: Text('Go to HomePage--Get.to'),
              onPressed: () {
                /*
                *
                *
                * Get.to(() => HomePage()); 的问题本质是：

                    重复入栈同一页面 → 创建多个 Route 实例。

                    依赖清理不完全 → _routesKey（查看 _removeDependencyByRoute方法 ）、Controller 无法及时释放。

                    内存和路由栈增长 → map 越来越大，可能导致性能问题。
                *
                *
                * */

                /*
                *
                * 1、页面入栈时：

                      Controller 被 Get.put() 注册到 GetInstance

                      非永久 Controller 绑定到当前 Route

                  2、页面出栈时：

                      _removeDependencyByRoute 被触发

                      调用 Controller 的 onClose()

                      从 _routesKey、_routesByCreate、GetInstance 中删除实例

                  3、永久 Controller 不会自动删除，需要手动 Get.delete()。
                *
                * */
                Get.to(() => HomePage());
              },
            ),
            ElevatedButton(
              child: Text('Go to HomePage--toNamed'),
              onPressed: () {
                Get.toNamed("/home");
              },
            ),
            ElevatedButton(
              child: Text('SecondPage--toNamed'),
              onPressed: () {
                Get.toNamed("/secondPage");
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomeController extends GetxController {
  var count = 0.obs;

  @override
  void onInit() {
    super.onInit();
    print('HomeController onInit()');
  }

  @override
  void onClose() {
    print('HomeController onClose()');
    super.onClose();
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 非永久依赖：未指定 permanent: true

    //controller 是绑定在路由上的，当路由页面关闭，调用释放
    /*
        在当前路由对应的 _routesKey[route] 中注册这个依赖的 key
        当路由关闭时，按设计应该通过 _removeDependencyByRoute 删除这个 key，并释放对应依赖

        _routesKey内存泄漏问题：

    Get.put() 默认不是 permanent: true，所以 当路由关闭时，GetX 确实调用了 GetInstance().delete(key) 释放控制器实例。
    但 _routesKey 的 Map 只是多了一个空 Set，没有被移除。

    每次 Get.to(() => HomePage()) 都会创建一个新的 Route 实例，它的 identity 不同，_routesKey 使用 Route 作为 key。
    当路由关闭后，虽然调用 _removeDependencyByRoute(route)，但是如果路由对象不完全匹配（或没有正确调用移除逻辑）， 这个 Map 就不会删除掉那个 key。
    所以 Map 会积累越来越多“已关闭页面的 route key”，形成一种逻辑残留

        */

    final controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Center(
        child: Column(
          children: [
            Obx(() => Text(
                  'Count: ${controller.count}',
                  style: TextStyle(fontSize: 24),
                )),
            ElevatedButton(
              child: Text('使用 Get.back() 返回'),
              onPressed: () {
                print('Get.back() 返回');
                Get.back(); // GetX 返回方式
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.count++,
        child: Icon(Icons.add),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page'),
        // 系统默认返回按钮 -> Navigator.pop
        leading: BackButton(
          onPressed: () {
            print('系统返回(Navigator.pop)');
            Navigator.pop(context); // 系统返回方式
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('使用 Get.back() 返回'),
              onPressed: () {
                print('Get.back() 返回');
                Get.back(); // GetX 返回方式
              },
            ),
          ],
        ),
      ),
    );
  }
}
