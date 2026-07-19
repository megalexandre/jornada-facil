import 'package:flutter/material.dart';
import 'package:jornadafacil/app/app.dart';
import 'package:jornadafacil/core/models/rbac.dart' as rbac;
import 'package:jornadafacil/core/models/weekly_review_detail_model.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart';
import 'package:jornadafacil/core/network/api_exception.dart';
import 'package:jornadafacil/core/services/admin_service.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';
import 'package:jornadafacil/features/admin/presentation/widgets/day_activity_tile.dart';
import 'package:jornadafacil/features/admin/presentation/widgets/metric_card.dart';
import 'package:jornadafacil/shared/utils/date_format_helper.dart';
import 'package:jornadafacil/shared/widgets/cards/week_locations_card.dart';

/// Detalhe da semana de um usuário: totais, batidas por dia e a ação de
/// aprovar (exige weekly_review:update).
class WeeklyReviewDetailPage extends StatefulWidget {
  final String userId;
  final String userName;
  final DateTime weekStart;

  const WeeklyReviewDetailPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.weekStart,
  });

  @override
  State<WeeklyReviewDetailPage> createState() => _WeeklyReviewDetailPageState();
}

class _WeeklyReviewDetailPageState extends State<WeeklyReviewDetailPage> {
  final AdminService _adminService = AdminService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  WeeklyReviewDetailModel? _detail;

  /// Dia destacado no mapa; null = mostra todos os dias.
  DateTime? _selectedDay;

  void _toggleDay(DateTime date) {
    setState(() => _selectedDay = _selectedDay == date ? null : date);
  }

  String get _weekStartIso {
    final month = widget.weekStart.month.toString().padLeft(2, '0');
    final day = widget.weekStart.day.toString().padLeft(2, '0');
    return '${widget.weekStart.year}-$month-$day';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await _adminService.getUserWeeklyReview(
        widget.userId,
        weekStart: _weekStartIso,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprovar jornada semanal'),
        content: Text('Confirmar a aprovação da semana de ${widget.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _submit(
      () => _adminService.approveWeeklyReview(
        widget.userId,
        weekStart: _weekStartIso,
      ),
      'Jornada semanal aprovada.',
    );
  }

  Future<void> _submit(Future<void> Function() action, String message) async {
    setState(() => _submitting = true);

    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = widget.weekStart.add(const Duration(days: 6));
    final canReview = context.appState.currentUser.can(
      '${rbac.Resources.weeklyReview}:${rbac.Actions.update}',
    );
    final alreadyApproved =
        _detail?.review?.status == WeeklyReviewStatus.approved;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName),
            Text(
              DateFormatHelper.formatWeekRange(widget.weekStart, weekEnd),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: _buildContent(),
      bottomNavigationBar: canReview && _detail != null && !alreadyApproved
          ? _buildActions()
          : null,
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    final detail = _detail!;

    // Dias plotados no mapa: todos, ou só o dia selecionado.
    final mapDays = _selectedDay == null
        ? detail.days
        : detail.days.where((d) => d.date == _selectedDay).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _TotalWeekCard(detail: detail),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  icon: Icons.schedule,
                  label: 'PADRÃO (40h)',
                  value: formatMinutes(detail.standardMinutes),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MetricCard(
                  icon: Icons.more_time,
                  label: 'HORA EXTRA',
                  value: formatMinutes(detail.overtimeMinutes),
                  valueColor: detail.overtimeMinutes > 0
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _AbsencesRow(absences: detail.absences),
          if (detail.review != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ReviewBanner(review: detail.review!),
          ],
          const SizedBox(height: AppSpacing.sm),
          WeekLocationsCard(
            weekStart: detail.weekStart,
            entries: [
              for (final day in mapDays)
                for (final interval in day.intervals)
                  if (interval.startLocation != null)
                    (point: interval.startLocation!, date: day.date),
            ],
            exits: [
              for (final day in mapDays)
                for (final interval in day.intervals)
                  if (interval.endLocation != null)
                    (point: interval.endLocation!, date: day.date),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Batidas da semana',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_selectedDay != null)
                TextButton(
                  onPressed: () => setState(() => _selectedDay = null),
                  child: const Text('Ver todos'),
                ),
            ],
          ),
          Text(
            'Toque num dia para ver só ele no mapa',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...detail.weekdays.map(
            (day) => DayActivityTile(
              day: day,
              selected: _selectedDay == day.date,
              onTap: () => _toggleDay(day.date),
            ),
          ),
          _WeekendCard(detail: detail),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _submitting ? null : _approve,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Aprovar jornada semanal'),
        ),
      ),
    );
  }
}

class _TotalWeekCard extends StatelessWidget {
  final WeeklyReviewDetailModel detail;

  const _TotalWeekCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final progress = detail.expectedMinutes == 0
        ? 0.0
        : (detail.totalMinutes / detail.expectedMinutes).clamp(0.0, 1.0);
    final over = detail.totalMinutes > detail.expectedMinutes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL DA SEMANA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryFixed,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatMinutes(detail.totalMinutes),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.onPrimary.withValues(alpha: 0.24),
              valueColor: AlwaysStoppedAnimation<Color>(
                over ? AppColors.errorContainer : AppColors.primaryFixed,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Previsto: ${formatMinutes(detail.expectedMinutes)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.primaryFixed),
          ),
        ],
      ),
    );
  }
}

class _AbsencesRow extends StatelessWidget {
  final int absences;

  const _AbsencesRow({required this.absences});

  @override
  Widget build(BuildContext context) {
    final hasAbsences = absences > 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.event_busy,
              size: 20,
              color: hasAbsences ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Faltas',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '$absences',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: hasAbsences ? AppColors.error : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  final WeeklyReviewInfoModel review;

  const _ReviewBanner({required this.review});

  @override
  Widget build(BuildContext context) {
    final approved = review.status == WeeklyReviewStatus.approved;
    final background = approved
        ? AppColors.successContainer
        : AppColors.errorContainer;
    final foreground = approved
        ? AppColors.onSuccessContainer
        : AppColors.onErrorContainer;
    final when = DateFormatHelper.formatDateTime(review.reviewedAt);
    final headline = approved
        ? 'Aprovada por ${review.reviewerName} em $when'
        : 'Reprovada por ${review.reviewerName} em $when';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: foreground,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  headline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Motivo: ${review.comment}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekendCard extends StatelessWidget {
  final WeeklyReviewDetailModel detail;

  const _WeekendCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final overtime = detail.weekendOvertimeMinutes;
    final worked = overtime > 0;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.weekend_outlined,
              size: 20,
              color: worked ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Fim de semana (sáb - dom)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              worked ? '+${formatMinutes(overtime)} extra' : 'Descanso',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: worked ? AppColors.error : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
