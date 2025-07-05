class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? phoneNumber;
  final bool verified;
  final int verificationLevel;
  final DateTime createdAt;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.verified = false,
    this.verificationLevel = 1,
    required this.createdAt,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      phoneNumber: map['phoneNumber'],
      verified: map['verified'] ?? false,
      verificationLevel: map['verificationLevel'] ?? 1,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'verified': verified,
      'verificationLevel': verificationLevel,
      'createdAt': createdAt,
      'fcmToken': fcmToken,
    };
  }
}