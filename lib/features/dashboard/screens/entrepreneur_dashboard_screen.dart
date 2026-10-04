import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import '../../projects/screens/projects_screen.dart';
import '../../formations/screens/formations_screen.dart';
import '../../financing/screens/financing_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../features/projects/screens/project_detail_screen.dart';
import '../../reporting/screens/reporting_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'mentoring_screen.dart';
import '../../../core/services/api_service.dart';
import '../../profile/screens/profile_screen.dart';
import '../../auth/screens/role_selection_screen.dart';

class EntrepreneurDashboardScreen extends StatefulWidget {
  const EntrepreneurDashboardScreen({super.key});

  @override
  State<EntrepreneurDashboardScreen> createState() =>
      _EntrepreneurDashboardScreenState();
}

class _EntrepreneurDashboardScreenState
    extends State<EntrepreneurDashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }
String? _profilePhoto;

Future<void> _loadDashboard() async {
  final response = await ApiService.get(AppUrls.dashboardEntrepreneur);
  final profileResponse = await ApiService.get(AppUrls.me);
  
  if (mounted) {
    final firstName = profileResponse['data']?['first_name'] ?? '';
    final lastName = profileResponse['data']?['last_name'] ?? '';
    
    setState(() {
      _dashboardData = response['success'] ? response['data'] : null;
      _userName = '$firstName $lastName'.trim();
      _profilePhoto = profileResponse['data']?['profile_photo'];
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentIndex == 0
          ? _buildHomeTab()
          : _currentIndex == 1
              ? const ProjectsScreen()
              : _currentIndex == 2
                  ? const FormationsScreen()
                  : _currentIndex == 3
                      ? const FinancingScreen()
                      : const ProfileScreen(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            _loadDashboard();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder_rounded),
            label: 'Projets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school_rounded),
            label: 'Formation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            activeIcon: Icon(Icons.account_balance_rounded),
            label: 'Financement',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final kpis = _dashboardData?['kpis'] ?? {};
    final projets = _dashboardData?['projets'] as List? ?? [];
    final formations = _dashboardData?['formations'] ?? {};
    final scoring = _dashboardData?['scoring'];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header vert avec score
            _buildHeader(kpis, scoring),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mon projet principal
                  _buildProjectSection(projets),

                  const SizedBox(height: 24),

                  // Mes activités
                  _buildActivitiesSection(),

                  const SizedBox(height: 24),

                  // Progression formations
                  _buildFormationsSection(formations),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map kpis, dynamic scoring) {
  final score = kpis['score_entrepreneurial'] ?? 0;
  final niveau = kpis['niveau'] ?? 'Non évalué';
  final unread = kpis['notifications_non_lues'] ?? 0;

  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A7A4A), Color(0xFF2E9E64)],
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
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu hamburger + nom
                Row(
                  children: [
                  /* GestureDetector(
                      onTap: () {},
                      child: const Icon(
                        Icons.menu_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),*/
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
                        _userName.isEmpty ? 'Entrepreneur' : _userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      ],
                    ),
                  ],
                ),

                // Notifications + Photo profil
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ).then((_) => _loadDashboard());
                          },
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.white,
                            size: 26,
                          ),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Photo profil
              // Photo profil cliquable
                  GestureDetector(
                    onTap: () => _showProfileMenu(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white38,
                          width: 2,
                        ),
                        image: _profilePhoto != null
                      ? DecorationImage(
                          image: NetworkImage(_profilePhoto!),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=100',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Score card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Score de votre projet',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$score',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                                height: 1,
                              ),
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            niveau,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      GestureDetector(
                      onTap: () {
                        if (_dashboardData?['projets'] != null &&
                            (_dashboardData!['projets'] as List).isNotEmpty) {
                          final projectId = _dashboardData!['projets'][0]['id'];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(
                                projectId: projectId,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Voir le détail',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                      ],
                    ),
                  ),

                  // Cercle score
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                        const Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.white,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

 Widget _buildProjectSection(List projets) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mon projet principal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentIndex = 1),
            child: const Text('Voir tout'),
          ),
        ],
      ),

      const SizedBox(height: 12),

      if (projets.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          child: const Center(
            child: Text(
              'Aucun projet pour le moment',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        )
      else
        GestureDetector(
          onTap: () => setState(() => _currentIndex = 1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                // Image projet placeholder
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1619451334792-150fd785ee74?w=200',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projets[0]['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        projets[0]['description'] ?? 'Aucune description',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusLabel(projets[0]['status'] ?? ''),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
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
        ),
    ],
  );
}

  Widget _buildActivitiesSection() {
    final activities = [
      {
        'icon': Icons.school_rounded,
        'label': 'Formations',
        'color': AppColors.primary,
        'index': 2,
      },
      {
        'icon': Icons.account_balance_rounded,
        'label': 'Demande de\nfinancement',
        'color': AppColors.secondary,
        'index': 3,
      },
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Suivi &\nReporting',
        'color': AppColors.mentor,
        'index': 0,
        'screen': 'reporting',
      },
      {
        'icon': Icons.people_rounded,
        'label': 'Mentorat',
        'color': AppColors.financeur,
        'index': 0,
        'screen': 'mentoring',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes activités',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: activities.map((activity) {
            return GestureDetector(
              onTap: () {
                if (activity['screen'] == 'reporting') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportingScreen(),
                  ),
                );
              } else if (activity['screen'] == 'mentoring') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MentoringScreen(),
                  ),
                );
              } else {
                setState(() => _currentIndex = activity['index'] as int);
              }
              },
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: activity['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFormationsSection(Map formations) {
  final total = formations['total'] ?? 0;
  final enCours = formations['en_cours'] ?? 0;
  final progression = formations['progression_moyenne'] ?? 0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Progression des formations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentIndex = 2),
            child: const Text('Voir tout'),
          ),
        ],
      ),

      const SizedBox(height: 12),

      if (total == 0)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          child: const Center(
            child: Text(
              'Aucune formation en cours',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        )
      else
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              // Image formation placeholder
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=200',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comment construire un business model solide',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progression / 100,
                        backgroundColor: AppColors.grey200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$progression%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
  String _getStatusLabel(String status) {
    switch (status) {
      case 'brouillon': return 'Brouillon';
      case 'soumis': return 'Soumis';
      case 'en_analyse': return 'En analyse';
      case 'accepte': return 'Accepté';
      case 'rejete': return 'Rejeté';
      case 'finance': return 'Financé';
      case 'en_suivi': return 'En suivi';
      default: return status;
    }
  }

  void _showProfileMenu() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.primary),
            ),
            title: const Text('Mon profil'),
            subtitle: const Text('Voir et modifier mes informations'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.error),
            ),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text(
                      'Voulez-vous vraiment vous déconnecter ?'),
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
              if (confirm == true) {
                await ApiService.deleteToken();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
}
