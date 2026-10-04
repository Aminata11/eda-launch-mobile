import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import 'entrepreneur_profile_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _selectedRole = 'tous';

  final List<Map<String, dynamic>> _roleFilters = [
    {'key': 'tous', 'label': 'Tous'},
    {'key': 'entrepreneur', 'label': 'Entrepreneurs'},
    {'key': 'mentor', 'label': 'Mentors'},
    {'key': 'financeur', 'label': 'Financeurs'},
    {'key': 'admin', 'label': 'Admins'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final response = await ApiService.get(
      '${AppUrls.baseUrl}/auth/users',
    );
    if (mounted) {
      setState(() {
        _users = response['success']
            ? (response['data']['users'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredUsers {
    if (_selectedRole == 'tous') return _users;
    return _users.where((u) => u['role'] == _selectedRole).toList();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'entrepreneur': return AppColors.entrepreneur;
      case 'mentor': return AppColors.mentor;
      case 'financeur': return AppColors.financeur;
      case 'admin': return AppColors.admin;
      default: return AppColors.grey500;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'entrepreneur': return 'Entrepreneur';
      case 'mentor': return 'Mentor';
      case 'financeur': return 'Financeur';
      case 'admin': return 'Admin';
      default: return role;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'entrepreneur': return Icons.rocket_launch_rounded;
      case 'mentor': return Icons.people_rounded;
      case 'financeur': return Icons.account_balance_rounded;
      case 'admin': return Icons.shield_rounded;
      default: return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.admin))
          : Column(
              children: [
                // Filtres rôles
                Container(
                  color: AppColors.white,
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _roleFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _roleFilters[index];
                      final isSelected = _selectedRole == filter['key'];
                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedRole = filter['key']),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.admin
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filter['label'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Compteur
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredUsers.length} utilisateur(s)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste utilisateurs
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun utilisateur',
                            style: TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          color: AppColors.admin,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              return _buildUserCard(
                                  _filteredUsers[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? '';
    final roleColor = _getRoleColor(role);
    final roleIcon = _getRoleIcon(role);
    final isVerified = user['is_verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Avatar rôle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(roleIcon, color: roleColor, size: 24),
          ),

          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${user['first_name']} ${user['last_name']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (user['phone'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user['phone'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getRoleLabel(role),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statut vérifié
         // Menu actions
PopupMenuButton<String>(
  onSelected: (value) async {
    if (value == 'details') {
  _showUserDetails(user);
} /*else if (value == 'verify') {
  // À implémenter
}*/
  },
  itemBuilder: (_) => [
    PopupMenuItem(
      value: 'details',
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          const Text('Voir détails'),
        ],
      ),
    ),
    /*if (!isVerified)
      PopupMenuItem(
        value: 'verify',
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            const Text('Vérifier'),
          ],
        ),
      ),*/
  ],
  child: const Icon(
    Icons.more_vert_rounded,
    color: AppColors.grey400,
  ),
),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
  final role = user['role'] ?? '';
  final roleColor = _getRoleColor(role);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar + nom
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_getRoleIcon(role), color: roleColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${user['first_name']} ${user['last_name']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user['is_verified'] == true) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: AppColors.primary, size: 18),
                        ],
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRoleLabel(role),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Infos
          _buildDetailRow(Icons.email_rounded, 'Email', user['email'] ?? ''),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.phone_rounded, 'Téléphone', user['phone'] ?? 'Non renseigné'),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.check_circle_rounded,
            'Statut',
            user['is_verified'] == true ? 'Vérifié ✅' : 'Non vérifié ⏳',
          ),

          // Profil complet si entrepreneur
if (user['role'] == 'entrepreneur') ...[
  const SizedBox(height: 16),
  const Divider(),
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
  Navigator.pop(context);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EntrepreneurProfileScreen(
        entrepreneurId: user['id'],
        entrepreneurName:
            '${user['first_name']} ${user['last_name']}',
      ),
    ),
  );
},
      icon: const Icon(Icons.person_rounded),
      label: const Text('Voir profil complet'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 46),
      ),
    ),
  ),
],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ],
  );
}

}