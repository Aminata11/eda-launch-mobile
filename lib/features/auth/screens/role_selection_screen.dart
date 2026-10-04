import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String selectedRole = 'entrepreneur';

  final List<Map<String, dynamic>> roles = [
    {
      'key': 'entrepreneur',
      'title': AppStrings.roleEntrepreneur,
      'description': AppStrings.roleEntrepreneurDesc,
      'icon': Icons.rocket_launch_rounded,
      'color': AppColors.entrepreneur,
    },
    {
      'key': 'mentor',
      'title': AppStrings.roleMentor,
      'description': AppStrings.roleMentorDesc,
      'icon': Icons.people_rounded,
      'color': AppColors.mentor,
    },
    {
      'key': 'financeur',
      'title': AppStrings.roleFinanceur,
      'description': AppStrings.roleFinanceurDesc,
      'icon': Icons.account_balance_rounded,
      'color': AppColors.financeur,
    },
    {
      'key': 'admin',
      'title': AppStrings.roleAdmin,
      'description': AppStrings.roleAdminDesc,
      'icon': Icons.shield_rounded,
      'color': AppColors.admin,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Logo EDA LAUNCH
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'EDA ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextSpan(
                          text: 'LAUNCH',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                AppStrings.appTagline,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),

              const SizedBox(height: 20),

              // Titre bienvenue
              const Text(
                'Bienvenue 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.welcomeSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 12),

              // Je suis
              const Text(
                'Je suis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Liste des rôles
              Expanded(
                child: ListView.separated(
                  itemCount: roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    final isSelected = selectedRole == role['key'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRole = role['key'];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (role['color'] as Color).withOpacity(0.08)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? role['color'] as Color
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icône du rôle
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: (role['color'] as Color).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                role['icon'] as IconData,
                                color: role['color'] as Color,
                                size: 24,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Titre et description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role['title'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? role['color'] as Color
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role['description'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Flèche
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: isSelected
                                  ? role['color'] as Color
                                  : AppColors.grey400,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Bouton Se connecter
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(role: selectedRole),
                    ),
                  );
                },
                child: const Text('Se connecter'),
              ),

              const SizedBox(height: 8),

              // Lien S'inscrire
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Vous n\'avez pas de compte ? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(role: selectedRole),
                        ),
                      );
                    },
                    child: const Text(
                      'S\'inscrire',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Features en bas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFeature(Icons.lock_rounded, 'Sécurisé'),
                  _buildFeature(Icons.flash_on_rounded, 'Rapide'),
                  _buildFeature(Icons.phone_android_rounded, 'Accessible'),
                  _buildFeature(Icons.language_rounded, 'Multilingue'),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}