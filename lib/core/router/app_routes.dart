abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const pinSetup = '/onboarding/pin';
  static const login = '/login';
  static const home = '/home';
  static const transactions = '/activity';
  static const rewards = '/rewards';
  static const profile = '/profile';
  static const send = '/send';
  static const personalDetails = '/profile/details';
  static const changePin = '/profile/change-pin';
  static const developer = '/developer';
  static const designSystem = '/developer/design-system';

  static String vas(String kind) => '/vas/$kind';

  static String transactionDetail(String id, String heroScope) =>
      '/activity/$id?from=$heroScope';

  static const Set<String> publicOnly = {splash, onboarding, pinSetup, login};
}
