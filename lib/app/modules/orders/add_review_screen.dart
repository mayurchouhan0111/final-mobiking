import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/order_controller.dart';
import 'package:mobiking/app/data/order_model.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Assuming you have a custom theme file

class AddReviewScreen extends StatefulWidget {
  final OrderModel order;

  const AddReviewScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _reviewController = TextEditingController();
  final OrderController _orderController = Get.find();
  double _rating = 0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Review'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ${widget.order.orderId}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'You are reviewing this order.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Rate your experience'),
            const SizedBox(height: 16),
            Center(
              child: RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                glow: false,
                itemSize: 40.0,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                    const Icon(Icons.star_rounded, color: Colors.amber),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),
            const SizedBox(height: 40),
            _buildSectionTitle('Write your review'),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: 'Share your thoughts about this order...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.neutralBackground),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.neutralBackground,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryPurple,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 40),
            Obx(() {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_orderController.isLoading.value || _rating == 0)
                      ? null
                      : () {
                          _orderController.submitReview(
                            widget.order.id,
                            _rating,
                            _reviewController.text,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: _orderController.isLoading.value
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Text(
                          'Submit Review',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }
}
