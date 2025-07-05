class MatchModel {
  final String id;
  final String lostItemId;
  final String foundItemId;
  final String lostUserId;
  final String foundUserId;
  final double matchScore;
  final String status; // 'pending', 'confirmed', 'rejected'
  final String? chatRoomId;
  final DateTime createdAt;

  MatchModel({
    required this.id,
    required this.lostItemId,
    required this.foundItemId,
    required this.lostUserId,
    required this.foundUserId,
    required this.matchScore,
    this.status = 'pending',
    this.chatRoomId,
    required this.createdAt,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map, String id) {
    return MatchModel(
      id: id,
      lostItemId: map['lostItemId'] ?? '',
      foundItemId: map['foundItemId'] ?? '',
      lostUserId: map['lostUserId'] ?? '',
      foundUserId: map['foundUserId'] ?? '',
      matchScore: (map['matchScore'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      chatRoomId: map['chatRoomId'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lostItemId': lostItemId,
      'foundItemId': foundItemId,
      'lostUserId': lostUserId,
      'foundUserId': foundUserId,
      'matchScore': matchScore,
      'status': status,
      'chatRoomId': chatRoomId,
      'createdAt': createdAt,
    };
  }
}