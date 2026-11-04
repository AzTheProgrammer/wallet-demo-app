import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/happy_path.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('log in, send money, see it in history', (tester) async {
    tester.usePhoneScreen();
    await runHappyPath(tester);
  });
}
