import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';
import 'package:wallet_app/features/profile/domain/entities/profile.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';
import 'package:wallet_app/features/send_money/domain/entities/beneficiary.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction_query.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';

final fixedNow = DateTime(2026, 3, 14, 10, 30);

const mainAccount = Account(
  id: 'acc-main',
  name: 'Everyday account',
  kind: AccountKind.main,
  balance: Money(1842675),
  number: '62018847291',
);

const savingsAccount = Account(
  id: 'acc-savings',
  name: 'Savings pocket',
  kind: AccountKind.savings,
  balance: Money(4125000),
  number: '62018847305',
);

final payment = Transaction(
  id: 'txn-1',
  title: 'Woolworths Food',
  type: TransactionType.payment,
  amount: const Money(-45099),
  occurredAt: fixedNow,
  status: TransactionStatus.completed,
  reference: 'WLT1001',
  accountName: 'Everyday account',
);

final salary = Transaction(
  id: 'txn-2',
  title: 'Salary',
  type: TransactionType.deposit,
  amount: const Money(3250000),
  occurredAt: fixedNow.subtract(const Duration(days: 2)),
  status: TransactionStatus.pending,
  reference: 'SAL1002',
);

final electricity = Transaction(
  id: 'txn-3',
  title: 'City Power electricity',
  type: TransactionType.electricity,
  amount: const Money(-20000),
  occurredAt: fixedNow.subtract(const Duration(days: 3)),
  status: TransactionStatus.failed,
  reference: 'VAS1003',
  token: '12345678901234567890',
);

final firstPage = TransactionPage(items: [payment, salary], hasMore: true);

final lastPage = TransactionPage(items: [electricity], hasMore: false);

const sipho = Beneficiary(
  id: 'ben-1',
  name: 'Sipho Dlamini',
  bank: 'Capitec',
  accountNumber: '1450028813',
);

const newPerson = NewBeneficiary(
  name: 'Anele Naidoo',
  bank: 'FNB',
  accountNumber: '62541190027',
);

const sendRequest = SendMoneyRequest(
  fromAccountId: 'acc-main',
  beneficiary: sipho,
  amount: Money(15000),
  reference: 'Lunch',
);

final sendReceipt = SendMoneyReceipt(
  transactionId: 'txn-9',
  reference: 'Lunch',
  sentAt: fixedNow,
);

const vodacom = VasProvider(id: 'vodacom', name: 'Vodacom');

const cityPower = VasProvider(id: 'citypower', name: 'City Power');

const airtimeOption = VasOption(
  id: 'air-29',
  label: 'R29 airtime',
  amount: Money(2900),
);

const electricityOption = VasOption(
  id: 'elec-100',
  label: 'R100 electricity',
  amount: Money(10000),
);

const airtimePurchase = VasPurchase(
  kind: VasKind.airtime,
  provider: vodacom,
  option: airtimeOption,
  recipient: '0825550142',
  accountId: 'acc-main',
);

final airtimeReceipt = VasReceipt(
  transactionId: 'txn-8',
  reference: 'VAS10000001',
  purchasedAt: fixedNow,
);

final electricityReceipt = VasReceipt(
  transactionId: 'txn-7',
  reference: 'VAS10000002',
  purchasedAt: fixedNow,
  token: '12345678901234567890',
  units: '31.3 kWh',
);

const tiers = [
  RewardTier(name: 'Bronze', minPoints: 0),
  RewardTier(name: 'Silver', minPoints: 5000),
  RewardTier(name: 'Gold', minPoints: 15000),
];

const rewardsSummary = RewardsSummary(points: 12480, tiers: tiers);

const airtimeOffer = RewardOffer(
  id: 'off-1',
  title: 'R20 airtime',
  description: 'Any network',
  kind: RewardKind.airtime,
  cost: 800,
);

const fuelOffer = RewardOffer(
  id: 'off-6',
  title: 'R500 fuel voucher',
  description: 'Partner garages',
  kind: RewardKind.voucher,
  cost: 20000,
);

const redemption = Redemption(
  code: 'WLT-123456',
  offerTitle: 'R20 airtime',
  pointsRemaining: 11680,
);

final thandi = Profile(
  fullName: 'Thandi Mokoena',
  email: 'thandi@example.co.za',
  phone: '0825550142',
  memberSince: DateTime(2023, 3, 14),
);
