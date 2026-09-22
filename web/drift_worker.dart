// drift WasmDatabase 专用 worker 入口（编译产物 drift_worker.js 由
// `dart compile js -O2 -o web/drift_worker.js web/drift_worker.dart` 生成）。
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
