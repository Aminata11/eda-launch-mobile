import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';
import 'module_player_screen.dart';

class FormationDetailScreen extends StatefulWidget {
  final String formationId;
  const FormationDetailScreen({super.key, required this.formationId});

  @override
  State<FormationDetailScreen> createState() => _FormationDetailScreenState();
}

class _FormationDetailScreenState extends State<FormationDetailScreen> {
  Map<String, dynamic>? _formation;
  List<dynamic> _modules = [];
  Map<String, dynamic>? _userProgress;
  bool _isLoading = true;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _loadFormation();
  }

  Future<void> _loadFormation() async {
    final response = await ApiService.get(
      AppUrls.formationById(widget.formationId),
    );

    if (mounted) {
      setState(() {
        if (response['success']) {
          _formation = response['data'];
          _modules = response['data']['modules'] as List? ?? [];
          _userProgress = response['data']['user_progress'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _enroll() async {
    setState(() => _isEnrolling = true);

    final response = await ApiService.post(
      AppUrls.enrollFormation(widget.formationId),
      {},
    );

    setState(() => _isEnrolling = false);

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription réussie ! Bonne formation !'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadFormation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateProgress(int progress) async {
    await ApiService.patch(
      AppUrls.updateProgress(widget.formationId),
      {'progress_percent': progress},
    );
    _loadFormation();
  }

void _openModule(Map<String, dynamic> module) {
  print('🎯 Ouverture module : ${module['title']} - Type: ${module['content_type']}');
  print('🎯 URL: ${module['content_url']}');
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ModulePlayerScreen(
        module: module,
        formationId: widget.formationId,
      ),
    ),
  ).then((_) => _loadFormation());
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_formation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Formation')),
        body: const Center(child: Text('Formation introuvable')),
      );
    }

    final isEnrolled = _userProgress != null;
    final progress = _userProgress?['progress_percent'] ?? 0;
    final isCompleted = _userProgress?['is_completed'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppColors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formation!['category'] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _formation!['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _formation!['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _buildStat(Icons.access_time_rounded,
                              '${_formation!['duration_minutes'] ?? 0} min'),
                          const SizedBox(width: 20),
                          _buildStat(Icons.layers_rounded,
                              '${_modules.length} modules'),
                          const SizedBox(width: 20),
                          _buildStat(Icons.bar_chart_rounded,
                              _formation!['level'] ?? ''),
                        ],
                      ),

                      if (isEnrolled) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isCompleted
                                  ? 'Formation complétée !'
                                  : 'Progression : $progress%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                            if (isCompleted)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: AppColors.grey200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contenu de la formation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_modules.isEmpty)
                        const Text(
                          'Aucun module disponible',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      else
                        ...(_modules.asMap().entries.map((entry) {
                          final index = entry.key;
                          final module = entry.value;
                          return _buildModuleItem(module, index, isEnrolled);
                        })),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: isEnrolled
            ? ElevatedButton(
                onPressed: isCompleted
                    ? null
                    : () {
                        final totalModules = _modules.length;
                        if (totalModules > 0) {
                          final newProgress =
                              (progress + (100 ~/ totalModules)).clamp(0, 100);
                          _updateProgress(newProgress);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCompleted ? AppColors.success : AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(
                  isCompleted
                      ? 'Formation complétée ✅'
                      : 'Continuer la formation',
                ),
              )
            : ElevatedButton(
                onPressed: _isEnrolling ? null : _enroll,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _isEnrolling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('S\'inscrire à cette formation'),
              ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey400),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleItem(
      Map<String, dynamic> module, int index, bool isEnrolled) {
    final contentType = module['content_type'] ?? 'video';

    IconData typeIcon;
    Color typeColor;

    switch (contentType) {
      case 'video':
        typeIcon = Icons.play_circle_rounded;
        typeColor = AppColors.error;
        break;
      case 'pdf':
        typeIcon = Icons.picture_as_pdf_rounded;
        typeColor = AppColors.warning;
        break;
      case 'quiz':
        typeIcon = Icons.quiz_rounded;
        typeColor = AppColors.primary;
        break;
      case 'podcast':
        typeIcon = Icons.headphones_rounded;
        typeColor = AppColors.mentor;
        break;
      default:
        typeIcon = Icons.article_rounded;
        typeColor = AppColors.info;
    }

    return GestureDetector(
      onTap: isEnrolled ? () => _openModule(module) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnrolled ? AppColors.white : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(typeIcon, size: 14, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        _getContentTypeLabel(contentType),
                        style: TextStyle(fontSize: 11, color: typeColor),
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

            Icon(
              isEnrolled
                  ? Icons.play_arrow_rounded
                  : Icons.lock_rounded,
              color: isEnrolled ? AppColors.primary : AppColors.grey300,
            ),
          ],
        ),
      ),
    );
  }

  String _getContentTypeLabel(String type) {
    switch (type) {
      case 'video': return 'Vidéo';
      case 'pdf': return 'PDF';
      case 'quiz': return 'Quiz';
      case 'podcast': return 'Podcast';
      case 'article': return 'Article';
      default: return type;
    }
  }
}