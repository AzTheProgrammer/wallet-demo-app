import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

abstract class FixtureLoader {
  Future<Object?> load(String name);
}

@LazySingleton(as: FixtureLoader)
class AssetFixtureLoader implements FixtureLoader {
  @override
  Future<Object?> load(String name) async {
    final raw = await rootBundle.loadString('assets/mock/$name.json');
    return jsonDecode(raw);
  }
}
