import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(GetMaterialApp(
    home: EntryPage(),
    // 确保使用 SmartManagement.full（默认），页面关闭后会自动删除控制器
    smartManagement: SmartManagement.full,
    getPages: [
      GetPage(name: '/home', page: () => HomePage()),
      GetPage(name: '/secondPage', page: () => SecondPage()),
      GetPage(
        name: '/detailPage',
        page: () => DetailPage(),
        binding: BindingsBuilder(() {
          Get.create<DetailController>(() => DetailController());
        }),
      ),
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
            ElevatedButton(
              child: Text('detailPage--toNamed'),
              onPressed: () {
                Get.toNamed("/detailPage");
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

class SecondController extends GetxController {
  var count = 0.obs;

  SecondController() {
    print('SecondController 构造函数被调用了');
  }

  @override
  void onInit() {
    super.onInit();
    print('SecondController onInit()');
  }

  @override
  void onClose() {
    print('SecondController onClose()');
    super.onClose();
  }
}

class SecondTagController extends GetxController {
  var count = 0.obs;

  SecondTagController() {
    print('SecondTagController 构造函数被调用了');
  }

  @override
  void onInit() {
    super.onInit();
    print('SecondTagController onInit()');
  }

  @override
  void onClose() {
    print('SecondTagController onClose()');
    super.onClose();
  }
}

class DetailController extends GetxController {
  var count = 0.obs;

  @override
  void onInit() {
    super.onInit();
    print('DetailController onInit()');
  }

  @override
  void onClose() {
    print('DetailController onClose()');
    super.onClose();
  }

  void increment() {
    count++;
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //controller 是绑定在路由上的，当路由页面关闭，调用释放
    /*
        在当前路由对应的 _routesKey[route] 中注册这个依赖的 key
        permanent默认是false， 当路由关闭时，按设计应该通过 _removeDependencyByRoute 删除这个 key，并释放对应依赖

        _routesKey内存泄漏问题：

          当路由关闭时，GetX 确实调用了 GetInstance().delete(key) 释放控制器实例。
          但 _routesKey 的 Map 只是多了一个空 Set，没有被移除。

    每次 Get.to(() => HomePage()) 都会创建一个新的 Route 实例，它的 identity 不同，_routesKey 使用 Route 作为 key。
    当路由关闭后，虽然调用 _removeDependencyByRoute(route)，但是如果路由对象不完全匹配（或没有正确调用移除逻辑）， 这个 Map 就不会删除掉那个 key。
    所以 Map 会积累越来越多“已关闭页面的 route key”，形成一种逻辑残留

        */

    //如果permanent是true，不会在页面关闭时清空控制器

    //static void _removeDependencyByRoute(Route routeName) ：
    // for (final element in keysToRemove) {
    //   final value = GetInstance().delete(key: element);
    //   if (value) {
    //     _routesKey[routeName]?.remove(element);
    //   }
    // }
    // bool delete<S>({String? tag, String? key, bool force = false}) ：
    // if (builder.permanent && !force) {
    //   Get.log(
    //     // ignore: lines_longer_than_80_chars
    //     '"$newKey" has been marked as permanent, SmartManagement is not authorized to delete it.',
    //     isError: true,
    //   );
    //   return false;
    // }
    final controller = Get.put(HomeController(), permanent: true);

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
    /*

       S? _initDependencies<S>({String? name}) {
        final key = _getKey(S, name);
        final isInit = _singl[key]!.isInit;
        S? i;

        if (!isInit) {
          //如果多次put，会使用上一个创建的控制器，不会进到这个代码分支里
          i = _startController<S>(tag: name);
          if (_singl[key]!.isSingleton!) {
            _singl[key]!.isInit = true;//并且不会重新绑定路由，也就是说多次Get.toNamed跳转页面，不会绑定多个控制器
            if (Get.smartManagement != SmartManagement.onlyBuilder) {
              RouterReportManager.reportDependencyLinkedToRoute(_getKey(S, name));
            }
          }
        }
        return i;
      }

      */

    // Get.put(SecondController()); 如果是多次put，会使用上一个创建的控制器，并且不会重新绑定路由，
    // 也即在多次put后，后面通过find出来的仍然是第一次push的页面创建的控制 ,且在非第一次push的页面，
    // 页面关闭时也不会调用控制器的删除流程，
    //static void _removeDependencyByRoute(Route routeName) ：
    // for (final element in keysToRemove) {
    //   final value = GetInstance().delete(key: element);
    //   if (value) {
    //     _routesKey[routeName]?.remove(element);
    //   }
    // }
    // bool delete<S>({String? tag, String? key, bool force = false}) ：
    // if (builder.permanent && !force) {
    //   Get.log(
    //     // ignore: lines_longer_than_80_chars
    //     '"$newKey" has been marked as permanent, SmartManagement is not authorized to delete it.',
    //     isError: true,
    //   );
    //   return false;
    // }
    // 因为 _routesKey下面没有后面第二个页面以后的路由，所以keysToRemove是空的，也就不会在页面关闭时删除

    Get.put(SecondController());
    final uniqueTag = 'myController_${const Uuid().v4()}';
    Get.put(SecondTagController(), tag: uniqueTag);
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
            ElevatedButton(
              child: Text('跳转SecondPage'),
              onPressed: () {
                Get.toNamed("/secondPage", preventDuplicates: false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 通过 Get.find 获取绑定的控制器实例
    final controller = Get.find<DetailController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              controller.increment(); // 点击加号修改 count
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() => Text('当前值: ${controller.count}')),
          ElevatedButton(
            child: Text('跳转 DetailPage'),
            onPressed: () {
              Get.toNamed("/detailPage", preventDuplicates: false);
            },
          ),
        ],
      ),
    );
  }
}
// S put<S>(
//     S dependency, {
//       String? tag,
//       bool permanent = false,
//       @Deprecated("Do not use builder, it will be removed in the next update")
//       InstanceBuilderCallback<S>? builder,
//     }) {
//   _insert(
//       isSingleton: true,
//       name: tag,
//       permanent: permanent,
//       builder: builder ?? (() => dependency)); //这里统一再包装成懒加载
//   return find<S>(tag: tag);
// }
//
//
//
// void _insert<S>({
//   bool? isSingleton,
//   String? name,
//   bool permanent = false,
//   required InstanceBuilderCallback<S> builder,
//   bool fenix = false,
// }) {
//   final key = _getKey(S, name);
//
//   if (_singl.containsKey(key)) {
//     final dep = _singl[key];
//     if (dep != null && dep.isDirty) {
//       _singl[key] = _InstanceBuilderFactory<S>(
//         isSingleton,
//         builder,
//         permanent,
//         false,
//         fenix,
//         name,
//         lateRemove: dep as _InstanceBuilderFactory<S>,
//       );
//     }
//   } else {
//     _singl[key] = _InstanceBuilderFactory<S>(
//       isSingleton,
//       builder,
//       permanent,
//       false,
//       fenix,
//       name,
//     );
//   }
// }
//
// void create<S>(
//     InstanceBuilderCallback<S> builder, {
//       String? tag,
//       bool permanent = true,
//     }) {
//   _insert(
//     isSingleton: false,
//     name: tag,
//     builder: builder,
//     permanent: permanent,
//   );
// }
//
//
// S find<S>({String? tag}) {
//   final key = _getKey(S, tag);
//   if (isRegistered<S>(tag: tag)) {
//     final dep = _singl[key];
//     if (dep == null) {
//       if (tag == null) {
//         throw 'Class "$S" is not registered';
//       } else {
//         throw 'Class "$S" with tag "$tag" is not registered';
//       }
//     }
//
//     // if (dep.lateRemove != null) {
//     //   dep.isDirty = true;
//     //   if(dep.fenix)
//     // }
//
//     /// although dirty solution, the lifecycle starts inside
//     /// `initDependencies`, so we have to return the instance from there
//     /// to make it compatible with `Get.create()`.
//     final i = _initDependencies<S>(name: tag);
//     return i ?? dep.getDependency() as S;
//   } else {
//     // ignore: lines_longer_than_80_chars
//     throw '"$S" not found. You need to call "Get.put($S())" or "Get.lazyPut(()=>$S())"';
//   }
// }
//
//
// S getDependency() {
//   if (isSingleton!) {//put方法时单例
//     if (dependency == null) {//为空则创建
//       _showInitLog();
//       dependency = builderFunc();
//     }
//     return dependency!;//不为空则复用
//   } else { //create方法不是单例
//     return builderFunc(); // 在put 那里对象通过 懒加载返回，create方法也是通过builder加载返回
//   }
// }
//
//
//
