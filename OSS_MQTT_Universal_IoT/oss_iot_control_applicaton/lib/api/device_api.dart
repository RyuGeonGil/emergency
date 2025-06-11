import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../session.dart';

class DeviceApi {
  static final DeviceApi _instance = DeviceApi._internal();

  factory DeviceApi() => _instance;

  DeviceApi._internal();

  // This will be implemented by your coworker to make actual API calls
  Future<List<Device>> getDevices() async {
    // TODO: Replace with actual API implementation
    //Example of how the API call might look:
    final sessionToken = SessionManager().sessionToken;
    if (sessionToken == null) throw Exception('No session token available');

    final headers = {
      'content-type': 'application/json',
      'session-token': sessionToken,
    };

    // Python의 stats_server 주소와 동일하게 사용
    final url = Uri.parse('http://Integration-Server:3000/protocol/mqtt/getstats');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Device.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load devices: ${response.statusCode}');
    }


    // Temporary mock data
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Device(
        id: 'dev_001',
        name: 'Living Room Light',
        isOnline: true,
        isOn: true,
        type: 'Light',
        location: 'Living Room',
      ),
      Device(
        id: 'dev_002',
        name: 'Kitchen Light',
        isOnline: true,
        isOn: false,
        type: 'Light',
        location: 'Kitchen',
      ),
      Device(
        id: 'dev_003',
        name: 'Bedroom AC',
        isOnline: false,
        isOn: false,
        type: 'Air Conditioner',
        location: 'Bedroom',
      ),
      Device(
        id: 'dev_004',
        name: 'Smart TV',
        isOnline: true,
        isOn: true,
        type: 'Entertainment',
        location: 'Living Room',
      ),
      Device(
        id: 'dev_005',
        name: 'Security Camera',
        isOnline: true,
        isOn: true,
        type: 'Security',
        location: 'Front Door',
      ),
      Device(
        id: 'dev_006',
        name: 'Smart Speaker',
        isOnline: true,
        isOn: false,
        type: 'Audio',
        location: 'Living Room',
      ),
    ];
  }

  // Example of how to implement device control
  Future<void> toggleDevice(String deviceId, bool turnOn) async {
    // TODO: Replace with actual API implementation
    final sessionToken = SessionManager().sessionToken;
    if (sessionToken == null) {
      throw Exception('No session token available');
    }

    final ip = SessionManager().ip;
    final port = SessionManager().port;
    if (ip == null || port == null) {
      throw Exception('Server information not available');
    }

    final deviceServer = 'http://$ip:$port/protocol/mqtt/command';
    final notificationServer = 'http://$ip:$port/notification/postnoti';

    final deviceHeaders = {
      'content-type': 'application/json',
      'session-token': sessionToken,
    };

    final deviceBody = json.encode({
      'device_id': deviceId,
      'topic': 'broadcast',
      'command': turnOn ? 'on' : 'off',
    });

    final deviceResponse = await http.post(
      Uri.parse(deviceServer),
      headers: deviceHeaders,
      body: deviceBody,
    );

    if (deviceResponse.statusCode != 200) {
      throw Exception('Failed to toggle device: ${deviceResponse.statusCode}');
    }

// 알림 전송용 헤더, uid는 SessionManager에서 가져온다고 가정
    final uid = SessionManager().uid;
    final now = DateTime.now().toIso8601String();

    final notificationHeaders = {
      'uid': uid ?? '',
      'content-type': 'application/json',
    };

    final notificationBody = json.encode({
      'content': turnOn ? '꺼져있던 머신 켜짐' : '켜져있던 머신 꺼짐',
      'time': now,
      'about': 1,
    });

    final notificationResponse = await http.post(
      Uri.parse(notificationServer),
      headers: notificationHeaders,
      body: notificationBody,
    );

    if (notificationResponse.statusCode != 200) {
      throw Exception('Failed to send notification: ${notificationResponse.statusCode}');
    }

    // Temporary mock implementation
    await Future.delayed(const Duration(milliseconds: 300));
  }
}