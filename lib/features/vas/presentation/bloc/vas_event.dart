part of 'vas_bloc.dart';

@freezed
sealed class VasEvent with _$VasEvent {
  const factory VasEvent.started(VasKind kind) = VasStarted;
  const factory VasEvent.providerSelected(VasProvider provider) =
      VasProviderSelected;
  const factory VasEvent.recipientChanged(String recipient) =
      VasRecipientChanged;
  const factory VasEvent.recipientSubmitted() = VasRecipientSubmitted;
  const factory VasEvent.optionSelected(VasOption option) = VasOptionSelected;
  const factory VasEvent.confirmed() = VasConfirmed;
  const factory VasEvent.stepBack() = VasStepBack;
}
