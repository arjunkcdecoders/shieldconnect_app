import 'package:flutter/material.dart';
import 'package:shieldconnect_app/view/login_screen.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class OnboardingItem {
  final String image;
  final String headline;
  final String subtitle;

  OnboardingItem({
    required this.image,
    required this.headline,
    required this.subtitle,
  });
}

class OnboardingController extends ChangeNotifier {
  final PageController pageController = PageController();
  int _currentPage = 0;

  int get currentPage => _currentPage;

  final List<OnboardingItem> items = [
    OnboardingItem(
      image: ImageAssets.obchild1,
      headline: "Now Discuss Anything",
      subtitle:
          "Create conferences, invite people,\nDiscuss any topic together.",
    ),
    OnboardingItem(
      image: ImageAssets.obchild2,
      headline: "See Each Other Anytime",
      subtitle:
          "Get to see each other anywhere,\nanytime. Enjoy safe, discreet messaging",
    ),
    OnboardingItem(
      image: ImageAssets.obchild3,
      headline: "Plan Anything & Anywhere",
      subtitle:
          "Just call to your group and plan your\ntrip or meeting at anytime.",
    ),
  ];

  void updatePage(int index) {
    _currentPage = index;
    notifyListeners();
  }

  void nextPage(BuildContext context) {
    if (_currentPage < items.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding and navigate to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void skip(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
