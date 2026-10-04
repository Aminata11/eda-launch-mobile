import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import '../../scoring/screens/scoring_screen.dart';
import 'business_plan_screen.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _project;
  Map<String, dynamic>? _diagnostic;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProject();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    final projectResponse = await ApiService.get(
      AppUrls.projectById(widget.projectId),
    );

    final diagnosticResponse = await ApiService.get(
      AppUrls.getDiagnostic(widget.projectId),
    );

    if (mounted) {
      setState(() {
        _project = projectResponse['success'] ? projectResponse['data'] : null;
        _diagnostic = diagnosticResponse['success']
            ? diagnosticResponse['data']
            : null;
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Projet')),
        body: const Center(child: Text('Projet introuvable')),
      );
    }

    final status = _project!['status'] ?? 'brouillon';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.mentor,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppColors.white),
              ),
              actions: [
                IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Soumettre
                          if (_project!['status'] == 'brouillon')
                            ListTile(
                              leading: const Icon(Icons.send_rounded,
                                  color: AppColors.primary),
                              title: const Text('Soumettre le projet'),
                              onTap: () async {
                                Navigator.pop(context);
                                await _submitProject();
                              },
                            ),
                          // Modifier
                          ListTile(
                            leading: const Icon(Icons.edit_rounded,
                                color: AppColors.warning),
                            title: const Text('Modifier le projet'),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        
                        // Business Plan
                      if (_project!['has_business_plan'] == true)
                        ListTile(
                          leading: const Icon(Icons.description_rounded,
                              color: AppColors.primary),
                          title: const Text('Voir le Business Plan'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessPlanScreen(
                                  projectId: widget.projectId,
                                ),
                              ),
                            );
                          },
                        ),

                          // Supprimer
                          ListTile(
                            leading: const Icon(Icons.delete_rounded,
                                color: AppColors.error),
                            title: const Text('Supprimer le projet',
                                style: TextStyle(color: AppColors.error)),
                            onTap: () async {
                              Navigator.pop(context);
                              await _deleteProject();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.white),
              ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Détail du projet',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A7A4A), Color(0xFF2E9E64)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Info projet
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Image projet
                      GestureDetector(
  onTap: () => _uploadProjectPhoto(),
  child: Stack(
    children: [
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          image: _project?['thumbnail_url'] != null
              ? DecorationImage(
                  image: NetworkImage(_project!['thumbnail_url']),
                  fit: BoxFit.cover,
                )
              : const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1619451334792-150fd785ee74?w=200',
                  ),
                  fit: BoxFit.cover,
                ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: AppColors.white,
            size: 12,
          ),
        ),
      ),
    ],
  ),
),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _project!['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _project!['description'] ?? '',
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Localisation + Date
                  Row(
                    children: [
                      if (_project!['location'] != null) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.grey400),
                        const SizedBox(width: 4),
                        Text(
                          _project!['location'],
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 16),
                      ],
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        'Créé le ${_project!['created_at']?.toString().substring(0, 10) ?? ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Onglets
            Container(
              color: AppColors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.mentor,
                unselectedLabelColor: AppColors.grey400,
                indicatorColor: AppColors.mentor,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Résumé'),
                  Tab(text: 'Scoring'),
                  Tab(text: 'Documents'),
                  Tab(text: 'Activités'),
                ],
              ),
            ),

            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResumeTab(),
                  _buildScoringTab(),
                  _buildDocumentsTab(),
                  _buildActivitiesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================
  // ONGLET RÉSUMÉ
  // ==============================
  Widget _buildResumeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Problème identifié',
              _project!['problem'] ?? 'Non renseigné'),
          const SizedBox(height: 16),
          _buildInfoSection('Solution proposée',
              _project!['solution'] ?? 'Non renseigné'),
          const SizedBox(height: 16),
          _buildInfoSection('Objectifs',
              _project!['objectives'] ?? 'Non renseigné'),
          const SizedBox(height: 16),
          _buildInfoSection('Marché cible',
              _project!['target_market'] ?? 'Non renseigné'),
          const SizedBox(height: 16),

          // Budget
          Row(
            children: [
              Expanded(
                child: _buildBudgetCard(
                  'Budget total',
                  '${_project!['budget'] ?? 0} FCFA',
                  Icons.account_balance_wallet_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBudgetCard(
                  'Financement recherché',
                  '${_project!['funding_needed'] ?? 0} FCFA',
                  Icons.monetization_on_rounded,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
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

  // ==============================
  // ONGLET SCORING
  // ==============================
  Widget _buildScoringTab() {
    if (_diagnostic == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined,
                size: 60, color: AppColors.grey300),
            const SizedBox(height: 16),
            const Text(
              'Aucun diagnostic effectué',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lancez le diagnostic pour obtenir votre score',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScoringScreen(
                    projectId: widget.projectId,
                  ),
                ),
              ).then((_) => _loadProject());
            },
            child: const Text('Lancer le diagnostic'),
          ),
          ],
        ),
      );
    }

    final globalScore = _diagnostic!['global_score'] ?? 0;
    final level = _diagnostic!['level'] ?? '';
    final innovation = _diagnostic!['innovation_score'] ?? 0;
    final feasibility = _diagnostic!['feasibility_score'] ?? 0;
    final impact = _diagnostic!['impact_score'] ?? 0;
    final profitability = _diagnostic!['profitability_score'] ?? 0;
    final strengths = _diagnostic!['strengths'] as List? ?? [];
    final weaknesses = _diagnostic!['weaknesses'] as List? ?? [];
    final recommendations = _diagnostic!['recommendations'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score global
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                // Cercle score
                // Cercle score
SizedBox(
  width: 90,
  height: 90,
  child: Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 90,
        height: 90,
        child: CircularProgressIndicator(
          value: globalScore / 100,
          strokeWidth: 8,
          backgroundColor: AppColors.grey200,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.getScoreColor(globalScore),
          ),
        ),
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$globalScore',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.getScoreColor(globalScore),
            ),
          ),
          const Text(
            '/100',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ],
  ),
),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Résultat du scoring',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Niveau :',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        level,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getScoreColor(globalScore),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Continuez à renforcer les points faibles.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Détail par critère
          const Text(
            'Détail par critère',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              children: [
                _buildCriteriaRow(
                    '💡', 'Innovation', innovation, AppColors.warning),
                _buildCriteriaRow(
                    '⚙️', 'Faisabilité', feasibility, AppColors.info),
                _buildCriteriaRow(
                    '🌍', 'Impact social', impact, AppColors.success),
                _buildCriteriaRow(
                    '💰', 'Rentabilité', profitability, AppColors.secondary),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Bouton recommandations
          ElevatedButton(
            onPressed: () {
              _showRecommendations(strengths, weaknesses, recommendations);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mentor,
            ),
            child: const Text('Voir les recommandations'),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(
      String emoji, String label, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$score/100',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: AppColors.grey200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecommendations(
      List strengths, List weaknesses, List recommendations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
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
              const Text(
                'Recommandations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              if (strengths.isNotEmpty) ...[
                const Text('✅ Forces',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
                const SizedBox(height: 8),
                ...strengths.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(s.toString(),
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              if (weaknesses.isNotEmpty) ...[
                const Text('⚠️ Faiblesses',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning)),
                const SizedBox(height: 8),
                ...weaknesses.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: AppColors.warning, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(w.toString(),
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              if (recommendations.isNotEmpty) ...[
                const Text('📌 Recommandations',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                const SizedBox(height: 8),
                ...recommendations.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(r.toString(),
                                  style: const TextStyle(fontSize: 13))),
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

  // ==============================
  // ONGLET DOCUMENTS
  // ==============================
  Widget _buildDocumentsTab() {
    final documents = _project!['documents'] as List? ?? [];

    return documents.isEmpty
        ? const Center(
            child: Text(
              'Aucun document uploadé',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.insert_drive_file_rounded,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.download_rounded,
                        color: AppColors.grey400),
                  ],
                ),
              );
            },
          );
  }

  // ==============================
  // ONGLET ACTIVITÉS
  // ==============================
  Widget _buildActivitiesTab() {
    final history = _project!['status_history'] as List? ?? [];

    return history.isEmpty
        ? const Center(
            child: Text(
              'Aucune activité',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['comment'] ?? 'Changement de statut',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['old_status'] ?? ''} → ${item['new_status'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Par ${item['changed_by_name'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  // Soumettre le projet
Future<void> _submitProject() async {
  final response = await ApiService.patch(
    AppUrls.projectStatus(widget.projectId),
    {
      'status': 'soumis',
      'comment': 'Projet soumis pour évaluation',
    },
  );

  if (!mounted) return;

  if (response['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Projet soumis avec succès !'),
        backgroundColor: AppColors.success,
      ),
    );
    _loadProject();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

// Supprimer le projet
Future<void> _deleteProject() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Supprimer le projet'),
      content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce projet ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Supprimer',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  final response = await ApiService.delete(
    AppUrls.projectById(widget.projectId),
  );

  if (!mounted) return;

  if (response['success']) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Projet supprimé !'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

Future<void> _uploadProjectPhoto() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 80,
  );

  if (image == null) return;

  try {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppUrls.uploadProjectPhoto(widget.projectId)),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('photo', image.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);
    print('📸 Project photo response: $data');

    if (!mounted) return;

    if (data['success'] == true) {
      await _loadProject();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo du projet mise à jour ✅'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

}

