class RazorpayVerifyRequest {
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;
  final String orderId; // Your backend's generated orderId

  RazorpayVerifyRequest({
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
    required this.orderId,
  });

  Map<String, dynamic> toJson() => {
    'razorpay_payment_id': razorpayPaymentId,
    'razorpay_order_id': razorpayOrderId,
    'razorpay_signature': razorpaySignature,
    'orderId': orderId,
  };
}
