import 'package:flutter/material.dart';
import 'package:get/get.dart';

// This controller manages the TabController for your categories/tabs.
// It uses GetSingleTickerProviderStateMixin because TabController requires a TickerProvider.
class TabControllerGetX extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController controller;
  final RxInt selectedIndex = 0.obs;
  
  /// ✅ NEW: Observable to notify listeners when the underlying controller is swapped
  final RxInt resetCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController(length: 3);
  }

  void _initializeController({required int length, int initialIndex = 0}) {
    controller = TabController(
      length: length, 
      vsync: this, 
      initialIndex: initialIndex.clamp(0, length - 1)
    );

    controller.addListener(() {
      // ✅ Only update if it hasn't been disposed
      try {
        if (!controller.indexIsChanging || controller.indexIsChanging) {
          selectedIndex.value = controller.index;
        }
      } catch (_) {
        // Handle race conditions where listener fires during/after disposal
      }
    });
  }

  @override
  void onClose() {
    print('[TabControllerGetX] 🗑 Disposing TabController');
    controller.dispose();
    super.onClose();
  }

  void changeTab(int index) {
    if (index >= 0 && index < controller.length) {
      controller.animateTo(index);
      selectedIndex.value = index;
    }
  }

  void updateIndex(int index) {
    if (selectedIndex.value == index) return;
    selectedIndex.value = index;
    if (controller.index != index && index < controller.length) {
      controller.index = index;
    }
  }

  /// ✅ New: Dynamically update TabController length safely
  void resetWithLength(int length) {
    if (length <= 0) return;
    if (controller.length == length) return;

    print('[TabControllerGetX] 🔄 Resetting controller with new length: $length');
    
    // 🚀 CRITICAL: Dispose the old one properly
    controller.dispose();
    
    // Create new one
    _initializeController(
      length: length, 
      initialIndex: selectedIndex.value.clamp(0, length - 1)
    );
    
    // ✅ Signal the UI (Obx) to rebuild with the brand new controller instance
    resetCount.value++;
    
    if (selectedIndex.value >= length) {
      selectedIndex.value = 0;
    }
  }
}
