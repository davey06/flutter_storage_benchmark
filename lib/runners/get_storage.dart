import 'package:get_storage/get_storage.dart';
import 'package:storage_benchmark/runners/runner.dart';

class GetStorageRunner implements BenchmarkRunner {
  @override
  String get name => 'GS';

  @override
  Future<void> setUp() async {
    await GetStorage.init();
    return;
  }

  @override
  Future<void> tearDown() async {
    await GetStorage('benchmark').erase();
  }

  @override
  Future<int> batchReadInt(List<String> keys) async {
    var s = Stopwatch()..start();
    for (var key in keys) {
      await GetStorage('benchmark').read(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchReadString(List<String> keys) async {
    return batchReadInt(keys);
  }

  @override
  Future<int> batchWriteInt(Map<String, int> entries) async {
    var s = Stopwatch()..start();
    for (var key in entries.keys) {
      await GetStorage('benchmark').write(key, entries[key]);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteString(Map<String, String> entries) async {
    var s = Stopwatch()..start();
    for (var key in entries.keys) {
      await GetStorage('benchmark').write(key, entries[key]);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteInt(List<String> keys) async {
    var s = Stopwatch()..start();
    for (var key in keys) {
      await GetStorage('benchmark').remove(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteString(List<String> keys) {
    return batchDeleteInt(keys);
  }
}
