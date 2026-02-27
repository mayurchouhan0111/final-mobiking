import 'dart:convert';

import 'package:mobiking/app/data/product_model.dart';
import 'package:mobiking/app/data/scan_model.dart';

import 'QueryModel.dart';

// ===================================================================
// QUERY MODEL (Included from previous context for completeness)
// ===================================================================


// ===================================================================
// SELLING PRICE & PRODUCT MODELS (Unchanged)
// ===================================================================
class SellingPrice {
  final String id;
  final String variantName;
  final double price;
  final int quantity;

  SellingPrice({required this.id, required this.variantName, required this.price, required this.quantity});

  factory SellingPrice.fromJson(Map<String, dynamic> json) {
    return SellingPrice(
      id: json['_id']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'variantName': variantName,
      'price': price,
      'quantity': quantity,
    };
  }
}

class OrderItemProductModel {
  final String id;
  final String name;
  final String fullName;
  final String slug;
  final String description;
  final bool active;
  final bool newArrival;
  final bool liked;
  final bool bestSeller;
  final bool recommended;
  final List<SellingPrice> sellingPrice;
  final String categoryId;
  final List<String> images;
  final int totalStock;
  final List<String> stockIds;
  final List<String> orderIds;
  final List<String> groupIds;
  final Map<String, int> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  OrderItemProductModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.slug,
    required this.description,
    required this.active,
    required this.newArrival,
    required this.liked,
    required this.bestSeller,
    required this.recommended,
    required this.sellingPrice,
    required this.categoryId,
    required this.images,
    required this.totalStock,
    required this.stockIds,
    required this.orderIds,
    required this.groupIds,
    required this.variants,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory OrderItemProductModel.fromJson(Map<String, dynamic> json) {
    return OrderItemProductModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      active: json['active'] as bool? ?? false,
      newArrival: json['newArrival'] as bool? ?? false,
      liked: json['liked'] as bool? ?? false,
      bestSeller: json['bestSeller'] as bool? ?? false,
      recommended: json['recommended'] as bool? ?? false,
      sellingPrice: (json['sellingPrice'] as List<dynamic>?)
          ?.map((e) => SellingPrice.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      categoryId: (json['category'] is Map && json['category'] != null)
          ? json['category']['_id']?.toString() ?? ''
          : (json['category'] is String ? json['category'].toString() : ''),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      totalStock: (json['totalStock'] as num?)?.toInt() ?? 0,
      stockIds: (json['stock'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      orderIds: (json['orders'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      groupIds: (json['groups'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      variants: Map<String, int>.from(json['variants'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'fullName': fullName,
      'slug': slug,
      'description': description,
      'active': active,
      'newArrival': newArrival,
      'liked': liked,
      'bestSeller': bestSeller,
      'recommended': recommended,
      'sellingPrice': sellingPrice.map((e) => e.toJson()).toList(),
      'category': categoryId,
      'images': images,
      'totalStock': totalStock,
      'stock': stockIds,
      'orders': orderIds,
      'groups': groupIds,
      'variants': variants,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}

class OrderItemModel {
  final String id;
  final OrderItemProductModel? productDetails;
  final String variantName;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.id,
    this.productDetails,
    required this.variantName,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['_id']?.toString() ?? '',
      productDetails: json['productId'] != null 
          ? (json['productId'] is Map<String, dynamic>
              ? OrderItemProductModel.fromJson(json['productId'] as Map<String, dynamic>)
              : OrderItemProductModel(
                  id: json['productId'].toString(),
                  name: '',
                  fullName: '',
                  slug: '',
                  description: '',
                  active: true,
                  newArrival: false,
                  liked: false,
                  bestSeller: false,
                  recommended: false,
                  sellingPrice: [],
                  categoryId: '',
                  images: [],
                  totalStock: 0,
                  stockIds: [],
                  orderIds: [],
                  groupIds: [],
                  variants: {},
                ))
          : null,
      variantName: json['variantName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productDetails?.toJson(),
      'variantName': variantName,
      'quantity': quantity,
      'price': price,
    };
  }
}

class OrderUserModel {
  final String id;
  final String? email;
  final String? phoneNo;

  OrderUserModel({
    required this.id,
    this.email,
    this.phoneNo,
  });

  factory OrderUserModel.fromJson(Map<String, dynamic> json) {
    return OrderUserModel(
      id: json['_id']?.toString() ?? '',
      email: json['email']?.toString(),
      phoneNo: json['phoneNo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'phoneNo': phoneNo,
    };
  }
}

class RequestModel {
  final String? id;
  final String type;
  final bool isRaised;
  final DateTime? raisedAt;
  final bool isResolved;
  final String status;
  final DateTime? resolvedAt;
  final String? reason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RequestModel({
    this.id,
    required this.type,
    this.isRaised = false,
    this.raisedAt,
    this.isResolved = false,
    this.status = "Pending",
    this.resolvedAt,
    this.reason,
    this.createdAt,
    this.updatedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['_id']?.toString(),
      type: json['type']?.toString() ?? 'Unknown',
      isRaised: json['isRaised'] as bool? ?? false,
      raisedAt: DateTime.tryParse(json['raisedAt']?.toString() ?? ''),
      isResolved: json['isResolved'] as bool? ?? false,
      status: json['status']?.toString() ?? 'Pending',
      resolvedAt: DateTime.tryParse(json['resolvedAt']?.toString() ?? ''),
      reason: json['reason']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'isRaised': isRaised,
      'raisedAt': raisedAt?.toIso8601String(),
      'isResolved': isResolved,
      'status': status,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'reason': reason,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}


// ===================================================================
// FULLY ALIGNED ORDER MODEL
// ===================================================================

class OrderModel {
  final String id;
  final String orderId;

  // Core Order States
  final String status;
  final String? reason; // MODIFIED: Changed from holdReason to generic reason
  final String? comments; // ADDED
  final String shippingStatus;
  final List<Scan>? scans;
  final Map<String, dynamic>? returnData; // ADDED: For Mixed type
  final String paymentStatus;
  final DateTime? paymentDate; // ADDED
  final bool isReviewed;

  // Shiprocket Fields
  final String? shipmentId;
  final String? shiprocketOrderId;
  final String? shiprocketChannelId;
  final String? awbCode;
  final String? courierName;
  final DateTime? courierAssignedAt;
  final bool pickupScheduled;
  final String? pickupTokenNumber;
  final String? pickupDate;
  final String? expectedDeliveryDate;
  final String? pickupSlot;
  final String? shippingLabelUrl;
  final String? shippingManifestUrl;
  final String? deliveredAt;
  final String? rtoInitiatedAt; // ADDED
  final String? rtoDeliveredAt; // ADDED
  final String? retrunDeliveredAt; // ADDED

  // Payment Fields
  final String? razorpayOrderId;
  final String? razorpayPaymentId;

  // Order Requests
  final List<RequestModel> requests;

  // Order Metadata
  final String type;
  final String method;
  final bool isAppOrder;
  final bool abondonedOrder;

  // Pricing
  final String? couponId; // ADDED: To store the coupon's _id
  final double orderAmount;
  final double deliveryCharge;
  final double discount;
  final String? gst;
  final double? subtotal;

  // Customer Info
  final String? name;
  final String? email;
  final String? phoneNo;

  // Address
  final String? address; // Main address line
  final String? address2; // ADDED
  final String? city; // ADDED
  final String? state; // ADDED
  final String? pincode; // ADDED
  final String? country; // ADDED
  final String? addressId;

  // Relations
  final OrderUserModel? userId;
  final QueryModel? query; // ADDED: To hold populated query details

  // Product/Items Details
  final List<OrderItemModel> items;
  final double? length; // ADDED
  final double? breadth; // ADDED
  final double? height; // ADDED
  final double? weight; // ADDED

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? v;


  OrderModel({
    required this.id,
    required this.orderId,
    required this.status,
    this.reason, // MODIFIED
    this.comments, // ADDED
    required this.shippingStatus,
    this.scans,
    this.returnData, // ADDED
    required this.paymentStatus,
    this.paymentDate, // ADDED
    this.isReviewed = false,
    this.shipmentId,
    this.shiprocketOrderId,
    this.shiprocketChannelId,
    this.awbCode,
    this.courierName,
    this.courierAssignedAt,
    this.pickupScheduled = false,
    this.pickupTokenNumber,
    this.pickupDate,
    this.expectedDeliveryDate,
    this.pickupSlot,
    this.shippingLabelUrl,
    this.shippingManifestUrl,
    this.deliveredAt,
    this.rtoInitiatedAt, // ADDED
    this.rtoDeliveredAt, // ADDED
    this.retrunDeliveredAt, // ADDED
    this.razorpayOrderId,
    this.razorpayPaymentId,
    List<RequestModel>? requests,
    required this.type,
    required this.method,
    this.isAppOrder = false,
    this.abondonedOrder = true,
    this.couponId, // ADDED
    required this.orderAmount,
    this.deliveryCharge = 0.0,
    this.discount = 0.0,
    this.gst,
    this.subtotal,
    this.name,
    this.email,
    this.phoneNo,
    this.address,
    this.address2, // ADDED
    this.city, // ADDED
    this.state, // ADDED
    this.pincode, // ADDED
    this.country, // ADDED
    this.addressId,
    this.userId,
    this.query, // ADDED
    required this.items,
    this.length, // ADDED
    this.breadth, // ADDED
    this.height, // ADDED
    this.weight, // ADDED
    required this.createdAt,
    required this.updatedAt,
    this.v,
  }) : requests = requests ?? [];

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    print('Parsing OrderModel. Query field: ${json['query']}');
    return OrderModel(
      id: json['_id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'New',
      reason: json['reason']?.toString(), // MODIFIED
      comments: json['comments']?.toString(), // ADDED
      shippingStatus: json['shippingStatus']?.toString() ?? 'Pending',
      scans: (json['scans'] as List<dynamic>?)
          ?.map((e) => Scan.fromJson(e as Map<String, dynamic>))
          .toList(),
      returnData: json['returnData'] as Map<String, dynamic>?, // ADDED
      paymentStatus: json['paymentStatus']?.toString() ?? 'Pending',
      paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? ''), // ADDED
      isReviewed: json['isReviewed'] as bool? ?? false,

      shipmentId: json['shipmentId']?.toString(),
      shiprocketOrderId: json['shiprocketOrderId']?.toString(),
      shiprocketChannelId: json['shiprocketChannelId']?.toString(),
      awbCode: json['awbCode']?.toString(),
      courierName: json['courierName']?.toString(),
      courierAssignedAt: DateTime.tryParse(json['courierAssignedAt']?.toString() ?? ''),
      pickupScheduled: json['pickupScheduled'] as bool? ?? false,
      pickupTokenNumber: json['pickupTokenNumber']?.toString(),
      pickupDate: json['pickupDate']?.toString(),
      expectedDeliveryDate: json['expectedDeliveryDate']?.toString(),
      pickupSlot: json['pickupSlot']?.toString(),
      shippingLabelUrl: json['shippingLabelUrl']?.toString(),
      shippingManifestUrl: json['shippingManifestUrl']?.toString(),
      deliveredAt: json['deliveredAt']?.toString(),
      rtoInitiatedAt: json['rtoInitiatedAt']?.toString(), // ADDED
      rtoDeliveredAt: json['rtoDeliveredAt']?.toString(), // ADDED
      retrunDeliveredAt: json['retrunDeliveredAt']?.toString(), // ADDED

      razorpayOrderId: json['razorpayOrderId']?.toString(),
      razorpayPaymentId: json['razorpayPaymentId']?.toString(),

      requests: (json['requests'] as List<dynamic>?)
          ?.map((e) => RequestModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],

      type: json['type']?.toString() ?? 'Regular',
      method: json['method']?.toString() ?? 'COD',
      isAppOrder: json['isAppOrder'] as bool? ?? false,
      abondonedOrder: json['abondonedOrder'] as bool? ?? true,

      couponId: (json['coupon'] is Map ? json['coupon']['_id'] : json['coupon'])?.toString(), // ADDED

      orderAmount: (json['orderAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      gst: json['gst']?.toString(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),

      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phoneNo: json['phoneNo']?.toString(),

      address: json['address']?.toString(),
      address2: json['address2']?.toString(), // ADDED
      city: json['city']?.toString(), // ADDED
      state: json['state']?.toString(), // ADDED
      pincode: json['pincode']?.toString(), // ADDED
      country: json['country']?.toString(), // ADDED
      addressId: json['addressId']?.toString(),

      userId: json['userId'] != null && json['userId'] is Map
          ? OrderUserModel.fromJson(json['userId'] as Map<String, dynamic>)
          : null,

      query: json['query'] != null && json['query'] is Map // ADDED
          ? QueryModel.fromJson(json['query'] as Map<String, dynamic>)
          : null,

      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],

      length: (json['length'] as num?)?.toDouble(), // ADDED
      breadth: (json['breadth'] as num?)?.toDouble(), // ADDED
      height: (json['height'] as num?)?.toDouble(), // ADDED
      weight: (json['weight'] as num?)?.toDouble(), // ADDED

      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderId': orderId,
      'status': status,
      'reason': reason, // MODIFIED
      'comments': comments, // ADDED
      'shippingStatus': shippingStatus,
      'scans': scans?.map((e) => e.toJson()).toList(),
      'returnData': returnData, // ADDED
      'paymentStatus': paymentStatus,
      'paymentDate': paymentDate?.toIso8601String(), // ADDED
      'isReviewed': isReviewed,
      'shipmentId': shipmentId,
      'shiprocketOrderId': shiprocketOrderId,
      'shiprocketChannelId': shiprocketChannelId,
      'awbCode': awbCode,
      'courierName': courierName,
      'courierAssignedAt': courierAssignedAt?.toIso8601String(),
      'pickupScheduled': pickupScheduled,
      'pickupTokenNumber': pickupTokenNumber,
      'pickupDate': pickupDate,
      'expectedDeliveryDate': expectedDeliveryDate,
      'pickupSlot': pickupSlot,
      'shippingLabelUrl': shippingLabelUrl,
      'shippingManifestUrl': shippingManifestUrl,
      'deliveredAt': deliveredAt,
      'rtoInitiatedAt': rtoInitiatedAt, // ADDED
      'rtoDeliveredAt': rtoDeliveredAt, // ADDED
      'retrunDeliveredAt': retrunDeliveredAt, // ADDED
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'requests': requests.map((e) => e.toJson()).toList(),
      'type': type,
      'method': method,
      'isAppOrder': isAppOrder,
      'abondonedOrder': abondonedOrder,
      'coupon': couponId, // ADDED
      'orderAmount': orderAmount,
      'deliveryCharge': deliveryCharge,
      'discount': discount,
      'gst': gst,
      'subtotal': subtotal,
      'name': name,
      'email': email,
      'phoneNo': phoneNo,
      'address': address,
      'address2': address2, // ADDED
      'city': city, // ADDED
      'state': state, // ADDED
      'pincode': pincode, // ADDED
      'country': country, // ADDED
      'addressId': addressId,
      'userId': userId?.toJson(),
      'query': query?.id, // ADDED: Send back only the ID
      'items': items.map((e) => e.toJson()).toList(),
      'length': length, // ADDED
      'breadth': breadth, // ADDED
      'height': height, // ADDED
      'weight': weight, // ADDED
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}

class OrdersResponse {
  final int statusCode;
  final List<OrderModel> data;
  final String message;
  final bool success;

  OrdersResponse({
    required this.statusCode,
    required this.data,
    required this.message,
    required this.success,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      statusCode: json['statusCode'] as int? ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'data': data.map((e) => e.toJson()).toList(),
      'message': message,
      'success': success,
    };
  }
}