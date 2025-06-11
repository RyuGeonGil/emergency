import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'lobby.dart';
import 'notifications.dart';
import 'gps.dart';
import 'session.dart';
// 로그인 페이지 위젯 (StatefulWidget으로 입력값 관리)
class LoginPage extends StatefulWidget {
  final String? errorMessage;
  
  const LoginPage({
    super.key,
    this.errorMessage,
  });
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 올바른 인증코드를 미리 지정 (차후 API에서 랜덤 시드로 결정된 코드를 받아와야 한다.)
  final String correctCode = '123456';

  final TextEditingController _textController = TextEditingController(); // ip 입력 컨트롤러
  final TextEditingController _portController = TextEditingController(); // 포트 입력 컨트롤러
  final TextEditingController _uidController = TextEditingController();  // uid 입력 컨트롤러

  // 사용자가 입력한 인증코드 저장 변수
  String _enteredCode = '';

  // 세션 토큰 저장 변수
  String? _sessionToken;

  // 에러 메시지를 표시하는 함수
  void _showError(BuildContext context, String message, {String? details}) {
    print('[Login Error] $message${details != null ? '\nDetails: $details' : ''}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null)
              Text(
                details,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: details != null ? SnackBarAction(
          label: '자세히',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('오류 상세'),
                content: SingleChildScrollView(
                  child: Text(details),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          },
        ) : null,
      ),
    );
  }

  // 로그인 버튼 클릭 시 실행되는 함수
  Future<void> _onLogin(BuildContext context, String code) async {
    String inputText = _textController.text.trim(); // 문자열 입력값
    String portText = _portController.text.trim();
    String uidText = _uidController.text.trim();

    // 주소 입력이 비었는지 체크
    if (inputText.isEmpty) {
      _showError(context, '주소를 입력해주세요.');
      return;
    }
    if (portText.isEmpty) {
      _showError(context, '포트 번호를 입력해주세요.');
      return;
    }
    if (uidText.isEmpty) {
      _showError(context, 'uid를 입력해주세요.');
      return;
    }
    // uid는 숫자만 입력 가능
    int? userId = int.tryParse(uidText);
    if (userId == null) {
      _showError(context, 'uid는 숫자만 입력해야 합니다.');
      return;
    }

    try {
      // 서버로 uid와 인증코드 전송
      final url = Uri.parse('http://$inputText:$portText/connect');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'uid': userId,
        'auth_code': code,
      });

      print('[Login] Attempting to connect to server at: $url');
      final response = await http.post(url, headers: headers, body: body);
      print('[Login] Server response - Status: ${response.statusCode}, Body: ${response.body}');

      final sessionToken = response.body.trim();

      if (response.statusCode == 200 && sessionToken.isNotEmpty) {
        print('[Login] Login successful, configuring services...');
        setState(() {
          _sessionToken = sessionToken;
        });
        
        try {
          //세션 매니저에 세션 토큰과 서버 정보 등록 (자동 갱신 시작)
          print('[Login] Configuring SessionManager...');
          SessionManager().configure(
            sessionToken: sessionToken,
            ip: inputText,
            port: portText,
            uid: userId.toString(),
          );
          print('[Login] Saving credentials to storage...');
          await SessionManager().saveToStorage();
          
          // NotificationService 설정
          print('[Login] Configuring NotificationService...');
          NotificationService().configure(
            ip: inputText,
            port: portText,
            uid: userId,
          );
          NotificationService().startPolling();

          // GpsTracker 설정
          print('[Login] Configuring GpsTracker...');
          GpsTracker().configure(
            ip: inputText,
            port: portText,
            uid: userId,
          );
          GpsTracker().startTracking();

          print('[Login] All services configured, navigating to lobby...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LobbyScreen()),
          );
        } catch (serviceError) {
          print('[Login] Service configuration error: $serviceError');
          _showError(
            context,
            '서비스 구성 중 오류가 발생했습니다.',
            details: '세부 오류: $serviceError\n서비스 구성에 실패했지만 로그인은 성공했습니다. 앱을 다시 시작해주세요.',
          );
        }
      } else {
        print('[Login] Login failed - Status: ${response.statusCode}, Body: ${response.body}');
        String errorMessage = '로그인에 실패했습니다.';
        String? details;
        
        switch (response.statusCode) {
          case 400:
            errorMessage = '잘못된 요청입니다.';
            details = '입력하신 정보를 다시 확인해주세요.';
            break;
          case 401:
            errorMessage = '인증에 실패했습니다.';
            details = '인증 코드를 확인해주세요.';
            break;
          case 404:
            errorMessage = '서버를 찾을 수 없습니다.';
            details = '서버 주소와 포트를 확인해주세요.';
            break;
          default:
            details = '서버 응답: ${response.body}';
        }
        
        _showError(context, errorMessage, details: details);
      }
    } catch (e) {
      print('[Login] Connection error: $e');
      String errorMessage = '서버 연결에 실패했습니다.';
      String details = '네트워크 연결을 확인하고 다시 시도해주세요.\n\n오류 내용: $e';
      
      if (e is http.ClientException) {
        if (e.message.contains('Connection refused')) {
          details = '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
        } else if (e.message.contains('Connection timed out')) {
          details = '서버 응답 시간이 초과되었습니다. 네트워크 상태를 확인해주세요.';
        }
      }
      
      _showError(context, errorMessage, details: details);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('통신정보 및 인증코드 입력')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 문자열 입력 필드
            TextField(
              controller: _textController, // 입력값을 컨트롤러로 관리
              decoration: const InputDecoration(
                labelText: '서버 주소 입력', // 힌트(라벨) 텍스트
                border: OutlineInputBorder(), // 테두리 스타일
              ),
            ),
            const SizedBox(height: 24), // 위젯 사이 간격

            // 포트 번호 입력 필드
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '포트 번호 입력',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // uid 입력 필드
            TextField(
              controller: _uidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'uid 입력 (숫자)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 인증코드 입력 필드 (Pinput)
            Pinput(
              length: 6, // 6자리로 고정
              keyboardType: TextInputType.number, // 숫자 키패드 표시
              onCompleted: (code) {
                // 인증코드 입력이 끝나면 코드 저장
                setState(() {
                  _enteredCode = code;
                });
              },
            ),
            const SizedBox(height: 24), // 위젯 사이 간격

            // 로그인 버튼
            ElevatedButton(
              onPressed: () => _onLogin(context, _enteredCode),
              child: const Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}