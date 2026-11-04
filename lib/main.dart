import 'package:flutter/material.dart';
import 'package:wallet_app/app.dart';
import 'package:wallet_app/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const WalletApp());
}
