import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isAnalyzing = false;

  // Controllers
  final _revenueController = TextEditingController();
  final _expensesController = TextEditingController();
  final _jobsController = TextEditingController();
  final _progressController = TextEditingController();
  final _commentsController = TextEditingController();

  // Projet sélectionné
  String? _selectedProjectId;
  String? _selectedProjectName;
  List<dynamic> _projects = [];

  // Photos
  List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();

  // Analyse IA
  Map<String, dynamic>? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _revenueController.dispose();
    _expensesController.dispose();
    _jobsController.dispose();
    _progressController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final response = await ApiService.get(AppUrls.projects);
    if (mounted) {
      setState(() {
        _projects = response['success']
            ? (response['data']['projects'] as List? ?? [])
            : [];
      });
    }
  }

  Future<void> _pickPhoto() async {
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
            const Text(
              'Ajouter une photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: const Text('Prendre une photo'),
              subtitle: const Text('Récoltes, sol, plants...'),
              onTap: () async {
                Navigator.pop(context);
                final photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (photo != null) {
                  setState(() => _photos.add(File(photo.path)));
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
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() => _photos.add(File(image.path)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeWithAI() async {
    if (_photos.isEmpty && _commentsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez des photos ou des commentaires pour l\'analyse IA'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppUrls.baseUrl}/reporting/analyze'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Données du rapport
      request.fields['project_id'] = _selectedProjectId ?? '';
      request.fields['revenue'] = _revenueController.text;
      request.fields['expenses'] = _expensesController.text;
      request.fields['jobs_created'] = _jobsController.text;
      request.fields['progress_percent'] = _progressController.text;
      request.fields['comments'] = _commentsController.text;

      // Photos
      for (int i = 0; i < _photos.length; i++) {
        request.files.add(await http.MultipartFile.fromPath(
          'photos',
          _photos[i].path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      setState(() => _isAnalyzing = false);

      if (response.statusCode == 200 && data['success']) {
        setState(() => _aiAnalysis = data['data']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Erreur analyse IA'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez un projet'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final response = await ApiService.post(
      AppUrls.reporting,
      {
        'project_id': _selectedProjectId,
        'report_month': weekStart.toIso8601String().substring(0, 10),
        'revenue': double.tryParse(_revenueController.text) ?? 0,
        'expenses': double.tryParse(_expensesController.text) ?? 0,
        'jobs_created': int.tryParse(_jobsController.text) ?? 0,
        'progress_percent': int.tryParse(_progressController.text) ?? 0,
        'comments': _commentsController.text.trim(),
        'ai_analysis': _aiAnalysis != null ? jsonEncode(_aiAnalysis) : null,
      },
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport soumis avec succès !'),
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
        title: const Text('Nouveau rapport'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Sélection projet
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Projet concerné',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      decoration: const InputDecoration(
                        hintText: 'Sélectionnez un projet',
                        prefixIcon: Icon(Icons.rocket_launch_rounded),
                      ),
                      items: _projects.map((p) {
                        return DropdownMenuItem<String>(
                          value: p['id'].toString(),
                          child: Text(p['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedProjectId = v;
                          _selectedProjectName = _projects
                              .firstWhere((p) => p['id'] == v)['name'];
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Données chiffrées
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Données de la semaine',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Revenus
                    TextFormField(
                      controller: _revenueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Revenus (FCFA)',
                        hintText: 'Ex: 150000',
                        prefixIcon: Icon(Icons.trending_up_rounded,
                            color: AppColors.success),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Revenus obligatoires'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Dépenses
                    TextFormField(
                      controller: _expensesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dépenses (FCFA)',
                        hintText: 'Ex: 80000',
                        prefixIcon: Icon(Icons.trending_down_rounded,
                            color: AppColors.error),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Dépenses obligatoires'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Emplois
                    TextFormField(
                      controller: _jobsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Emplois créés',
                        hintText: 'Ex: 2',
                        prefixIcon: Icon(Icons.people_rounded,
                            color: AppColors.primary),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progression
                    TextFormField(
                      controller: _progressController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Progression du projet (%)',
                        hintText: 'Ex: 35',
                        prefixIcon: Icon(Icons.percent_rounded,
                            color: AppColors.warning),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 0 || n > 100) {
                          return 'Entre 0 et 100';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Commentaires
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commentaires',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commentsController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Décrivez l\'évolution de votre projet cette semaine, les défis rencontrés...',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Photos
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const Text(
                      'Ajoutez des photos de vos récoltes, du sol ou des plants pour analyse IA',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_photos.isEmpty)
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.grey300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded,
                                    color: AppColors.grey400, size: 32),
                                SizedBox(height: 8),
                                Text(
                                  'Cliquer pour ajouter une photo',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _photos.length) {
                              return GestureDetector(
                                onTap: _pickPhoto,
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.grey300),
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: AppColors.grey400,
                                    size: 32,
                                  ),
                                ),
                              );
                            }
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(_photos[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _photos.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: AppColors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Analyse IA
              if (_aiAnalysis != null) _buildAIAnalysis(),

              const SizedBox(height: 16),

              // Bouton analyse IA
             OutlinedButton.icon(
  onPressed: _isAnalyzing ? null : _analyzeImageWithAI,
  icon: _isAnalyzing
      ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        )
      : const Icon(Icons.image_search_rounded),
  label: Text(
    _isAnalyzing
        ? 'Analyse en cours...'
        : 'Analyser l\'image',
  ),
  style: OutlinedButton.styleFrom(
    minimumSize: const Size(double.infinity, 52),
  ),
),

              const SizedBox(height: 12),

              // Bouton soumettre
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitReport,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Soumettre le rapport'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIAnalysis() {
    final positifs = _aiAnalysis!['points_positifs'] as List? ?? [];
    final negatifs = _aiAnalysis!['points_negatifs'] as List? ?? [];
    final recommandations = _aiAnalysis!['recommandations'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Analyse IA',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          if (positifs.isNotEmpty) ...[
            const Text('✅ Points positifs',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success)),
            const SizedBox(height: 8),
            ...positifs.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(p.toString(),
                              style:
                                  const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          if (negatifs.isNotEmpty) ...[
            const Text('⚠️ Points à améliorer',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning)),
            const SizedBox(height: 8),
            ...negatifs.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_rounded,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(n.toString(),
                              style:
                                  const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          if (recommandations.isNotEmpty) ...[
            const Text('💡 Recommandations',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            const SizedBox(height: 8),
            ...recommandations.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(r.toString(),
                              style:
                                  const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }


  Future<void> _analyzeImageWithAI() async {
  if (_photos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajoutez une photo pour l\'analyse'),
        backgroundColor: AppColors.warning,
      ),
    );
    return;
  }

  setState(() => _isAnalyzing = true);

  try {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppUrls.analyzeImage),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['context'] = 'Photo de sol ou plante agricole au Sénégal';

    // Envoie seulement la première photo
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _photos[0].path,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);
    print('📸 Analyze image response: $data'); // ← ici
print('📸 Status code: ${response.statusCode}'); // ← ici

    setState(() => _isAnalyzing = false);

    if (!mounted) return;

    if (data['success'] == true) {
      setState(() => _aiAnalysis = data['data']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Erreur analyse image'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } catch (e) {
    setState(() => _isAnalyzing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
}