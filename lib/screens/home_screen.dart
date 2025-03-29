import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:travelcompanionfinder/screens/dashboard_screen.dart';
import 'package:travelcompanionfinder/screens/map_screen.dart';

import '../theme.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  LatLng? _currentLocation;
  bool _locationLoading = false;
  String _locationError = '';

  final List<Widget> _pages = [
    DashboardScreen(),
    MapScreen(),
    ProfileScreen(),
  ];

  @override
/*************  ✨ Codeium Command ⭐  *************/
/// Initializes the state of the HomeScreen by setting up the page controller
/// and requesting location permissions.

/******  5027b7da-11ba-4104-ba3b-34ce40f11ecf  *******/
  void initState() {
    super.initState();
    _pageController = PageController();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _locationLoading = true;
      _locationError = '';
    });

    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        await _getCurrentLocation();
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _locationError =
              'Location permission permanently denied. Please enable it in app settings.';
        });
        await openAppSettings();
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error getting location: ${e.toString()}';
      });
    } finally {
      setState(() {
        _locationLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() {
        _locationError = 'Could not get current location: ${e.toString()}';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          if (_locationLoading)
            const Center(child: CircularProgressIndicator()),
          if (_locationError.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: _buildLocationError(),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLocationError() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(_locationError)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _locationError = ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: AppTheme.primaryColor,
          selectedItemColor: Colors.amberAccent,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: "Map",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
