import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import '../../projects/screens/business_plan_screen.dart';

class AdminProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const AdminProjectDetailScreen({super.key, required this.projectId});

  @override
  State<AdminProjectDetailScreen> createState() =>
      _AdminProjectDetailScreenState();
}

class _AdminProjectDetailScreenState
  extends State<AdminProjectDetailScreen>
  with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _project;
  Map<String, dynamic>? _diagnostic;
  List<dynamic> _financeurs = [];
  List<dynamic> _mentors = [];
  bool _isLoading = true;
  String? _selectedFinanceurId;
  String? _selectedMentorId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final projectResponse = await ApiService.get(
      AppUrls.projectById(widget.projectId),
    );
    final diagnosticResponse = await ApiService.get(
      AppUrls.getDiagnostic(widget.projectId),
    );
    final usersResponse = await ApiService.get(AppUrls.projects);

    // Récupère financeurs et mentors
    final financeurResponse = await ApiService.get(
      '${AppUrls.baseUrl}/auth/users?role=financeur',
    );
    final mentorResponse = await ApiService.get(
      '${AppUrls.baseUrl}/auth/users?role=mentor',
    );

    if (mounted) {
      setState(() {
        _project = projectResponse['success']
            ? projectResponse['data']
            : null;
        _diagnostic = diagnosticResponse['success']
            ? diagnosticResponse['data']
            : null;
        _financeurs = financeurResponse['success']
            ? (financeurResponse['data']['users'] as List? ?? [])
            : [];
        _mentors = mentorResponse['success']
            ? (mentorResponse['data']['users'] as List? ?? [])
            : [];
        _isLoading = false;
      });
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.admin),
        ),
      );
    }

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Projet')),
        body: const Center(child: Text('Projet introuvable')),
      );
    }

    final status = _project!['status'] ?? '';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail projet'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.admin,
          unselectedLabelColor: AppColors.grey400,
          indicatorColor: AppColors.admin,
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Scoring'),
            Tab(text: 'Actions'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header projet
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _project!['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                  _project!['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      _project!['entrepreneur_name'] ?? '',
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
                      _project!['location'] ?? '',
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

          // Onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResumeTab(),
                _buildScoringTab(),
                _buildActionsTab(),
              ],
            ),
          ),
        ],
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
          _buildInfoSection('Stratégie commerciale',
              _project!['target_customers'] ?? 'Non renseigné'),
          const SizedBox(height: 16),
          _buildInfoSection('Organisation',
              _project!['team_description'] ?? 'Non renseigné'),
              

          const SizedBox(height: 16),

          // Business Plan
          if (_project!['has_business_plan'] == true)
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessPlanScreen(
                    projectId: widget.projectId,
                    showSubmitButton: false,
                  ),
                ),
              ),
              icon: const Icon(Icons.description_rounded),
              label: const Text('Voir le Business Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.admin,
                minimumSize: const Size(double.infinity, 50),
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
      return const Center(
        child: Text(
          'Aucun diagnostic effectué',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final score = _diagnostic!['global_score'] ?? 0;
    final level = _diagnostic!['level'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 10,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.getScoreColor(score),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getScoreColor(score),
                            ),
                          ),
                          const Text('/100',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
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
                      Text(
                        level,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getScoreColor(score),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Risque : ${_diagnostic!['risk_level'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                _buildCriteriaRow('💡', 'Innovation',
                    _diagnostic!['innovation_score'] ?? 0,
                    AppColors.warning),
                _buildCriteriaRow('⚙️', 'Faisabilité',
                    _diagnostic!['feasibility_score'] ?? 0,
                    AppColors.info),
                _buildCriteriaRow('🌍', 'Impact social',
                    _diagnostic!['impact_score'] ?? 0,
                    AppColors.success),
                _buildCriteriaRow('💰', 'Rentabilité',
                    _diagnostic!['profitability_score'] ?? 0,
                    AppColors.secondary),
              ],
            ),
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
                    Text(label,
                        style: const TextStyle(fontSize: 13)),
                    Text('$score/100',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: AppColors.grey200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(color),
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

  // ==============================
  // ONGLET ACTIONS ADMIN
  // ==============================
  Widget _buildActionsTab() {
    final status = _project!['status'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Changer le statut
          const Text(
            'Changer le statut',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (status == 'brouillon') 
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: AppColors.grey400),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ce projet est encore en brouillon. L\'entrepreneur doit le soumettre avant que vous puissiez agir.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (status == 'soumis' || status == 'en_analyse') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _changeStatus('en_analyse'),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Mettre en analyse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _changeStatus('accepte'),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _changeStatus('rejete'),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Rejeter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (status == 'accepte') ...[
            ElevatedButton.icon(
              onPressed: () => _changeStatus('finance'),
              icon: const Icon(Icons.monetization_on_rounded),
              label: const Text('Marquer comme financé'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ],

          if (status == 'rejete') ...[
            ElevatedButton.icon(
              onPressed: () => _changeStatus('en_analyse'),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Remettre en analyse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _changeStatus('accepte'),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Accepter finalement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Matching financeurs
          const Text(
            'Matching Financeurs',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () => _showMatchingResults(),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Voir financeurs compatibles'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.admin,
              minimumSize: const Size(double.infinity, 46),
            ),
          ),

          const SizedBox(height: 24),

          // Assigner mentor
          const Text(
            'Mentor',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (_project!['mentor_id'] != null)
            // Mentor déjà assigné
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mentorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mentor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.mentor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mentor : ${_project!['mentor_name'] ?? 'Assigné'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mentor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _project!['mentor_id'] = null;
                      _selectedMentorId = null;
                    }),
                    child: const Text('Changer',
                        style: TextStyle(color: AppColors.mentor)),
                  ),
                ],
              ),
            )
          else
            // Pas de mentor assigné
            if (_mentors.isEmpty)
              const Text('Aucun mentor disponible',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedMentorId,
                    decoration: const InputDecoration(
                      labelText: 'Sélectionner un mentor',
                      prefixIcon: Icon(Icons.people_rounded),
                    ),
                    items: _mentors.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['id'].toString(),
                        child: Text('${m['first_name']} ${m['last_name']}'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedMentorId = v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedMentorId == null ? null : _assignMentor,
                    icon: const Icon(Icons.people_rounded),
                    label: const Text('Assigner le mentor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mentor,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                  ),
                ],
              ),

          const SizedBox(height: 24),

          // Assigner financeur
          const Text(
            'Financeur',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (_project!['financer_id'] != null)
            // Financeur déjà assigné
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.financeur.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.financeur),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Financeur : ${_project!['financer_name'] ?? 'Assigné'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.financeur,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _project!['financer_id'] = null;
                      _selectedFinanceurId = null;
                    }),
                    child: const Text('Changer',
                        style: TextStyle(color: AppColors.financeur)),
                  ),
                ],
              ),
            )
          else
            if (_financeurs.isEmpty)
              const Text('Aucun financeur disponible',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedFinanceurId,
                    decoration: const InputDecoration(
                      labelText: 'Sélectionner un financeur',
                      prefixIcon: Icon(Icons.account_balance_rounded),
                    ),
                    items: _financeurs.map((f) {
                      return DropdownMenuItem<String>(
                        value: f['id'].toString(),
                        child: Text('${f['first_name']} ${f['last_name']}'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedFinanceurId = v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedFinanceurId == null ? null : _assignFinanceur,
                    icon: const Icon(Icons.account_balance_rounded),
                    label: const Text('Assigner le financeur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.financeur,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                  ),
                ],
              ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _changeStatus(String status) async {
    final messages = {
      'en_analyse': 'Mettre le projet en analyse ?',
      'accepte': 'Accepter ce projet ?',
      'rejete': 'Rejeter ce projet ?',
      'finance': 'Marquer ce projet comme financé ?',
    };

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(messages[status] ?? 'Changer le statut ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await ApiService.patch(
      AppUrls.projectStatus(widget.projectId),
      {
        'status': status,
        'comment': 'Statut mis à jour par l\'administrateur',
      },
    );

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statut mis à jour ✅'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    }
  }

  Future<void> _showMatchingResults() async {
    final response = await ApiService.get(
      AppUrls.matchingFinancers(widget.projectId),
    );

    if (!mounted) return;

    if (response['success']) {
      final recommendations =
          response['data']['recommendations'] as List? ?? [];

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.8,
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
                const Text(
                  'Financeurs compatibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...recommendations.map((rec) {
                  final isEligible = rec['is_eligible'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isEligible
                          ? AppColors.white
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEligible
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.grey200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                rec['label'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isEligible
                                    ? AppColors.successLight
                                    : AppColors.grey200,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                isEligible
                                    ? 'Éligible'
                                    : 'Non éligible',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isEligible
                                      ? AppColors.success
                                      : AppColors.grey400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rec['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '💰 ${rec['recommended_amount']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Exemples d'entreprises
                        if ((rec['examples'] as List? ?? []).isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (rec['examples'] as List)
                                .map((e) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.grey100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        e.toString(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),

                        const SizedBox(height: 4),
                        Text(
                          '📋 ${rec['conditions']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
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
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _assignMentor() async {
  final response = await ApiService.patch(
    AppUrls.assignMentor(widget.projectId),
    {'mentor_id': _selectedMentorId},
  );

  if (!mounted) return;

  if (response['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mentor assigné avec succès ✅'),
        backgroundColor: AppColors.success,
      ),
    );
    _loadData();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

Future<void> _assignFinanceur() async {
  // Récupère d'abord l'ID de la demande de financement
  final requestResponse = await ApiService.get(
    '${AppUrls.baseUrl}/financing?project_id=${widget.projectId}',
  );

  if (!mounted) return;

  // Cherche la demande en attente pour ce projet
  final requests = requestResponse['data']?['requests'] as List? ?? [];
  final pendingRequest = requests.firstWhere(
    (r) => r['project_id'] == widget.projectId,
    orElse: () => null,
  );

  if (pendingRequest == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aucune demande de financement pour ce projet'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  final response = await ApiService.patch(
    AppUrls.assignFinancer(pendingRequest['id']),
    {'financer_id': _selectedFinanceurId},
  );

  if (!mounted) return;

  if (response['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Financeur assigné avec succès ✅'),
        backgroundColor: AppColors.success,
      ),
    );
    _loadData();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor: AppColors.error,
      ),
    );
  }
}



}