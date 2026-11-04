import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet_app/features/profile/domain/entities/profile.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
abstract class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String fullName,
    required String email,
    required String phone,
    required DateTime memberSince,
  }) = _ProfileModel;

  const ProfileModel._();

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  factory ProfileModel.fromEntity(Profile profile) => ProfileModel(
    fullName: profile.fullName,
    email: profile.email,
    phone: profile.phone,
    memberSince: profile.memberSince,
  );

  Profile toEntity() => Profile(
    fullName: fullName,
    email: email,
    phone: phone,
    memberSince: memberSince,
  );
}
