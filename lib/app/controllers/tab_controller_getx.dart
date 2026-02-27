import 'package:flutter/material.dart';
import 'package:get/get.dart';

// This controller manages the TabController for your categories/tabs.
// It uses GetSingleTickerProviderStateMixin because TabController requires a TickerProvider.
class TabControllerGetX extends GetxController
    with GetSingleTickerProviderStateMixin {
  // late keyword means it will be initialized before first use, but not in the constructor.
  // It's initialized in onInit().
  late TabController controller;

  // RxInt for the currently selected tab index.
  // Using .obs makes it observable, so any Obx widget listening to it will rebuild.
  final RxInt selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize the TabController.
    // 'length' should be the total number of tabs you have.
    // Ensure this matches the number of tabs in your CustomTabBarSection.
    // For now, I'm setting it to 3 as a common default, adjust if needed.
    controller = TabController(length: 3, vsync: this);

    // Add a listener to the TabController to update our observable index.
    // This keeps the GetX RxInt in sync with the TabController's state.
    controller.addListener(() {
      if (controller.indexIsChanging || !controller.indexIsChanging) {
        // Only update if the index actually changes, or on initial load
        // to ensure Obx reacts. controller.indexIsChanging check can prevent
        // unnecessary rapid updates during animation, but for simplicity,
        // updating on any change is often fine.
        selectedIndex.value = controller.index;
      }
    });

    // You might want to pre-select a tab if needed
    // selectedIndex.value = 0; // Default to the first tab
  }

  // Called when the controller is removed from memory (e.g., when its parent page is disposed).
  // Crucial for performance to dispose of the TabController.
  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }

  // You can add methods to programmatically change tabs if needed
  void changeTab(int index) {
    if (index >= 0 && index < controller.length) {
      controller.animateTo(index);
      selectedIndex.value =
          index; // Update the observable value manually if not already updated by listener
    }
  }

  void updateIndex(int index) {
    if (selectedIndex.value == index) return; // Prevent unnecessary updates
    selectedIndex.value = index;
  }
}
