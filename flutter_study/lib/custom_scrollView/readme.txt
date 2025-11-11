| 页面结构                             | 用哪个？                         |
| -------------------------------- | ---------------------------- |
| 只有一个列表                           | ✔ CustomScrollView           |
| 列表 + Header + 吸顶分类               | ✔ CustomScrollView           |
| 顶部 SliverAppBar + TabBar + 多子列表  | ⭐ 必须 NestedScrollView        |
| TabBarView 内多个 ListView/GridView | ⭐ 必须 NestedScrollView        |
| 子列表要刷新（SmartRefresher）           | ✔ 两者都可（NestedScrollView 更合适） |
| 子页面滚动互不影响                        | ✔ NestedScrollView           |
| 子页面滚动需要同步折叠 AppBar               | ⭐ 只能 NestedScrollView        |
| 内层需要 Sliver + 外层也有 Sliver        | ⭐ NestedScrollView + 重叠处理    |




🔵 一、CustomScrollView：单层滚动场景（只有一个滚动体系）
✅ 使用 CustomScrollView 的典型场景

当你的页面 只有一个滚动列表 时（可以是多个 Sliver 组合，但它们属于同一个主滚动区域）

例如：

✔ 场景 1：顶部 Banner + 吸顶标题 + 列表
SliverAppBar
SliverPersistentHeader (吸顶 Filter 条)
SliverList

✔ 场景 2：任意 Sliver 组合
SliverGrid
SliverToBoxAdapter
SliverPadding
SliverList

✔ 场景 3：需要高度可控的自定义滚动结构
✔ 场景 4：不需要 TabBarView + 多个列表
❌ CustomScrollView 的限制（非常关键）

⚠ 不能处理：一个外层滚动 + 多个子列表同时滚动的联动问题

例如：

SliverAppBar（折叠）
TabBar（吸顶）
TabBarView 内每个 Tab 有自己的 ListView


CustomScrollView 做不了，因为：

子 ListView 是独立滚动的

外层无法继续折叠 AppBar

滚动容易闪动、抖动、布局报错

不能同步滚动位置

🟣 二、NestedScrollView：双层滚动场景（外层 Sliver + 内层多个列表）
✅ 使用 NestedScrollView 的典型场景（你项目最常用）
✔ 场景 1：顶部可折叠 AppBar + 吸顶 TabBar + 多个列表

示例：

SliverAppBar(可折叠)
SliverPersistentHeader(吸顶 TabBar)
TabBarView(
  ListView
  ListView
  ListView
)


🔥 这就是 NestedScrollView 的唯一核心能力。
用于 “多个子滚动 + 一个外层滚动联动”。

✔ 场景 2：每个 Tab 是独立的滚动页面

例如：

Tab1 = ListView

Tab2 = MasonryGrid

Tab3 = CustomScrollView

Tab4 = 大卡页 + 滚动内容

NestedScrollView 能把它们全部统一联动头部折叠。

✔ 场景 3：子列表需要绑定 SmartRefresher

例如：

外层：SliverAppBar（折叠）
内层：每个 Tab 都 SmartRefresher + ListView


NestedScrollView 不会干扰子滚动控制器，可以无缝配合 SmartRefresher。

✔ 场景 4：子页面有自己的 KeepAlive（保持状态）

NestedScrollView 能让 Tab 切换：

保持滚动位置

保持刷新状态

不重建列表

✔ 场景 5：需要让多个子列表共享同一部分滚动区域（如 AppBar）

即：

“所有子列表顶部，都应该能把 SliverAppBar 向上推折叠”

NestedScrollView 自动处理滚动同步。

🔴 三、NestedScrollView 场景中必须避免的坑
❗ 原则：

如果你的内层需要 Sliver（CustomScrollView），必须配套：

SliverOverlapAbsorber

SliverOverlapInjector

否则你会看到：

SliverGeometry is not valid
layoutExtent > paintExtent
constraints missing
RenderNestedScrollViewViewport mismatch


如果你只使用 SmartRefresher + ListView，不需要 absorber/injector。

🟢 四、总结成一句话
✅ 只有一个滚动体系 → 用 CustomScrollView

（适合页面复杂但滚动单一）

✅ 外层 Sliver + 内层多个独立滚动列表 → 必须 NestedScrollView

（TabBarView + ListView/GridView 是 NestedScrollView 的专属场景）