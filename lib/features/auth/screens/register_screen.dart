import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});
  

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Validation mot de passe
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUpperCase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _passwordController.text.contains(RegExp(r'[!@#$%^&*]'));

  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await ApiService.post(
      AppUrls.register,
      {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': '+221${_phoneController.text.trim().replaceAll(' ', '')}',
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': _selectedRole,
      },
      isPublic: true,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success']) {
      final data = response['data'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            userId: data['user_id'],
            otpType: data['otp_type'],
            contact: data['otp_sent_to'],
          ),
        ),
      );
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

                // Retour + langue
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

                // Tabs rôles
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      {'key': 'entrepreneur', 'label': 'Entrepreneur', 'color': AppColors.entrepreneur, 'icon': Icons.rocket_launch_rounded},
                      {'key': 'mentor', 'label': 'Mentor', 'color': AppColors.mentor, 'icon': Icons.people_rounded},
                      {'key': 'financeur', 'label': 'Financeur', 'color': AppColors.financeur, 'icon': Icons.account_balance_rounded},
                      {'key': 'admin', 'label': 'Admin', 'color': AppColors.admin, 'icon': Icons.shield_rounded},
                    ].map((role) {
  final isSelected = _selectedRole == role['key'];
  return GestureDetector(
    onTap: () => setState(() => _selectedRole = role['key'] as String),
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

                // Titre
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Remplissez les informations pour créer votre compte',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Informations personnelles
                const Text(
                  'Informations personnelles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Nom complet
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    hintText: 'Entrez votre prénom',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppColors.grey400),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Prénom obligatoire' : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Entrez votre nom',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppColors.grey400),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nom obligatoire' : null,
                ),

                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    hintText: '77 123 45 67',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🇸🇳',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 4),
                          const Text('+221',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: AppColors.grey400),
                        ],
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Téléphone obligatoire' : null,
                ),

                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Entrez votre email',
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        color: AppColors.grey400),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email obligatoire';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Créez un mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.grey400),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe obligatoire';
                    if (!_hasMinLength || !_hasUpperCase || !_hasNumber || !_hasSpecial) {
                      return 'Mot de passe trop faible';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Indicateurs validation mot de passe
                _buildPasswordIndicator(_hasMinLength, '8 caractères minimum'),
                _buildPasswordIndicator(_hasUpperCase, 'Une lettre majuscule'),
                _buildPasswordIndicator(_hasNumber, 'Un chiffre'),
                _buildPasswordIndicator(_hasSpecial, 'Un caractère spécial'),

                const SizedBox(height: 32),

                // Bouton continuer
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Continuer'),
                ),

                const SizedBox(height: 16),

                // Lien connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Vous avez déjà un compte ? ',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Se connecter',
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

  Widget _buildPasswordIndicator(bool isValid, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: isValid ? AppColors.success : AppColors.grey400,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
