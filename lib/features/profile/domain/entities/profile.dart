import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.memberSince,
  });

  final String fullName;
  final String email;
  final String phone;
  final DateTime memberSince;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  Profile copyWith({String? fullName, String? email, String? phone}) => Profile(
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    memberSince: memberSince,
  );

  @override
  List<Object?> get props => [fullName, email, phone, memberSince];
}
