import 'package:flutter/material.dart';

class ModeratorUsersController extends ChangeNotifier {
  List<Map<String, dynamic>> users = [
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
      "isActive": true,
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
      "isActive": true,
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
      "isActive": true,
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
      "isActive": false,
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
      "isActive": false,
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
      "isActive": true,
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
      "isActive": false,
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image": "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
      "isActive": true,
    },
  ];

  void toggleUserStatus(int index) {
    users[index]['isActive'] = !users[index]['isActive'];
    notifyListeners();
  }
}
