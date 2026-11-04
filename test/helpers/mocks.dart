import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/config/demo_config.dart';
import 'package:wallet_app/core/mock/fixture_loader.dart';
import 'package:wallet_app/core/utils/app_clock.dart';
import 'package:wallet_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:wallet_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:wallet_app/features/auth/presentation/change_pin/change_pin_cubit.dart';
import 'package:wallet_app/features/auth/presentation/pin_entry/pin_entry_cubit.dart';
import 'package:wallet_app/features/auth/presentation/pin_setup/pin_setup_cubit.dart';
import 'package:wallet_app/features/dashboard/domain/repositories/account_repository.dart';
import 'package:wallet_app/features/dashboard/domain/usecases/get_accounts.dart';
import 'package:wallet_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:wallet_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:wallet_app/features/profile/domain/usecases/profile_usecases.dart';
import 'package:wallet_app/features/profile/presentation/cubit/developer_cubit.dart';
import 'package:wallet_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wallet_app/features/profile/presentation/cubit/settings_cubit.dart';
import 'package:wallet_app/features/rewards/domain/repositories/rewards_repository.dart';
import 'package:wallet_app/features/rewards/domain/usecases/rewards_usecases.dart';
import 'package:wallet_app/features/rewards/presentation/cubit/rewards_cubit.dart';
import 'package:wallet_app/features/send_money/domain/repositories/send_money_repository.dart';
import 'package:wallet_app/features/send_money/domain/usecases/send_money_usecases.dart';
import 'package:wallet_app/features/send_money/presentation/bloc/send_money_bloc.dart';
import 'package:wallet_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:wallet_app/features/transactions/domain/usecases/transaction_usecases.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:wallet_app/features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import 'package:wallet_app/features/vas/domain/repositories/vas_repository.dart';
import 'package:wallet_app/features/vas/domain/usecases/vas_usecases.dart';
import 'package:wallet_app/features/vas/presentation/bloc/vas_bloc.dart';

class MockClock extends Mock implements AppClock {}

class MockDemoConfig extends Mock implements DemoConfig {}

class MockFixtureLoader extends Mock implements FixtureLoader {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockSendMoneyRepository extends Mock implements SendMoneyRepository {}

class MockVasRepository extends Mock implements VasRepository {}

class MockRewardsRepository extends Mock implements RewardsRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockCheckPinExists extends Mock implements CheckPinExists {}

class MockCreatePin extends Mock implements CreatePin {}

class MockVerifyPin extends Mock implements VerifyPin {}

class MockChangePin extends Mock implements ChangePin {}

class MockGetLockout extends Mock implements GetLockout {}

class MockGetBiometricStatus extends Mock implements GetBiometricStatus {}

class MockSetBiometricsEnabled extends Mock implements SetBiometricsEnabled {}

class MockAuthenticate extends Mock implements AuthenticateWithBiometrics {}

class MockGetAccounts extends Mock implements GetAccounts {}

class MockGetTransactions extends Mock implements GetTransactions {}

class MockGetRecent extends Mock implements GetRecentTransactions {}

class MockGetTransactionById extends Mock implements GetTransactionById {}

class MockWatchLedger extends Mock implements WatchLedgerChanges {}

class MockGetProfile extends Mock implements GetProfile {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

class MockGetTheme extends Mock implements GetThemePreference {}

class MockSaveTheme extends Mock implements SaveThemePreference {}

class MockGetBeneficiaries extends Mock implements GetBeneficiaries {}

class MockAddBeneficiary extends Mock implements AddBeneficiary {}

class MockSendMoney extends Mock implements SendMoney {}

class MockGetVasProviders extends Mock implements GetVasProviders {}

class MockGetVasOptions extends Mock implements GetVasOptions {}

class MockPurchaseVas extends Mock implements PurchaseVas {}

class MockGetRewardsSummary extends Mock implements GetRewardsSummary {}

class MockGetRewardOffers extends Mock implements GetRewardOffers {}

class MockRedeemReward extends Mock implements RedeemReward {}

class MockPinEntryCubit extends MockCubit<PinEntryState>
    implements PinEntryCubit {}

class MockPinSetupCubit extends MockCubit<PinSetupState>
    implements PinSetupCubit {}

class MockChangePinCubit extends MockCubit<ChangePinState>
    implements ChangePinCubit {}

class MockDashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

class MockTransactionsBloc
    extends MockBloc<TransactionsEvent, TransactionsState>
    implements TransactionsBloc {}

class MockTransactionDetailCubit extends MockCubit<TransactionDetailState>
    implements TransactionDetailCubit {}

class MockSendMoneyBloc extends MockBloc<SendMoneyEvent, SendMoneyState>
    implements SendMoneyBloc {}

class MockVasBloc extends MockBloc<VasEvent, VasState> implements VasBloc {}

class MockRewardsCubit extends MockCubit<RewardsState>
    implements RewardsCubit {}

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class MockDeveloperCubit extends MockCubit<DeveloperState>
    implements DeveloperCubit {}
