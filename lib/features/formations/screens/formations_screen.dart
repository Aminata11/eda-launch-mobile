import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import 'formation_detail_screen.dart';

class FormationsScreen extends StatefulWidget {
  const FormationsScreen({super.key});

  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  List<dynamic> _formations = [];
  List<dynamic> _myFormations = [];
  bool _isLoading = true;
  String _selectedCategory = 'tous';

  final List<Map<String, dynamic>> _categories = [
    {'key': 'tous', 'label': 'Tous'},
    {'key': 'entrepreneuriat', 'label': 'Entrepreneuriat'},
    {'key': 'leadership', 'label': 'Leadership'},
    {'key': 'gestion_financiere', 'label': 'Finance'},
    {'key': 'marketing', 'label': 'Marketing'},
    {'key': 'digital', 'label': 'Digital'},
    {'key': 'agroalimentaire', 'label': 'Agro'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    final formationsResponse = await ApiService.get(AppUrls.formations);
    final myFormationsResponse = await ApiService.get(AppUrls.myFormations);

    if (mounted) {
      setState(() {
        _formations = formationsResponse['success']
            ? (formationsResponse['data']['formations'] as List? ?? [])
            : [];
        _myFormations = myFormationsResponse['success']
            ? (myFormationsResponse['data']['formations'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredFormations {
    if (_selectedCategory == 'tous') return _formations;
    return _formations
        .where((f) => f['category'] == _selectedCategory)
        .toList();
  }

  bool _isEnrolled(String formationId) {
    return _myFormations.any((f) => f['id'] == formationId);
  }

  int _getProgress(String formationId) {
    final formation = _myFormations.firstWhere(
      (f) => f['id'] == formationId,
      orElse: () => null,
    );
    return formation?['progress_percent'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Formations'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadFormations,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Mes formations en cours
                if (_myFormations.isNotEmpty) _buildMyFormationsSection(),

                // Filtres catégories
                _buildCategoryFilter(),

                // Liste formations
                Expanded(
                  child: _filteredFormations.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune formation disponible',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFormations,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredFormations.length,
                            itemBuilder: (context, index) {
                              return _buildFormationCard(
                                  _filteredFormations[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMyFormationsSection() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes formations en cours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _myFormations.length,
              itemBuilder: (context, index) {
                final formation = _myFormations[index];
                final progress = formation['progress_percent'] ?? 0;
                final isCompleted = formation['is_completed'] ?? false;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormationDetailScreen(
                        formationId: formation['id'],
                      ),
                    ),
                  ).then((_) => _loadFormations()),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            if (isCompleted)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 16),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formation['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: AppColors.grey200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$progress%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: AppColors.white,
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['key'];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['key']),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat['label'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormationCard(Map<String, dynamic> formation) {
    final enrolled = _isEnrolled(formation['id']);
    final progress = _getProgress(formation['id']);
    final isCompleted = enrolled &&
        _myFormations.firstWhere(
              (f) => f['id'] == formation['id'],
              orElse: () => {'is_completed': false},
            )['is_completed'] ==
            true;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FormationDetailScreen(
            formationId: formation['id'],
          ),
        ),
      ).then((_) => _loadFormations()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Badge catégorie
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getCategoryLabel(formation['category'] ?? ''),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  // Badge complété
                  if (isCompleted)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_rounded,
                                color: AppColors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Complété',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formation['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formation['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Infos
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        '${formation['duration_minutes'] ?? 0} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.bar_chart_rounded,
                          size: 14, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        _getLevelLabel(formation['level'] ?? ''),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${formation['modules_count'] ?? 0} modules',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Progression si inscrit
                  if (enrolled) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$progress% complété',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Bouton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormationDetailScreen(
                            formationId: formation['id'],
                          ),
                        ),
                      ).then((_) => _loadFormations()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: enrolled
                            ? (isCompleted
                                ? AppColors.success
                                : AppColors.primary)
                            : AppColors.primary,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: Text(
                        enrolled
                            ? (isCompleted ? 'Revoir' : 'Continuer')
                            : 'Commencer',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'entrepreneuriat': return 'Entrepreneuriat';
      case 'leadership': return 'Leadership';
      case 'gestion_financiere': return 'Finance';
      case 'marketing': return 'Marketing';
      case 'digital': return 'Digital';
      case 'agroalimentaire': return 'Agro';
      default: return category;
    }
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'débutant': return 'Débutant';
      case 'intermédiaire': return 'Intermédiaire';
      case 'avancé': return 'Avancé';
      default: return level;
    }
  }
}