import 'package:flutter/material.dart';

class CustomColorSelector extends StatefulWidget {
  final List<Map<String, dynamic>> colorOptions;
  final int initialSelectedIndex;
  final Function(int index, Map<String, dynamic> selectedColor) onColorSelected;

  const CustomColorSelector({
    super.key,
    required this.colorOptions,
    this.initialSelectedIndex = 0,
    required this.onColorSelected,
  });

  @override
  State<CustomColorSelector> createState() => _CustomColorSelectorState();
}

class _CustomColorSelectorState extends State<CustomColorSelector> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Colour',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(widget.colorOptions.length, (index) {
              final colorItem = widget.colorOptions[index];
              final bool isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                  widget.onColorSelected(index, colorItem);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurple.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.deepPurple
                          : Colors.grey.shade400,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    colorItem['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.deepPurple : Colors.black87,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
