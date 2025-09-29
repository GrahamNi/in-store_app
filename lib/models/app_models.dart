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
      lastUpdated: DateTime.now(), // Update timestamp
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
      lastUpdated: DateTime.now(), // Update timestamp
    );
  }
  
  // Check if progress has expired (older than 3 days)
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inDays >= 3;
  }
  
  // Convert to JSON for persistence
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
  
  // Create from JSON
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