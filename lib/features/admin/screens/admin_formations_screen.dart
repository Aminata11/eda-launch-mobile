import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class AdminFormationsScreen extends StatefulWidget {
  const AdminFormationsScreen({super.key});

  @override
  State<AdminFormationsScreen> createState() =>
      _AdminFormationsScreenState();
}

class _AdminFormationsScreenState
    extends State<AdminFormationsScreen> {
  List<dynamic> _formations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    final response = await ApiService.get(AppUrls.formations);
    if (mounted) {
      setState(() {
        _formations = response['success']
            ? (response['data']['formations'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des formations'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _loadFormations,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFormation(),
        backgroundColor: AppColors.admin,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Nouvelle formation',
            style: TextStyle(color: AppColors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.admin))
          : _formations.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune formation créée',
                    style:
                        TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFormations,
                  color: AppColors.admin,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _formations.length,
                    itemBuilder: (context, index) {
                      return _buildFormationCard(
                          _formations[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildFormationCard(Map<String, dynamic> formation) {
    final isActive = formation['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Expanded(
                child: Text(
                  formation['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.successLight
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.success
                        : AppColors.grey500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            formation['description'] ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formation['category'] ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formation['level'] ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    _showModules(formation),
                icon: const Icon(Icons.list_rounded,
                    size: 16),
                label: const Text('Modules'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.admin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================
  // CRÉER UNE FORMATION
  // ==============================
  void _showCreateFormation() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final durationController = TextEditingController();
    String selectedCategory = 'entrepreneuriat';
    String selectedLevel = 'débutant';

    final categories = [
      'entrepreneuriat', 'leadership', 'gestion_financiere',
      'marketing', 'digital', 'agroalimentaire'
    ];
    final levels = ['débutant', 'intermédiaire', 'avancé'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
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

                const Text(
                  'Nouvelle formation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre de la formation',
                    hintText: 'Ex: Finance d\'entreprise niveau 1',
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Décrivez le contenu de la formation...',
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                  ),
                  items: categories.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c))
                  ).toList(),
                  onChanged: (v) =>
                      setStateModal(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Niveau',
                  ),
                  items: levels.map((l) =>
                    DropdownMenuItem(value: l, child: Text(l))
                  ).toList(),
                  onChanged: (v) =>
                      setStateModal(() => selectedLevel = v!),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durée totale (minutes)',
                    hintText: 'Ex: 120',
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;

                    final response = await ApiService.post(
                      AppUrls.formations,
                      {
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'category': selectedCategory,
                        'level': selectedLevel,
                        'duration_minutes': int.tryParse(
                            durationController.text) ?? 0,
                      },
                    );

                    if (!mounted) return;
                    Navigator.pop(context);

                    if (response['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Formation créée ✅'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _loadFormations();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.admin,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text('Créer la formation'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================
  // GÉRER LES MODULES
  // ==============================
  void _showModules(Map<String, dynamic> formation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminModulesScreen(
          formationId: formation['id'],
          formationTitle: formation['title'],
        ),
      ),
    ).then((_) => _loadFormations());
  }
}

// ==============================
// ÉCRAN MODULES
// ==============================
class AdminModulesScreen extends StatefulWidget {
  final String formationId;
  final String formationTitle;

  const AdminModulesScreen({
    super.key,
    required this.formationId,
    required this.formationTitle,
  });

  @override
  State<AdminModulesScreen> createState() =>
      _AdminModulesScreenState();
}

class _AdminModulesScreenState extends State<AdminModulesScreen> {
  List<dynamic> _modules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    final response = await ApiService.get(
      AppUrls.formationModules(widget.formationId),
    );
    if (mounted) {
      setState(() {
        _modules = response['success']
            ? (response['data']['modules'] as List? ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'video': return Icons.play_circle_rounded;
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'audio': return Icons.headphones_rounded;
      case 'quiz': return Icons.quiz_rounded;
      default: return Icons.article_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'video': return AppColors.error;
      case 'pdf': return AppColors.primary;
      case 'audio': return AppColors.mentor;
      case 'quiz': return AppColors.warning;
      default: return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.formationTitle),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddModule(),
        backgroundColor: AppColors.admin,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Ajouter module',
            style: TextStyle(color: AppColors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.admin))
          : _modules.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded,
                          size: 60, color: AppColors.grey300),
                      SizedBox(height: 16),
                      Text(
                        'Aucun module ajouté',
                        style: TextStyle(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _modules.length,
                  itemBuilder: (context, index) {
                    return _buildModuleCard(
                        _modules[index], index + 1);
                  },
                ),
    );
  }

  Widget _buildModuleCard(
      Map<String, dynamic> module, int order) {
    final type = module['content_type'] ?? 'text';
    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (module['duration_minutes'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${module['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '#$order',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey300,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddModule() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final durationController = TextEditingController();
    String selectedType = 'video';
    List<Map<String, dynamic>> quizQuestions = [];

    final types = [
      {'key': 'video', 'label': 'Vidéo', 'icon': Icons.play_circle_rounded},
      {'key': 'pdf', 'label': 'PDF', 'icon': Icons.picture_as_pdf_rounded},
      {'key': 'audio', 'label': 'Audio', 'icon': Icons.headphones_rounded},
      {'key': 'quiz', 'label': 'Quiz', 'icon': Icons.quiz_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
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

                const Text(
                  'Ajouter un module',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Type de module
                const Text(
                  'Type de contenu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: types.map((t) {
                    final isSelected = selectedType == t['key'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setStateModal(
                            () => selectedType = t['key'] as String),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.admin.withOpacity(0.1)
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.admin
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                t['icon'] as IconData,
                                color: isSelected
                                    ? AppColors.admin
                                    : AppColors.grey400,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t['label'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? AppColors.admin
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre du module',
                    hintText: 'Ex: Introduction à la finance',
                  ),
                ),

                const SizedBox(height: 16),

                // URL selon le type
                if (selectedType != 'quiz') ...[
                  TextFormField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: selectedType == 'video'
                          ? 'Lien YouTube'
                          : selectedType == 'pdf'
                              ? 'Lien PDF'
                              : 'Lien Audio',
                      hintText: selectedType == 'video'
                          ? 'https://youtube.com/...'
                          : 'https://...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Durée (minutes)',
                      hintText: 'Ex: 15',
                    ),
                  ),
                ],

                // Quiz
                if (selectedType == 'quiz') ...[
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Questions du quiz',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setStateModal(() {
                            quizQuestions.add({
                              'question': '',
                              'options': ['', '', '', ''],
                              'correct_answer': 0,
                            });
                          });
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),

                  ...quizQuestions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final q = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: q['question'],
                            decoration: const InputDecoration(
                              hintText: 'Entrez la question...',
                            ),
                            onChanged: (v) => q['question'] = v,
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(4, (optIndex) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: optIndex,
                                    groupValue: q['correct_answer'],
                                    activeColor: AppColors.success,
                                    onChanged: (v) => setStateModal(
                                        () => q['correct_answer'] = v),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: q['options'][optIndex],
                                      decoration: InputDecoration(
                                        hintText: 'Option ${optIndex + 1}',
                                        isDense: true,
                                      ),
                                      onChanged: (v) =>
                                          q['options'][optIndex] = v,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;

                    final body = {
                      'title': titleController.text.trim(),
                      'content_type': selectedType,
                      'content_url': urlController.text.trim(),
                      'duration_minutes': int.tryParse(
                          durationController.text) ?? 0,
                      'order_index': _modules.length + 1,
                    };

                    if (selectedType == 'quiz' &&
                        quizQuestions.isNotEmpty) {
                      body['quiz_questions'] =
                          quizQuestions as dynamic;
                    }

                    final response = await ApiService.post(
                      AppUrls.formationModules(
                          widget.formationId),
                      body,
                    );

                    if (!mounted) return;
                    Navigator.pop(context);

                    if (response['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Module ajouté ✅'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _loadModules();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response['message'] ??
                              'Erreur'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.admin,
                    minimumSize:
                        const Size(double.infinity, 52),
                  ),
                  child: const Text('Ajouter le module'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}