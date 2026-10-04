import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class AdminAvailabilityScreen extends StatefulWidget {
  const AdminAvailabilityScreen({super.key});

  @override
  State<AdminAvailabilityScreen> createState() =>
      _AdminAvailabilityScreenState();
}

class _AdminAvailabilityScreenState
    extends State<AdminAvailabilityScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  

  final List<String> _jours = [
    'Dimanche', 'Lundi', 'Mardi', 'Mercredi',
    'Jeudi', 'Vendredi', 'Samedi'
  ];

  // Disponibilités par jour
  final List<Map<String, dynamic>> _availabilities = [
    {'day': 1, 'label': 'Lundi', 'enabled': false, 'start': '08:00', 'end': '17:00'},
    {'day': 2, 'label': 'Mardi', 'enabled': false, 'start': '08:00', 'end': '17:00'},
    {'day': 3, 'label': 'Mercredi', 'enabled': false, 'start': '08:00', 'end': '17:00'},
    {'day': 4, 'label': 'Jeudi', 'enabled': false, 'start': '08:00', 'end': '17:00'},
    {'day': 5, 'label': 'Vendredi', 'enabled': false, 'start': '08:00', 'end': '17:00'},
    {'day': 6, 'label': 'Samedi', 'enabled': false, 'start': '08:00', 'end': '12:00'},
  ];

  Future<void> _selectTime(int index, bool isStart) async {
    final current = isStart
        ? _availabilities[index]['start'] as String
        : _availabilities[index]['end'] as String;

    final parts = current.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.admin,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final time =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _availabilities[index]['start'] = time;
        } else {
          _availabilities[index]['end'] = time;
        }
      });
    }
  }

  Future<void> _saveAvailabilities() async {
    final enabled = _availabilities.where((a) => a['enabled'] == true).toList();

    if (enabled.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un jour'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final slots = enabled.map((a) => {
      'day_of_week': a['day'],
      'start_time': a['start'],
      'end_time': a['end'],
    }).toList();

    final response = await ApiService.post(
      AppUrls.availabilities,
      {'availabilities': slots},
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disponibilités enregistrées ✅'),
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
        title: const Text('Mes disponibilités'),
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
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Définissez vos créneaux disponibles pour les rendez-vous avec les financeurs.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Jours et horaires',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Liste des jours
            ...List.generate(_availabilities.length, (index) {
              final day = _availabilities[index];
              final isEnabled = day['enabled'] as bool;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.white
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isEnabled
                        ? AppColors.admin.withOpacity(0.3)
                        : AppColors.grey200,
                    width: isEnabled ? 2 : 1,
                  ),
                  boxShadow: isEnabled ? AppColors.cardShadow : [],
                ),
                child: Column(
                  children: [
                    // Jour + toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day['label'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Switch(
                          value: isEnabled,
                          onChanged: (v) =>
                              setState(() => day['enabled'] = v),
                          activeColor: AppColors.admin,
                        ),
                      ],
                    ),

                    // Horaires
                    if (isEnabled) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Heure début
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(index, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      day['start'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '→',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),

                          // Heure fin
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(index, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      day['end'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Bouton sauvegarder
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAvailabilities,
              icon: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving
                    ? 'Enregistrement...'
                    : 'Enregistrer les disponibilités',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.admin,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
void initState() {
  super.initState();
  _loadExistingAvailabilities();
}

Future<void> _loadExistingAvailabilities() async {
  setState(() => _isLoading = true);
  
  final response = await ApiService.get(AppUrls.availabilities);
  
  if (response['success']) {
    final existing = response['data']['availabilities'] as List? ?? [];
    
    for (final slot in existing) {
      final dayOfWeek = slot['day_of_week'] as int;
      final index = _availabilities.indexWhere((a) => a['day'] == dayOfWeek);
      if (index != -1) {
        setState(() {
          _availabilities[index]['enabled'] = true;
          _availabilities[index]['start'] = slot['start_time'].toString().substring(0, 5);
          _availabilities[index]['end'] = slot['end_time'].toString().substring(0, 5);
        });
      }
    }
  }
  
  setState(() => _isLoading = false);
}
}