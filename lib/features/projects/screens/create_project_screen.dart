import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import 'business_plan_screen.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isGeneratingBP = false;
  String? _createdProjectId;

  // Controllers étape 1
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSector;
  String? _selectedLocation;

  // Controllers étape 2
  final _problemController = TextEditingController();
  final _solutionController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _targetMarketController = TextEditingController();

  // Controllers étape 3 — Stratégie commerciale
  final _targetCustomersController = TextEditingController();
  final _pricingPolicyController = TextEditingController();
  final _communicationChannelsController = TextEditingController();

  // Controllers étape 4 — Organisation
  final _teamDescriptionController = TextEditingController();
  final _humanResourcesController = TextEditingController();
  final _technicalResourcesController = TextEditingController();

  // Fichiers étape 5
  File? _bfiFile;
  File? _bfrFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _sectors = [
    'Agriculture', 'Agroalimentaire', 'Commerce', 'Digital',
    'Education', 'Energie', 'Environnement', 'Finance',
    'Sante', 'Tourisme', 'Transport', 'Autre',
  ];

  final List<String> _locations = [
    'Dakar', 'Thies', 'Saint-Louis', 'Ziguinchor',
    'Kaolack', 'Diourbel', 'Louga', 'Fatick',
    'Kolda', 'Tambacounda', 'Matam', 'Kedougou',
    'Sedhiou', 'Kaffrine',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _objectivesController.dispose();
    _targetMarketController.dispose();
    _targetCustomersController.dispose();
    _pricingPolicyController.dispose();
    _communicationChannelsController.dispose();
    _teamDescriptionController.dispose();
    _humanResourcesController.dispose();
    _technicalResourcesController.dispose();
    super.dispose();
  }

  // Créer le projet (étapes 1-4)
  Future<void> _createProject() async {
    setState(() => _isLoading = true);

    final response = await ApiService.post(
      AppUrls.projects,
      {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'sector': _selectedSector,
        'location': _selectedLocation,
        'problem': _problemController.text.trim(),
        'solution': _solutionController.text.trim(),
        'objectives': _objectivesController.text.trim(),
        'target_market': _targetMarketController.text.trim(),
        'target_customers': _targetCustomersController.text.trim(),
        'pricing_policy': _pricingPolicyController.text.trim(),
        'communication_channels': _communicationChannelsController.text.trim(),
        'team_description': _teamDescriptionController.text.trim(),
        'human_resources': _humanResourcesController.text.trim(),
        'technical_resources': _technicalResourcesController.text.trim(),
      },
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success']) {
      _createdProjectId = response['data']['id'];
      setState(() => _currentStep = 4);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Charger les factures de test depuis les assets
Future<void> _loadTestInvoices() async {
  try {
    // Copie BFI depuis assets vers fichier temporaire
    final bfiData = await rootBundle.load(
    'assets/invoices/Facture_Proforma_BFI_AgriSen.pdf');
    final bfrData = await rootBundle.load(
        'assets/invoices/Facture_Proforma_BFR_AgriSen.pdf');

    final tempDir = await getTemporaryDirectory();

    final bfiFile = File('${tempDir.path}/test_bfi_agrisen.pdf');
    await bfiFile.writeAsBytes(bfiData.buffer.asUint8List());

    final bfrFile = File('${tempDir.path}/test_bfr_agrisen.pdf');
    await bfrFile.writeAsBytes(bfrData.buffer.asUint8List());

    setState(() {
      _bfiFile = bfiFile;
      _bfrFile = bfrFile;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Factures de test chargées ! ✅'),
        backgroundColor: AppColors.success,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

  // Picker fichier
  Future<void> _pickFile(bool isBfi) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBfi ? 'Facture BFI' : 'Facture BFR',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(context);
                final photo = await _picker.pickImage(
                    source: ImageSource.camera);
                if (photo != null) {
                  setState(() {
                    if (isBfi) {
                      _bfiFile = File(photo.path);
                    } else {
                      _bfrFile = File(photo.path);
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _picker.pickImage(
                    source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    if (isBfi) {
                      _bfiFile = File(image.path);
                    } else {
                      _bfrFile = File(image.path);
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.warning),
              title: const Text('Uploader un PDF'),
              subtitle: const Text('Depuis vos fichiers'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Upload PDF disponible après déploiement AWS S3'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Générer le Business Plan
  Future<void> _generateBusinessPlan() async {
    if (_bfiFile == null || _bfrFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez uploader les factures BFI et BFR'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isGeneratingBP = true);

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppUrls.generateBusinessPlan(_createdProjectId!)),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'bfi_invoice',
        _bfiFile!.path,
      ));

      request.files.add(await http.MultipartFile.fromPath(
        'bfr_invoice',
        _bfrFile!.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() => _isGeneratingBP = false);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business Plan généré avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessPlanScreen(
              projectId: _createdProjectId!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la génération du Business Plan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingBP = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
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
        title: const Text('Nouveau projet'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () async {
            if (_currentStep == 3) {
              await _createProject();
            } else if (_currentStep < 3) {
              setState(() => _currentStep++);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0 && _currentStep < 4) {
              setState(() => _currentStep--);
            } else if (_currentStep == 0) {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (context, details) {
            if (_currentStep == 4) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_currentStep == 3
                              ? 'Créer le projet'
                              : 'Suivant →'),
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
              title: const Text('Informations générales'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du projet *',
                      hintText: 'Ex: Beej Bi',
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Nom obligatoire'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Décrivez votre projet',
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Description obligatoire'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSector,
                    decoration: const InputDecoration(
                        labelText: "Secteur d'activité"),
                    items: _sectors
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedSector = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration:
                        const InputDecoration(labelText: 'Localisation'),
                    items: _locations
                        .map((l) => DropdownMenuItem(
                              value: l,
                              child: Text(l),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedLocation = v),
                  ),
                ],
              ),
            ),

            // ÉTAPE 2 — Détails du projet
            Step(
              title: const Text('Détails du projet'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _problemController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Problème identifié',
                      hintText: 'Quel problème votre projet résout-il ?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _solutionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Solution proposée',
                      hintText: 'Comment résolvez-vous ce problème ?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _objectivesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Objectifs',
                      hintText: 'Quels sont vos objectifs ?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetMarketController,
                    decoration: const InputDecoration(
                      labelText: 'Marché cible',
                      hintText: 'Ex: Femmes, jeunes, coopératives',
                    ),
                  ),
                ],
              ),
            ),

            // ÉTAPE 3 — Stratégie commerciale
            Step(
              title: const Text('Stratégie commerciale'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb_rounded,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ces informations aideront l\'IA à générer un Business Plan complet.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetCustomersController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Comment attirer les clients ?',
                      hintText:
                          'Ex: Réseaux sociaux, bouche à oreille, marchés...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pricingPolicyController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Politique de prix',
                      hintText:
                          'Ex: Prix compétitifs, premium, selon le marché...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _communicationChannelsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Canaux de communication',
                      hintText:
                          'Ex: Facebook, WhatsApp, radio locale, événements...',
                    ),
                  ),
                ],
              ),
            ),

            // ÉTAPE 4 — Organisation
            Step(
              title: const Text('Organisation'),
              isActive: _currentStep >= 3,
              state: _currentStep > 3
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _teamDescriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Équipe',
                      hintText:
                          'Ex: 1 responsable, 2 couturières, 1 commercial...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _humanResourcesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ressources humaines',
                      hintText:
                          'Ex: Formations prévues, recrutements...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _technicalResourcesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ressources techniques',
                      hintText:
                          'Ex: Machines, logiciels, équipements...',
                    ),
                  ),
                ],
              ),
            ),

            // ÉTAPE 5 — Factures + Business Plan
            Step(
              title: const Text('Business Plan'),
              isActive: _currentStep >= 4,
              state: StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStep == 4) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: AppColors.success),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Projet créé avec succès ! Uploadez maintenant vos factures proforma pour générer le Business Plan.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Upload BFI
                    const Text(
                      'Facture proforma BFI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Besoin en Fonds d\'Investissement (équipements, local...)',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickFile(true),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bfiFile != null
                              ? AppColors.successLight
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _bfiFile != null
                                ? AppColors.success
                                : AppColors.grey300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _bfiFile != null
                                  ? Icons.check_circle_rounded
                                  : Icons.cloud_upload_rounded,
                              color: _bfiFile != null
                                  ? AppColors.success
                                  : AppColors.grey400,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _bfiFile != null
                                    ? _bfiFile!.path.split('/').last
                                    : 'Cliquer pour uploader (PDF, JPG, PNG)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _bfiFile != null
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Upload BFR
                    const Text(
                      'Facture proforma BFR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Besoin en Fonds de Roulement (stocks, charges...) ',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickFile(false),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bfrFile != null
                              ? AppColors.successLight
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _bfrFile != null
                                ? AppColors.success
                                : AppColors.grey300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _bfrFile != null
                                  ? Icons.check_circle_rounded
                                  : Icons.cloud_upload_rounded,
                              color: _bfrFile != null
                                  ? AppColors.success
                                  : AppColors.grey400,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _bfrFile != null
                                    ? _bfrFile!.path.split('/').last
                                    : 'Cliquer pour uploader (PDF, JPG, PNG)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _bfrFile != null
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                   const SizedBox(height: 24),

                    // Bouton charger factures de test
                    OutlinedButton.icon(
                      onPressed: _loadTestInvoices,
                      icon: const Icon(Icons.science_rounded),
                      label: const Text('Utiliser les factures de test'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bouton générer BP
                    ElevatedButton.icon(
                      onPressed: _isGeneratingBP
                          ? null
                          : _generateBusinessPlan,
                      icon: _isGeneratingBP
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _isGeneratingBP
                            ? 'Génération en cours...'
                            : 'Générer le Business Plan',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Ignorer et aller au projet
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: const Text(
                          'Passer — Générer plus tard'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}