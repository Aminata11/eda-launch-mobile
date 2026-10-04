 import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import 'admin_project_detail_screen.dart';

class AdminProjectsScreen extends StatefulWidget {
  const AdminProjectsScreen({super.key});

  @override
  State<AdminProjectsScreen> createState() => _AdminProjectsScreenState();
}

class _AdminProjectsScreenState extends State<AdminProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allProjects = [];
  bool _isLoading = true;
  String _selectedStatus = 'tous';

  final List<Map<String, dynamic>> _statusFilters = [
  {'key': 'tous', 'label': 'Tous'},
  {'key': 'soumis', 'label': 'Soumis'},
  {'key': 'en_analyse', 'label': 'Analyse'},
  {'key': 'accepte', 'label': 'Accepté'},
  {'key': 'finance', 'label': 'Financé'},
  {'key': 'en_suivi', 'label': 'Suivi'},
  {'key': 'rejete', 'label': 'Rejeté'},
];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final response = await ApiService.get(AppUrls.projects);
    if (mounted) {
      setState(() {
        _allProjects = response['success']
            ? (response['data']['projects'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredProjects {
    if (_selectedStatus == 'tous') return _allProjects;
    return _allProjects
        .where((p) => p['status'] == _selectedStatus)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'brouillon': return AppColors.grey500;
      case 'soumis': return AppColors.info;
      case 'en_analyse': return AppColors.warning;
      case 'accepte': return AppColors.success;
      case 'rejete': return AppColors.error;
      case 'finance': return AppColors.primary;
      case 'en_suivi': return AppColors.mentor;
      default: return AppColors.grey500;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des projets'),
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _loadProjects,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.admin))
          : Column(
              children: [
                // Filtres statuts
                Container(
                  color: AppColors.white,
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    itemCount: _statusFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _statusFilters[index];
                      final isSelected =
                          _selectedStatus == filter['key'];
                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedStatus = filter['key']),
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.admin
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

                // Liste projets
                Expanded(
                  child: _filteredProjects.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun projet',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProjects,
                          color: AppColors.admin,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredProjects.length,
                            itemBuilder: (context, index) {
                              return _buildProjectCard(
                                  _filteredProjects[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final status = project['status'] ?? 'brouillon';
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminProjectDetailScreen(
            projectId: project['id'],
          ),
        ),
      ).then((_) => _loadProjects()),
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
                      fontSize: 16,
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

            Text(
              project['description'] ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                if (project['sector'] != null) ...[
                  const Icon(Icons.category_rounded,
                      size: 14, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(
                    project['sector'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (project['location'] != null) ...[
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(
                    project['location'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                if (project['has_business_plan'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.description_rounded,
                            size: 12, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'BP disponible',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Boutons action rapide pour projets soumis
            if (status == 'soumis' || status == 'en_analyse') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _changeStatus(
                          project['id'], 'accepte', project['name']),
                      icon: const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.success),
                      label: const Text('Accepter',
                          style: TextStyle(color: AppColors.success)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.success),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _changeStatus(
                          project['id'], 'rejete', project['name']),
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.error),
                      label: const Text('Rejeter',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(
      String projectId, String status, String projectName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(status == 'accepte'
            ? 'Accepter le projet'
            : 'Rejeter le projet'),
        content: Text(
          status == 'accepte'
              ? 'Voulez-vous accepter le projet "$projectName" ?'
              : 'Voulez-vous rejeter le projet "$projectName" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'accepte'
                  ? AppColors.success
                  : AppColors.error,
            ),
            child: Text(
                status == 'accepte' ? 'Accepter' : 'Rejeter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await ApiService.patch(
      AppUrls.projectStatus(projectId),
      {
        'status': status,
        'comment': status == 'accepte'
            ? 'Projet accepté par l\'administrateur'
            : 'Projet rejeté par l\'administrateur',
      },
    );

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'accepte'
              ? 'Projet accepté ✅'
              : 'Projet rejeté ❌'),
          backgroundColor: status == 'accepte'
              ? AppColors.success
              : AppColors.error,
        ),
      );
      _loadProjects();
    }
  }
}