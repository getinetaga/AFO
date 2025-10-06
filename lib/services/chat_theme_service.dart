import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatTheme {
  final String name;
  final Color primary;
  final Color appBarColor;
  final Color background;
  final Color outgoingBubble;
  final Color incomingBubble;
  final Color outgoingText;
  final Color incomingText;

  const ChatTheme({
    required this.name,
    required this.primary,
    required this.appBarColor,
    required this.background,
    required this.outgoingBubble,
    required this.incomingBubble,
    required this.outgoingText,
    required this.incomingText,
  });

  @override
  String toString() => name;
}

class ChatThemeService {
  static final ChatThemeService _instance = ChatThemeService._internal();
  factory ChatThemeService() => _instance;
  ChatThemeService._internal() {
    _notifier = ValueNotifier<ChatTheme>(_presets.first);
    _load();
  }

  static const String _prefsKey = 'chat_theme_name';

  late final ValueNotifier<ChatTheme> _notifier;
  ValueNotifier<ChatTheme> get notifier => _notifier;

  static final List<ChatTheme> _presets = [
    ChatTheme(
      name: 'AFO Blue',
      primary: Color(0xFF1565C0),
      appBarColor: Color(0xFF1565C0),
      background: Color(0xFFF5F7FA),
      outgoingBubble: Color(0xFF1565C0),
      incomingBubble: Colors.white,
      outgoingText: Colors.white,
      incomingText: Colors.black87,
    ),
    ChatTheme(
      name: 'Dark',
      primary: Color(0xFF1F1F1F),
      appBarColor: Color(0xFF121212),
      background: Color(0xFF0D0D0D),
      outgoingBubble: Color(0xFF2E7D32),
      incomingBubble: Color(0xFF1E1E1E),
      outgoingText: Colors.white,
      incomingText: Colors.white70,
    ),
    ChatTheme(
      name: 'Pastel',
      primary: Color(0xFF7B8FA1),
      appBarColor: Color(0xFF7B8FA1),
      background: Color(0xFFFFFBFA),
      outgoingBubble: Color(0xFF8FC6A9),
      incomingBubble: Colors.white,
      outgoingText: Colors.white,
      incomingText: Colors.black87,
    ),
    ChatTheme(
      name: 'Forest',
      primary: Color(0xFF2E7D32),
      appBarColor: Color(0xFF2E7D32),
      background: Color(0xFFF0F7EE),
      outgoingBubble: Color(0xFF2E7D32),
      incomingBubble: Colors.white,
      outgoingText: Colors.white,
      incomingText: Colors.black87,
    ),
    ChatTheme(
      name: 'Mono',
      primary: Color(0xFF424242),
      appBarColor: Color(0xFF424242),
      background: Color(0xFFF7F7F7),
      outgoingBubble: Color(0xFF616161),
      incomingBubble: Colors.white,
      outgoingText: Colors.white,
      incomingText: Colors.black87,
    ),
  ];

  List<ChatTheme> get presets => List.unmodifiable(_presets);

  ChatTheme? _findByName(String name) {
    try {
      return _presets.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsKey);
    if (name != null) {
      final t = _findByName(name);
      if (t != null) _notifier.value = t;
    }
  }

  Future<void> setTheme(ChatTheme theme) async {
    _notifier.value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, theme.name);
  }
}
