// Data Models for the In-Store app
class UserProfile {
  final String name;
  final String email;
  final UserType userType;
  final ClientLogo clientLogo;

  UserProfile({
    required this.name,
    required this.email,
    required this.userType,
    required this.clientLogo,
  });
}

enum UserType { inStore, inStorePromo }
enum ClientLogo { inStore, rdas, fmcg }
enum CameraMode { sceneCapture, labelCapture }

// ✅ ADDED: Store Model
class Store {
  final String id;
  final String name;
  final String chain;
  final String address;
  final double latitude;
  final double longitude;
  double? distance; // Calculated distance from user

  Store({
    required this.id,
    required this.name,
    required this.chain,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert to double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Extract chain from store name if not provided
    String extractChain(String? storeName, String? chainField) {
      // If chain field exists, use it
      if (chainField != null && chainField.isNotEmpty && chainField != 'Unknown') {
        return chainField;
      }
      
      // Otherwise extract from store name
      if (storeName == null || storeName.isEmpty) return 'Unknown';
      
      final nameLower = storeName.toLowerCase();
      if (nameLower.contains('woolworth') || nameLower.contains('woolies')) return 'Woolworths';
      if (nameLower.contains('coles')) return 'Coles';
      if (nameLower.contains('aldi')) return 'Aldi';
      if (nameLower.contains('iga')) return 'IGA';
      if (nameLower.contains('new world') || nameLower.contains('newworld')) return 'New World';
      
      return 'Unknown';
    }

    final storeName = json['store_name']?.toString() ?? json['name']?.toString() ?? 'Unknown Store';
    final chainField = json['chain']?.toString() ?? json['brand']?.toString();

    return Store(
      id: json['store_id']?.toString() ?? json['id']?.toString() ?? 'unknown',
      name: storeName,
      chain: extractChain(storeName, chainField),
      address: json['address_1']?.toString() ?? json['address']?.toString() ?? '',
      latitude: parseDouble(json['latitude'] ?? json['lat']),
      longitude: parseDouble(json['longitude'] ?? json['lon']),
      distance: json['distance_km'] != null ? parseDouble(json['distance_km']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': id,
      'name': name,
      'store_name': name,
      'chain': chain,
      'address': address,
      'address_1': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance_km': distance,
    };
  }
}

// Installation Types for Location Selection
enum InstallationType {
  // Aisle-based installations (require aisle 1-20)
  end('End', true, 'end'),
  front('Front', true, 'front'),
  frontLeftWing('Front Left Wing', true, 'front_left_wing'),
  frontRightWing('Front Right Wing', true, 'front_right_wing'),
  back('Back', true, 'back'),
  backLeftWing('Back Left Wing', true, 'back_left_wing'),
  backRightWing('Back Right Wing', true, 'back_right_wing'),
  freezer('Freezer', true, 'freezer'),
  
  // Off locations (multi-capture allowed)
  deli('Deli', false, 'deli'),
  entrance('Entrance', false, 'entrance'),
  pos('POS', false, 'pos');
  
  const InstallationType(this.displayName, this.requiresAisle, this.id);
  
  final String displayName;
  final bool requiresAisle;
  final String id;
}

// Visit Progress Tracking
class VisitProgress {
  final String storeId;
  final String visitId;
  final Map<String, Set<int>> completedAisleInstallations;
  final Map<String, int> offLocationCaptures;
  final DateTime lastUpdated;
  
  VisitProgress({
    required this.storeId,
    required this.visitId,
    this.completedAisleInstallations = const {},
    this.offLocationCaptures = const {},
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  bool isAisleInstallationComplete(InstallationType type, int aisle) {
    return completedAisleInstallations[type.id]?.contains(aisle) ?? false;
  }
  
  int getCompletionCount(InstallationType type) {
    if (type.requiresAisle) {
      return completedAisleInstallations[type.id]?.length ?? 0;
    } else {
      return offLocationCaptures[type.id] ?? 0;
    }
  }
  
  VisitProgress markAisleComplete(InstallationType type, int aisle) {
    if (!type.requiresAisle) return this;
    
    final updated = Map<String, Set<int>>.from(completedAisleInstallations);
    updated[type.id] = (updated[type.id] ?? <int>{})..add(aisle);
    
    return VisitProgress(
      storeId: storeId,
      visitId: visitId,
      completedAisleInstallations: updated,
      offLocationCaptures: offLocationCaptures,
      lastUpdated: DateTime.now(),
    );
  }
  
  VisitProgress addOffLocationCapture(InstallationType type) {
    if (type.requiresAisle) return this;
    
    final updated = Map<String, int>.from(offLocationCaptures);
    updated[type.id] = (updated[type.id] ?? 0) + 1;
    
    return VisitProgress(
      storeId: storeId,
      visitId: visitId,
      completedAisleInstallations: completedAisleInstallations,
      offLocationCaptures: updated,
      lastUpdated: DateTime.now(),
    );
  }
  
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inDays >= 3;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'visitId': visitId,
      'completedAisleInstallations': completedAisleInstallations.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
      'offLocationCaptures': offLocationCaptures,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  factory VisitProgress.fromJson(Map<String, dynamic> json) {
    return VisitProgress(
      storeId: json['storeId'] as String,
      visitId: json['visitId'] as String,
      completedAisleInstallations: (json['completedAisleInstallations'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Set<int>.from(value as List)),
      ),
      offLocationCaptures: Map<String, int>.from(json['offLocationCaptures'] as Map),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

class Visit {
  final String id;
  final String storeName;
  final DateTime startTime;
  final double progress;
  final int photoCount;

  Visit({
    required this.id,
    required this.storeName,
    required this.startTime,
    required this.progress,
    required this.photoCount,
  });
}
