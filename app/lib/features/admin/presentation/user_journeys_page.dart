import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/core/models/user_summary_model.dart';
import 'package:jornadafacil/core/network/api_exception.dart';
import 'package:jornadafacil/core/services/admin_service.dart';
import 'package:jornadafacil/features/admin/presentation/widgets/journey_list_tile.dart';

/// Jornadas de um usuário escolhido na aba de administração.
class UserJourneysPage extends StatefulWidget {
  final UserSummaryModel user;

  const UserJourneysPage({super.key, required this.user});

  @override
  State<UserJourneysPage> createState() => _UserJourneysPageState();
}

class _UserJourneysPageState extends State<UserJourneysPage> {
  final AdminService _adminService = AdminService();

  bool _loading = true;
  String? _error;
  List<JourneyModel> _journeys = const [];

  @override
  void initState() {
    super.initState();
    _loadJourneys();
  }

  Future<void> _loadJourneys() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final journeys = await _adminService.listUserJourneys(widget.user.id);
      if (!mounted) return;
      setState(() {
        _journeys = journeys;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user.name)),
      body: _buildContent(),
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
            TextButton(
              onPressed: _loadJourneys,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_journeys.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadJourneys,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Nenhuma jornada registrada.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJourneys,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _journeys.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) =>
            JourneyListTile(journey: _journeys[index]),
      ),
    );
  }
}
