import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildProductCard(String imagePath) {
  return Container(
    width: 100,
    height: 100,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Image.asset(imagePath, fit: BoxFit.contain),
  );
}
