import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/role_selection_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers
  final _bioController = TextEditingController();
  final _sectorController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkedinController = TextEditingController();
  String? _selectedLevel;

  final List<String> _levels = [
    'débutant',
    'intermédiaire',
    'avancé',
    'expert',
  ];

  final TextEditingController _skillController = TextEditingController();
List<String> _skills = [];

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _sectorController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

Future<void> _loadProfile() async {
  final profileResponse = await ApiService.get(AppUrls.me);
  final dashboardResponse = await ApiService.get(AppUrls.dashboardEntrepreneur);

  if (mounted) {
    setState(() {
      _profileData = profileResponse['success'] ? profileResponse['data'] : null;
      _skills = List<String>.from(
    _profileData?['skills'] as List? ?? []);
      
      // Ajoute les stats depuis le dashboard
      if (_profileData != null && dashboardResponse['success']) {
        final kpis = dashboardResponse['data']['kpis'];
        _profileData!['score_entrepreneurial'] = kpis['score_entrepreneurial'];
        _profileData!['nombre_projets'] = kpis['nombre_projets'];
        _profileData!['formations_completees'] = kpis['formations_completees'];
        _profileData!['formations_en_cours'] = dashboardResponse['data']['formations']['en_cours'];
      }

      if (_profileData != null) {
        _bioController.text = _profileData!['bio'] ?? '';
        _sectorController.text = _profileData!['sector'] ?? '';
        _locationController.text = _profileData!['location'] ?? '';
        _linkedinController.text = _profileData!['linkedin_url'] ?? '';
        _selectedLevel = _profileData!['entrepreneurial_level'];
      }
      _isLoading = false;
    });
  }
}

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Déconnecter',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiService.post(AppUrls.logout, {});
    await ApiService.deleteToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Annuler'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Photo + nom
                  _buildProfileHeader(),
                  const SizedBox(height: 24),

                  // Stats
                  _buildStats(),
                  const SizedBox(height: 24),

                  // Informations
                  _buildInfoSection(),
                  const SizedBox(height: 24),

                  // Compétences
                  _buildSkillsSection(),
                  const SizedBox(height: 24),

                  // Bouton enregistrer
                  if (_isEditing) ...[
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _saveProfile,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 52),
      ),
      child: const Text('Enregistrer'),
    ),
  ),
  const SizedBox(height: 24),
],

                  // Déconnexion
                  _buildLogoutButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final firstName = _profileData?['first_name'] ?? '';
    final lastName = _profileData?['last_name'] ?? '';
    final role = _profileData?['role'] ?? '';
    final isVerified = _profileData?['is_verified'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Photo profil
          GestureDetector(
  onTap: _uploadProfilePhoto,
  child: Stack(
    children: [
      Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 3,
          ),
          image: _profileData?['profile_photo'] != null
              ? DecorationImage(
                  image: NetworkImage(_profileData!['profile_photo']),
                  fit: BoxFit.cover,
                )
              : const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=200',
                  ),
                  fit: BoxFit.cover,
                ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            size: 14,
            color: AppColors.white,
          ),
        ),
      ),
    ],
  ),
),

          const SizedBox(height: 16),

          // Nom
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$firstName $lastName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Email
          Text(
            _profileData?['email'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 6),

          // Rôle badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleLabel(role),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Projets',
            '${_profileData?["nombre_projets"] ?? 1}',
            Icons.folder_rounded,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Score moyen',
            '${_profileData?["score_entrepreneurial"] ?? 0}/100',
            Icons.analytics_rounded,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
  'En cours',
  '${_profileData?["formations_en_cours"] ?? 0}',
  Icons.school_rounded,
  AppColors.warning,
),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                'Informations personnelles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Téléphone
          _buildInfoRow(
            Icons.phone_rounded,
            'Téléphone',
            _profileData?['phone'] ?? 'Non renseigné',
          ),

          const Divider(height: 24),

          // Bio
          _isEditing
              ? TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Biographie',
                    hintText: 'Parlez de vous...',
                  ),
                )
              : _buildInfoRow(
                  Icons.person_outline_rounded,
                  'Biographie',
                  _profileData?['bio'] ?? 'Non renseigné',
                ),

          const Divider(height: 24),

          // Secteur
          _isEditing
              ? TextFormField(
                  controller: _sectorController,
                  decoration: const InputDecoration(
                    labelText: "Secteur d'activité",
                    hintText: 'Ex: Agriculture, Digital...',
                  ),
                )
              : _buildInfoRow(
                  Icons.work_outline_rounded,
                  "Secteur d'activité",
                  _profileData?['sector'] ?? 'Non renseigné',
                ),

          const Divider(height: 24),

          // Localisation
          _isEditing
              ? TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Localisation',
                    hintText: 'Ex: Dakar, Sénégal',
                  ),
                )
              : _buildInfoRow(
                  Icons.location_on_outlined,
                  'Localisation',
                  _profileData?['location'] ?? 'Non renseigné',
                ),

          const Divider(height: 24),

          // Niveau entrepreneurial
          _isEditing
              ? DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Niveau entrepreneurial',
                  ),
                  items: _levels
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLevel = v),
                )
              : _buildInfoRow(
                  Icons.trending_up_rounded,
                  'Niveau entrepreneurial',
                  _profileData?['entrepreneurial_level'] ?? 'Non renseigné',
                ),

          const Divider(height: 24),

          // LinkedIn
          _isEditing
              ? TextFormField(
                  controller: _linkedinController,
                  decoration: const InputDecoration(
                    labelText: 'LinkedIn',
                    hintText: 'https://linkedin.com/in/...',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                )
              : _buildInfoRow(
                  Icons.link_rounded,
                  'LinkedIn',
                  _profileData?['linkedin_url'] ?? 'Non renseigné',
                ),

                const Divider(height: 24),
// CV
_isEditing
    ? TextFormField(
        initialValue: _profileData?['cv_url'] ?? '',
        decoration: const InputDecoration(
          labelText: 'Lien CV',
          hintText: 'https://drive.google.com/...',
          prefixIcon: Icon(Icons.description_rounded),
        ),
        onChanged: (v) {
          _profileData ??= {};
          _profileData!['cv_url'] = v;
        },
      )
    : GestureDetector(
        onTap: () async {
          final cvUrl = _profileData?['cv_url'];
          if (cvUrl != null && cvUrl.isNotEmpty) {
            final uri = Uri.parse(cvUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: _buildInfoRow(
          Icons.description_rounded,
          'CV',
          _profileData?['cv_url'] != null && _profileData!['cv_url']!.isNotEmpty
              ? '🔗 Voir mon CV'
              : 'Non renseigné',
        ),
      ),
          
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildSkillsSection() {
  final skills = _skills.isNotEmpty
      ? _skills
      : ((_profileData?['skills'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          []);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppColors.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compétences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

if (_isEditing) ...[
  Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: TextField(
          controller: _skillController,
          decoration: const InputDecoration(
            hintText: 'Ex: Marketing, Finance...',
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
          onSubmitted: (v) => _addSkill(v),
        ),
      ),
      const SizedBox(width: 8),
      TextButton(
        onPressed: () => _addSkill(_skillController.text),
        child: const Text('Ajouter'),
      ),
    ],
  ),
  const SizedBox(height: 12),
],

        if (skills.isEmpty && !_isEditing)
          const Text(
            'Aucune compétence renseignée',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          )
        else if (skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) {
              return Chip(
                label: Text(
                  skill,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isEditing
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
                backgroundColor: _isEditing
                    ? AppColors.errorLight
                    : AppColors.primaryLight,
                deleteIcon: _isEditing
                    ? const Icon(Icons.close_rounded,
                        size: 14, color: AppColors.error)
                    : null,
                onDeleted: _isEditing
                    ? () => _removeSkill(skill)
                    : null,
              );
            }).toList(),
          ),
      ],
    ),
  );
}

  Widget _buildLogoutButton() {
  return Material(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: _logout,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Se déconnecter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _saveProfile() async {
  final response = await ApiService.patch(
    AppUrls.me,
    {
      'bio': _bioController.text.trim(),
      'sector': _sectorController.text.trim(),
      'location': _locationController.text.trim(),
      'entrepreneurial_level': _selectedLevel,
      'linkedin_url': _linkedinController.text.trim(),
      'cv_url': _profileData?['cv_url'],
      'skills': _skills,
    },
  );

  if (!mounted) return;

  if (response['success']) {
    setState(() => _isEditing = false);
    await _loadProfile();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil mis à jour ✅'),
        backgroundColor: AppColors.success,
      ),
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
String _getRoleLabel(String role) {
  switch (role) {
    case 'entrepreneur': return 'Entrepreneur';
    case 'mentor': return 'Mentor / Coach';
    case 'financeur': return 'Financeur / Investisseur';
    case 'admin': return 'Administrateur';
    default: return role;
  }
}


Future<void> _uploadProfilePhoto() async {
  final picker = ImagePicker();

  final source = await showDialog<ImageSource>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Choisir une photo'),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, ImageSource.camera),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Caméra'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(context, ImageSource.gallery),
          icon: const Icon(Icons.photo_library_rounded),
          label: const Text('Galerie'),
        ),
      ],
    ),
  );

  if (source == null) return;

  final image = await picker.pickImage(
    source: source,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 80,
  );

  if (image == null) return;

  try {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppUrls.uploadProfilePhoto),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('photo', image.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);
    print('📸 Upload response: $data');

    if (!mounted) return;

    if (data['success'] == true) {
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil mise à jour ✅'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Erreur'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}



}