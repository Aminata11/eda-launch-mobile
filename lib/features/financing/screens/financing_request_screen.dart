import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class FinancingRequestScreen extends StatefulWidget {
  final List<dynamic> projects;
  const FinancingRequestScreen({super.key, required this.projects});

  @override
  State<FinancingRequestScreen> createState() => _FinancingRequestScreenState();
}

class _FinancingRequestScreenState extends State<FinancingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  String? _selectedProjectId;
  String? _selectedProjectName;
  String? _selectedDuration;

  final List<String> _durations = [
    '3 mois',
    '6 mois',
    '12 mois',
    '18 mois',
    '24 mois',
    '36 mois',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);

    final durationMonths = _selectedDuration != null
        ? int.tryParse(_selectedDuration!.split(' ')[0])
        : null;

    final response = await ApiService.post(
      AppUrls.financing,
      {
        'project_id': _selectedProjectId,
        'amount_requested': double.tryParse(_amountController.text) ?? 0,
        'duration_months': durationMonths,
        'purpose': _purposeController.text.trim(),
      },
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande soumise avec succès !'),
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
        title: const Text('Demande de financement'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _submitRequest();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep == 3
                                  ? 'Soumettre la demande'
                                  : 'Suivant →',
                            ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Retour'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // ÉTAPE 1 — Informations générales
            Step(
              title: const Text('Informations'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  // Titre projet
                  DropdownButtonFormField<String>(
                    value: _selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: 'Projet concerné *',
                      prefixIcon: Icon(Icons.rocket_launch_rounded),
                    ),
                    items: widget.projects.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'].toString(),
                        child: Text(p['name'].toString()),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedProjectId = v;
                        _selectedProjectName = widget.projects
                            .firstWhere((p) => p['id'] == v)['name'];
                      });
                    },
                    validator: (v) =>
                        v == null ? 'Sélectionnez un projet' : null,
                  ),

                  const SizedBox(height: 16),

                  // Secteur (auto-rempli)
                  if (_selectedProjectId != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Projet sélectionné : $_selectedProjectName',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ÉTAPE 2 — Projet
            Step(
              title: const Text('Projet'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _purposeController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Utilisation prévue du financement *',
                      hintText:
                          'Ex: Achat de matières premières, équipements de production et marketing...',
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Ce champ est obligatoire'
                        : null,
                  ),
                ],
              ),
            ),

            // ÉTAPE 3 — Financement
            Step(
              title: const Text('Financement'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant demandé (FCFA) *',
                      hintText: 'Ex: 5000000',
                      prefixIcon:
                          Icon(Icons.monetization_on_rounded),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Montant obligatoire'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    decoration: const InputDecoration(
                      labelText: 'Durée du financement',
                      prefixIcon: Icon(Icons.access_time_rounded),
                    ),
                    items: _durations
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedDuration = v),
                  ),
                ],
              ),
            ),

            // ÉTAPE 4 — Documents
            Step(
              title: const Text('Documents'),
              isActive: _currentStep >= 3,
              state: StepState.indexed,
              content: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.grey300,
                          style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_upload_rounded,
                          size: 48,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Upload de justificatifs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Business plan, pièce d\'identité,\nrelevés bancaires...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Upload disponible après déploiement AWS S3'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          },
                          icon: const Icon(Icons.attach_file_rounded),
                          label: const Text('Ajouter un document'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_rounded,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vous pouvez soumettre votre demande sans documents. Vous pourrez les ajouter ultérieurement.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
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
}