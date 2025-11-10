class PolicyResponse {
  final int statusCode;
  final List<Policy> data;
  final String message;
  final bool success;

  PolicyResponse({
    required this.statusCode,
    required this.data,
    required this.message,
    required this.success,
  });

  factory PolicyResponse.fromJson(Map<String, dynamic> json) {
    return PolicyResponse(
      statusCode: json['statusCode'] as int,
      data: (json['data'] as List<dynamic>)
          .map((item) => Policy.fromJson(item as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String,
      success: json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'data': data.map((policy) => policy.toJson()).toList(),
      'message': message,
      'success': success,
    };
  }
}

class Policy {
  final String id;
  final String policyName;
  final String slug;
  final String heading;
  final String content;
  final DateTime? lastUpdated;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  Policy({
    required this.id,
    required this.policyName,
    required this.slug,
    required this.heading,
    required this.content,
    this.lastUpdated,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['_id'] as String,
      policyName: json['policyName'] as String,
      slug: json['slug'] as String,
      heading: json['heading'] as String,
      content: json['content'] as String,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      v: json['__v'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'policyName': policyName,
      'slug': slug,
      'heading': heading,
      'content': content,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}
