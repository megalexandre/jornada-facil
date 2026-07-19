import 'package:flutter/material.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';

enum JourneyState {
  idle,
  working;

  String get buttonLabel {
    return switch (this) {
      JourneyState.idle => 'ENTRADA',
      JourneyState.working => 'SAÍDA',
    };
  }

  Color get buttonColor {
    return switch (this) {
      JourneyState.idle => AppColors.buttonBlue,
      JourneyState.working => AppColors.buttonRed
    };
  }

  String get message {
    return switch (this) {
      JourneyState.idle => 'Toque no botão para registrar seu início de jornada',
      JourneyState.working => 'Toque no botão para registrar seu término de jornada'
    };
  }
}
