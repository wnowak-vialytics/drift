@TestOn('browser')
import 'package:drift/wasm.dart';
import 'package:drift_testcases/tests.dart';
import 'package:sqlite3/wasm.dart';
import 'package:test/test.dart';

class DriftWasmExecutor extends TestExecutor {
  final InMemoryFileSystem fs;
  final WasmSqlite3 Function() sqlite3;

  DriftWasmExecutor(this.fs, this.sqlite3);

  @override
  bool get supportsNestedTransactions => true;

  @override
  bool get supportsReturning => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection(
        WasmDatabase(sqlite3: sqlite3(), path: '/drift_test.db'));
  }

  @override
  Future<void> deleteData() async {
    fs.fileData.clear();
  }
}

void main() {
  final fs = InMemoryFileSystem();
  late WasmSqlite3 sqlite3;

  setUpAll(() async {
    final channel = spawnHybridUri('/test/test_utils/sqlite_server.dart');
    final port = (await channel.stream.first as num).toInt();

    sqlite3 = await WasmSqlite3.loadFromUrl(
        Uri.parse('http://localhost:$port/sqlite3.wasm'));
    sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

    channel.sink.close();
  });

  runAllTests(DriftWasmExecutor(fs, () => sqlite3));
}
