import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import 'register_screen.dart';
import 'otp_screen.dart';
import '../../dashboard/screens/entrepreneur_dashboard_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../financeur/screens/financeur_dashboard_screen.dart';
import '../../mentor/screens/mentor_dashboard_screen.dart';
import 'complete_profile_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String _selectedRole = '';

  final List<Map<String, dynamic>> _roles = [
    {'key': 'entrepreneur', 'label': 'Entrepreneur', 'color': AppColors.entrepreneur, 'icon': Icons.rocket_launch_rounded},
    {'key': 'mentor', 'label': 'Mentor', 'color': AppColors.mentor, 'icon': Icons.people_rounded},
    {'key': 'financeur', 'label': 'Financeur', 'color': AppColors.financeur, 'icon': Icons.account_balance_rounded},
    {'key': 'admin', 'label': 'Admin', 'color': AppColors.admin, 'icon': Icons.shield_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await ApiService.post(
      AppUrls.login,
      {
        'identifier': _identifierController.text.trim(),
        'password': _passwordController.text,
        'role': _selectedRole,
      },
      isPublic: true,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success']) {
      // Sauvegarde le token
      await ApiService.saveToken(response['data']['token']);

      // Navigue vers le dashboard selon le rôle
      final role = response['data']['user']['role'];
      _navigateToDashboard(role);
    } else {
      // Vérifie si compte non vérifié
      if (response['statusCode'] == 403) {
        final data = response['data'];
        if (data != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                userId: data['user_id'],
                otpType: data['otp_type'],
                contact: _identifierController.text.trim(),
              ),
            ),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

Future<void> _navigateToDashboard(String role) async {
  Widget dashboard;
  
  switch (role) {
    case 'admin':
      dashboard = const AdminDashboardScreen();
      break;
    case 'financeur':
      dashboard = const FinanceurDashboardScreen();
      break;
    case 'mentor':
      dashboard = const MentorDashboardScreen();
      break;
    case 'entrepreneur':
    default:
      // Vérifie si le profil est complet
      final profileResponse = await ApiService.get(AppUrls.me);
      if (profileResponse['success']) {
        final profile = profileResponse['data'];
        final isProfileComplete =
          profile['bio'] != null &&
          profile['sector'] != null &&
          profile['location'] != null &&
          profile['entrepreneurial_level'] != null &&
          profile['linkedin_url'] != null &&
          profile['cv_url'] != null &&
          (profile['skills'] as List?)?.isNotEmpty == true;

        dashboard = isProfileComplete
            ? const EntrepreneurDashboardScreen()
            : const CompleteProfileScreen();
      } else {
        dashboard = const EntrepreneurDashboardScreen();
      }
      break;
  }

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => dashboard),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Bouton retour + langue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.language_rounded,
                              size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Text('Français',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Titre
                const Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connectez-vous à votre compte',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Tabs des rôles
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roles.map((role) {
                      final isSelected = _selectedRole == role['key'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRole = role['key']),
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected
                                    ? role['color'] as Color
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                role['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? role['color'] as Color
                                    : AppColors.grey400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                role['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? role['color'] as Color
                                      : AppColors.grey400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),

                // Champ email/téléphone
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email ou téléphone',
                    hintText: 'Entrez votre email ou téléphone',
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        color: AppColors.grey400),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est obligatoire';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Champ mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Entrez votre mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.grey400),
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est obligatoire';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Se souvenir + mot de passe oublié
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                        ),
                        const Text(
                          'Se souvenir de moi',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Bouton connexion
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Se connecter'),
                ),

                const SizedBox(height: 24),

                // Ou continuer avec
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou continuer avec',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 16),

                // Boutons sociaux
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                        label: const Text('Google'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.facebook_rounded, size: 24),
                        label: const Text('Facebook'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bouton Apple
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.apple_rounded, size: 24),
                  label: const Text('Apple'),
                ),

                const SizedBox(height: 24),

                // Lien inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Vous n\'avez pas de compte ? ',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RegisterScreen(role: _selectedRole),
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

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
