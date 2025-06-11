import 'package:flutter/material.dart';
import 'config.dart';
import 'login.dart';
import 'lobby.dart'; // LobbyScreen import 필요
import 'notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'session.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.location.request();
  await NotificationService().initialize();
  await SessionManager().loadFromStorage();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 자동 로그인 상태
  bool _autoLoginChecked = false;
  bool _autoLoginSuccess = false;

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
    _tryAutoLogin();
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  // 자동 로그인 시도
  Future<void> _tryAutoLogin() async {
    final ip = SessionManager().ip;
    final port = SessionManager().port;
    final sessionToken = SessionManager().sessionToken;
    final uid = SessionManager().uid; // uid도 SessionManager에 저장되어 있어야 함

    if (ip != null && port != null && sessionToken != null && uid != null) {
      try {
        final url = Uri.parse('http://$ip:$port/notification/sync');
        final headers = {
          'uid': uid,
          'session-token': sessionToken,
        };
        final response = await http.get(url, headers: headers);
        if (response.statusCode == 200) {
          setState(() {
            _autoLoginChecked = true;
            _autoLoginSuccess = true;
          });
          return;
        }
      } catch (_) {}
    }
    setState(() {
      _autoLoginChecked = true;
      _autoLoginSuccess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 자동 로그인 체크 전에는 로딩 표시
    if (!_autoLoginChecked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT Control Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFFd3d3ff),
        brightness: Brightness.dark,
      ),
      themeMode: themeNotifier.themeMode,
      home: _autoLoginSuccess ? const LobbyScreen() : const LoginPage(),
    );
  }
}
