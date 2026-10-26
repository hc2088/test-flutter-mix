# `runZonedGuarded`

在其自身的错误 Zone 中运行 `body`。

它会基于 `zoneSpecification` 和 `zoneValues`，通过 [`Zone.fork`](https://api.dart.dev/dart-async/Zone/fork.html) 创建一个新的 Zone，然后在该 Zone 中运行 `body` 并返回其结果。

`onError` 函数有两种用途：一是通过覆盖 `zoneSpecification`（如果有提供）中的 [`ZoneSpecification.handleUncaughtError`](https://api.dart.dev/dart-async/ZoneSpecification/handleUncaughtError.html) 来处理异步错误；二是处理调用 `body` 时同步抛出的错误。

如果 `body` 同步发生错误，而 `onError` 处理器又抛出了错误，那么 `runZonedGuarded` 调用本身会抛出该错误；如果 `onError` 没有抛出错误，`runZonedGuarded` 则返回 `null`。

创建出来的 Zone 始终是一个错误 Zone。不同 `Zone.errorZone` 的 Zone 之间，Future 中的异步错误不会跨 Zone 边界传播。因此，在创建出来的 Zone 中以错误结束的 `Future`，如果在另一个属于不同错误 Zone 的 Zone 中使用，可能会看起来一直无法完成。多次尝试在无法访问该错误的 Zone 中使用这个 Future，会导致该错误在原始错误 Zone 中被再次报告。
