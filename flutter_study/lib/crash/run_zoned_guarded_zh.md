# `runZonedGuarded` 文档翻译与实现说明

## 文档翻译

在一个独立的错误 Zone 中运行 `body`。

它会基于 `zoneSpecification` 和 `zoneValues`，通过 [`Zone.fork`](https://api.dart.dev/dart-async/Zone/fork.html) 创建一个新的 Zone，然后在该 Zone 中运行 `body` 并返回其结果。

`onError` 函数有两种用途：一是通过覆盖 `zoneSpecification`（如果有提供）中的 [`ZoneSpecification.handleUncaughtError`](https://api.dart.dev/dart-async/ZoneSpecification/handleUncaughtError.html) 来处理异步错误；二是处理调用 `body` 时同步抛出的错误。

如果 `body` 同步抛出错误，而 `onError` 处理器也抛出了错误，那么 `runZonedGuarded` 调用本身会抛出 `onError` 抛出的错误；如果 `onError` 正常返回，`runZonedGuarded` 则返回 `null`。

创建出来的 Zone 始终是一个错误 Zone。属于不同 `Zone.errorZone` 的 Zone 之间，Future 中的异步错误不会跨 Zone 边界传播。因此，在创建出来的 Zone 中以错误结束的 `Future`，如果在另一个属于不同错误 Zone 的 Zone 中使用，可能会看起来一直无法完成。在无法访问该错误的 Zone 中多次尝试使用这个 Future，会导致错误在原始错误 Zone 中被再次报告。

## 实现说明

### 1. 保存调用方的 Zone

```dart
_Zone parentZone = Zone._current;
```

`parentZone` 是调用 `runZonedGuarded` 时所在的 Zone。之后调用 `onError` 时，实现在这个外层 Zone 中运行它，而不是在要被监控的子 Zone 中运行。

### 2. 建立异步错误处理器

```dart
HandleUncaughtErrorHandler errorHandler = (
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  Object error,
  StackTrace stackTrace,
) {
  try {
    parentZone.runBinary(onError, error, stackTrace);
  } catch (e, s) {
    if (identical(e, error)) {
      parent.handleUncaughtError(zone, error, stackTrace);
    } else {
      parent.handleUncaughtError(zone, e, s);
    }
  }
};
```

Zone 中出现未处理的异步错误时，会调用这个处理器。`parentZone.runBinary(...)` 在外层 Zone 中调用用户传入的 `onError(error, stackTrace)`。这样可以避免 `onError` 自己抛出的错误又被同一个 `onError` 递归处理。

处理器也捕获 `onError` 自身抛出的异常：

- 如果 `onError` 重新抛出的是同一个错误对象（`identical(e, error)`），就把原始错误及其原始堆栈交给父级错误处理器。
- 如果 `onError` 抛出了另一个错误，就把这个新错误及其堆栈交给父级错误处理器。

这里的 `parent` 是 Zone 的父级委托对象；`zone` 表示发生原始错误的 Zone。调用 `parent.handleUncaughtError(...)` 会把 `onError` 自身未处理的错误继续交给父级处理链。

### 3. 确保新 Zone 使用这个处理器

```dart
if (zoneSpecification == null) {
  zoneSpecification = ZoneSpecification(
    handleUncaughtError: errorHandler,
  );
} else {
  zoneSpecification = ZoneSpecification.from(
    zoneSpecification,
    handleUncaughtError: errorHandler,
  );
}
```

没有传入 `zoneSpecification` 时，创建一个只设置了 `handleUncaughtError` 的 specification。若调用方传入了 specification，则基于它创建新对象、保留其他配置，同时把 `handleUncaughtError` 设置为这里构造的处理器。

### 4. 运行 `body` 并处理同步异常

```dart
try {
  return _runZoned<R>(body, zoneValues, zoneSpecification);
} catch (error, stackTrace) {
  onError(error, stackTrace);
}
return null;
```

`_runZoned` 会创建并进入新 Zone，然后运行 `body`。如果调用 `body` 时同步抛出异常，外层 `catch` 会直接调用 `onError`：

- `onError` 正常返回：函数返回 `null`，表示没有可返回的 `body` 结果。
- `onError` 再次抛出异常：异常会从 `runZonedGuarded` 调用处继续向外抛出。
- `body` 正常返回：函数返回 `body` 的结果，类型为 `R?`。

异步错误走前面配置的 `handleUncaughtError`，不是这里的同步 `catch`。例如 `body` 是 `async` 函数时，函数体里的 `throw` 通常会让它返回的 Future 以错误结束；若该错误未被 Future 的 `catch` 处理，就会由所属 Zone 的异步错误处理器接收。

## 使用时需要记住

- `runZonedGuarded` 捕获的是它创建的 Zone 中未处理的错误；已经被 `try/catch`、Future 错误处理器或 Flutter 框架错误处理器接管的错误，不会再作为该 Zone 的未处理错误传入 `onError`。
- Zone 是 isolate 内的执行上下文。子 isolate 的错误不会直接跨 isolate 进入外层 Zone；像 `compute` 这样的 API 会把错误作为调用方 Future 的错误传回，而直接创建的 isolate 则需要通过错误端口等方式转发。
- `Future` 的错误不能跨越拥有不同 `errorZone` 的 Zone。若在另一个错误 Zone 中观察这个 Future，错误可能无法在那里被接收，而会继续在原始错误 Zone 中报告。
