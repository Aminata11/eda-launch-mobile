import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/role_selection_screen.dart';
import 'admin_projects_screen.dart';
import 'admin_users_screen.dart';
import 'admin_financing_screen.dart';
import 'admin_availability_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'admin_appointments_screen.dart';
import 'admin_formations_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  int _currentIndex = 0;
  int _unreadCount = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
  final response = await ApiService.get(AppUrls.dashboardAdmin);
  final profileResponse = await ApiService.get(AppUrls.me);
  final notifResponse = await ApiService.get(AppUrls.notifications);

  if (mounted) {
    final firstName = profileResponse['data']?['first_name'] ?? '';
    final lastName = profileResponse['data']?['last_name'] ?? '';
    final notifs = notifResponse['data']?['notifications'] as List? ?? [];

    setState(() {
      _dashboardData = response['success'] ? response['data'] : null;
      _userName = '$firstName $lastName'.trim();
      _unreadCount = notifs.where((n) => n['is_read'] == false).length;
      _isLoading = false;
    });
  }
}

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
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
      ? _buildHomeTab()
      : _currentIndex == 1
          ? const AdminProjectsScreen()
          : const AdminFormationsScreen(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (index) => setState(() => _currentIndex = index),
  backgroundColor: AppColors.white,
  selectedItemColor: AppColors.admin,
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
    BottomNavigationBarItem(
      icon: Icon(Icons.school_outlined),
      activeIcon: Icon(Icons.school_rounded),
      label: 'Formations',
    ),
  ],
);
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.admin),
      );
    }

    final kpis = _dashboardData?['kpis'] ?? {};
    final utilisateurs = _dashboardData?['utilisateurs'] ?? {};
    final projets = _dashboardData?['projets'] ?? {};
    final financement = _dashboardData?['financement'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.admin,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Admin
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bonjour 👋',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _userName.isEmpty ? 'Administrateur' : _userName,
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
                                        builder: (_) => const NotificationsScreen(),
                                      ),
                                    ).then((_) => _loadDashboard()),
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
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$_unreadCount',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminAppointmentsScreen(),
                                  ),
                                ).then((_) => _loadDashboard()),
                                icon: const Icon(
                                  Icons.event_note_rounded,
                                  color: AppColors.white,
                                ),
                                tooltip: 'Rendez-vous',
                              ),
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminAvailabilityScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: AppColors.white,
                                ),
                                tooltip: 'Mes disponibilités',
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

                      // KPIs principaux
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              'Utilisateurs',
                              '${kpis['total_utilisateurs'] ?? 0}',
                              Icons.people_rounded,
                              Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              'Projets',
                              '${kpis['total_projets'] ?? 0}',
                              Icons.rocket_launch_rounded,
                              Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              'Taux financement',
                              '${kpis['taux_financement'] ?? 0}%',
                              Icons.percent_rounded,
                              Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Utilisateurs par rôle
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Utilisateurs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminUsersScreen(),
                        ),
                      ),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(
                        'Entrepreneurs',
                        '${utilisateurs['entrepreneurs'] ?? 0}',
                        AppColors.entrepreneur,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard(
                        'Mentors',
                        '${utilisateurs['mentors'] ?? 0}',
                        AppColors.mentor,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard(
                        'Financeurs',
                        '${utilisateurs['financeurs'] ?? 0}',
                        AppColors.financeur,
                      )),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Projets par statut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Projets par statut',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _currentIndex = 1),
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _buildStatusRow('Brouillon',
                            projets['par_statut']?['brouillons'] ?? 0,
                            AppColors.grey500),
                        _buildStatusRow('Soumis',
                            projets['par_statut']?['soumis'] ?? 0,
                            AppColors.info),
                        _buildStatusRow('En analyse',
                            projets['par_statut']?['en_analyse'] ?? 0,
                            AppColors.warning),
                        _buildStatusRow('Acceptés',
                            projets['par_statut']?['acceptes'] ?? 0,
                            AppColors.success),
                        _buildStatusRow('Financés',
                            projets['par_statut']?['finances'] ?? 0,
                            AppColors.primary),
                        _buildStatusRow('En suivi',
                            projets['par_statut']?['en_suivi'] ?? 0,
                            AppColors.mentor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Financement
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Financement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminFinancingScreen(),
                        ),
                      ),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _buildFinanceRow(
                          'Total demandes',
                          '${financement['total_demandes'] ?? 0}',
                          AppColors.primary,
                        ),
                        _buildFinanceRow(
                          'Approuvées',
                          '${financement['approuvees'] ?? 0}',
                          AppColors.success,
                        ),
                        _buildFinanceRow(
                          'En attente',
                          '${financement['en_attente'] ?? 0}',
                          AppColors.warning,
                        ),
                        _buildFinanceRow(
                          'Montant approuvé',
                          '${financement['montant_total_approuve'] ?? 0} FCFA',
                          AppColors.success,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}