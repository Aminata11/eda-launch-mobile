import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class EntrepreneurProfileScreen extends StatefulWidget {
  final String entrepreneurId;
  final String entrepreneurName;

  const EntrepreneurProfileScreen({
    super.key,
    required this.entrepreneurId,
    required this.entrepreneurName,
  });

  @override
  State<EntrepreneurProfileScreen> createState() =>
      _EntrepreneurProfileScreenState();
}

class _EntrepreneurProfileScreenState
    extends State<EntrepreneurProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final response = await ApiService.get(
      AppUrls.userProfile(widget.entrepreneurId),
    );
    if (mounted) {
      setState(() {
        _profile = response['success'] ? response['data'] : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _profile == null
              ? const Center(child: Text('Profil introuvable'))
              : CustomScrollView(
                  slivers: [
                    // Header
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      backgroundColor: AppColors.primary,
                      leading: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: AppColors.white),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF6C2BD9),
                                Color(0xFF4F1DA1)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white38, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${_profile!['first_name']} ${_profile!['last_name']}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _profile!['email'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Infos générales
                            _buildSection(
                              'Informations générales',
                              Icons.info_rounded,
                              [
                                _buildInfoRow(Icons.phone_rounded,
                                    'Téléphone',
                                    _profile!['phone'] ?? 'Non renseigné'),
                                _buildInfoRow(Icons.work_rounded,
                                    'Secteur',
                                    _profile!['sector'] ?? 'Non renseigné'),
                                _buildInfoRow(
                                    Icons.location_on_rounded,
                                    'Localisation',
                                    _profile!['location'] ??
                                        'Non renseigné'),
                                _buildInfoRow(
                                    Icons.trending_up_rounded,
                                    'Niveau entrepreneurial',
                                    _profile!['entrepreneurial_level'] ??
                                        'Non renseigné'),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Biographie
                            if (_profile!['bio'] != null)
                              _buildSection(
                                'Biographie',
                                Icons.person_outline_rounded,
                                [
                                  Text(
                                    _profile!['bio'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 16),

                            // Compétences
                            _buildSection(
                              'Compétences',
                              Icons.star_rounded,
                              [
                                if ((_profile!['skills'] as List?)
                                        ?.isEmpty ??
                                    true)
                                  const Text('Aucune compétence renseignée',
                                      style: TextStyle(
                                          color: AppColors.textSecondary))
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        (_profile!['skills'] as List)
                                            .map((s) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.primaryLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    s.toString(),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Liens
                            _buildSection(
                              'Liens',
                              Icons.link_rounded,
                              [
                                _buildInfoRow(
                                    Icons.link_rounded,
                                    'LinkedIn',
                                    _profile!['linkedin_url'] ??
                                        'Non renseigné'),
                                _buildInfoRow(
                                    Icons.description_rounded,
                                    'CV',
                                    _profile!['cv_url'] ?? 'Non renseigné'),
                              ],
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, List<Widget> children) {
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
              Icon(icon, color: AppColors.primary, size: 18),
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.grey400),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}