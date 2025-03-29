import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travelcompanionfinder/theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_screen.dart';
import 'custom_appbar.dart';
import 'user_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 14.0;
  LatLng? _selectedLocation;
  bool _showFilters = false;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<String> _availableInterests = [];
  LatLng? _currentUserLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _getCurrentLocation();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      await _fetchUsers();
    } catch (e) {
      print("Error initializing Firebase: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentUserLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _focusOnCurrentLocation() async {
    if (_currentUserLocation != null) {
      _mapController.move(_currentUserLocation!, _currentZoom);
    } else {
      await _getCurrentLocation();
      if (_currentUserLocation != null) {
        _mapController.move(_currentUserLocation!, _currentZoom);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not fetch current location")),
        );
      }
    }
  }

  Future<void> _fetchUsers() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> users = [];
      Set<String> uniqueInterests = {};

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        if (userData['latitude'] != null && userData['longitude'] != null) {
          users.add({
            'id': doc.id,
            'name': userData['name'] ?? 'Unknown',
            'interest': userData['interest'] ?? 'General',
            'lat': userData['latitude'],
            'long': userData['longitude'],
            'profilePic': userData['profilePic'],
            'email': userData['email'],
            'phone': userData['phone'],
            'bio': userData['bio'],
          });

          if (userData['interest'] != null &&
              userData['interest'].toString().isNotEmpty) {
            uniqueInterests.add(userData['interest'].toString());
          }
        }
      }

      setState(() {
        _users = users;
        _filteredUsers = users;
        _availableInterests = uniqueInterests.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _zoomIn() {
    setState(() => _currentZoom += 1);
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _focusOnUser(Map<String, dynamic> user) {
    setState(() {
      _selectedLocation = LatLng(user['lat'], user['long']);
    });
    _mapController.move(LatLng(user['lat'], user['long']), _currentZoom);
  }

  void _zoomOut() {
    setState(() => _currentZoom -= 1);
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _showUserInfo(Map<String, dynamic> user) {
    setState(() {
      _selectedLocation = LatLng(user['lat'], user['long']);
    });
  }

  Widget _buildUserInfo(Map<String, dynamic> user) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 260,
        minWidth: 230,
        minHeight: 160,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 260,
              height: 50,
              child: Center(
                child: Text(
                  user['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (user['bio'] != null && user['bio'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  user['bio'],
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Text(
              'Interest: ${user['interest'] ?? 'General'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                _buildIconButton(
                  icon: Icons.directions,
                  color: AppTheme.primaryColor,
                  tooltip: 'Navigate',
                  onPressed: () => _navigateToUser(user),
                ),
                _buildIconButton(
                  icon: Icons.message,
                  tooltip: 'Message',
                  onPressed: () => _messageUser(user),
                ),
                if (user['phone'] != null && user['phone'].isNotEmpty)
                  _buildIconButton(
                    icon: Icons.call,
                    tooltip: 'Call',
                    color: Colors.green,
                    onPressed: () => _makeCall(user['phone']),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No phone number available")),
      );
      return;
    }

    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch phone app")),
      );
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    Color? color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, size: 18),
          color: color,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onPressed,
        ),
      ),
    );
  }

  void _navigateToUser(Map<String, dynamic> user) {
    final double lat = user['lat'] ?? 0.0;
    final double lng = user['long'] ?? 0.0;

    if (lat != 0.0 && lng != 0.0) {
      _openGoogleMaps(lat, lng);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not available")),
      );
    }
  }

  Future<void> _openGoogleMaps(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not available")),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch maps")),
      );
    }
  }

  void _messageUser(Map<String, dynamic> user) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Generate consistent chat ID by combining sorted user IDs
    List<String> ids = [currentUserId, user['id']];
    ids.sort();
    final chatId = ids.join('_');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          user: user,
          chatId: chatId,
        ),
      ),
    );
  }

  void _applyFilters(List<String> selectedInterests) {
    if (selectedInterests.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
    } else {
      setState(() {
        _filteredUsers = _users
            .where((user) => selectedInterests.contains(user['interest']))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "Travel Companions Map",
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentUserLocation ?? const LatLng(28.6139, 77.2090),
              initialZoom: _currentZoom,
              onTap: (_, __) => setState(() => _selectedLocation = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              if (_currentUserLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentUserLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on,
                          color: Colors.blue, size: 40),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  ..._filteredUsers.map((user) => Marker(
                        point: LatLng(user['lat'], user['long']),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _showUserInfo(user),
                          child: UserMarker(
                            imageUrl: user['profilePic'],
                            isCurrentUser: false,
                          ),
                        ),
                      )),
                ],
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80,
                      height: 80,
                      child: _buildUserInfo(
                        _filteredUsers.firstWhere((user) =>
                            user['lat'] == _selectedLocation!.latitude &&
                            user['long'] == _selectedLocation!.longitude),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "current_location",
                  onPressed: _focusOnCurrentLocation,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoom_in",
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.zoom_in, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.zoom_out, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
          if (_showFilters) _buildFilterPanel(),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    final Map<String, bool> interestFilters = {
      for (var interest in _availableInterests) interest: true
    };

    return Positioned(
      top: 80,
      right: 20,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter by Interest",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_availableInterests.isEmpty)
                    const Text('No interests available',
                        style: TextStyle(color: Colors.grey))
                  else
                    ..._availableInterests.map((interest) => CheckboxListTile(
                          title: Text(interest),
                          value: interestFilters[interest] ?? false,
                          onChanged: (value) {
                            setState(() {
                              interestFilters[interest] = value!;
                            });
                          },
                        )),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final selectedInterests = interestFilters.entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();
                      _applyFilters(selectedInterests);
                      setState(() => _showFilters = false);
                    },
                    child: const Text("Apply Filters"),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
