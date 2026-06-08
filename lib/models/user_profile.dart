class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final bool smsAutoRead;
  final bool pushNotifications;
  final bool budgetAlerts;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    this.smsAutoRead = false,
    this.pushNotifications = true,
    this.budgetAlerts = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'smsAutoRead': smsAutoRead,
      'pushNotifications': pushNotifications,
      'budgetAlerts': budgetAlerts,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      smsAutoRead: map['smsAutoRead'] as bool? ?? false,
      pushNotifications: map['pushNotifications'] as bool? ?? true,
      budgetAlerts: map['budgetAlerts'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    bool? smsAutoRead,
    bool? pushNotifications,
    bool? budgetAlerts,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      smsAutoRead: smsAutoRead ?? this.smsAutoRead,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
