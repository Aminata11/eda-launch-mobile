import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class FinancingDetailScreen extends StatefulWidget {
  final String requestId;
  const FinancingDetailScreen({super.key, required this.requestId});

  @override
  State<FinancingDetailScreen> createState() => _FinancingDetailScreenState();
}

class _FinancingDetailScreenState extends State<FinancingDetailScreen> {
  Map<String, dynamic>? _request;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final response = await ApiService.get(
      AppUrls.financingById(widget.requestId),
    );
    if (mounted) {
      setState(() {
        _request = response['success'] ? response['data'] : null;
        _isLoading = false;
      });
    }
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
      case 'approuve': return 'Approuvé ✅';
      case 'rejete': return 'Rejeté ❌';
      case 'decaisse': return 'Décaissé 💰';
      default: return status;
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

    if (_request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Demande')),
        body: const Center(child: Text('Demande introuvable')),
      );
    }

    final status = _request!['status'] ?? 'en_attente';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail de la demande'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Statut
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    status == 'approuve'
                        ? Icons.check_circle_rounded
                        : status == 'rejete'
                            ? Icons.cancel_rounded
                            : status == 'decaisse'
                                ? Icons.monetization_on_rounded
                                : Icons.hourglass_empty_rounded,
                    color: statusColor,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (_request!['rejection_reason'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _request!['rejection_reason'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Projet
            _buildSection(
              'Projet concerné',
              Icons.rocket_launch_rounded,
              AppColors.primary,
              [
                _buildRow('Nom', _request!['project_name'] ?? ''),
                _buildRow('Secteur', _request!['project_sector'] ?? ''),
                if (_request!['project_score'] != null)
                  _buildRow('Score', '${_request!['project_score']}/100'),
              ],
            ),

            const SizedBox(height: 16),

            // Montants
            _buildSection(
              'Financement',
              Icons.monetization_on_rounded,
              AppColors.success,
              [
                _buildRow('Montant demandé',
                    '${_request!['amount_requested']} FCFA'),
                if (_request!['amount_approved'] != null)
                  _buildRow('Montant approuvé',
                      '${_request!['amount_approved']} FCFA'),
                if (_request!['duration_months'] != null)
                  _buildRow('Durée',
                      '${_request!['duration_months']} mois'),
                if (_request!['conditions'] != null)
                  _buildRow('Conditions', _request!['conditions']),
              ],
            ),

            const SizedBox(height: 16),

            // Utilisation
            _buildSection(
              'Utilisation prévue',
              Icons.info_outline_rounded,
              AppColors.info,
              [
                Text(
                  _request!['purpose'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Financeur
            if (_request!['financer_name'] != null)
              _buildSection(
                'Financeur',
                Icons.account_balance_rounded,
                AppColors.warning,
                [
                  _buildRow('Institution', _request!['financer_name']),
                ],
              ),

            const SizedBox(height: 16),

            // Documents
            _buildSection(
              'Justificatifs',
              Icons.attach_file_rounded,
              AppColors.primary,
              [
                if ((_request!['documents'] as List? ?? []).isEmpty)
                  const Text(
                    'Aucun document uploadé',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  ...(_request!['documents'] as List).map((doc) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              doc['name'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      )),
              ],
            ),

            const SizedBox(height: 16),

            // Dates
            _buildSection(
              'Dates',
              Icons.calendar_today_rounded,
              AppColors.grey500,
              [
                _buildRow('Soumis le',
                    _request!['created_at']?.toString().substring(0, 10) ?? ''),
                _buildRow('Mis à jour le',
                    _request!['updated_at']?.toString().substring(0, 10) ?? ''),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children) {
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}