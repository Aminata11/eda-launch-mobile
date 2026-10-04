import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/role_selection_screen.dart';
import '../../projects/screens/business_plan_screen.dart';
import 'appointment_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../admin/screens/entrepreneur_profile_screen.dart';

class FinanceurDashboardScreen extends StatefulWidget {
  const FinanceurDashboardScreen({super.key});
  

  @override
  State<FinanceurDashboardScreen> createState() =>
      _FinanceurDashboardScreenState();
}

class _FinanceurDashboardScreenState
    extends State<FinanceurDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _selectedStatus = 'tous';
  int _currentIndex = 0;

  String? _selectedCondition;

  int _unreadCount = 0;

  String _userName = '';

final List<String> _conditionsPredefinies = [
  'Don sans remboursement',
  'Remboursement sur 6 mois sans intérêt',
  'Remboursement sur 12 mois à 5%',
  'Remboursement sur 24 mois à 5%',
  'Remboursement sur 36 mois à 7%',
  'Subvention partielle (50% don + 50% prêt)',
];

 final List<Map<String, dynamic>> _statusFilters = [
  {'key': 'tous', 'label': 'Tous'},
  {'key': 'en_analyse', 'label': 'En analyse'},
  {'key': 'approuve', 'label': 'Approuvé'},
  {'key': 'decaisse', 'label': 'Décaissé'},
  {'key': 'rejete', 'label': 'Rejeté'},
];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  final dashResponse = await ApiService.get(AppUrls.dashboardFinanceur);
  final requestsResponse = await ApiService.get(AppUrls.financing);
  final profileResponse = await ApiService.get(AppUrls.me);
  final notifResponse = await ApiService.get(AppUrls.notifications);

  if (mounted) {
    final firstName = profileResponse['data']?['first_name'] ?? '';
    final lastName = profileResponse['data']?['last_name'] ?? '';
    final notifs = notifResponse['data']?['notifications'] as List? ?? [];

    setState(() {
      _dashboardData = dashResponse['success'] ? dashResponse['data'] : null;
      _requests = requestsResponse['success']
          ? (requestsResponse['data']['requests'] as List? ?? [])
          : [];
      _userName = '$firstName $lastName'.trim();
      _unreadCount = notifs.where((n) => n['is_read'] == false).length;
      _isLoading = false;
    });
  }
}

  List<dynamic> get _filteredRequests {
    if (_selectedStatus == 'tous') return _requests;
    return _requests
        .where((r) => r['status'] == _selectedStatus)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente': return AppColors.warning;
      case 'en_analyse': return AppColors.info;
      case 'approuve': return AppColors.success;
      case 'rejete': return AppColors.error;
      case 'decaisse': return AppColors.mentor;
      default: return AppColors.grey500;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'en_attente': return 'En attente';
      case 'en_analyse': return 'En analyse';
      case 'approuve': return 'Approuvé';
      case 'rejete': return 'Rejeté';
      case 'decaisse': return 'Décaissé';
      default: return status;
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
          ? _buildDashboardTab()
          : _buildRequestsTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _loadData();
        },
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.financeur,
        unselectedItemColor: AppColors.grey400,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            activeIcon: Icon(Icons.account_balance_rounded),
            label: 'Demandes',
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
        child: CircularProgressIndicator(color: AppColors.financeur),
      );
    }

    final kpis = _dashboardData?['kpis'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.financeur,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Financeur
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFB45309)],
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
                              _userName.isEmpty ? 'Financeur' : _userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            ],
                          ),
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
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
                            onPressed: _logout,
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // KPIs
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              'Demandes traitées',
                              '${kpis['total_traitees'] ?? 0}',
                              Icons.assignment_turned_in_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              'Approuvées',
                              '${kpis['approuvees'] ?? 0}',
                              Icons.check_circle_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
  child: _buildKpiCard(
    'En analyse',
    '${kpis['demandes_en_attente'] ?? 0}',
    Icons.search_rounded,
  ),
),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Volume financé
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Volume total financé',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${kpis['volume_finance'] ?? 0} FCFA',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

           // Demandes de financement
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Demandes de financement',
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

                  ...(_requests
                      .where((r) => r['status'] == 'en_attente' || r['status'] == 'en_analyse')
                      .take(3)
                      .map((r) => _buildRequestMiniCard(r))),

                  if (_requests
                      .where((r) => r['status'] == 'en_attente' || r['status'] == 'en_analyse')
                      .isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Aucune demande en attente',
                          style: TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                // Projets financés
                const Text(
                  'Projets financés',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (_requests.where((r) => r['status'] == 'approuve' || r['status'] == 'decaisse').isEmpty)
                  const Text(
                    'Aucun projet financé pour le moment',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  ..._requests
                      .where((r) => r['status'] == 'approuve' || r['status'] == 'decaisse')
                      .map((r) => Container(
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
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['project_name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Demandé : ${r['amount_requested']} FCFA',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        'Approuvé : ${r['amount_approved']} FCFA',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon) {
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

  Widget _buildRequestMiniCard(Map<String, dynamic> request) {
    return GestureDetector(
      onTap: () => _showRequestDetail(request),
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
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request['project_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${request['amount_requested']} FCFA',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.financeur,
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
  // ONGLET DEMANDES
  // ==============================
  Widget _buildRequestsTab() {
    return Column(
      children: [
        AppBar(
          title: const Text('Demandes de financement'),
          backgroundColor: AppColors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),

        // Filtres
        Container(
          color: AppColors.white,
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            itemCount: _statusFilters.length,
            itemBuilder: (context, index) {
              final filter = _statusFilters[index];
              final isSelected = _selectedStatus == filter['key'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedStatus = filter['key']),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.financeur
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Liste
        Expanded(
          child: _filteredRequests.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune demande',
                    style:
                        TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.financeur,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(
                          _filteredRequests[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'en_attente';
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () => _showRequestDetail(request),
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
                    request['project_name'] ?? '',
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    size: 16, color: AppColors.financeur),
                const SizedBox(width: 4),
                Text(
                  '${request['amount_requested']} FCFA',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.financeur,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              request['purpose'] ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            Text(
              request['created_at']
                      ?.toString()
                      .substring(0, 10) ??
                  '',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetail(Map<String, dynamic> request) {
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

              // Titre
              Text(
                request['project_name'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // Montant
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Montant demandé',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.financeur,
                      ),
                    ),
                    Text(
                      '${request['amount_requested']} FCFA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.financeur,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Utilisation
              const Text(
                'Utilisation prévue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                request['purpose'] ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Voir Business Plan
              if (request['project_id'] != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusinessPlanScreen(
                          projectId: request['project_id'],
                          showSubmitButton: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Voir le Business Plan'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),

                const SizedBox(height: 12),

              // Bouton Fixer un RDV
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentScreen(
                        projectId: request['project_id'],
                        financingRequestId: request['id'],
                      ),
                    ),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.financeur),
                label: const Text(
                  'Fixer un rendez-vous',
                  style: TextStyle(color: AppColors.financeur),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.financeur),
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EntrepreneurProfileScreen(
                      entrepreneurId: request['entrepreneur_id'],
                      entrepreneurName: request['entrepreneur_name'] ?? '',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_rounded,
                  color: AppColors.financeur),
              label: const Text('Voir profil entrepreneur',
                  style: TextStyle(color: AppColors.financeur)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.financeur),
                minimumSize: const Size(double.infinity, 46),
              ),
            ),

            const SizedBox(height: 12),

              // Actions
            if (request['status'] == 'en_attente' || request['status'] == 'en_analyse') ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _approveRequest(request);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approuver la demande'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize:
                        const Size(double.infinity, 52),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _rejectRequest(request['id']);
                  },
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.error),
                  label: const Text('Rejeter',
                      style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    minimumSize:
                        const Size(double.infinity, 52),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    // Demande le montant approuvé
    final TextEditingController amountController =
        TextEditingController(
            text: request['amount_requested'].toString());
    final TextEditingController conditionsController =
        TextEditingController();

   final confirm = await showDialog<bool>(
  context: context,
  builder: (_) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approuver la demande',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
  'Montant approuvé (FCFA)',
  style: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ),
),
const SizedBox(height: 8),
TextFormField(
  controller: amountController,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
    prefixIcon: Icon(Icons.monetization_on_rounded),
    hintText: 'Ex: 15000000',
  ),
),
          const SizedBox(height: 16),
          const Text(
            'Conditions du financement',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCondition,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Sélectionner les conditions',
                    ),
                    items: _conditionsPredefinies
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setStateDialog(() => _selectedCondition = v);
                      conditionsController.text = v ?? '';
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: conditionsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ou conditions personnalisées',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Approuver'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

    if (confirm != true) return;

    final response = await ApiService.patch(
      AppUrls.financingStatus(request['id']),
      {
        'status': 'approuve',
        'amount_approved':
            double.tryParse(amountController.text) ?? 0,
        'conditions': conditionsController.text.trim(),
      },
    );

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande approuvée ✅'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final TextEditingController reasonController =
        TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejeter la demande'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Raison du rejet',
            hintText: 'Expliquez pourquoi...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await ApiService.patch(
      AppUrls.financingStatus(requestId),
      {
        'status': 'rejete',
        'rejection_reason': reasonController.text.trim(),
      },
    );

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande rejetée ❌'),
          backgroundColor: AppColors.error,
        ),
      );
      _loadData();
    }
  }
}