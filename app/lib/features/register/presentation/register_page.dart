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
import 'package:jornadafacil/shared/utils/responsive.dart';

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

  Future<void> _syncWithServer() async {
    try {
      final journeys = await _journeyService.listJourneys();

      if (!mounted) return;
      setState(() {
        _journeys = journeys;
        _openJourney = _firstOpen(journeys);
        if (_openJourney != null) {
          _reflectTimes(_openJourney!);
        } else {
          final latest = journeys.isEmpty ? null : journeys.first;
          if (latest != null && _isToday(latest.startedAt.toLocal())) {
            _reflectTimes(latest);
          } else {
            _clearTimes();
          }
        }
      });
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  bool _isToday(DateTime dateTime) =>
      DateUtils.isSameDay(dateTime, DateTime.now());

  JourneyModel? _firstOpen(List<JourneyModel> journeys) {
    for (final journey in journeys) {
      if (journey.isOpen) return journey;
    }
    return null;
  }

  void _reflectTimes(JourneyModel journey) {
    _entryTime = journey.startedAt.toLocal();
    _exitTime = journey.finishedAt?.toLocal();
  }

  void _clearTimes() {
    _entryTime = null;
    _exitTime = null;
  }

  List<JourneyModel> get _todayJourneys {
    final today =
        _journeys
            .where((journey) => _isToday(journey.startedAt.toLocal()))
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return today;
  }

  Future<void> _handleWorkSessionTap() async {
    if (_saving || _syncing) return;
    setState(() => _saving = true);

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
          _reflectTimes(journey);
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
          _reflectTimes(journey);
        });
      }
    } on ApiException catch (e) {
      _showError(e.message);
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalMargin,
                  vertical: 16,
                ),
                child: _content(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    final canRegister = context.appState.currentUser.can(
      '${rbac.Resources.journey}:${rbac.Actions.view}',
    );

    return Column(
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
        if (canRegister) ...[
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
    );
  }
}
