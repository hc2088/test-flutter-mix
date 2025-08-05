```
///StatefulElement

Element? updateChild(Element? child, Widget? newWidget, Object? newSlot) {
    if (newWidget == null) {
      // 如果新 Widget 为 null，说明应该移除这个 child（也就是销毁）
      if (child != null) {
        deactivateChild(child);
      }
      return null;
    }

    final Element newChild;
    if (child != null) {
      bool hasSameSuperclass = true;
      
   
      if (hasSameSuperclass && child.widget == newWidget) {//同一个widget， widget没变，例如const修饰的widget
      
      // 完全一样的 const Widget，Flutter 会复用 Widget 本身（而不仅是 Element）
      
        if (child.slot != newSlot) {
          updateSlotForChild(child, newSlot);
        }

        newChild = child;
      } else if (hasSameSuperclass && Widget.canUpdate(child.widget, newWidget)) {//key相同，复用element 及其element.state
      
        // 判断是否可以复用当前 child（Element）
          if (child.slot != newSlot) {
            updateSlotForChild(child, newSlot);
          }

 
            // 如果可以复用，就调用 child.update() 更新数据
            //复用的机制是调用原有 Element 的 update() 方法，让它把新 Widget 的数据同步过来
 
        child.update(newWidget);//如果是statefullelement，将调用对应的state.didUpdateWidget(oldWidget)
        //所以这里注意的用法就是 build widget statefullwidget类型widget构造时传递的参数给到widget， 在state到build方法里面如果在initState时结收了widget.xx，而不是build方法中用widget.xx，而使用state.xx，那么这时候就没更新， 需要在didUpdateWidget对state.xx重新赋值
      
  
        newChild = child;
      } else {//key不同、或者
        //我们hot reload时，把一个StatelessWidget改成了StateFullWidget，类名没有改，父类改了
        //这时候runtimeType是相等的，但是应该被当作不同widget，所以不能仅用类名来判断
        
        
            // 如果不能复用，就销毁原有 Element，重新创建一个
        deactivateChild(child);
 
        newChild = inflateWidget(newWidget, newSlot);
      }
    } else {
     // 创建一个新的 Element，并将其挂载
      newChild = inflateWidget(newWidget, newSlot);
    }
 

    return newChild;

}


// 判断是否复用的关键
static bool canUpdate(Widget oldWidget, Widget newWidget) {
  return oldWidget.runtimeType == newWidget.runtimeType && //类型一致
         oldWidget.key == newWidget.key;    //key 一致
}

//满足这两个条件，说明可以复用旧的 Element 实例，只更新内部状态。
//否则，说明是不同的 Widget，不能复用，必须销毁旧的，创建新的。

| 情况                    | Widget 是否新建  | Element 是否复用 | RenderObject 是否复用 |
| --------------------- | ------------ | ------------ | ----------------- |
| 类型一致，key 相同（非 const）  | ✅ 新建 Widget  | ✅ 复用 Element | ✅ 复用 RenderObject |
| 类型一致，key 相同（都是 const） | ❌ 复用旧 Widget | ✅ 复用 Element | ✅ 复用 RenderObject |


///
Element inflateWidget(Widget newWidget, Object? newSlot) {

    try {
      final Key? key = newWidget.key;
      if (key is GlobalKey) {//如果是globalkey类型的key， 复用element，（允许跨组件树）组件需要 状态保留 或 跨树移动
        final Element? newChild = _retakeInactiveElement(key, newWidget);
        //复用非活动 Element：在构建新 widget 时，尝试“重新取回”一个处于非活动状态（inactive）的 Element，用于复用
        if (newChild != null) {
  
          try {
            newChild._activateWithParent(this, newSlot);
          } catch (_) {
           
          }
          final Element? updatedChild = updateChild(newChild, newWidget, newSlot);
 
          return updatedChild!;
        }
      }
      final Element newChild = newWidget.createElement();//创建新的 element
     
      newChild.mount(this, newSlot);
  
      return newChild;
    } finally {
 
    }

}

@override
void update(StatefulWidget newWidget) {
super.update(newWidget);

    final StatefulWidget oldWidget = state._widget!;
    state._widget = widget as StatefulWidget;
    final Object? debugCheckForReturnedFuture = state.didUpdateWidget(oldWidget) as dynamic;
    assert(() {
 
      return true;
    }());
    rebuild(force: true);

}

@protected
void deactivateChild(Element child) {

    assert(child._parent == this);

    child._parent = null;

    //所以它的行为是统一的，不区分是否是 GlobalKey。判断是否是 GlobalKey 并不是它该管的事
    //将一个子元素从当前父元素中解绑、从渲染树中分离，并加入 “非活跃池” 等待可能的复用或销毁。
    child.detachRenderObject();

    owner!._inactiveElements.add(child); // this eventually calls child.deactivate()

    assert(() {
        if (debugPrintGlobalKeyedWidgetLifecycle) {
        if (child.widget.key is GlobalKey) {
        debugPrint('Deactivated $child (keyed child of $this)');
        }
        }
        return true;
    }());

}

如果一个 widget 使用了 GlobalKey，是否对应的 Element 在 App 运行过程中就一直不会被释放？？

GlobalKey 不等于永久驻留内存，但如果你一直引用它，或者 Flutter 仍然认为它可能会复用，那对应的
Element/State 就不会释放。
所以正确管理 GlobalKey 的生命周期很重要，错误使用会造成内存泄漏。
 



State：


//当前 State 组件重建
  @protected
  void setState(VoidCallback fn) {
     
    final Object? result = fn() as dynamic;
    assert(() {
      if (result is Future) {
        
      return true;
    }());
    _element!.markNeedsBuild(); //记这个 StatefulElement 需要重新 build
  }






InheritedElement：

    //所有依赖组件重建
    @protected
  void notifyDependent(covariant InheritedWidget oldWidget, Element dependent) {
    dependent.didChangeDependencies(); //通知依赖者
  }





Element： 

  @mustCallSuper
  void didChangeDependencies() {
 
    markNeedsBuild(); //标记为脏
  }

 
  //无论是 State.setState() 还是 InheritedElement，最终都是走到这个逻辑：
  void markNeedsBuild() {


    if (dirty) { 
      return;
    }

    _dirty = true; //标记为脏

    owner!.scheduleBuildFor(this);  //BuildOwner 安排重建
  }


  Flutter 中一切刷新 UI 的机制，归根结底都是通过调用 Element.markNeedsBuild()，将 Element 标记为“脏”，
  由 BuildOwner.scheduleBuildFor() 安排重建。
 
```