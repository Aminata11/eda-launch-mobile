import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState
    extends State<AdminAppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _statusFilters = [
  {'key': 'tous', 'label': 'Tous'},
  {'key': 'en_attente', 'label': 'Attente'},
  {'key': 'confirme', 'label': 'Confirmé'},
  {'key': 'annule', 'label': 'Annulé'},
  {'key': 'termine', 'label': 'Terminé'},
];

  String _selectedStatus = 'tous';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final response = await ApiService.get(AppUrls.appointments);
    if (mounted) {
      setState(() {
        _appointments = response['success']
            ? (response['data']['appointments'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredAppointments {
    if (_selectedStatus == 'tous') return _appointments;
    return _appointments
        .where((a) => a['status'] == _selectedStatus)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente': return AppColors.warning;
      case 'confirme': return AppColors.success;
      case 'annule': return AppColors.error;
      case 'termine': return AppColors.grey500;
      default: return AppColors.grey500;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'en_attente': return 'En attente';
      case 'confirme': return 'Confirmé';
      case 'annule': return 'Annulé';
      case 'termine': return 'Terminé';
      default: return status;
    }
  }

  String _getCanalIcon(String canal) {
    switch (canal) {
      case 'meet': return '📹';
      case 'appel': return '📞';
      case 'presentiel': return '📍';
      default: return '📅';
    }
  }

  String _getCanalLabel(String canal) {
    switch (canal) {
      case 'meet': return 'Google Meet';
      case 'appel': return 'Appel téléphonique';
      case 'presentiel': return 'Présentiel';
      default: return canal;
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    final messages = {
      'confirme': 'Confirmer ce rendez-vous ?',
      'annule': 'Annuler ce rendez-vous ?',
      'termine': 'Marquer ce rendez-vous comme terminé ?',
    };

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(messages[status] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'confirme'
                  ? AppColors.success
                  : status == 'annule'
                      ? AppColors.error
                      : AppColors.primary,
            ),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await ApiService.patch(
      AppUrls.updateAppointment(id),
      {'status': status},
    );

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'confirme'
              ? 'RDV confirmé ✅'
              : status == 'annule'
                  ? 'RDV annulé ❌'
                  : 'RDV marqué comme terminé'),
          backgroundColor: status == 'confirme'
              ? AppColors.success
              : status == 'annule'
                  ? AppColors.error
                  : AppColors.primary,
        ),
      );
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rendez-vous'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.admin))
          : Column(
              children: [
                // Filtres
                Container(
                  color: AppColors.white,
                  height: 50,
                  
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    child: Row(
                      children: _statusFilters.map((filter) {
                        final isSelected = _selectedStatus == filter['key'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedStatus = filter['key']),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
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
                      }).toList(),
                    ),
                  ),
                ),

                // Liste RDV
                Expanded(
                  child: _filteredAppointments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 60, color: AppColors.grey300),
                              SizedBox(height: 16),
                              Text(
                                'Aucun rendez-vous',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAppointments,
                          color: AppColors.admin,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredAppointments.length,
                            itemBuilder: (context, index) {
                              return _buildAppointmentCard(
                                  _filteredAppointments[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'en_attente';
    final statusColor = _getStatusColor(status);
    final canal = appointment['canal'] ?? 'appel';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: status == 'en_attente'
            ? Border.all(
                color: AppColors.warning.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  appointment['project_name'] ?? '',
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

          const SizedBox(height: 12),

          // Financeur
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  size: 16, color: AppColors.financeur),
              const SizedBox(width: 6),
              Text(
                appointment['financer_name'] ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Contact financeur
          if (appointment['financer_phone'] != null)
            Row(
              children: [
                const Icon(Icons.phone_rounded,
                    size: 14, color: AppColors.grey400),
                const SizedBox(width: 6),
                Text(
                  appointment['financer_phone'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.email_rounded,
                  size: 14, color: AppColors.grey400),
              const SizedBox(width: 6),
              Text(
                appointment['financer_email'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Date + heure + canal
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                appointment['scheduled_date']
                        ?.toString()
                        .substring(0, 10) ??
                    '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                appointment['scheduled_time']
                        ?.toString()
                        .substring(0, 5) ??
                    '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_getCanalIcon(canal)} ${_getCanalLabel(canal)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Note
          if (appointment['note'] != null &&
              appointment['note'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_rounded,
                      size: 14, color: AppColors.grey400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment['note'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions
          if (status == 'en_attente') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _updateStatus(appointment['id'], 'confirme'),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Confirmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _updateStatus(appointment['id'], 'annule'),
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.error),
                    label: const Text('Annuler',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (status == 'confirme') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  _updateStatus(appointment['id'], 'termine'),
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Marquer comme terminé'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 38),
              ),
            ),
          ],
        ],
      ),
    );
  }
}