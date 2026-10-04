import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class ScoringScreen extends StatefulWidget {
  final String? projectId;
  const ScoringScreen({super.key, this.projectId});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  List<dynamic> _questions = [];
  Map<String, Map<String, int>> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _currentCriteria = 0;

  final List<Map<String, dynamic>> _criteria = [
    {'key': 'innovation', 'label': 'Innovation', 'icon': '💡', 'color': AppColors.warning},
    {'key': 'feasibility', 'label': 'Faisabilité', 'icon': '⚙️', 'color': AppColors.info},
    {'key': 'impact', 'label': 'Impact Social', 'icon': '🌍', 'color': AppColors.success},
    {'key': 'profitability', 'label': 'Rentabilité', 'icon': '💰', 'color': AppColors.secondary},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestionnaire();
  }

  Future<void> _loadQuestionnaire() async {
  try {
    final response = await ApiService.get(AppUrls.questionnaire);
    
    if (mounted) {
      if (response['success'] && response['data'] != null) {
        setState(() {
          _questions = [response['data']];
          _isLoading = false;
        });
      } else {
        // Retry après 2 secondes
        await Future.delayed(const Duration(seconds: 2));
        final retryResponse = await ApiService.get(AppUrls.questionnaire);
        if (mounted) {
          setState(() {
            _questions = retryResponse['success'] && retryResponse['data'] != null
                ? [retryResponse['data']]
                : [];
            _isLoading = false;
          });
        }
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _submitDiagnostic() async {
    if (widget.projectId == null) return;

    setState(() => _isSubmitting = true);

    // Convertit les réponses au bon format
    final answers = {};
    _answers.forEach((criteriaKey, questionAnswers) {
      answers[criteriaKey] = {};
      questionAnswers.forEach((questionId, answerIndex) {
        answers[criteriaKey][questionId] = answerIndex;
      });
    });

    final response = await ApiService.post(
      AppUrls.createDiagnostic(widget.projectId!),
      {'answers': answers},
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (response['success']) {
      final data = response['data'];
      _showResults(data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showResults(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Résultat du diagnostic',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Score global
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: (data['scores']['global'] ?? 0) / 100,
                        strokeWidth: 12,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.getScoreColor(data['scores']['global'] ?? 0),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${data['scores']['global'] ?? 0}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getScoreColor(
                                data['scores']['global'] ?? 0),
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                data['level'] ?? '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getScoreColor(
                      data['scores']['global'] ?? 0),
                ),
              ),

              const SizedBox(height: 24),

              // Scores par critère
              ...['innovation', 'feasibility', 'impact', 'profitability']
                  .map((key) {
                final labels = {
                  'innovation': '💡 Innovation',
                  'feasibility': '⚙️ Faisabilité',
                  'impact': '🌍 Impact Social',
                  'profitability': '💰 Rentabilité',
                };
                final score = data['scores'][key] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          labels[key] ?? key,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: score / 100,
                            backgroundColor: AppColors.grey200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.getScoreColor(score),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$score/100',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getScoreColor(score),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Voir mon projet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnostic & Scoring'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _buildQuestionnaire(),
    );
  }

  Widget _buildQuestionnaire() {
    if (_questions.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 60, color: AppColors.error),
        const SizedBox(height: 16),
        const Text(
          'Questionnaire non disponible',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vérifiez votre connexion et réessayez',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            setState(() => _isLoading = true);
            _loadQuestionnaire();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Réessayer'),
        ),
      ],
    ),
  );
}

    final data = _questions[0] as Map<String, dynamic>;
    final criteriaKey = _criteria[_currentCriteria]['key'] as String;
    final criteriaLabel = _criteria[_currentCriteria]['label'] as String;
    final criteriaIcon = _criteria[_currentCriteria]['icon'] as String;
    final criteriaColor = _criteria[_currentCriteria]['color'] as Color;
    final questions = (data[criteriaKey]['questions'] as List?) ?? [];

    return Column(
      children: [
        // Progression
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$criteriaIcon $criteriaLabel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: criteriaColor,
                    ),
                  ),
                  Text(
                    '${_currentCriteria + 1}/${_criteria.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentCriteria + 1) / _criteria.length,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(criteriaColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        // Questions
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index] as Map<String, dynamic>;
              final questionId = question['id'] as String;
              final options = question['options'] as List;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}. ${question['question']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...options.asMap().entries.map((entry) {
                      final optionIndex = entry.key;
                      final option = entry.value as Map<String, dynamic>;
                      final isSelected = _answers[criteriaKey]?[questionId] == optionIndex;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _answers[criteriaKey] ??= {};
                            _answers[criteriaKey]![questionId] = optionIndex;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? criteriaColor.withOpacity(0.1)
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? criteriaColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? criteriaColor
                                        : AppColors.grey400,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? criteriaColor
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 12,
                                        color: AppColors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  option['label'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? criteriaColor
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),

        // Boutons navigation
        Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.white,
          child: Row(
            children: [
              if (_currentCriteria > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _currentCriteria--),
                    child: const Text('Précédent'),
                  ),
                ),
              if (_currentCriteria > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_currentCriteria < _criteria.length - 1) {
                            setState(() => _currentCriteria++);
                          } else {
                            _submitDiagnostic();
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentCriteria < _criteria.length - 1
                              ? 'Suivant →'
                              : 'Obtenir mon score',
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}