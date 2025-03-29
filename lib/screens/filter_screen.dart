import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class FilterScreen extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final Function(List<Map<String, dynamic>>) onFilterSubmit;

  FilterScreen(
      {required this.users,
      required this.onFilterSubmit,
      required List<Map<String, dynamic>> initialFilters});

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String selectedInterest = "Biker";
  double selectedRange = 5.0;

  List<Map<String, dynamic>> getFilteredUsers() {
    return widget.users.where((user) {
      double distance =
          _calculateDistance(28.6139, 77.2090, user["lat"], user["long"]);
      return user["interest"] == selectedInterest && distance <= selectedRange;
    }).toList();
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371; // Radius of Earth in kilometers
    var dLat = _degToRad(lat2 - lat1);
    var dLon = _degToRad(lon2 - lon1);
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c; // Distance in km
  }

  double _degToRad(double deg) {
    return deg * (pi / 180.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Filter Travelers")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedInterest,
              items: [
                "Biker",
                "Pilgrim",
                "Tourist",
                "Devotee",
                "College",
                "Party",
                "Exam Center"
              ].map((interest) {
                return DropdownMenuItem(value: interest, child: Text(interest));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedInterest = value!);
              },
            ),
            Slider(
              value: selectedRange,
              min: 1,
              max: 20,
              divisions: 4,
              label: "$selectedRange km",
              onChanged: (value) {
                setState(() => selectedRange = value);
              },
            ),
            ElevatedButton(
              onPressed: () {
                // Pass the filtered list back to the HomeScreen
                widget.onFilterSubmit(getFilteredUsers());
                Navigator.pop(context);
              },
              child: Text("Submit"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: getFilteredUsers().length,
                itemBuilder: (context, index) {
                  var user = getFilteredUsers()[index];
                  return ListTile(
                    title: Text(user["name"]),
                    subtitle: Text("Interest: ${user["interest"]}"),
                    leading: Icon(Icons.person),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
