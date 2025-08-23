import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(GetMaterialApp(
    home: const EntryPage(),
    smartManagement: SmartManagement.full, // 确保自动回收
  ));
}

class EntryPage extends StatelessWidget {
  const EntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entry Page')),
      body: Center(
        child: ElevatedButton(
          child: const Text('打开 HomePage'),
          onPressed: () {
            // 使用 offNamed 或者 tag 确保不重复创建
            Get.to(() => const HomePage(),
                preventDuplicates: true, // 避免重复 push
                routeName: '/home'); // 显式命名路由
          },
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
    // 页面销毁时强制删除对应 route 的 key（防御性措施）
    Get.routing.args = null;
    Get.delete<HomeController>();
    super.onClose();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    //_routesKey 并不能解决空set占用问题

    // 每次进入时注册控制器，绑定到 routeName ---RouterReportManager.reportDependencyLinkedToRoute(_getKey(S, name));
    final controller = Get.put(HomeController(), tag: Get.currentRoute);

    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: Obx(() => Text(
          'Count: ${controller.count}',
          style: const TextStyle(fontSize: 24),
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.count++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
