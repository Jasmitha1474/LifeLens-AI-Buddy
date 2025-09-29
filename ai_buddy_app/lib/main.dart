import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// ------------------------------
/// Hive Model + Adapter (no codegen needed)
/// ------------------------------
class Task {
  String title;
  DateTime? dueDate;
  bool isDone;

  Task({required this.title, this.dueDate, this.isDone = false});
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    final title = reader.readString();
    final hasDate = reader.readBool();
    DateTime? due;
    if (hasDate) {
      due = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    }
    final done = reader.readBool();
    return Task(title: title, dueDate: due, isDone: done);
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.title);
    writer.writeBool(obj.dueDate != null);
    if (obj.dueDate != null) {
      writer.writeInt(obj.dueDate!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.isDone);
  }
}

/// ------------------------------
/// Reminder Provider with Hive persistence
/// ------------------------------
class ReminderProvider extends ChangeNotifier {
  final Box<Task> _box;

  ReminderProvider(this._box) {
    // Ensure initial notify so listeners render existing tasks
    notifyListeners();
  }

  List<Task> get tasks => _box.values.toList(growable: false);

  void addTask(Task task) {
    // avoid duplicates: same title + same dueDate
    final exists = _box.values.any((t) =>
        t.title.trim() == task.title.trim() &&
        (t.dueDate?.compareTo(task.dueDate ?? DateTime(0)) ?? 0) == 0);
    if (!exists) {
      _box.add(task);
      notifyListeners();
    }
  }

  void toggleTaskDone(int index) {
    if (index < 0 || index >= _box.length) return;
    final t = _box.getAt(index);
    if (t == null) return;
    final updated = Task(title: t.title, dueDate: t.dueDate, isDone: !t.isDone);
    _box.putAt(index, updated);
    notifyListeners();
  }
}

/// ------------------------------
/// Utility: month normalization + alert extraction
/// ------------------------------
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
    final regex = RegExp(r'\b' + abbr + r'\b', caseSensitive: false);
    text = text.replaceAll(regex, full);
  });

  return text;
}

List<Task> extractReminders(String text) {
  text = normalizeMonthAbbreviations(text);

  final List<Task> tasks = [];
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

/// ------------------------------
/// App entry
/// ------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  final tasksBox = await Hive.openBox<Task>('tasksBox');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ReminderProvider(tasksBox),
      child: const LifeLensApp(),
    ),
  );
}

/// ------------------------------
/// App + Theme
/// ------------------------------
class LifeLensApp extends StatelessWidget {
  const LifeLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    return MaterialApp(
      title: 'LIFELENS - Your AI Buddy',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F12),
        colorScheme: base.colorScheme.copyWith(
          primary: Colors.greenAccent.shade400,
          secondary: Colors.tealAccent.shade700,
        ),
        textTheme: base.textTheme.copyWith(
          headlineSmall: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
          bodyLarge: const TextStyle(color: Colors.white70, fontSize: 16),
          bodyMedium: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black.withOpacity(0.5),
          selectedItemColor: Colors.greenAccent.shade400,
          unselectedItemColor: Colors.white54,
          elevation: 12,
          showUnselectedLabels: true,
        ),
      ),
      home: const TabbedHomePage(),
    );
  }
}

/// ------------------------------
/// Tabs
/// ------------------------------
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
    return Container(
      // subtle gradient backdrop
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0F12), Color(0xFF0E1A16), Color(0xFF0D0F12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.greenAccent.shade400.withOpacity(0.18), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: AppBar(
              title: const Text('LIFELENS'),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _screens[_selectedIndex],
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTap,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Reminders'),
              BottomNavigationBarItem(icon: Icon(Icons.file_upload), label: 'Files'),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// Voice Screen
/// ------------------------------
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
  double _currentLevel = 0.0;
  List<Task> _alerts = [];

  late AnimationController _animationController;
  Timer? _summaryDelayTimer; // fixed: nullable + safe cancel
  static const int _summaryDelaySeconds = 3;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
    _summaryDelayTimer?.cancel();
    super.dispose();
  }

  void _startListening() async {
    final available = await _speech.initialize(
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
            _currentLevel = (level / 100).clamp(0.0, 1.0);
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
    _summaryDelayTimer?.cancel();
    _summaryDelayTimer = Timer(const Duration(seconds: _summaryDelaySeconds), () {
      _generateSummaryAndAlerts();
    });
  }

  void _generateSummaryAndAlerts() {
    setState(() {
      if (_transcribedText.length > 120) {
        _summaryText = _transcribedText.substring(0, 115) + '...';
      } else if (_transcribedText.isEmpty) {
        _summaryText = "No transcription to summarize.";
      } else {
        _summaryText = _transcribedText;
      }
      _alerts = extractReminders(_transcribedText);
    });
  }

  Widget _glassCard(Widget child, {EdgeInsets padding = const EdgeInsets.all(12)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.18),
            blurRadius: 10,
            spreadRadius: 1.2,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final neonColor = Colors.greenAccent.shade400;

    return Padding(
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
                    Text("Transcription:", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    _glassCard(
                      Text(_transcribedText, style: const TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_summaryText.isNotEmpty) ...[
                    Text("Summary:", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    _glassCard(
                      Text(
                        _summaryText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_alerts.isNotEmpty) ...[
                    Text("Alerts:", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    ..._alerts.map(
                      (alert) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: neonColor.withOpacity(0.18),
                              blurRadius: 8,
                              spreadRadius: 0.8,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.notification_important, color: Colors.greenAccent),
                          title: Text(alert.title, style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w600)),
                          subtitle: alert.dueDate != null
                              ? Text('Due: ${DateFormat.yMMMd().format(alert.dueDate!)}',
                                  style: const TextStyle(color: Colors.white60))
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.add, color: Colors.greenAccent, size: 28),
                            tooltip: 'Add reminder',
                            onPressed: () {
                              Provider.of<ReminderProvider>(context, listen: false).addTask(alert);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added "${alert.title}" to reminders.'), duration: const Duration(seconds: 2)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _isListening ? 136 : 120,
                height: _isListening ? 136 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      neonColor.withOpacity(0.7 * _currentLevel + 0.35),
                      Colors.black87,
                    ],
                    stops: const [0.35, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: neonColor.withOpacity(0.55),
                      blurRadius: 22 * (_currentLevel + 0.35),
                      spreadRadius: 10 * (_currentLevel + 0.35),
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
                      shadows: [Shadow(color: neonColor, blurRadius: 20)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
    final paint = Paint()..color = color.withOpacity(0.45);

    final waveHeight = size.height / 3;
    final baseLine = size.height * (1 - level);

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseLine);

    for (double x = 0; x <= size.width; x++) {
      final y = baseLine +
          sin((x / size.width * 2 * pi) + DateTime.now().millisecondsSinceEpoch / 300) *
              waveHeight / 4;
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

/// ------------------------------
/// Reminders Screen (with Hive-backed provider)
/// ------------------------------
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
        backgroundColor: const Color(0xFF1C1F24),
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
                              dialogBackgroundColor: const Color(0xFF1C1F24),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setStateSB(() => selectedDate = picked);
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade400,
            ),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final task = Task(title: titleController.text.trim(), dueDate: selectedDate);
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

  Widget _reminderCard(BuildContext context, Task task, int index) {
    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.16),
            blurRadius: 10,
            spreadRadius: 0.8,
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          activeColor: Colors.greenAccent.shade400,
          onChanged: (_) => reminderProvider.toggleTaskDone(index),
        ),
        title: Text(
          task.title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: task.dueDate != null
            ? Text(
                'Due: ${DateFormat.yMMMd().format(task.dueDate!)}',
                style: const TextStyle(color: Colors.white60),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReminderProvider>(
      builder: (_, reminderProvider, __) {
        final tasks = reminderProvider.tasks;

        return Column(
          children: [
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No reminders yet. Add one with the + button.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) => _reminderCard(context, tasks[index], index),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20, right: 20),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () => _showAddDialog(context),
                  backgroundColor: Colors.greenAccent.shade400,
                  child: const Icon(Icons.add),
                  tooltip: 'Add Reminder',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ------------------------------
/// Files Screen (unchanged logic, polished UI)
/// ------------------------------
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
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _errorMessage = 'No file selected';
          _isLoading = false;
        });
        return;
      }

      final file = result.files.first;
      setState(() => _selectedFileName = file.name);

      final uri = Uri.parse('http://192.168.1.3:8000/upload_file/')
          .replace(queryParameters: {'max_sentences': _maxSentences.toString()});
      final request = http.MultipartRequest('POST', uri);

      if (file.bytes != null) {
        final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
        final mediaTypeParts = mimeType.split('/');
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
          contentType: mediaTypeParts.length == 2
              ? MediaType(mediaTypeParts[0], mediaTypeParts[1])
              : null,
        ));
      } else if (file.path != null) {
        final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
        final mediaTypeParts = mimeType.split('/');
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          contentType: mediaTypeParts.length == 2
              ? MediaType(mediaTypeParts[0], mediaTypeParts[1])
              : null,
        ));
      } else {
        throw Exception("No valid file bytes or path found.");
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResp = jsonDecode(respStr);

        setState(() {
          _summary = jsonResp['summary'] ?? '';
          _keywords = jsonResp['keywords'] != null
              ? List<String>.from(jsonResp['keywords'])
              : [];
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

  Widget _glassCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.16),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 14),
          if (_selectedFileName != null)
            Text(
              "Selected File: $_selectedFileName",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
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
            const SizedBox(height: 16),
            Text(
              "Summary",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 6),
            _glassCard(
              Text(
                _summary!,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            if (_docType.isNotEmpty)
              Text("Document Type: $_docType",
                  style: const TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 14),
            Text(
              "Keywords",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _keywords
                  .map(
                    (k) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade700.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        k,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
