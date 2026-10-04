import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';

class BusinessPlanScreen extends StatefulWidget {
  final String projectId;
  final bool showSubmitButton;
  const BusinessPlanScreen({
    super.key, 
    required this.projectId,
    this.showSubmitButton = true,
    });

  @override
  State<BusinessPlanScreen> createState() => _BusinessPlanScreenState();
}

class _BusinessPlanScreenState extends State<BusinessPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _businessPlan;
  List<dynamic> _amortissements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBusinessPlan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessPlan() async {
    final response = await ApiService.get(
      AppUrls.getBusinessPlan(widget.projectId),
    );

    if (mounted) {
      setState(() {
        if (response['success']) {
          _businessPlan = response['data'];
          _amortissements = response['data']['amortissements'] as List? ?? [];
        }
        _isLoading = false;
      });
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

    if (_businessPlan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Plan')),
        body: const Center(
          child: Text('Aucun Business Plan disponible'),
        ),
      );
    }

    final content = _businessPlan!['content'] as Map<String, dynamic>? ?? {};
    final planFinancier = content['plan_financier'] as Map<String, dynamic>? ?? {};
    final bfi = planFinancier['bfi'] as Map<String, dynamic>? ?? {};
    final bfr = planFinancier['bfr'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Business Plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _downloadPdf,
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Télécharger PDF',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Marché'),
            Tab(text: 'Finance'),
            Tab(text: 'Amortissements'),
            Tab(text: 'Organisation'),
          ],
        ),
      ),
      body: Column(
        children: [
          // KPIs financiers
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildKpi(
                    'BFI',
                    '${_formatMontant(_businessPlan!['bfi_amount'])} FCFA',
                    AppColors.primary,
                    Icons.build_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpi(
                    'BFR',
                    '${_formatMontant(_businessPlan!['bfr_amount'])} FCFA',
                    AppColors.warning,
                    Icons.rotate_right_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpi(
                    'Total',
                    '${_formatMontant(_businessPlan!['total_financement'])} FCFA',
                    AppColors.success,
                    Icons.monetization_on_rounded,
                  ),
                ),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ONGLET 1 — Résumé
                _buildResumeTab(content),

                // ONGLET 2 — Analyse marché
                _buildMarcheTab(content),

                // ONGLET 3 — Plan financier
                _buildFinanceTab(bfi, bfr, planFinancier),

                // ONGLET 4 — Amortissements
                _buildAmortissementsTab(),

                // ONGLET 5 — Organisation
                _buildOrganisationTab(content),
              ],
            ),
          ),
        ],
      ),

      // Bouton soumettre
      // Bouton soumettre
bottomNavigationBar: widget.showSubmitButton
    ? Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: AppColors.cardShadow,
        ),
        child: ElevatedButton.icon(
          onPressed: () => _showSubmitConfirmation(),
          icon: const Icon(Icons.send_rounded),
          label: const Text('Soumettre le projet'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: AppColors.success,
          ),
        ),
      )
    : null,
    );
  }

  // ==============================
  // ONGLET RÉSUMÉ
  // ==============================
  Widget _buildResumeTab(Map<String, dynamic> content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Résumé Exécutif',
            Icons.description_rounded,
            AppColors.primary,
            content['resume_executif'] ?? '',
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Conclusion',
            Icons.flag_rounded,
            AppColors.success,
            content['conclusion'] ?? '',
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Recommandation Financement',
            Icons.lightbulb_rounded,
            AppColors.warning,
            (content['plan_financier'] as Map?)?['recommandation_financement'] ?? '',
          ),
        ],
      ),
    );
  }

  // ==============================
  // ONGLET MARCHÉ
  // ==============================
  Widget _buildMarcheTab(Map<String, dynamic> content) {
    final marche = content['analyse_marche'] as Map<String, dynamic>? ?? {};
    final strategie = content['strategie_commerciale'] as Map<String, dynamic>? ?? {};
    final opportunites = marche['opportunites'] as List? ?? [];
    final canaux = strategie['canaux_communication'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Description du Marché',
            Icons.store_rounded,
            AppColors.primary,
            marche['description'] ?? '',
          ),
          const SizedBox(height: 16),

          // Opportunités
          _buildListSection(
            'Opportunités',
            Icons.trending_up_rounded,
            AppColors.success,
            opportunites.map((o) => o.toString()).toList(),
          ),
          const SizedBox(height: 16),

          _buildSection(
            'Concurrents',
            Icons.groups_rounded,
            AppColors.error,
            marche['concurrents'] ?? '',
          ),
          const SizedBox(height: 16),

          _buildSection(
            'Acquisition Clients',
            Icons.person_add_rounded,
            AppColors.info,
            strategie['acquisition_clients'] ?? '',
          ),
          const SizedBox(height: 16),

          _buildSection(
            'Politique de Prix',
            Icons.price_change_rounded,
            AppColors.warning,
            strategie['politique_prix'] ?? '',
          ),
          const SizedBox(height: 16),

          _buildListSection(
            'Canaux de Communication',
            Icons.campaign_rounded,
            AppColors.primary,
            canaux.map((c) => c.toString()).toList(),
          ),
        ],
      ),
    );
  }

  // ==============================
  // ONGLET FINANCE
  // ==============================
  Widget _buildFinanceTab(
      Map bfi, Map bfr, Map planFinancier) {
    final equipements = bfi['equipements'] as List? ?? [];
    final details = bfr['details'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BFI
          const Text(
            'BFI — Besoin en Fonds d\'Investissement',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          ...equipements.map((eq) {
            final e = eq as Map<String, dynamic>;
            return Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['designation'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${e['quantite']} x ${_formatMontant(e['prix_unitaire'])} FCFA',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_formatMontant(e['total'])} FCFA',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total BFI',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                Text(
                  '${_formatMontant(bfi['total'])} FCFA',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // BFR
          const Text(
            'BFR — Besoin en Fonds de Roulement',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 12),

          ...details.map((d) {
            final detail = d as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      detail['designation'] ?? '',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    '${_formatMontant(detail['montant'])} FCFA',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            );
          }),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total BFR',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning)),
                Text(
                  '${_formatMontant(bfr['total'])} FCFA',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                      fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Total financement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL FINANCEMENT NÉCESSAIRE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${_formatMontant(planFinancier['total_financement_necessaire'])} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    fontSize: 16,
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
  // ONGLET AMORTISSEMENTS
  // ==============================
  Widget _buildAmortissementsTab() {
    if (_amortissements.isEmpty) {
      return const Center(
        child: Text('Aucun amortissement calculé'),
      );
    }

    double totalAnnuel = 0;
    for (final a in _amortissements) {
      totalAnnuel += double.tryParse(a['amortissement_annuel'].toString()) ?? 0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total amortissements/an',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${_formatMontant(totalAnnuel)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ..._amortissements.map((a) {
            final amort = a as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
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
                          amort['equipement'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          amort['categorie'] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmortRow(
                          'Montant',
                          '${_formatMontant(amort['montant'])} FCFA',
                        ),
                      ),
                      Expanded(
                        child: _buildAmortRow(
                          'Durée',
                          '${amort['duree_ans']} ans',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmortRow(
                          'Amort. annuel',
                          '${_formatMontant(amort['amortissement_annuel'])} FCFA',
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: _buildAmortRow(
                          'Amort. mensuel',
                          '${_formatMontant(amort['amortissement_mensuel'])} FCFA',
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAmortRow(String label, String value,
      {Color color = AppColors.textPrimary}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==============================
  // ONGLET ORGANISATION
  // ==============================
  Widget _buildOrganisationTab(Map<String, dynamic> content) {
    final org = content['organisation'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSection(
            'Équipe',
            Icons.people_rounded,
            AppColors.primary,
            org['equipe'] ?? '',
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Ressources Humaines',
            Icons.person_rounded,
            AppColors.mentor,
            org['ressources_humaines'] ?? '',
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Ressources Techniques',
            Icons.build_rounded,
            AppColors.warning,
            org['ressources_techniques'] ?? '',
          ),
        ],
      ),
    );
  }

  // ==============================
  // WIDGETS UTILITAIRES
  // ==============================
  Widget _buildKpi(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, String content) {
    return Container(
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
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
      String title, IconData icon, Color color, List<String> items) {
    return Container(
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
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatMontant(dynamic montant) {
    if (montant == null) return '0';
    final num = double.tryParse(montant.toString()) ?? 0;
    return num.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Soumettre le projet'),
        content: const Text(
          'En soumettant votre projet, vous envoyez votre dossier complet avec le Business Plan à l\'équipe EDA LAUNCH pour évaluation.\n\nVoulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitProject();
            },
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProject() async {
  final response = await ApiService.patch(
    AppUrls.projectStatus(widget.projectId),
    {
      'status': 'soumis',
      'comment': 'Projet soumis avec Business Plan généré par IA',
    },
  );

  if (!mounted) return;

  if (response['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Projet soumis avec succès ! 🎉'),
        backgroundColor: AppColors.success,
      ),
    );
    // Retourne à la racine de la navigation
    Navigator.of(context).popUntil((route) => route.isFirst);
  } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _downloadPdf() async {
  print('🔵 _downloadPdf appelé');
   if (_businessPlan == null) {
    print('❌ _businessPlan est null');
    return;
  }
  print('✅ _businessPlan trouvé, génération...');
  print('📋 Business Plan data: ${_businessPlan!.keys.toList()}');
print('📋 Resume: ${_businessPlan!['resume_executif']?.toString().substring(0, 50)}');
print('📋 Content type: ${_businessPlan!['content'].runtimeType}');
print('📋 Content: ${_businessPlan!['content'].toString().substring(0, 200)}');

  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du PDF en cours...'),
        backgroundColor: AppColors.info,
      ),
    );

    final pdf = pw.Document();
    final plan = _businessPlan!['content'] as Map<String, dynamic>;
    final projectName = _businessPlan!['project_name'] ?? 'Projet';
    final bfiAmount = _businessPlan!['bfi_amount'] ?? 0;
    final bfrAmount = _businessPlan!['bfr_amount'] ?? 0;
    final totalFinancement = _businessPlan!['total_financement'] ?? 0;

  pdf.addPage(
  pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (context) => [
      // En-tête
      pw.Text('BUSINESS PLAN',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.Text(projectName,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.Text('Généré par EDA LAUNCH',
          style: const pw.TextStyle(fontSize: 11)),
      pw.Divider(),
      pw.SizedBox(height: 12),

      // Résumé exécutif
      pw.Text('1. Résumé Exécutif',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text(plan['resume_executif']?.toString() ?? '',
          style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 16),

      // Analyse marché
      pw.Text('2. Analyse du Marché',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text(plan['analyse_marche']?['description']?.toString() ?? '',
          style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 8),
      if (plan['analyse_marche']?['opportunites'] != null)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Opportunités :',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ...(plan['analyse_marche']['opportunites'] as List).map(
              (o) => pw.Text('• $o', style: const pw.TextStyle(fontSize: 11)),
            ),
          ],
        ),
      pw.SizedBox(height: 16),

      // Stratégie commerciale
      pw.Text('3. Stratégie Commerciale',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text('Acquisition clients : ${plan['strategie_commerciale']?['acquisition_clients'] ?? ''}',
          style: const pw.TextStyle(fontSize: 11)),
      pw.Text('Politique de prix : ${plan['strategie_commerciale']?['politique_prix'] ?? ''}',
          style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 16),

      // Organisation
      pw.Text('4. Organisation',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text('Équipe : ${plan['organisation']?['equipe'] ?? ''}',
          style: const pw.TextStyle(fontSize: 11)),
      pw.Text('Ressources humaines : ${plan['organisation']?['ressources_humaines'] ?? ''}',
          style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 16),

      // Plan financier
      pw.Text('5. Plan Financier',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text('BFI (Investissement) : $bfiAmount FCFA',
          style: const pw.TextStyle(fontSize: 11)),
      pw.Text('BFR (Roulement) : $bfrAmount FCFA',
          style: const pw.TextStyle(fontSize: 11)),
      pw.Text('Total Financement : $totalFinancement FCFA',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text(plan['plan_financier']?['recommandation_financement']?.toString() ?? '',
          style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 16),

      // Conclusion
      pw.Text('6. Conclusion',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text(plan['conclusion']?.toString() ?? '',
          style: const pw.TextStyle(fontSize: 11)),
    ],
  ),
);

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'business_plan.pdf',
    );

  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
}