import '../../cloud/models/user_profile_model.dart';

enum FriendStatus {
  active('Active'),
  blocked('Blocked');

  const FriendStatus(this.label);
  final String label;
}

enum FriendRequestStatus {
  pending('Pending'),
  accepted('Accepted'),
  rejected('Rejected'),
  cancelled('Cancelled');

  const FriendRequestStatus(this.label);
  final String label;
}

class FriendModel {
  const FriendModel({
    required this.userId,
    required this.friendUserId,
    required this.friendName,
    required this.friendUsername,
    required this.friendPhone,
    required this.friendCity,
    required this.friendPhotoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.chatId,
  });

  final String userId;
  final String friendUserId;
  final String friendName;
  final String friendUsername;
  final String friendPhone;
  final String friendCity;
  final String friendPhotoUrl;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String chatId;

  bool get isActive => status == FriendStatus.active;

  Map<String, Object?> toMap() {
    return {
      'userId': userId,
      'friendUserId': friendUserId,
      'friendName': friendName,
      'friendUsername': friendUsername,
      'friendPhone': friendPhone,
      'friendCity': friendCity,
      'friendPhotoUrl': friendPhotoUrl,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'chatId': chatId,
    };
  }

  factory FriendModel.fromMap(Map<String, Object?> map) {
    return FriendModel(
      userId: '${map['userId'] ?? ''}',
      friendUserId: '${map['friendUserId'] ?? ''}',
      friendName: '${map['friendName'] ?? ''}',
      friendUsername: '${map['friendUsername'] ?? ''}',
      friendPhone: '${map['friendPhone'] ?? ''}',
      friendCity: '${map['friendCity'] ?? ''}',
      friendPhotoUrl: '${map['friendPhotoUrl'] ?? ''}',
      status: FriendStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => FriendStatus.active,
      ),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      chatId: '${map['chatId'] ?? ''}',
    );
  }

  static DateTime _date(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }
}

class FriendRequestModel {
  const FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromName,
    required this.fromUsername,
    required this.fromPhone,
    required this.fromCity,
    required this.fromPhotoUrl,
    required this.toName,
    required this.toUsername,
    required this.toPhone,
    required this.toCity,
    required this.toPhotoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromName;
  final String fromUsername;
  final String fromPhone;
  final String fromCity;
  final String fromPhotoUrl;
  final String toName;
  final String toUsername;
  final String toPhone;
  final String toCity;
  final String toPhotoUrl;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;

  bool get isPending => status == FriendRequestStatus.pending;

  String otherUserId(String currentUserId) {
    return fromUserId == currentUserId ? toUserId : fromUserId;
  }

  String otherName(String currentUserId) {
    return fromUserId == currentUserId ? toName : fromName;
  }

  String otherUsername(String currentUserId) {
    return fromUserId == currentUserId ? toUsername : fromUsername;
  }

  String otherPhotoUrl(String currentUserId) {
    return fromUserId == currentUserId ? toPhotoUrl : fromPhotoUrl;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'participantIds': [fromUserId, toUserId],
      'fromName': fromName,
      'fromUsername': fromUsername,
      'fromPhone': fromPhone,
      'fromCity': fromCity,
      'fromPhotoUrl': fromPhotoUrl,
      'toName': toName,
      'toUsername': toUsername,
      'toPhone': toPhone,
      'toCity': toCity,
      'toPhotoUrl': toPhotoUrl,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }

  factory FriendRequestModel.fromMap(Map<String, Object?> map) {
    return FriendRequestModel(
      id: '${map['id'] ?? ''}',
      fromUserId: '${map['fromUserId'] ?? ''}',
      toUserId: '${map['toUserId'] ?? ''}',
      fromName: '${map['fromName'] ?? ''}',
      fromUsername: '${map['fromUsername'] ?? ''}',
      fromPhone: '${map['fromPhone'] ?? ''}',
      fromCity: '${map['fromCity'] ?? ''}',
      fromPhotoUrl: '${map['fromPhotoUrl'] ?? ''}',
      toName: '${map['toName'] ?? ''}',
      toUsername: '${map['toUsername'] ?? ''}',
      toPhone: '${map['toPhone'] ?? ''}',
      toCity: '${map['toCity'] ?? ''}',
      toPhotoUrl: '${map['toPhotoUrl'] ?? ''}',
      status: FriendRequestStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      respondedAt: _nullableDate(map['respondedAt']),
    );
  }
}

class ChatThreadModel {
  const ChatThreadModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  String otherUserId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.millisecondsSinceEpoch,
      'lastSenderId': lastSenderId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ChatThreadModel.fromMap(Map<String, Object?> map) {
    return ChatThreadModel(
      id: '${map['id'] ?? ''}',
      participantIds: _stringList(map['participantIds']),
      participantNames: _stringMap(map['participantNames']),
      participantPhotos: _stringMap(map['participantPhotos']),
      lastMessage: '${map['lastMessage'] ?? ''}',
      lastMessageAt: _nullableDate(map['lastMessageAt']),
      lastSenderId: '${map['lastSenderId'] ?? ''}',
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.readBy,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final List<String> readBy;

  bool isMine(String userId) => senderId == userId;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'readBy': readBy,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, Object?> map) {
    return ChatMessageModel(
      id: '${map['id'] ?? ''}',
      chatId: '${map['chatId'] ?? ''}',
      senderId: '${map['senderId'] ?? ''}',
      text: '${map['text'] ?? ''}',
      createdAt: _date(map['createdAt']),
      readBy: _stringList(map['readBy']),
    );
  }
}

class FriendSearchResult {
  const FriendSearchResult({
    required this.profile,
    required this.isFriend,
    this.outgoingRequest,
    this.incomingRequest,
  });

  final UserProfileModel profile;
  final bool isFriend;
  final FriendRequestModel? outgoingRequest;
  final FriendRequestModel? incomingRequest;

  bool get hasOutgoingRequest =>
      outgoingRequest?.status == FriendRequestStatus.pending;
  bool get hasIncomingRequest =>
      incomingRequest?.status == FriendRequestStatus.pending;
}

String chatIdForUsers(String firstUserId, String secondUserId) {
  final ids = [firstUserId, secondUserId]..sort();
  return '${ids[0]}_${ids[1]}';
}

String friendRequestIdForUsers(String firstUserId, String secondUserId) {
  final ids = [firstUserId, secondUserId]..sort();
  return '${ids[0]}_${ids[1]}';
}

DateTime _date(Object? value) {
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.now();
}

DateTime? _nullableDate(Object? value) {
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value.map((item) => '$item').toList();
  }
  return const <String>[];
}

Map<String, String> _stringMap(Object? value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry('$key', '$item'));
  }
  return const <String, String>{};
}
