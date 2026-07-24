  import 'package:flutter/material.dart';
  import 'package:jornadafacil/core/services/vibration_service.dart';
  import 'package:jornadafacil/core/theme/app_colors.dart';
  import 'package:jornadafacil/features/register/presentation/widgets/journey_state.dart';
  import 'package:jornadafacil/shared/widgets/buttons/action_button.dart';
  import 'package:jornadafacil/shared/widgets/buttons/circular_progress_button.dart';

  class JourneyButton extends StatefulWidget {
    final DateTime? entryTime;
    final DateTime? exitTime;
    final VoidCallback onTap;
    final bool isInsideGeofence;

    const JourneyButton({
      super.key,
      this.entryTime,
      this.exitTime,
      required this.onTap,
      this.isInsideGeofence = false,
    });

    @override
    State<JourneyButton> createState() => _JourneyButtonState();
  }

  class _JourneyButtonState extends State<JourneyButton> {
    @override
    void didUpdateWidget(JourneyButton oldWidget) {
      super.didUpdateWidget(oldWidget);

      if (oldWidget.isInsideGeofence != widget.isInsideGeofence) {
        _vibrate();
      }
    }

    void _vibrate() {
      if (widget.isInsideGeofence) {
        VibrationService().vibrate(duration: 200);
      } else {
        VibrationService().vibrate(duration: 300);
      }
    }

    JourneyState _getState() {
      if (widget.entryTime != null && widget.exitTime == null) {
        return JourneyState.working;
      }
      return JourneyState.idle;
    }

    IconData _getIcon() {
      final state = _getState();
      return switch (state) {
        JourneyState.idle => Icons.login,
        JourneyState.working => Icons.logout
      };
    }

    Color _getInverseBorderColor() {
      final state = _getState();
      return state.buttonColor == AppColors.primaryContainer
          ? AppColors.error
          : AppColors.primaryContainer;
    }

    Color _getButtonColor() {
      if (!widget.isInsideGeofence) {
        return AppColors.darkGrey;
      }
      final state = _getState();
      return state.buttonColor;
    }

    void _handleCompletion() {
      VibrationService().vibrate(duration: 150);
      widget.onTap();
    }

    @override
    Widget build(BuildContext context) {
      final state = _getState();

      return CircularProgressButton(
        enabled: widget.isInsideGeofence,
        onCompleted: _handleCompletion,
        builder: (context, isPressed, progress, pulse) {
          return SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isPressed)
                  AnimatedBuilder(
                    animation: progress,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (pulse.value * 0.15),
                        child: CustomPaint(
                          size: const Size(double.infinity, 140),
                          painter: CircularBorderPainter(
                            progress: progress.value,
                            color: _getInverseBorderColor(),
                          ),
                        ),
                      );
                    },
                  ),
                if (isPressed)
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (context, child) {
                      final scale = 1.0 + (pulse.value * 0.15);
                      return Transform.scale(
                        scale: scale,
                        child: ActionButton(
                          label: state.buttonLabel,
                          icon: _getIcon(),
                          onTap: null,
                          backgroundColor: _getButtonColor(),
                        ),
                      );
                    },
                  )
                else
                  ActionButton(
                    label: state.buttonLabel,
                    icon: _getIcon(),
                    onTap: null,
                    backgroundColor: _getButtonColor(),
                  ),
              ],
            ),
          );
        },
      );
    }
  }
