import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';

class Task {
  String title;
  DateTime? dueDate;
  bool isDone;

  Task({required this.title, this.dueDate, this.isDone = false});
}

class ReminderProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  void addTask(Task task) {
    bool exists = _tasks.any((t) =>
        t.title == task.title &&
        t.dueDate?.compareTo(task.dueDate ?? DateTime(0)) == 0);
    if (!exists) {
      _tasks.add(task);
      notifyListeners();
    }
  }

  void toggleTaskDone(int index) {
    _tasks[index].isDone = !_tasks[index].isDone;
    notifyListeners();
  }
}

String normalizeMonthAbbreviations(String text) {
  final monthAbbrMap = {
    'Jan': 'January',
    'Feb': 'February',
    'Mar': 'March',
    'Apr': 'April',
    'May': 'May',
    'Jun': 'June',
    'Jul': 'July',
    'Aug': 'August',
    'Sep': 'September',
    'Sept': 'September',
    'Oct': 'October',
    'Nov': 'November',
    'Dec': 'December',
  };

  monthAbbrMap.forEach((abbr, full) {
    // Replace only whole word matches, case-insensitive
    final regex = RegExp(r'\b' + abbr + r'\b', caseSensitive: false);
    text = text.replaceAll(regex, full);
  });

  return text;
}


List<Task> extractReminders(String text) {
  text = normalizeMonthAbbreviations(text);
  
  List<Task> tasks = [];
  final regex = RegExp(
    r'\b(project submission|assignment|test|exam)\b(?:\s+([A-Za-z0-9 ]+?))?\s*(?:due|on|by)?\s*(\d{1,2}\s(?:January|February|March|April|May|June|July|August|September|October|November|December)\s\d{4})',
    caseSensitive: false,
  );

  for (final match in regex.allMatches(text)) {
    final type = match.group(1)?.trim() ?? '';
    final titleCandidate = match.group(2)?.trim() ?? '';
    final dateStr = match.group(3);

    String cleanTitle;
    if (type.toLowerCase() == 'project submission' && titleCandidate.isNotEmpty) {
      cleanTitle = 'Project Submission: $titleCandidate';
    } else if (type.isNotEmpty && titleCandidate.isNotEmpty) {
      cleanTitle = '${type[0].toUpperCase()}${type.substring(1)}: $titleCandidate';
    } else if (type.isNotEmpty) {
      cleanTitle = '${type[0].toUpperCase()}${type.substring(1)}';
    } else {
      cleanTitle = 'Reminder';
    }

    try {
      if (dateStr != null) {
        final parsedDate = DateFormat('d MMMM yyyy').parse(dateStr);
        tasks.add(Task(title: cleanTitle, dueDate: parsedDate));
      } else {
        tasks.add(Task(title: cleanTitle));
      }
    } catch (_) {
      tasks.add(Task(title: cleanTitle));
    }
  }

  return tasks;
}



void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ReminderProvider(),
      child: const LifeLensApp(),
    ),
  );
}

class LifeLensApp extends StatelessWidget {
  const LifeLensApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIFELENS - Your AI Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.greenAccent.shade400,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Segoe UI',
        textTheme: const TextTheme(
          headlineSmall:
              TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.greenAccent.shade400,
          elevation: 8,
          splashColor: Colors.greenAccent.shade700,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF121212),
          selectedItemColor: Colors.greenAccent.shade400,
          unselectedItemColor: Colors.white54,
          elevation: 12,
        ),
      ),
      home: const TabbedHomePage(),
    );
  }
}

class TabbedHomePage extends StatefulWidget {
  const TabbedHomePage({Key? key}) : super(key: key);

  @override
  State<TabbedHomePage> createState() => _TabbedHomePageState();
}

class _TabbedHomePageState extends State<TabbedHomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const VoiceTranscriptionScreen(),
    const RemindersScreen(),
    const FilesScreen(),
  ];

  void _onTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Reminders'),
          BottomNavigationBarItem(icon: Icon(Icons.file_upload), label: 'Files'),
        ],
      ),
    );
  }
}

class VoiceTranscriptionScreen extends StatefulWidget {
  const VoiceTranscriptionScreen({Key? key}) : super(key: key);

  @override
  State<VoiceTranscriptionScreen> createState() =>
      _VoiceTranscriptionScreenState();
}

class _VoiceTranscriptionScreenState extends State<VoiceTranscriptionScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _transcribedText = "";
  String _summaryText = "";
  double _currentLevel = 0.0; // <-- Properly declared inside class!
  List<Task> _alerts = [];

  late AnimationController _animationController;
  late Timer _summaryDelayTimer;

  static const int _summaryDelaySeconds = 3;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
    if (_summaryDelayTimer.isActive) _summaryDelayTimer.cancel();
    super.dispose();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _stopListening();
        }
      },
      onError: (error) {
        setState(() {
          _transcribedText = "Error: ${error.errorMsg}";
          _isListening = false;
          _currentLevel = 0;
        });
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _transcribedText = "";
        _summaryText = "";
        _currentLevel = 0;
        _alerts = [];
      });
      _speech.listen(
        listenMode: ListenMode.dictation,
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
            _currentLevel = result.confidence;
          });
          if (result.finalResult) {
            _startSummaryDelay();
          }
        },
        onSoundLevelChange: (level) {
          setState(() {
            _currentLevel = level / 100;
            if (_currentLevel > 1) _currentLevel = 1;
          });
        },
        listenFor: const Duration(minutes: 10),
      );
    } else {
      setState(() {
        _transcribedText = "Speech recognition not available";
      });
    }
  }

  void _stopListening() {
    if (!_isListening) return;
    _speech.stop();
    setState(() {
      _isListening = false;
      _currentLevel = 0;
    });
    _startSummaryDelay();
  }

  void _startSummaryDelay() {
    _summaryDelayTimer = Timer(const Duration(seconds: _summaryDelaySeconds), () {
      _generateSummaryAndAlerts();
    });
  }

  void _generateSummaryAndAlerts() {
    setState(() {
      if (_transcribedText.length > 80) {
        _summaryText = _transcribedText.substring(0, 75) + '...';
      } else if (_transcribedText.isEmpty) {
        _summaryText = "No transcription to summarize.";
      } else {
        _summaryText = _transcribedText;
      }

      _alerts = extractReminders(_transcribedText);
    });
  }

  @override
  Widget build(BuildContext context) {
    final neonColor = Colors.greenAccent.shade400;
    final backgroundColor = const Color(0xFF121212);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("LIFELENS - Voice"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_transcribedText.isNotEmpty) ...[
                      Text(
                        "Transcription:",
                        style: TextStyle(
                            color: neonColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: neonColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2),
                          ],
                        ),
                        child: Text(
                          _transcribedText,
                          style:
                              const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_summaryText.isNotEmpty) ...[
                      Text(
                        "Summary:",
                        style: TextStyle(
                            color: neonColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: neonColor.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 2),
                          ],
                        ),
                        child: Text(
                          _summaryText,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_alerts.isNotEmpty) ...[
                      Text(
                        "Alerts:",
                        style: TextStyle(
                            color: neonColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      ..._alerts.map(
                        (alert) => ListTile(
                          leading: const Icon(Icons.notification_important,
                              color: Colors.greenAccent),
                          title: Text(alert.title,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: alert.dueDate != null
                              ? Text('Due: ${DateFormat.yMMMd().format(alert.dueDate!)}',
                                  style: const TextStyle(color: Colors.white54))
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.add,
                                color: Colors.greenAccent, size: 30),
                            onPressed: () {
                              Provider.of<ReminderProvider>(context, listen: false)
                                  .addTask(alert);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Added "${alert.title}" to your reminders!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Add reminder',
                          ),
                        ),
                      )
                    ],
                  ],
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        neonColor.withOpacity(0.7 * _currentLevel + 0.3),
                        Colors.black87,
                      ],
                      stops: const [0.3, 1],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonColor.withOpacity(0.6),
                        blurRadius: 20 * (_currentLevel + 0.3),
                        spreadRadius: 10 * (_currentLevel + 0.3),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _LiquidPainter(level: _currentLevel, color: neonColor),
                    child: Center(
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 56,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: neonColor,
                            blurRadius: 20,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double level; // 0 to 1
  final Color color;

  _LiquidPainter({required this.level, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.5);

    final waveHeight = size.height / 3;
    final baseLine = size.height * (1 - level);

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseLine);

    for (double x = 0; x <= size.width; x++) {
      double y = baseLine +
          sin((x / size.width * 2 * pi) + DateTime.now().millisecondsSinceEpoch / 300) *
              waveHeight /
              4;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.level != level;
  }
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Future<void> _showAddDialog(BuildContext context) async {
    final titleController = TextEditingController();
    DateTime? selectedDate;

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Add Reminder', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setStateSB) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Reminder Title',
                  labelStyle: TextStyle(color: Colors.greenAccent),
                  enabledBorder:
                      UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'No date chosen'
                          : 'Due: ${DateFormat.yMMMd().format(selectedDate!)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Colors.greenAccent.shade400,
                                onPrimary: Colors.black,
                                surface: Colors.black,
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: const Color(0xFF222222),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setStateSB(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Pick Date', style: TextStyle(color: Colors.greenAccent)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade400,
            ),
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final task = Task(
                  title: titleController.text,
                  dueDate: selectedDate,
                );
                Provider.of<ReminderProvider>(context, listen: false).addTask(task);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('LIFELENS - Reminders'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, reminderProvider, _) {
          final tasks = reminderProvider.tasks;
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'No reminders yet! Add one with the + button.',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(top: 12),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                leading: Checkbox(
                  value: task.isDone,
                  activeColor: Colors.greenAccent.shade400,
                  onChanged: (_) => reminderProvider.toggleTaskDone(index),
                ),
                title: Text(
                  task.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                subtitle: task.dueDate != null
                    ? Text(
                        'Due: ${DateFormat.yMMMd().format(task.dueDate!)}',
                        style: const TextStyle(color: Colors.white54),
                      )
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.greenAccent.shade400,
        child: const Icon(Icons.add),
        tooltip: 'Add Reminder',
      ),
    );
  }
}

class FilesScreen extends StatefulWidget {
  const FilesScreen({Key? key}) : super(key: key);

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String? _selectedFileName;
  String? _summary = '';
  List<String> _keywords = [];
  String _docType = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _maxSentences = 3;

  Future<void> _pickAndUploadFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _summary = '';
      _keywords = [];
      _docType = '';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);

      if (result == null || result.files.isEmpty) {
        setState(() {
          _errorMessage = 'No file selected';
          _isLoading = false;
        });
        return;
      }

      final file = result.files.first;
      setState(() => _selectedFileName = file.name);

      final uri = Uri.parse('http://192.168.0.108:8000/upload_file/')
          .replace(queryParameters: {'max_sentences': _maxSentences.toString()});
      final request = http.MultipartRequest('POST', uri);

      if (file.bytes != null) {
        final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
        final mediaTypeParts = mimeType.split('/');
        request.files.add(http.MultipartFile.fromBytes('file', file.bytes!,
            filename: file.name,
            contentType: mediaTypeParts.length == 2
                ? MediaType(mediaTypeParts[0], mediaTypeParts[1])
                : null));
      } else if (file.path != null) {
        final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
        final mediaTypeParts = mimeType.split('/');
        request.files.add(await http.MultipartFile.fromPath('file', file.path!,
            contentType: mediaTypeParts.length == 2
                ? MediaType(mediaTypeParts[0], mediaTypeParts[1])
                : null));
      } else {
        throw Exception("No valid file bytes or path found.");
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResp = jsonDecode(respStr);

        setState(() {
          _summary = jsonResp['summary'] ?? '';
          _keywords =
              jsonResp['keywords'] != null ? List<String>.from(jsonResp['keywords']) : [];
          _docType = jsonResp['doc_type'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Upload failed with status ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('LIFELENS - File Upload & Reading'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload PDF/Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              onPressed: _isLoading ? null : _pickAndUploadFile,
            ),
            const SizedBox(height: 20),
            if (_selectedFileName != null)
              Text(
                "Selected File: $_selectedFileName",
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
            ],
            if (_summary != null && _summary!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                "Summary:",
                style: TextStyle(
                    color: Colors.greenAccent.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _summary!,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              if (_docType.isNotEmpty)
                Text(
                  "Document Type: $_docType",
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              const SizedBox(height: 20),
              Text(
                "Keywords:",
                style: TextStyle(
                    color: Colors.greenAccent.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _keywords
                    .map((k) => Chip(
                          backgroundColor: Colors.greenAccent.shade700,
                          label: Text(k, style: const TextStyle(color: Colors.black87)),
                        ))
                    .toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
