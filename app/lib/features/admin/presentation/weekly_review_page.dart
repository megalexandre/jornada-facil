import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart';
import 'package:jornadafacil/core/network/api_exception.dart';
import 'package:jornadafacil/core/services/admin_service.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';
import 'package:jornadafacil/features/admin/presentation/weekly_review_detail_page.dart';
import 'package:jornadafacil/features/admin/presentation/widgets/compliance_card.dart';
import 'package:jornadafacil/features/admin/presentation/widgets/week_header.dart';
import 'package:jornadafacil/features/admin/presentation/widgets/weekly_user_tile.dart';
import 'package:jornadafacil/shared/utils/responsive.dart';
import 'package:jornadafacil/shared/utils/week_utils.dart';

class WeeklyReviewPage extends StatefulWidget {
  const WeeklyReviewPage({super.key});

  @override
  State<WeeklyReviewPage> createState() => _WeeklyReviewPageState();
}

class _WeeklyReviewPageState extends State<WeeklyReviewPage> {
  final AdminService _adminService = AdminService();

  late DateTime _weekStart;
  bool _loading = true;
  String? _error;
  WeeklyReviewSummaryModel? _summary;

  @override
  void initState() {
    super.initState();
    _weekStart = WeekUtils.mondayOfWeek(DateTime.now());
    _load();
  }

  static String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool get _canGoNext =>
      _weekStart.isBefore(WeekUtils.mondayOfWeek(DateTime.now()));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await _adminService.getWeeklyReview(
        weekStart: _isoDate(_weekStart),
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
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

  void _changeWeek(int days) {
    setState(() => _weekStart = _weekStart.add(Duration(days: days)));
    _load();
  }

  Future<void> _openDetail(WeeklyReviewUserRowModel user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeeklyReviewDetailPage(
          userId: user.id,
          userName: user.name,
          weekStart: _weekStart,
        ),
      ),
    );
    // Ao voltar, recarrega para refletir aprovações/reprovações.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    // Limita a largura num desktop/web: sem isso o cabeçalho, a barra de semana
    // e a lista esticariam pela janela inteira. Num celular o maxWidth não restringe.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revisão Semanal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jornadas da equipe na semana',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            WeekHeader(
              weekStart: _weekStart,
              canGoNext: _canGoNext,
              onPrevious: () => _changeWeek(-7),
              onNext: () => _changeWeek(7),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
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

    final summary = _summary!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: ComplianceCard(
              complianceRate: summary.complianceRate,
              delta: summary.complianceDelta,
            ),
          ),
          if (summary.users.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: Text('Nenhum usuário encontrado.')),
            )
          else
            ...summary.users.map(
              (user) => Column(
                children: [
                  WeeklyUserTile(user: user, onTap: () => _openDetail(user)),
                  const Divider(height: 1),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
