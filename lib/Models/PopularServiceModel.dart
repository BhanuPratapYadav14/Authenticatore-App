// lib/Models/PopularServiceModel.dart (FIXED)

import 'package:flutter/material.dart';

class PopularServiceModel {
  final String id;
  final String name;
  final String iconText;
  final String route; // Route for navigation (e.g., specific setup page)
  final Color color; // Brand color for the icon background (Required for UI)
  final String setupUrl; // External link for setup guide (Good practice)

  PopularServiceModel({
    required this.id,
    required this.name,
    required this.iconText,
    required this.route,
    required this.color, // Now required
    required this.setupUrl, // Now required
  });
}
