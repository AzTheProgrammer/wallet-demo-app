import 'package:injectable/injectable.dart';

@lazySingleton
class AppClock {
  DateTime now() => DateTime.now();
}
