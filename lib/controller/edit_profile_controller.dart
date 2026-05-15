import 'package:flutter/material.dart';

/// Externalized reactive state tracking for field Focus Nodes and editing parameters
class EditProfileController extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode aboutFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();

  EditProfileController() {
    // Attach reactive update listeners to trigger instantaneous UI shadow repainting
    nameFocusNode.addListener(notifyListeners);
    aboutFocusNode.addListener(notifyListeners);
    emailFocusNode.addListener(notifyListeners);
  }

  @override
  void dispose() {
    nameController.dispose();
    aboutController.dispose();
    emailController.dispose();
    nameFocusNode.dispose();
    aboutFocusNode.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }
}
