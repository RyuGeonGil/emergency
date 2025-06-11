import 'package:flutter/material.dart';
import 'config.dart';
import 'login.dart';
import 'lobby.dart'; // LobbyScreen import 필요
import 'notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'session.dart';
import 'package:http/http.dart' as http;
import 'gps.dart';

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
  String? _errorMessage;  // Add error message state

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
    print('Starting auto-login process...');
    setState(() {
      _errorMessage = null;  // Clear any previous error
    });
    
    final ip = SessionManager().ip;
    final port = SessionManager().port;
    final sessionToken = SessionManager().sessionToken;
    final uid = SessionManager().uid;

    print('Loaded credentials from storage:');
    print('- IP: $ip');
    print('- Port: $port');
    print('- UID: $uid');
    print('- Has Token: ${sessionToken != null}');

    if (ip != null && port != null && sessionToken != null && uid != null) {
      try {
        final url = Uri.parse('http://$ip:$port/notification/sync');
        final headers = {
          'uid': uid,
          'session-token': sessionToken,
          'content-type': 'application/json',
        };
        print('Attempting to validate session at: $url');
        print('Using headers: $headers');
        
        final response = await http.get(url, headers: headers);
        print('Server response - Status: ${response.statusCode}, Body: ${response.body}');
        
        // If we can successfully call sync endpoint (200) or get a valid 404 (no notifications), session is valid
        if (response.statusCode == 200 || response.statusCode == 404) {
          print('Session validation successful (status: ${response.statusCode}), configuring services...');
          
          // Configure services after successful validation
          try {
            print('Configuring NotificationService...');
            NotificationService().configure(
              ip: ip,
              port: port,
              uid: int.parse(uid),
            );
            NotificationService().startPolling();
            print('NotificationService configured successfully');

            print('Configuring GpsTracker...');
            GpsTracker().configure(
              ip: ip,
              port: port,
              uid: int.parse(uid),
            );
            GpsTracker().startTracking();
            print('GpsTracker configured successfully');

            setState(() {
              _autoLoginChecked = true;
              _autoLoginSuccess = true;
              _errorMessage = null;
            });
            print('Auto-login completed successfully');
            return;
          } catch (serviceError) {
            print('Error configuring services: $serviceError');
            setState(() {
              _errorMessage = '서비스 구성 중 오류가 발생했습니다';
            });
            throw serviceError;
          }
        } else {
          print('Session validation failed: ${response.statusCode} - ${response.body}');
          setState(() {
            _errorMessage = '세션이 만료되었습니다. 다시 로그인해주세요.';
          });
        }
      } catch (e) {
        print('Auto-login failed with error: $e');
        setState(() {
          _errorMessage = '서버 연결에 실패했습니다. 네트워크를 확인해주세요.';
        });
      }
    } else {
      print('No stored credentials found');
      setState(() {
        _autoLoginChecked = true;
        _autoLoginSuccess = false;
        _errorMessage = null;  // Don't show error when there are no credentials
      });
    }
    
    print('Auto-login failed, clearing stored session...');
    await SessionManager().clearStorage();
    setState(() {
      _autoLoginChecked = true;
      _autoLoginSuccess = false;
    });
    print('Auto-login process completed with failure');
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
      home: _autoLoginSuccess 
          ? const LobbyScreen() 
          : LoginPage(errorMessage: _errorMessage),
    );
  }
}
