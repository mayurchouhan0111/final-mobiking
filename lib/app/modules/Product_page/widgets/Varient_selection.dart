import 'package:flutter/material.dart';

class VariantSelector extends StatefulWidget {
  final List<String> variantNames;
  final int initialSelectedIndex;
  final Function(int) onVariantSelected;

  const VariantSelector({
    super.key,
    required this.variantNames,
    this.initialSelectedIndex = 0,
    required this.onVariantSelected,
  });

  @override
  State<VariantSelector> createState() => _VariantSelectorState();
}

class _VariantSelectorState extends State<VariantSelector> {
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
          'Select Variant',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(widget.variantNames.length, (index) {
              final variantName = widget.variantNames[index];
              final isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                  widget.onVariantSelected(index);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.deepPurple
                          : Colors.grey.shade400,
                      width: 1.5,
                    ),
                    color: isSelected
                        ? Colors.deepPurple.withOpacity(0.15)
                        : Colors.white,
                  ),
                  child: Text(
                    variantName,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
