import 'dart:convert';
import 'package:uuid/uuid.dart';

final Uuid _uuid = Uuid();

// =======================
// QueryModel
// =======================
class QueryModel {
  final String id;
  String title;
  String message;
  final String userEmail;
  List<ReplyModel> replies;
  final DateTime createdAt;
  bool isRead;

  // Optional Fields
  final String? status;
  final String? assignedTo;
  final DateTime? raisedAt;
  final DateTime? resolvedAt;
  final int? rating;
  final String? review;
  final String? orderId;

  QueryModel({
    required this.id,
    required this.title,
    required this.message,
    required this.userEmail,
    List<ReplyModel>? replies,
    DateTime? createdAt,
    this.isRead = false,
    this.status,
    this.assignedTo,
    this.raisedAt,
    this.resolvedAt,
    this.rating,
    this.review,
    this.orderId,
  })  : replies = replies ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory QueryModel.fromJson(Map<String, dynamic> json) {
    String id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    String title = json['title']?.toString() ?? '';
    String message = json['message']?.toString() ?? json['description']?.toString() ?? '';

    // Handle raisedBy (Map or String)
    String userEmail = '';
    if (json['raisedBy'] is Map<String, dynamic>) {
      userEmail = json['raisedBy']['email']?.toString() ?? '';
    } else {
      userEmail = json['raisedBy']?.toString() ?? '';
    }

    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now();

    final replies = (json['replies'] as List<dynamic>?)
        ?.map((e) => ReplyModel.fromJson(e))
        .toList() ??
        [];

    bool isRead = json['isRead'] ?? false;

    String? status = json['status']?.toString();
    final isResolved = json['isResolved'];
    if (status == null && isResolved != null) {
      status = isResolved ? 'resolved' : 'open';
    }

    String? assignedTo;
    if (json['assignedTo'] is Map<String, dynamic>) {
      final a = json['assignedTo'];
      assignedTo = a['name']?.toString() ?? a['_id']?.toString() ?? a['id']?.toString();
    } else {
      assignedTo = json['assignedTo']?.toString();
    }

    final raisedAt = DateTime.tryParse(json['raisedAt']?.toString() ?? '');
    final resolvedAt = DateTime.tryParse(json['resolvedAt']?.toString() ?? '');

    int? rating;
    final rawRating = json['rating'];
    if (rawRating is int) {
      rating = rawRating;
    } else if (rawRating is String) {
      rating = int.tryParse(rawRating);
    }

    String? orderId;
    final rawOrderId = json['orderId'];
    if (rawOrderId is String) {
      orderId = rawOrderId;
    } else if (rawOrderId is Map<String, dynamic>) {
      orderId = rawOrderId['_id']?.toString() ?? rawOrderId['id']?.toString();
    }

    final review = json['review']?.toString();

    return QueryModel(
      id: id,
      title: title,
      message: message,
      userEmail: userEmail,
      replies: replies,
      createdAt: createdAt,
      isRead: isRead,
      status: status,
      assignedTo: assignedTo,
      raisedAt: raisedAt,
      resolvedAt: resolvedAt,
      rating: rating,
      review: review,
      orderId: orderId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'title': title,
      'message': message,
      'userEmail': userEmail,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'status': status,
      'assignedTo': assignedTo,
      'raisedAt': raisedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'rating': rating,
      'review': review,
      if (orderId != null) 'orderId': orderId,
    };
  }

  static QueryModel createNew({
    required String title,
    required String message,
    required String userEmail,
    String? orderId,
  }) {
    return QueryModel(
      id: _uuid.v4(),
      title: title,
      message: message,
      userEmail: userEmail,
      isRead: false,
      status: 'open',
      orderId: orderId,
    );
  }

  void addLocalReply(ReplyModel reply) {
    replies.add(reply);
  }
}

// =======================
// ReplyModel
// =======================
class ReplyModel {
  final String userId;
  final String replyText;
  final DateTime timestamp;
  final bool isAdmin;

  ReplyModel({
    required this.userId,
    required this.replyText,
    DateTime? timestamp,
    this.isAdmin = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    String userId = '';
    if (json['messagedBy'] is Map<String, dynamic>) {
      final mb = json['messagedBy'];
      userId = mb['_id']?.toString() ?? mb['id']?.toString() ?? '';
    } else {
      userId = json['messagedBy']?.toString() ?? '';
    }

    final replyText = json['replyText']?.toString() ?? json['message']?.toString() ?? '';
    final timestamp =
        DateTime.tryParse(json['messagedAt']?.toString() ?? '') ?? DateTime.now();

    final bool isAdmin = json['isAdmin'] ??
        (json['messagedBy'] is Map<String, dynamic> &&
            ['admin', 'employee'].contains(json['messagedBy']['role'])
            ? true
            : false);

    return ReplyModel(
      userId: userId,
      replyText: replyText,
      timestamp: timestamp,
      isAdmin: isAdmin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': replyText,
      'messagedBy': {
        '_id': userId,
      },
      'messagedAt': timestamp.toIso8601String(),
    };
  }

  static ReplyModel createNew({
    required String replyText,
    required String userId,
    bool isAdmin = false,
  }) {
    return ReplyModel(
      userId: userId,
      replyText: replyText,
      isAdmin: isAdmin,
    );
  }
}

// =======================
// MessageModel (Optional)
// =======================
class MessageModel {
  final String id;
  final String queryId;
  final String sender;
  final String text;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.queryId,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id']?.toString() ?? '',
      queryId: map['queryId']?.toString() ?? '',
      sender: map['sender']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'queryId': queryId,
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// =======================
// Request Models
// =======================
class RaiseQueryRequestModel {
  final String title;
  final String description;
  final String? orderId;

  RaiseQueryRequestModel({
    required this.title,
    required this.description,
    this.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (orderId != null) 'orderId': orderId,
    };
  }
}

class ReplyQueryRequestModel {
  final String queryId;
  final String message;

  ReplyQueryRequestModel({
    required this.queryId,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'queryId': queryId,
      'message': message,
    };
  }
}

class RateQueryRequestModel {
  final int rating;
  final String? review;

  RateQueryRequestModel({
    required this.rating,
    this.review,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'review': review,
    };
  }
}

// =======================
// Generic API Response Wrapper
// =======================
class ApiResponse<T> {
  final int? statusCode;
  final String? message;
  final T? data;

  ApiResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic) dataParser,
      ) {
    return ApiResponse<T>(
      statusCode: json['statusCode'],
      message: json['message'],
      data: dataParser(json['data']),
    );
  }
}
