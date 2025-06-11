class Device {
  final String id;
  final String name;
  final bool isOnline;
  final bool isOn;
  final String type;
  final String location;

  Device({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.isOn,
    required this.type,
    required this.location,
  });

  // Create a copy of the device with updated fields
  Device copyWith({
    String? id,
    String? name,
    bool? isOnline,
    bool? isOn,
    String? type,
    String? location,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      isOn: isOn ?? this.isOn,
      type: type ?? this.type,
      location: location ?? this.location,
    );
  }

  // Convert Device to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isOnline': isOnline,
      'isOn': isOn,
      'type': type,
      'location': location,
    };
  }

  // Create Device from JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      isOnline: json['isOnline'] as bool,
      isOn: json['isOn'] as bool,
      type: json['type'] as String,
      location: json['location'] as String,
    );
  }
} 