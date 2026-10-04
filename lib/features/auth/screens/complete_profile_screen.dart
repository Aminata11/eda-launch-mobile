import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import '../../dashboard/screens/entrepreneur_dashboard_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _sectorController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _cvController = TextEditingController();
  final _skillController = TextEditingController();
  List<String> _skills = [];
  String? _selectedLevel;
  bool _isLoading = false;

  final List<String> _levels = [
    'débutant',
    'intermédiaire',
    'avancé',
    'expert',
  ];

  void _addSkill(String skill) {
    if (skill.trim().isEmpty) return;
    setState(() {
      _skills.add(skill.trim());
      _skillController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une compétence'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.patch(
      AppUrls.me,
      {
        'bio': _bioController.text.trim(),
        'sector': _sectorController.text.trim(),
        'location': _locationController.text.trim(),
        'entrepreneurial_level': _selectedLevel,
        'linkedin_url': _linkedinController.text.trim(),
        'cv_url': _cvController.text.trim(),
        'skills': _skills,
      },
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success']) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const EntrepreneurDashboardScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Erreur'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👋 Bienvenue !',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complétez votre profil avant d\'accéder à l\'application. Ces informations nous permettent de mieux vous accompagner.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Biographie
                const Text('Biographie *',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Parlez de vous, votre parcours...',
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Biographie obligatoire'
                      : null,
                ),

                const SizedBox(height: 16),

                // Secteur
                const Text("Secteur d'activité *",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sectorController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Agriculture, Digital, Finance...',
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Secteur obligatoire'
                      : null,
                ),

                const SizedBox(height: 16),

                // Localisation
                const Text('Localisation *',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Dakar, Saint-Louis...',
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Localisation obligatoire'
                      : null,
                ),

                const SizedBox(height: 16),

                // Niveau entrepreneurial
                const Text('Niveau entrepreneurial *',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  decoration: const InputDecoration(
                    hintText: 'Sélectionnez votre niveau',
                  ),
                  items: _levels
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedLevel = v),
                  validator: (v) => v == null
                      ? 'Niveau obligatoire'
                      : null,
                ),

                const SizedBox(height: 16),

                // LinkedIn
                const Text('LinkedIn *',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _linkedinController,
                  decoration: const InputDecoration(
                    hintText: 'https://linkedin.com/in/...',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'LinkedIn obligatoire'
                      : null,
                ),

                const SizedBox(height: 16),

                // CV
                const Text('Lien CV *',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cvController,
                  decoration: const InputDecoration(
                    hintText: 'https://drive.google.com/...',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'CV obligatoire'
                      : null,
                ),

                const SizedBox(height: 16),

                // Compétences
                const Text('Compétences *',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Marketing, Finance...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (v) => _addSkill(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          _addSkill(_skillController.text),
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (_skills.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skills.map((skill) {
                      return Chip(
                        label: Text(skill,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary)),
                        backgroundColor: AppColors.primaryLight,
                        deleteIcon: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.error),
                        onDeleted: () => _removeSkill(skill),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 32),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 52),
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
                        : const Text('Accéder à l\'application'),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}