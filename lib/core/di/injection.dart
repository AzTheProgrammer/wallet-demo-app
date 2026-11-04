import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/core/config/data_source_mode.dart';
import 'package:wallet_app/core/di/injection.config.dart';

final GetIt getIt = GetIt.instance;

const mockSource = Environment('mock');
const apiSource = Environment('api');

@InjectableInit(ignoreUnregisteredTypes: [DataSourceMode])
Future<void> configureDependencies({
  DataSourceMode mode = DataSourceMode.mock,
}) async {
  getIt.registerSingleton<DataSourceMode>(mode);
  await getIt.init(environment: mode.name);
}

@module
abstract class PlatformModule {
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  LocalAuthentication get localAuth => LocalAuthentication();

  @preResolve
  Future<SharedPreferences> get preferences => SharedPreferences.getInstance();
}
