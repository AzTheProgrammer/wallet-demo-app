import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/config/data_source_mode.dart';
import 'package:wallet_app/core/config/demo_config.dart';

part 'developer_cubit.freezed.dart';

@freezed
abstract class DeveloperState with _$DeveloperState {
  const factory DeveloperState({
    required DataSourceMode mode,
    required double failureRate,
    required bool offline,
  }) = _DeveloperState;
}

@injectable
class DeveloperCubit extends Cubit<DeveloperState> {
  DeveloperCubit(this._config, DataSourceMode mode)
    : super(
        DeveloperState(
          mode: mode,
          failureRate: _config.failureRate,
          offline: _config.offline,
        ),
      );

  final DemoConfig _config;

  void setFailureRate(double rate) {
    _config.failureRate = rate;
    emit(state.copyWith(failureRate: rate));
  }

  void setOffline({required bool offline}) {
    _config.offline = offline;
    emit(state.copyWith(offline: offline));
  }
}
