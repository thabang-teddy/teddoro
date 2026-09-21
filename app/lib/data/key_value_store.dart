import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Minimal string store. Each key is one document, which keeps the app
/// offline-first and lets a sync layer diff whole documents later.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Stores each key as `<documents>/teddoro/<key>.json`.
class FileKeyValueStore implements KeyValueStore {
  FileKeyValueStore._(this._dir);

  final Directory _dir;

  static Future<FileKeyValueStore> open() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}teddoro');
    if (!await dir.exists()) await dir.create(recursive: true);
    return FileKeyValueStore._(dir);
  }

  File _file(String key) =>
      File('${_dir.path}${Platform.pathSeparator}$key.json');

  @override
  Future<String?> read(String key) async {
    final file = _file(key);
    if (!await file.exists()) return null;
    try {
      return await file.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    // Write to a temp file then rename so a crash mid-write cannot corrupt
    // the document.
    final target = _file(key);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(value, flush: true);
    await tmp.rename(target.path);
  }
}

/// In-memory store for tests.
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}
