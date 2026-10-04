import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class AppointmentScreen extends StatefulWidget {
  final String projectId;
  final String financingRequestId;
  const AppointmentScreen({
    super.key,
    required this.projectId,
    required this.financingRequestId,
  });

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  List<dynamic> _availabilities = [];
  Map<String, dynamic>? _adminInfo;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Formulaire RDV
  DateTime? _selectedDate;
  String? _selectedTime;
  String _selectedCanal = 'appel';
  final _noteController = TextEditingController();

  final List<Map<String, dynamic>> _canaux = [
    {'key': 'appel', 'label': 'Appel téléphonique', 'icon': Icons.phone_rounded},
    {'key': 'meet', 'label': 'Google Meet', 'icon': Icons.video_call_rounded},
    {'key': 'presentiel', 'label': 'Présentiel', 'icon': Icons.location_on_rounded},
  ];

  final List<String> _joursSemaine = [
    'Dimanche', 'Lundi', 'Mardi', 'Mercredi',
    'Jeudi', 'Vendredi', 'Samedi'
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailabilities();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilities() async {
    final response = await ApiService.get(AppUrls.availabilities);
    if (mounted) {
      setState(() {
        _availabilities = response['success']
            ? (response['data']['availabilities'] as List? ?? [])
            : [];
        _adminInfo = response['success'] ? response['data']['admin'] : null;
        _isLoading = false;
      });
    }
  }

  // Heures disponibles pour un jour donné
  List<String> _getTimesForDay(int dayOfWeek) {
    final slots = _availabilities
        .where((a) => a['day_of_week'] == dayOfWeek)
        .toList();

    List<String> times = [];
    for (final slot in slots) {
      final start = slot['start_time'].toString().substring(0, 5);
      final end = slot['end_time'].toString().substring(0, 5);

      // Génère des créneaux de 30 minutes
      final startHour = int.parse(start.split(':')[0]);
      final startMin = int.parse(start.split(':')[1]);
      final endHour = int.parse(end.split(':')[0]);
      final endMin = int.parse(end.split(':')[1]);

      int currentMin = startHour * 60 + startMin;
      final endTotal = endHour * 60 + endMin;

      while (currentMin < endTotal) {
        final h = currentMin ~/ 60;
        final m = currentMin % 60;
        times.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
        currentMin += 30;
      }
    }
    return times;
  }

  Future<void> _submitAppointment() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez une date et une heure'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await ApiService.post(
      AppUrls.appointments,
      {
        'project_id': widget.projectId,
        'financing_request_id': widget.financingRequestId,
        'scheduled_date': _selectedDate!.toIso8601String().substring(0, 10),
        'scheduled_time': _selectedTime,
        'canal': _selectedCanal,
        'note': _noteController.text.trim(),
      },
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendez-vous demandé avec succès ! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fixer un rendez-vous'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.financeur))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Coordonnées Admin
                  if (_adminInfo != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person_rounded,
                                  color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Contact Administrateur',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                '${_adminInfo!['first_name']} ${_adminInfo!['last_name']}',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.email_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _adminInfo!['email'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          if (_adminInfo!['phone'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _adminInfo!['phone'],
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Disponibilités Admin
                  const Text(
                    'Créneaux disponibles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_availabilities.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Aucun créneau disponible pour le moment. Contactez l\'administrateur directement.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        children: _availabilities.map((a) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _joursSemaine[a['day_of_week']],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${a['start_time'].toString().substring(0, 5)} - ${a['end_time'].toString().substring(0, 5)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Choisir une date
                  const Text(
                    'Choisir une date',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                            const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                            const Duration(days: 60)),
                        locale: const Locale('fr', 'FR'),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.financeur,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                          _selectedTime = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDate != null
                              ? AppColors.financeur
                              : AppColors.border,
                          width: _selectedDate != null ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: _selectedDate != null
                                ? AppColors.financeur
                                : AppColors.grey400,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null
                                ? '${_joursSemaine[_selectedDate!.weekday % 7]} ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Sélectionner une date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Créneaux horaires
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Choisir un créneau horaire',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Builder(builder: (context) {
                      final dayOfWeek = _selectedDate!.weekday % 7;
                      final times = _getTimesForDay(dayOfWeek);

                      if (times.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Aucun créneau disponible ce jour. Choisissez une autre date.',
                            style: TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: times.map((time) {
                          final isSelected = _selectedTime == time;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedTime = time),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.financeur
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.financeur
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],

                  const SizedBox(height: 20),

                  // Canal
                  const Text(
                    'Canal de communication',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: _canaux.map((canal) {
                      final isSelected = _selectedCanal == canal['key'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _selectedCanal = canal['key']),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: canal['key'] != 'presentiel'
                                  ? 8
                                  : 0,
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.financeur.withOpacity(0.1)
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.financeur
                                    : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  canal['icon'] as IconData,
                                  color: isSelected
                                      ? AppColors.financeur
                                      : AppColors.grey400,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  canal['label'].toString().split(' ')[0],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.financeur
                                        : AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Note
                  const Text(
                    'Note (optionnelle)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Ex: Je souhaite discuter des modalités de remboursement...',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton soumettre
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitAppointment,
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.calendar_month_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'Envoi en cours...'
                          : 'Confirmer le rendez-vous',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.financeur,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}