import 'package:flutter/material.dart';
import 'package:teddoro/app/dependencies.dart';
import 'package:teddoro/app/teddoro_app.dart';
import 'package:teddoro/data/key_value_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await FileKeyValueStore.open();
  final deps = await AppDependencies.create(store: store);
  runApp(TeddoroApp(deps: deps));
}
