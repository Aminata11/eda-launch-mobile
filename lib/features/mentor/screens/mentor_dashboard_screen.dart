import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/role_selection_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../reporting/screens/report_detail_screen.dart';
import '../../projects/screens/business_plan_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'mentor_project_detail_screen.dart';

class MentorDashboardScreen extends StatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  State<MentorDashboardScreen> createState() =>
      _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends State<MentorDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _projects = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int _unreadCount = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

Future<void> _loadData() async {
  final dashResponse = await ApiService.get(AppUrls.dashboardMentor);
  final projectsResponse = await ApiService.get(AppUrls.projects);
  final notifResponse = await ApiService.get(AppUrls.notifications);
  final profileResponse = await ApiService.get(AppUrls.me);

  if (mounted) {
    final firstName = profileResponse['data']?['first_name'] ?? '';
    final lastName = profileResponse['data']?['last_name'] ?? '';
    final notifs = notifResponse['data']?['notifications'] as List? ?? [];

    setState(() {
      _dashboardData = dashResponse['success'] ? dashResponse['data'] : null;
      _projects = projectsResponse['success']
          ? (projectsResponse['data']['projects'] as List? ?? [])
          : [];
      _unreadCount = notifs.where((n) => n['is_read'] == false).length;
      _userName = '$firstName $lastName'.trim();
      _isLoading = false;
    });
  }
}

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content:
            const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await ApiService.deleteToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentIndex == 0
          ? _buildDashboardTab()
          : _buildProjectsTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _loadData();
        },
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.mentor,
        unselectedItemColor: AppColors.grey400,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder_rounded),
            label: 'Projets',
          ),
        ],
      ),
    );
  }

  // ==============================
  // ONGLET DASHBOARD
  // ==============================
  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mentor),
      );
    }

    final kpis = _dashboardData?['kpis'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.mentor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Mentor
          Container(
              decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A7A4A), Color(0xFF15693E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                        Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour 👋',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                              _userName.isEmpty ? 'Mentor / Coach' : _userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            ],
                          ),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen(),
                                      ),
                                    ).then((_) => _loadData()),
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  if (_unreadCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.all(4),
                                        decoration:
                                            const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$_unreadCount',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                onPressed: _logout,
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // KPIs
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              'Entrepreneurs',
                              '${kpis['total_entrepreneurs'] ?? 0}',
                              Icons.people_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              'Projets actifs',
                              '${kpis['projets_actifs'] ?? 0}',
                              Icons.rocket_launch_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              'Rapports',
                              '${kpis['total_rapports'] ?? 0}',
                              Icons.bar_chart_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Projets assignés
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes entrepreneurs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_projects.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Aucun projet assigné pour le moment',
                          style: TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._projects.map((p) => _buildProjectMiniCard(p)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
      String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.white, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectMiniCard(Map<String, dynamic> project) {
    return GestureDetector(
      onTap: () => _showProjectDetail(project),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.mentorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: AppColors.mentor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    project['sector'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
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
  }

  // ==============================
  // ONGLET PROJETS
  // ==============================
  Widget _buildProjectsTab() {
    return Column(
      children: [
        AppBar(
          title: const Text('Projets assignés'),
          backgroundColor: AppColors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: _projects.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun projet assigné',
                    style:
                        TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.mentor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      return _buildProjectCard(_projects[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final status = project['status'] ?? '';

    return GestureDetector(
      onTap: () => _showProjectDetail(project),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mentorLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mentor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project['description'] ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category_rounded,
                    size: 14, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  project['sector'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  project['location'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDetail(Map<String, dynamic> project) {
  Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MentorProjectDetailScreen(project: project),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReports(String projectId) async {
    final response = await ApiService.get(
      '${AppUrls.reporting}?project_id=$projectId',
    );

    if (!mounted) return;

    final reports = response['success']
        ? (response['data']['reports'] as List? ?? [])
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rapports hebdomadaires',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (reports.isEmpty)
                const Text(
                  'Aucun rapport soumis',
                  style:
                      TextStyle(color: AppColors.textSecondary),
                )
              else
                ...reports.map((r) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(
                              reportId: r['id'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(16),
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
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Revenus: ${r['revenue']} FCFA | Dépenses: ${r['expenses']} FCFA',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors
                                          .textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.grey400,
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addCoachingNote(
    String projectId, String projectName) async {
  final TextEditingController noteController =
      TextEditingController();
  double _note = 10;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: Text('Note coaching — $projectName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note sur 20
            const Text(
              'Note sur 20',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _note,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    activeColor: AppColors.mentor,
                    label: '${_note.toInt()}/20',
                    onChanged: (v) =>
                        setStateDialog(() => _note = v),
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
                    '${_note.toInt()}/20',
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
            // Observations
            const Text(
              'Observations et conseils',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
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
                  'score': _note.toInt(),
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
              backgroundColor: AppColors.mentor,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showEvolution(String projectId, String projectName) async {
  final response = await ApiService.get(
    AppUrls.projectReports(projectId),
  );

  if (!mounted) return;

  final reports = response['success']
      ? (response['data']['reports'] as List? ?? [])
      : [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Évolution — $projectName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (reports.isEmpty)
              const Center(
                child: Text(
                  'Aucun rapport disponible',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else ...[

              // Graphique Revenus vs Dépenses
              const Text(
                'Revenus vs Dépenses (FCFA)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < reports.length) {
                              return Text(
                                'S${index + 1}',
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Revenus
                      LineChartBarData(
                        spots: reports.asMap().entries.map((e) {
                          return FlSpot(
                            e.key.toDouble(),
                            double.tryParse(
                                    e.value['revenue'].toString()) ??
                                0,
                          );
                        }).toList(),
                        isCurved: true,
                        color: AppColors.success,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                      // Dépenses
                      LineChartBarData(
                        spots: reports.asMap().entries.map((e) {
                          return FlSpot(
                            e.key.toDouble(),
                            double.tryParse(
                                    e.value['expenses'].toString()) ??
                                0,
                          );
                        }).toList(),
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

              // Légende
              Row(
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      )),
                  const SizedBox(width: 6),
                  const Text('Revenus',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      )),
                  const SizedBox(width: 6),
                  const Text('Dépenses',
                      style: TextStyle(fontSize: 12)),
                ],
              ),

              const SizedBox(height: 24),

              // Graphique Progression
              const Text(
                'Progression du projet (%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 150,
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1, 
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < reports.length) {
                              return Text(
                                'S${index + 1}',
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: reports.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: double.tryParse(
                                    e.value['progress_percent']
                                        .toString()) ??
                                0,
                            color: AppColors.mentor,
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tableau récapitulatif
              const Text(
                'Récapitulatif',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              ...reports.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sem. ${r['report_month']?.toString().substring(0, 10) ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '+${r['revenue']} FCFA',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '-${r['expenses']} FCFA',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${r['progress_percent']}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mentor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<void> _showCoachingHistory(
    String projectId, String projectName) async {
  final response = await ApiService.get(
    AppUrls.coachingNotes(projectId),
  );

  if (!mounted) return;

  final notes = response['success']
      ? (response['data']['notes'] as List? ?? [])
      : [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coaching — $projectName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mentorLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Moy: ${(notes.map((n) => n['score'] ?? 0).reduce((a, b) => a + b) / notes.length).toStringAsFixed(1)}/20',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mentor,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            if (notes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aucune note de coaching',
                    style:
                        TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...notes.map((n) => Container(
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
                                color: AppColors.textSecondary,
                              ),
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
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    ),
  );
}

Color _getScoreColor(int score) {
  if (score >= 16) return AppColors.success;
  if (score >= 12) return AppColors.mentor;
  if (score >= 8) return AppColors.warning;
  return AppColors.error;
}

// ==============================
// ALERTES ENTREPRENEUR
// ==============================
Future<void> _showAlerts(
    String projectId, String projectName) async {
  final response = await ApiService.get(
    AppUrls.entrepreneurAlerts(projectId),
  );

  if (!mounted) return;

  final alerts = response['success']
      ? (response['data']['alerts'] as List? ?? [])
      : [];

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Alertes — $projectName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (alerts.isEmpty)
            Container(
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
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...alerts.map((alert) {
              final isError = alert['type'] == 'error';
              final color =
                  isError ? AppColors.error : AppColors.warning;
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
                          color: color,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

// ==============================
// SUIVI FORMATIONS
// ==============================
Future<void> _showFormationsProgress(
    String entrepreneurId, String projectName) async {
  final response = await ApiService.get(
    AppUrls.entrepreneurFormations(entrepreneurId),
  );

  if (!mounted) return;

  final formations = response['success']
      ? (response['data']['formations'] as List? ?? [])
      : [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Formations — $projectName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (formations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aucune formation suivie',
                    style: TextStyle(
                        color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...formations.map((f) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                f['formation_title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                f['category'] ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Barre de progression
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                value: (double.tryParse(f['progress_percent'].toString()) ?? 0) / 100,
                                backgroundColor: AppColors.grey200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getProgressColor(
                                    double.tryParse(f['progress_percent'].toString()) ?? 0,
                                  ),
                                ),
                                minHeight: 8,
                              ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${f['progress_percent']}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _getProgressColor(
                                    double.tryParse(
                                            f['progress_percent']
                                                .toString()) ??
                                        0),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.book_rounded,
                                size: 14,
                                color: AppColors.grey400),
                            const SizedBox(width: 4),
                            Text(
  f['is_completed'] == true ? '✅ Complétée' : '🔄 En cours',
  style: TextStyle(
    fontSize: 12,
    color: f['is_completed'] == true
        ? AppColors.success
        : AppColors.warning,
    fontWeight: FontWeight.w600,
  ),
),
const SizedBox(width: 16),
const Icon(Icons.access_time_rounded,
    size: 14, color: AppColors.grey400),
const SizedBox(width: 4),
Text(
  'Démarré : ${f['started_at']?.toString().substring(0, 10) ?? 'N/A'}',
  style: const TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  ),
),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    ),
  );
}

Color _getProgressColor(double progress) {
  if (progress >= 75) return AppColors.success;
  if (progress >= 50) return AppColors.mentor;
  if (progress >= 25) return AppColors.warning;
  return AppColors.error;
}
}