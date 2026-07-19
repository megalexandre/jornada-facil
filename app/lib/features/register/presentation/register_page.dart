import 'package:flutter/material.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/core/models/rbac.dart' as rbac;
import 'package:jornadafacil/core/network/api_exception.dart';
import 'package:jornadafacil/core/services/journey_service.dart';
import 'package:jornadafacil/app/app.dart';
import 'package:jornadafacil/features/register/presentation/widgets/journey_button.dart';
import 'package:jornadafacil/features/register/presentation/widgets/journey_turns_table.dart';
import 'package:jornadafacil/shared/widgets/cards/local_date_time_card.dart';
import 'package:jornadafacil/shared/utils/date_format_helper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final JourneyService _journeyService = JourneyService();

  JourneyModel? _openJourney;
  List<JourneyModel> _journeys = const [];
  DateTime? _entryTime;
  DateTime? _exitTime;
  bool _syncing = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _syncWithServer();
  }

  /// Restaura o estado a partir da API: jornada aberta vira "trabalhando";
  /// sem jornada aberta, a última jornada de hoje preenche entrada/saída.
  Future<void> _syncWithServer() async {
    try {
      final journeys = await _journeyService.listJourneys();

      JourneyModel? open;
      for (final journey in journeys) {
        if (journey.isOpen) {
          open = journey;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _journeys = journeys;
        _openJourney = open;
        if (open != null) {
          _entryTime = open.startedAt.toLocal();
          _exitTime = null;
        } else {
          final latest = journeys.isEmpty ? null : journeys.first;
          if (latest != null && _isToday(latest.startedAt.toLocal())) {
            _entryTime = latest.startedAt.toLocal();
            _exitTime = latest.finishedAt?.toLocal();
          } else {
            _entryTime = null;
            _exitTime = null;
          }
        }
      });
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Jornadas de hoje, da mais antiga para a mais recente (1º Turno primeiro).
  List<JourneyModel> get _todayJourneys {
    final today = _journeys
        .where((journey) => _isToday(journey.startedAt.toLocal()))
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return today;
  }

  Future<void> _handleWorkSessionTap() async {
    if (_saving || _syncing) return;
    setState(() => _saving = true);

    // Última posição conhecida no momento do toque; null sem fix do GPS.
    final latitude = context.appState.latitude;
    final longitude = context.appState.longitude;

    try {
      if (_openJourney == null) {
        final journey = await _journeyService.openJourney(
          latitude: latitude,
          longitude: longitude,
        );
        if (!mounted) return;
        setState(() {
          _journeys = [journey, ..._journeys];
          _openJourney = journey;
          _entryTime = journey.startedAt.toLocal();
          _exitTime = null;
        });
      } else {
        final journey = await _journeyService.finishJourney(
          _openJourney!.id,
          latitude: latitude,
          longitude: longitude,
        );
        if (!mounted) return;
        setState(() {
          _journeys = [
            for (final item in _journeys)
              item.id == journey.id ? journey : item,
          ];
          _openJourney = null;
          _entryTime = journey.startedAt.toLocal();
          _exitTime = journey.finishedAt?.toLocal();
        });
      }
    } on ApiException catch (e) {
      _showError(e.message);
      // Estado local pode ter divergido do servidor (ex.: jornada já aberta
      // em outro dispositivo) — re-sincroniza.
      await _syncWithServer();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.appState,
      builder: (context, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatHelper.formatDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 24),
                const LocalDateTimeCard(),
                const SizedBox(height: 24),

                if (context.appState.currentUser.can('${rbac.Resources.journey}:${rbac.Actions.view}')) ...[
                  JourneyButton(
                    entryTime: _entryTime,
                    exitTime: _exitTime,
                    onTap: _handleWorkSessionTap,
                    isInsideGeofence: context.appState.isInsideGeofence,
                  ),
                  const SizedBox(height: 24),
                ],

                JourneyTurnsTable(journeys: _todayJourneys),
              ],
            ),
          ),
        );
      },
    );
  }
}
