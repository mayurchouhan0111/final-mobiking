class CompanyDetailsResponse {
  final int statusCode;
  final CompanyDetails data;
  final String message;
  final bool success;

  CompanyDetailsResponse({
    required this.statusCode,
    required this.data,
    required this.message,
    required this.success,
  });

  factory CompanyDetailsResponse.fromJson(Map<String, dynamic> json) {
    return CompanyDetailsResponse(
      statusCode: json['statusCode'] as int,
      data: CompanyDetails.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String,
      success: json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'data': data.toJson(),
      'message': message,
      'success': success,
    };
  }
}

class CompanyDetails {
  final String id;
  final String phoneNo;
  final String whatsappNo;
  final String email;
  final String address;
  final String instaLink;
  final String? facebookLink;
  final String? twitterLink;
  final String? websiteLink;
  final String androidAppLink;
  final String? iosAppLink;
  final String? logoImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyDetails({
    required this.id,
    required this.phoneNo,
    required this.whatsappNo,
    required this.email,
    required this.address,
    required this.instaLink,
    this.facebookLink,
    this.twitterLink,
    this.websiteLink,
    required this.androidAppLink,
    this.iosAppLink,
    this.logoImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      id: json['_id'] as String,
      phoneNo: json['phoneNo'] as String,
      whatsappNo: json['whatsappNo'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      instaLink: json['instaLink'] as String,
      facebookLink: json['facebookLink'] as String?,
      twitterLink: json['twitterLink'] as String?,
      websiteLink: json['websiteLink'] as String?,
      androidAppLink: json['androidAppLink'] as String,
      iosAppLink: json['iosAppLink'] as String?,
      logoImage: json['logoImage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'phoneNo': phoneNo,
      'whatsappNo': whatsappNo,
      'email': email,
      'address': address,
      'instaLink': instaLink,
      'facebookLink': facebookLink,
      'twitterLink': twitterLink,
      'websiteLink': websiteLink,
      'androidAppLink': androidAppLink,
      'iosAppLink': iosAppLink,
      'logoImage': logoImage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
