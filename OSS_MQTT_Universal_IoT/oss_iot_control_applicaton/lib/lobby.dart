import 'package:flutter/material.dart';
import 'config.dart';
import 'models/device.dart';
import '../api/device_api.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DeviceApi _deviceApi = DeviceApi();
  List<Device> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final devices = await _deviceApi.getDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading devices: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('IoT Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.5,
                ),
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return DeviceCard(
                    device: device,
                    onDeviceToggled: _loadDevices,
                  );
                },
              ),
            ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: const Text(
                'Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onDeviceToggled;

  const DeviceCard({
    Key? key,
    required this.device,
    required this.onDeviceToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Define colors based on theme mode
    final Color cardColor = device.isOnline 
        ? (device.isOn 
            ? Theme.of(context).primaryColor.withOpacity(isDarkMode ? 0.8 : 1.0)
            : (isDarkMode ? Colors.grey[800]! : Colors.grey[300]!))
        : (isDarkMode ? Colors.grey[900]! : Colors.grey[200]!);

    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDarkMode ? Colors.grey[300]! : Colors.grey[600]!;
    final Color disabledTextColor = isDarkMode ? Colors.grey[500]! : Colors.grey[400]!;

    return Card(
      elevation: device.isOnline ? 4 : 1,
      margin: EdgeInsets.zero,
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: InkWell(
        onTap: device.isOnline 
            ? () async {
                try {
                  await DeviceApi().toggleDevice(device.id, !device.isOn);
                  // Call the callback to reload devices
                  onDeviceToggled();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${device.name} turned ${device.isOn ? 'off' : 'on'}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error toggling device: $e')),
                    );
                  }
                }
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: cardColor.withOpacity(isDarkMode ? 0.2 : 0.1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Icon on the left
                Icon(
                  _getDeviceIcon(device.type),
                  size: 32,
                  color: device.isOnline 
                      ? (device.isOn 
                          ? Theme.of(context).primaryColor 
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]))
                      : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                ),
                const SizedBox(width: 12),
                // Device info on the right
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device name
                      Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: device.isOnline 
                              ? textColor 
                              : disabledTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Text(
                        device.location,
                        style: TextStyle(
                          color: device.isOnline 
                              ? secondaryTextColor 
                              : disabledTextColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Status
                      Text(
                        device.isOnline ? (device.isOn ? 'On' : 'Off') : 'Offline',
                        style: TextStyle(
                          color: device.isOnline 
                              ? (device.isOn 
                                  ? Theme.of(context).primaryColor 
                                  : secondaryTextColor)
                              : disabledTextColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return Icons.lightbulb;
      case 'air conditioner':
        return Icons.ac_unit;
      case 'entertainment':
        return Icons.tv;
      case 'security':
        return Icons.security;
      case 'audio':
        return Icons.speaker;
      default:
        return Icons.devices;
    }
  }
}
