import 'package:flutter/material.dart';

class AppTheme {
  // Define Primary and Secondary Colors
  static const Color primaryColor = Color(0xFF1E88E5); // Blue
  static const Color secondaryColor = Color(0xFFF1F1F1); // Light Grey
  static const Color accentColor = Color(0xFF76FF03); // Green

  // Text Styles
  static TextStyle headingStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );
  static TextStyle subHeadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  static TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black54,
  );

  // Button Style
  static ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor, // Button background color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Rounded corners
    ),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
  );

  // Input Field Decoration
  static InputDecoration inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: primaryColor),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.black45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }
}
