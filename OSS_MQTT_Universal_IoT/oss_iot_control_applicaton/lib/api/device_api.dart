import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../session.dart';

class DeviceApi {
  static final DeviceApi _instance = DeviceApi._internal();

  factory DeviceApi() => _instance;

  DeviceApi._internal();

  // Helper method to get server URL
  String _getServerUrl(String endpoint) {
    final ip = SessionManager().ip;
    final port = SessionManager().port;
    if (ip == null || port == null) {
      throw Exception('Server information not available');
    }
    return 'http://$ip:$port/$endpoint';
  }

  // Helper method to get common headers
  Map<String, String> _getHeaders({String? uid}) {
    final sessionToken = SessionManager().sessionToken;
    if (sessionToken == null) {
      throw Exception('No session token available');
    }

    final headers = {
      'content-type': 'application/json',
      'session-token': sessionToken,
    };

    if (uid != null) {
      headers['uid'] = uid;
    }

    return headers;
  }

  Future<List<Device>> getDevices() async {
    try {
      final url = Uri.parse(_getServerUrl('protocol/mqtt/getstats'));
      final headers = _getHeaders();

      print('[DeviceAPI] Fetching devices from: $url');
      final response = await http.get(url, headers: headers);
      print('[DeviceAPI] Get devices response - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        print('[DeviceAPI] Decoded data: $decodedData');
        
        if (!decodedData.containsKey('stats')) {
          throw Exception('Response missing stats field');
        }

        final List<dynamic> stats = decodedData['stats'];
        final devices = stats.map((stat) {
          final parts = stat.toString().trim().split(' ');
          if (parts.length != 2) {
            throw Exception('Invalid stat format: $stat');
          }

          final id = parts[0];
          final status = parts[1];

          return Device(
            id: id,
            name: id,
            isOnline: true,
            isOn: status == '1',
            type: 'unknown',
            location: 'Location $id'
          );
        }).toList();
        
        print('[DeviceAPI] Processed devices: $devices');
        return devices;
      } else {
        throw Exception('Failed to load devices: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('[DeviceAPI] Error getting devices: $e');
      print('[DeviceAPI] Stack trace: $stackTrace');
      throw Exception('Failed to load devices: $e');
    }
  }

  Future<void> toggleDevice(String deviceId, bool turnOn) async {
    try {
      final deviceUrl = Uri.parse(_getServerUrl('protocol/mqtt/command'));
      final notificationUrl = Uri.parse(_getServerUrl('notification/postnoti'));
      final deviceHeaders = _getHeaders();

      final deviceBody = json.encode({
        'device_id': deviceId,
        'topic': 'broadcast',
        'command': turnOn ? 'on' : 'off',
      });

      print('[DeviceAPI] Sending toggle command to: $deviceUrl');
      print('[DeviceAPI] Command body: $deviceBody');
      
      final deviceResponse = await http.post(
        deviceUrl,
        headers: deviceHeaders,
        body: deviceBody,
      );
      print('[DeviceAPI] Toggle device response - Status: ${deviceResponse.statusCode}, Body: ${deviceResponse.body}');

      if (deviceResponse.statusCode != 200) {
        throw Exception('Failed to toggle device: ${deviceResponse.statusCode} - ${deviceResponse.body}');
      }

      // Send notification
      final uid = SessionManager().uid;
      if (uid != null) {
        final now = DateTime.now().toIso8601String();
        final notificationHeaders = _getHeaders(uid: uid);
        
        final notificationBody = json.encode({
          'content': turnOn ? '꺼져있던 머신 켜짐' : '켜져있던 머신 꺼짐',
          'time': now,
          'about': 1,
        });

        print('[DeviceAPI] Sending notification to: $notificationUrl');
        final notificationResponse = await http.post(
          notificationUrl,
          headers: notificationHeaders,
          body: notificationBody,
        );
        print('[DeviceAPI] Notification response - Status: ${notificationResponse.statusCode}, Body: ${notificationResponse.body}');

        if (notificationResponse.statusCode != 200) {
          print('[DeviceAPI] Warning: Failed to send notification: ${notificationResponse.statusCode} - ${notificationResponse.body}');
          // Don't throw here as the device toggle was successful
        }
      }
    } catch (e) {
      print('[DeviceAPI] Error toggling device: $e');
      throw Exception('Failed to toggle device: $e');
    }
  }
}