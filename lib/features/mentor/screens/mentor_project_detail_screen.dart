import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import '../../projects/screens/business_plan_screen.dart';
import '../../reporting/screens/report_detail_screen.dart';
import '../../admin/screens/entrepreneur_profile_screen.dart';

class MentorProjectDetailScreen extends StatelessWidget {
  final Map<String, dynamic> project;

  const MentorProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(project['name'] ?? ''),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Infos projet
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Secteur', project['sector'] ?? ''),
                  _buildInfoRow('Localisation', project['location'] ?? ''),
                  _buildInfoRow('Statut', project['status'] ?? ''),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Actions
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Business Plan
            if (project['has_business_plan'] == true)
              _buildActionButton(
                context,
                label: 'Voir le Business Plan',
                icon: Icons.description_rounded,
                color: AppColors.mentor,
                outlined: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BusinessPlanScreen(
                      projectId: project['id'],
                      showSubmitButton: false,
                    ),
                  ),
                ),
              ),

              _buildActionButton(
                context,
                label: 'Voir profil entrepreneur',
                icon: Icons.person_rounded,
                color: AppColors.mentor,
                outlined: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EntrepreneurProfileScreen(
                      entrepreneurId: project['entrepreneur_id'],
                      entrepreneurName: project['entrepreneur_name'] ?? '',
                    ),
                  ),
                ),
              ),

            _buildActionButton(
              context,
              label: 'Voir les rapports',
              icon: Icons.bar_chart_rounded,
              color: AppColors.mentor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MentorReportsScreen(
                    projectId: project['id'],
                    projectName: project['name'],
                  ),
                ),
              ),
            ),

            _buildActionButton(
              context,
              label: 'Voir l\'évolution',
              icon: Icons.trending_up_rounded,
              color: AppColors.info,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MentorEvolutionScreen(
                    projectId: project['id'],
                    projectName: project['name'],
                  ),
                ),
              ),
            ),

            _buildActionButton(
              context,
              label: 'Ajouter note de coaching',
              icon: Icons.comment_rounded,
              color: AppColors.mentor,
              outlined: true,
              onTap: () => _addCoachingNote(context, project['id'], project['name']),
            ),

            _buildActionButton(
              context,
              label: 'Historique coaching',
              icon: Icons.history_rounded,
              color: AppColors.mentor,
              outlined: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MentorCoachingHistoryScreen(
                    projectId: project['id'],
                    projectName: project['name'],
                  ),
                ),
              ),
            ),

            _buildActionButton(
              context,
              label: 'Voir les alertes',
              icon: Icons.warning_rounded,
              color: AppColors.warning,
              outlined: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MentorAlertsScreen(
                    projectId: project['id'],
                    projectName: project['name'],
                  ),
                ),
              ),
            ),

            _buildActionButton(
              context,
              label: 'Suivi formations',
              icon: Icons.school_rounded,
              color: AppColors.info,
              outlined: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MentorFormationsScreen(
                    entrepreneurId: project['entrepreneur_id'],
                    projectName: project['name'],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label : ',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color, size: 18),
              label: Text(label, style: TextStyle(color: color)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                minimumSize: const Size(double.infinity, 46),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
    );
  }

  Future<void> _addCoachingNote(
      BuildContext context, String projectId, String projectName) async {
    final TextEditingController noteController = TextEditingController();
    double score = 10;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Note coaching — $projectName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Note sur 20',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: score,
                      min: 0,
                      max: 20,
                      divisions: 20,
                      activeColor: AppColors.mentor,
                      label: '${score.toInt()}/20',
                      onChanged: (v) =>
                          setStateDialog(() => score = v),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mentorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${score.toInt()}/20',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mentor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Observations et conseils',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Observations, conseils, points à améliorer...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.post(
                  '${AppUrls.baseUrl}/reporting/$projectId/coaching',
                  {
                    'note': noteController.text.trim(),
                    'score': score.toInt(),
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note de coaching ajoutée ✅'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mentor),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================
// ÉCRAN RAPPORTS
// ==============================
class MentorReportsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const MentorReportsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<MentorReportsScreen> createState() => _MentorReportsScreenState();
}

class _MentorReportsScreenState extends State<MentorReportsScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final response = await ApiService.get(
      '${AppUrls.reporting}?project_id=${widget.projectId}',
    );
    if (mounted) {
      setState(() {
        _reports = response['success']
            ? (response['data']['reports'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Rapports — ${widget.projectName}'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.mentor))
          : _reports.isEmpty
              ? const Center(
                  child: Text('Aucun rapport soumis',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final r = _reports[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReportDetailScreen(reportId: r['id']),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Semaine du ${r['report_month']?.toString().substring(0, 10) ?? ''}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Revenus: ${r['revenue']} FCFA | Dépenses: ${r['expenses']} FCFA',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: AppColors.grey400),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ==============================
// ÉCRAN ÉVOLUTION
// ==============================
class MentorEvolutionScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const MentorEvolutionScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<MentorEvolutionScreen> createState() =>
      _MentorEvolutionScreenState();
}

class _MentorEvolutionScreenState extends State<MentorEvolutionScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final response =
        await ApiService.get(AppUrls.projectReports(widget.projectId));
    if (mounted) {
      setState(() {
        _reports = response['success']
            ? (response['data']['reports'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Évolution — ${widget.projectName}'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.mentor))
          : _reports.isEmpty
              ? const Center(
                  child: Text('Aucun rapport disponible',
                      style:
                          TextStyle(color: AppColors.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenus vs Dépenses (FCFA)',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < _reports.length) {
                                      return Text('S${index + 1}',
                                          style: const TextStyle(
                                              fontSize: 10));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _reports
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                          e.key.toDouble(),
                                          double.tryParse(e.value[
                                                      'revenue']
                                                  .toString()) ??
                                              0,
                                        ))
                                    .toList(),
                                isCurved: true,
                                color: AppColors.success,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                              LineChartBarData(
                                spots: _reports
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                          e.key.toDouble(),
                                          double.tryParse(e.value[
                                                      'expenses']
                                                  .toString()) ??
                                              0,
                                        ))
                                    .toList(),
                                isCurved: true,
                                color: AppColors.error,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Revenus',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 16),
                          Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Dépenses',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Progression (%)',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: BarChart(
                          BarChartData(
                            gridData:
                                const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < _reports.length) {
                                      return Text('S${index + 1}',
                                          style: const TextStyle(
                                              fontSize: 10));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: _reports
                                .asMap()
                                .entries
                                .map((e) => BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: double.tryParse(
                                                  e.value[
                                                          'progress_percent']
                                                      .toString()) ??
                                              0,
                                          color: AppColors.mentor,
                                          width: 20,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  4),
                                        ),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Récapitulatif',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ..._reports.map((r) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.grey200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Sem. ${r['report_month']?.toString().substring(0, 10) ?? ''}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text('+${r['revenue']} FCFA',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text('-${r['expenses']} FCFA',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text('${r['progress_percent']}%',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mentor,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
    );
  }
}

// ==============================
// ÉCRAN HISTORIQUE COACHING
// ==============================
class MentorCoachingHistoryScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const MentorCoachingHistoryScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<MentorCoachingHistoryScreen> createState() =>
      _MentorCoachingHistoryScreenState();
}

class _MentorCoachingHistoryScreenState
    extends State<MentorCoachingHistoryScreen> {
  List<dynamic> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final response =
        await ApiService.get(AppUrls.coachingNotes(widget.projectId));
    if (mounted) {
      setState(() {
        _notes = response['success']
            ? (response['data']['notes'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 16) return AppColors.success;
    if (score >= 12) return AppColors.mentor;
    if (score >= 8) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    double moyenne = 0;
    if (_notes.isNotEmpty) {
      final scores = _notes
          .where((n) => n['score'] != null)
          .map((n) => (n['score'] as num).toDouble())
          .toList();
      if (scores.isNotEmpty) {
        moyenne = scores.reduce((a, b) => a + b) / scores.length;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Coaching — ${widget.projectName}'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: _notes.isNotEmpty
            ? [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.mentorLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Moy: ${moyenne.toStringAsFixed(1)}/20',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mentor,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.mentor))
          : _notes.isEmpty
              ? const Center(
                  child: Text('Aucune note de coaching',
                      style:
                          TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final n = _notes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                n['created_at']
                                        ?.toString()
                                        .substring(0, 10) ??
                                    '',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                              if (n['score'] != null)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getScoreColor(
                                            n['score'] as int)
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${n['score']}/20',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _getScoreColor(
                                          n['score'] as int),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            n['note'] ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ==============================
// ÉCRAN ALERTES
// ==============================
class MentorAlertsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const MentorAlertsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<MentorAlertsScreen> createState() => _MentorAlertsScreenState();
}

class _MentorAlertsScreenState extends State<MentorAlertsScreen> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final response = await ApiService.get(
        AppUrls.entrepreneurAlerts(widget.projectId));
    if (mounted) {
      setState(() {
        _alerts = response['success']
            ? (response['data']['alerts'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Alertes — ${widget.projectName}'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.mentor))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _alerts.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: AppColors.success),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aucune alerte — L\'entrepreneur est sur la bonne voie ! 🎉',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        final isError = alert['type'] == 'error';
                        final color = isError
                            ? AppColors.error
                            : AppColors.warning;
                        final bgColor = isError
                            ? AppColors.errorLight
                            : AppColors.warningLight;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isError
                                    ? Icons.trending_down_rounded
                                    : Icons.warning_rounded,
                                color: color,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  alert['message'] ?? '',
                                  style: TextStyle(
                                      color: color, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// ==============================
// ÉCRAN FORMATIONS
// ==============================
class MentorFormationsScreen extends StatefulWidget {
  final String entrepreneurId;
  final String projectName;

  const MentorFormationsScreen({
    super.key,
    required this.entrepreneurId,
    required this.projectName,
  });

  @override
  State<MentorFormationsScreen> createState() =>
      _MentorFormationsScreenState();
}

class _MentorFormationsScreenState
    extends State<MentorFormationsScreen> {
  List<dynamic> _formations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    final response = await ApiService.get(
        AppUrls.entrepreneurFormations(widget.entrepreneurId));
    if (mounted) {
      setState(() {
        _formations = response['success']
            ? (response['data']['formations'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return AppColors.success;
    if (progress >= 50) return AppColors.mentor;
    if (progress >= 25) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Formations — ${widget.projectName}'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.mentor))
          : _formations.isEmpty
              ? const Center(
                  child: Text('Aucune formation suivie',
                      style:
                          TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _formations.length,
                  itemBuilder: (context, index) {
                    final f = _formations[index];
                    final progress = double.tryParse(
                            f['progress_percent'].toString()) ??
                        0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['formation_title'] ?? '',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                    backgroundColor: AppColors.grey200,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      _getProgressColor(progress),
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$progress%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _getProgressColor(progress),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            f['is_completed'] == true
                                ? '✅ Complétée'
                                : '🔄 En cours',
                            style: TextStyle(
                              fontSize: 12,
                              color: f['is_completed'] == true
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}