import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/data/product_model.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductsGridView.dart';
import 'package:mobiking/app/services/category_service.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class SubCategoryProductsScreen extends StatefulWidget {
  final String subcategorySlug;
  final String subcategoryName;

  const SubCategoryProductsScreen({
    Key? key,
    required this.subcategorySlug,
    required this.subcategoryName,
  }) : super(key: key);

  @override
  _SubCategoryProductsScreenState createState() =>
      _SubCategoryProductsScreenState();
}

class _SubCategoryProductsScreenState extends State<SubCategoryProductsScreen> {
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = CategoryService().getProductsBySubCategorySlug(
      widget.subcategorySlug,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subcategoryName),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        centerTitle: true,
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          } else {
            return AllProductsGridView(
              products: snapshot.data!,
              showTitle: false,
            );
          }
        },
      ),
    );
  }
}
