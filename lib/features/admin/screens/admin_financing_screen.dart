import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class AdminFinancingScreen extends StatefulWidget {
  const AdminFinancingScreen({super.key});

  @override
  State<AdminFinancingScreen> createState() => _AdminFinancingScreenState();
}

class _AdminFinancingScreenState extends State<AdminFinancingScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _selectedStatus = 'tous';

  final List<Map<String, dynamic>> _statusFilters = [
  {'key': 'tous', 'label': 'Tous'},
  {'key': 'en_analyse', 'label': 'Analyse'},
  {'key': 'approuve', 'label': 'Approuvé'},
  {'key': 'rejete', 'label': 'Rejeté'},
  {'key': 'decaisse', 'label': 'Décaissé'},
];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final response = await ApiService.get(AppUrls.financing);
    if (mounted) {
      setState(() {
        _requests = response['success']
            ? (response['data']['requests'] as List? ?? [])
            : [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financement'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.admin))
          : Column(
              children: [
                // Stats rapides
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatMini(
                          'Total',
                          '${_requests.length}',
                          AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: _buildStatMini(
                          'En attente',
                          '${_requests.where((r) => r['status'] == 'en_attente').length}',
                          AppColors.warning,
                        ),
                      ),
                      Expanded(
                        child: _buildStatMini(
                          'Approuvés',
                          '${_requests.where((r) => r['status'] == 'approuve').length}',
                          AppColors.success,
                        ),
                      ),
                      Expanded(
                        child: _buildStatMini(
                          'Rejetés',
                          '${_requests.where((r) => r['status'] == 'rejete').length}',
                          AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filtres
                Container(
                  color: AppColors.white,
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: _statusFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _statusFilters[index];
                      final isSelected =
                          _selectedStatus == filter['key'];
                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedStatus = filter['key']),
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
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

                // Liste demandes
                Expanded(
                  child: _filteredRequests.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune demande',
                            style: TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRequests,
                          color: AppColors.admin,
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
            ),
    );
  }

  Widget _buildStatMini(String label, String value, Color color) {
    return Column(
      children: [
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
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'en_attente';
    final statusColor = _getStatusColor(status);

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
          // Projet + statut
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

          // Entrepreneur
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: AppColors.grey400),
              const SizedBox(width: 4),
              Text(
                request['entrepreneur_name'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Montants
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Montant demandé',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${request['amount_requested']} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (request['amount_approved'] != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Montant approuvé',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${request['amount_approved']} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Utilisation
          Text(
            request['purpose'] ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Actions pour demandes en attente
          if (status == 'en_attente') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _changeStatus(request['id'], 'approuve'),
                    icon: const Icon(Icons.check_rounded,
                        size: 16, color: AppColors.success),
                    label: const Text('Approuver',
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
                    onPressed: () =>
                        _changeStatus(request['id'], 'rejete'),
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

           // Décaissement
          if (status == 'approuve') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  _changeStatus(request['id'], 'decaisse'),
              icon: const Icon(Icons.payments_rounded,
                  size: 16, color: AppColors.primary),
              label: const Text(
                'Marquer comme décaissé',
                style: TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ],

          // Date
          const SizedBox(height: 8),
          Text(
            request['created_at']?.toString().substring(0, 10) ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(String requestId, String status) async {
    final confirm = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    title: Text(status == 'approuve'
        ? 'Approuver la demande'
        : status == 'decaisse'
            ? 'Décaisser la demande'
            : 'Rejeter la demande'),
    content: Text(
      status == 'approuve'
          ? 'Voulez-vous approuver cette demande de financement ?'
          : status == 'decaisse'
              ? 'Confirmer le décaissement de cette demande ?'
              : 'Voulez-vous rejeter cette demande ?',
    ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
         ElevatedButton(
  onPressed: () => Navigator.pop(context, true),
  style: ElevatedButton.styleFrom(
    backgroundColor: status == 'approuve'
        ? AppColors.success
        : status == 'decaisse'
            ? AppColors.primary
            : AppColors.error,
  ),
  child: Text(
    status == 'approuve'
        ? 'Approuver'
        : status == 'decaisse'
            ? 'Confirmer'
            : 'Rejeter',
  ),
),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await ApiService.patch(
      AppUrls.financingStatus(requestId),
      {
        'status': status,
        'amount_approved': status == 'approuve'
            ? _requests.firstWhere(
                (r) => r['id'] == requestId)['amount_requested']
            : null,
        'conditions': status == 'approuve'
            ? 'Financement approuvé par EDA LAUNCH'
            : null,
        'rejection_reason': status == 'rejete'
            ? 'Demande rejetée par EDA LAUNCH'
            : null,
      },
    );

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(status == 'approuve'
        ? 'Demande approuvée ✅'
        : status == 'decaisse'
            ? 'Décaissement confirmé ✅'
            : 'Demande rejetée ❌'),
    backgroundColor: status == 'approuve'
        ? AppColors.success
        : status == 'decaisse'
            ? AppColors.primary
            : AppColors.error,
  ),
);
      _loadRequests();
    }
  }
}