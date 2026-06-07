import 'package:flutter/material.dart';

class ModeratorHomeController extends ChangeNotifier {
  // Dummy data for the dashboard based on the image
  final List<Map<String, dynamic>> dashboardStats = [
    {"title": "Total Users", "value": "04", "color": const Color(0xFF0CA1CF)},
    {"title": "Pending Review", "value": "04", "color": const Color(0xFF1A9E16)},
    {"title": "Rejections", "value": "04", "color": const Color(0xFFC61D1D)},
    {"title": "Escalations", "value": "02", "color": const Color(0xFFD42554)},
  ];

  final List<Map<String, dynamic>> moderationItems = [
    {
      "postId": "post-007",
      "userName": "SkyRunner",
      "riskScore": "0.87",
      "tags": ["GROOMING", "TRUST_BUILDING"],
      "content": "You seem so mature for your age. I've never met anyone who underst...",
      "timestamp": "1/15/2025  8:45:00 PM",
    },
    {
      "postId": "post-007",
      "userName": "SkyRunner",
      "riskScore": "0.87",
      "tags": ["GROOMING", "TRUST_BUILDING"],
      "content": "You seem so mature for your age. I've never met anyone who underst...",
      "timestamp": "1/15/2025  8:45:00 PM",
    },
    {
      "postId": "post-007",
      "userName": "SkyRunner",
      "riskScore": "0.87",
      "tags": ["GROOMING", "TRUST_BUILDING"],
      "content": "You seem so mature for your age. I've never met anyone who underst...",
      "timestamp": "1/15/2025  8:45:00 PM",
    },
    {
      "postId": "post-007",
      "userName": "SkyRunner",
      "riskScore": "0.87",
      "tags": ["GROOMING", "TRUST_BUILDING"],
      "content": "You seem so mature for your age. I've never met anyone who underst...",
      "timestamp": "1/15/2025  8:45:00 PM",
    },
  ];

  final List<Map<String, dynamic>> recentRegistrations = [
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200"
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200"
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200"
    },
  ];
}
