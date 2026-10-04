import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class MentoringScreen extends StatefulWidget {
  const MentoringScreen({super.key});

  @override
  State<MentoringScreen> createState() => _MentoringScreenState();
}

class _MentoringScreenState extends State<MentoringScreen> {
  List<Map<String, dynamic>> _mentorProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMentoringData();
  }

  Future<void> _loadMentoringData() async {
    final projectsResponse = await ApiService.get(AppUrls.projects);

    if (mounted) {
      final projects = projectsResponse['success']
          ? (projectsResponse['data']['projects'] as List? ?? [])
          : [];

      // Tous les projets avec mentor assigné
      final mentorProjects = projects
          .where((p) => p['mentor_id'] != null)
          .toList();

      // Récupère les notes pour chaque projet
      List<Map<String, dynamic>> result = [];
      for (final p in mentorProjects) {
        final notesResponse = await ApiService.get(
          AppUrls.coachingNotes(p['id']),
        );
        final notes = notesResponse['success']
            ? (notesResponse['data']['notes'] as List? ?? [])
            : [];

        result.add({
          'project': p,
          'notes': notes,
        });
      }

      setState(() {
        _mentorProjects = result;
        _isLoading = false;
      });
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 16) return AppColors.success;
    if (score >= 12) return AppColors.mentor;
    if (score >= 8) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Mentorat'),
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.mentor))
          : _mentorProjects.isEmpty
              ? _buildNoMentor()
              : RefreshIndicator(
                  onRefresh: _loadMentoringData,
                  color: AppColors.mentor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _mentorProjects.length,
                    itemBuilder: (context, index) {
                      return _buildProjectMentoringCard(
                          _mentorProjects[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildNoMentor() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.people_outline_rounded,
                  size: 50, color: AppColors.grey400),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun mentor assigné',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Un mentor vous sera assigné après la soumission et l\'approbation de votre projet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectMentoringCard(Map<String, dynamic> data) {
    final project = data['project'] as Map;
    final notes = data['notes'] as List;

    double moyenneScore = 0;
    if (notes.isNotEmpty) {
      final scores = notes
          .where((n) => n['score'] != null)
          .map((n) => (n['score'] as num).toDouble())
          .toList();
      if (scores.isNotEmpty) {
        moyenneScore = scores.reduce((a, b) => a + b) / scores.length;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Header projet + mentor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A7A4A), Color(0xFF15693E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.people_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project['mentor_name'] ?? 'Mentor',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Mentor — ${project['name']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (notes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${moyenneScore.toStringAsFixed(1)}/20',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Notes de coaching
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notes de coaching',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${notes.length} note(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (notes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Aucune note de coaching pour le moment',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13),
                    ),
                  )
                else
                  ...notes.map((note) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  note['created_at']
                                          ?.toString()
                                          .substring(0, 10) ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (note['score'] != null)
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(
                                              note['score'] as int)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${note['score']}/20',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getScoreColor(
                                            note['score'] as int),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              note['note'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          // Bouton contact mentor
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (project['mentor_email'] != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Contacter le mentor'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.email_rounded,
                                        color: AppColors.mentor, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        project['mentor_email'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                if (project['mentor_phone'] != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded,
                                          color: AppColors.mentor, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        project['mentor_phone'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.contact_mail_rounded,
                          color: AppColors.mentor, size: 18),
                      label: const Text('Contacter',
                          style: TextStyle(color: AppColors.mentor)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.mentor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              if (project['id'] != null) {
                _sendMessageToMentor(project['id'].toString());
              }
            },
            icon: const Icon(Icons.message_rounded, size: 18),
            label: const Text('Écrire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mentor,
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _sendMessageToMentor(String projectId) async {
  final messageController = TextEditingController();

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Message au mentor'),
      content: TextField(
        controller: messageController,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Décrivez votre problème ou question...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (messageController.text.trim().isEmpty) return;
            Navigator.pop(context);

            final response = await ApiService.post(
              AppUrls.messageToMentor(projectId),
              {'message': messageController.text.trim()},
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['success']
                    ? 'Message envoyé au mentor ✅'
                    : response['message']),
                backgroundColor: response['success']
                    ? AppColors.success
                    : AppColors.error,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mentor,
          ),
          child: const Text('Envoyer'),
        ),
      ],
    ),
  );
}
}