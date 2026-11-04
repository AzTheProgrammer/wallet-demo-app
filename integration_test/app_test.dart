import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'happy_path.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('log in, send money, see it in history', runHappyPath);
}
