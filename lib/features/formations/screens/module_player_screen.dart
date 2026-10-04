import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/services/api_service.dart';

class ModulePlayerScreen extends StatefulWidget {
  final Map<String, dynamic> module;
  final String formationId;

  const ModulePlayerScreen({
    super.key,
    required this.module,
    required this.formationId,
  });

  @override
  State<ModulePlayerScreen> createState() => _ModulePlayerScreenState();
}

class _ModulePlayerScreenState extends State<ModulePlayerScreen> {
  WebViewController? _webViewController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _pdfPath;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final type = widget.module['content_type'] ?? '';
    final url = widget.module['content_url'] ?? '';
    print('🎬 Type: $type');
  print('🎬 URL: $url');

    if (type == 'video' && url.isNotEmpty) {
  String embedUrl = url;
  bool isYoutube = false;

  if (url.contains('youtube.com/watch?v=')) {
    final videoId = url.split('v=')[1].split('&')[0];
    embedUrl = 'https://www.youtube.com/embed/$videoId';
    isYoutube = true;
  } else if (url.contains('youtu.be/')) {
    final videoId = url.split('youtu.be/')[1].split('?')[0];
    embedUrl = 'https://www.youtube.com/embed/$videoId';
    isYoutube = true;
  } else if (url.contains('youtube.com/shorts/')) {
    final videoId = url.split('/').last.split('?')[0];
    embedUrl = 'https://www.youtube.com/embed/$videoId';
    isYoutube = true;
  }

  _webViewController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.contains('youtube.com') ||
              request.url.contains('youtu.be') ||
              request.url.contains('amazonaws.com') ||
              request.url.contains('about:blank')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ),
    )
    ..loadHtmlString('''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; }
          body { background: #000; }
          video { width: 100vw; height: 100vh; object-fit: contain; }
          iframe { width: 100vw; height: 100vh; border: none; }
        </style>
      </head>
      <body>
        ${isYoutube ? 
          '<iframe src="$embedUrl?playsinline=1" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>' :
          '<video controls src="$embedUrl" playsinline></video>'
        }
      </body>
      </html>
    ''');
  setState(() {});
} else if (type == 'audio' || type == 'podcast') {
      _audioPlayer = AudioPlayer();
      try {
        await _audioPlayer!.setUrl(url);
        _audioPlayer!.durationStream.listen((d) {
          if (mounted) setState(() => _audioDuration = d ?? Duration.zero);
        });
        _audioPlayer!.positionStream.listen((p) {
          if (mounted) setState(() => _audioPosition = p);
        });
        _audioPlayer!.playerStateStream.listen((state) {
          if (mounted) setState(() => _isPlaying = state.playing);
        });
      } catch (e) {
        debugPrint('Audio error: $e');
      }

    } else if (type == 'pdf' && url.isNotEmpty) {
      setState(() => _isLoading = true);
      print('📄 Téléchargement PDF depuis : $url');
      try {
        final response = await http.get(Uri.parse(url));
        print('📄 Status code : ${response.statusCode}');
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/module.pdf');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _pdfPath = file.path;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _markAsCompleted() async {
    await ApiService.patch(
      '${AppUrls.baseUrl}/formations/${widget.formationId}/progress',
      {'module_id': widget.module['id'], 'completed': true},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Module complété ✅'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.module['content_type'] ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.module['title'] ?? ''),
        backgroundColor: type == 'video' ? Colors.black : AppColors.white,
        foregroundColor: type == 'video' ? AppColors.white : AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: _buildContent(type),
      bottomNavigationBar: type != 'quiz'
          ? Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.white,
              child: ElevatedButton.icon(
                onPressed: _markAsCompleted,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Marquer comme complété'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.success,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(String type) {
    switch (type) {
      case 'video': return _buildVideoPlayer();
      case 'pdf': return _buildPdfViewer();
      case 'audio':
      case 'podcast': return _buildAudioPlayer();
      case 'quiz': return _buildQuiz();
      default: return const Center(child: Text('Type non supporté'));
    }
  }

 Widget _buildVideoPlayer() {
  final url = widget.module['content_url'] ?? '';
  String videoId = '';
  
  if (url.contains('youtube.com/watch?v=')) {
    videoId = url.split('v=')[1].split('&')[0];
  } else if (url.contains('youtu.be/')) {
    videoId = url.split('youtu.be/')[1].split('?')[0];
  }

  final thumbnailUrl = videoId.isNotEmpty
      ? 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg'
      : '';

  return Column(
    children: [
      // Vignette YouTube
      GestureDetector(
        onTap: () async {
          // Ouvre dans le WebView interne
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: Text(widget.module['title'] ?? ''),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                backgroundColor: Colors.black,
                body: WebViewWidget(
                  controller: WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/91.0.4472.120 Mobile Safari/537.36')
                    ..loadRequest(Uri.parse(url)),
                ),
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            videoId.isNotEmpty
                ? Image.network(
                    thumbnailUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: Colors.black,
                      child: const Icon(Icons.play_circle_outline,
                          color: Colors.white, size: 80),
                    ),
                  )
                : Container(
                    height: 220,
                    color: Colors.black,
                  ),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(35),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 45,
              ),
            ),
          ],
        ),
      ),

      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.module['title'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.module['duration_minutes'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 16, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.module['duration_minutes']} minutes',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_rounded,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cliquez sur la vidéo pour la regarder.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
  Widget _buildPdfViewer() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Chargement du PDF...'),
          ],
        ),
      );
    }
    if (_pdfPath == null) {
      return const Center(
        child: Text('Impossible de charger le PDF',
            style: TextStyle(color: AppColors.error)),
      );
    }
    return PDFView(filePath: _pdfPath!);
  }

  Widget _buildAudioPlayer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150, height: 150,
            decoration: BoxDecoration(
              color: AppColors.mentorLight,
              borderRadius: BorderRadius.circular(75),
            ),
            child: const Icon(Icons.headphones_rounded,
                color: AppColors.mentor, size: 80),
          ),
          const SizedBox(height: 32),
          Text(
            widget.module['title'] ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Slider(
            value: _audioPosition.inSeconds.toDouble(),
            min: 0,
            max: _audioDuration.inSeconds.toDouble() > 0
                ? _audioDuration.inSeconds.toDouble()
                : 1,
            activeColor: AppColors.mentor,
            onChanged: (v) =>
                _audioPlayer?.seek(Duration(seconds: v.toInt())),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_audioPosition),
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.textSecondary)),
                Text(_formatDuration(_audioDuration),
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  final p = _audioPosition - const Duration(seconds: 10);
                  _audioPlayer?.seek(p < Duration.zero ? Duration.zero : p);
                },
                icon: const Icon(Icons.replay_10_rounded, size: 36),
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _isPlaying
                    ? _audioPlayer?.pause()
                    : _audioPlayer?.play(),
                child: Container(
                  width: 70, height: 70,
                  decoration: const BoxDecoration(
                    color: AppColors.mentor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: AppColors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () {
                  _audioPlayer?.seek(
                      _audioPosition + const Duration(seconds: 10));
                },
                icon: const Icon(Icons.forward_10_rounded, size: 36),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final questions = widget.module['quiz_questions'];
    if (questions == null) {
      return const Center(
        child: Text('Aucune question disponible',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final quizList = questions as List;
    final Map<int, int> selectedAnswers = {};

    return StatefulBuilder(
      builder: (context, setStateQuiz) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quiz',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...quizList.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value as Map;
              final options = q['options'] as List;
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${i + 1} : ${q['question']}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...options.asMap().entries.map((opt) {
                      final optIndex = opt.key;
                      final isSelected = selectedAnswers[i] == optIndex;
                      return GestureDetector(
                        onTap: () => setStateQuiz(
                            () => selectedAnswers[i] = optIndex),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.grey300,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: AppColors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(opt.value.toString(),
                                      style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (selectedAnswers.length < quizList.length) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Répondez à toutes les questions'),
                        backgroundColor: AppColors.warning),
                  );
                  return;
                }
                int correct = 0;
                for (int i = 0; i < quizList.length; i++) {
                  final q = quizList[i] as Map;
                  if (selectedAnswers[i] == q['correct_answer']) correct++;
                }
                final score = (correct / quizList.length * 100).round();
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Résultat'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$correct/${quizList.length}',
                            style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: score >= 60
                                    ? AppColors.success
                                    : AppColors.error)),
                        Text('$score%',
                            style: TextStyle(
                                fontSize: 24,
                                color: score >= 60
                                    ? AppColors.success
                                    : AppColors.error)),
                        const SizedBox(height: 8),
                        Text(score >= 60
                            ? '🎉 Félicitations !'
                            : '😔 Réessayez !',
                            textAlign: TextAlign.center),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (score >= 60) _markAsCompleted();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: score >= 60
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        child: Text(score >= 60 ? 'Terminer' : 'Réessayer'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Soumettre'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.warning,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}