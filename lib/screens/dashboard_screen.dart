import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travelcompanionfinder/screens/detail_profile_page.dart';
import 'package:travelcompanionfinder/theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_screen.dart';
import 'custom_appbar.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _showActiveOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Find Travel Companions",
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or interest...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 50),
                        SizedBox(height: 16),
                        Text(
                          "Error loading users",
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 50, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No users found",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                var users = snapshot.data!.docs.where((doc) {
                  var userData = doc.data() as Map<String, dynamic>;
                  bool matchesSearch = _searchQuery.isEmpty ||
                      (userData['name']
                                  ?.toString()
                                  .toLowerCase()
                                  .contains(_searchQuery) ==
                              true ||
                          (userData['interest']
                                  ?.toString()
                                  .toLowerCase()
                                  .contains(_searchQuery) ==
                              true));

                  bool matchesFilter =
                      !_showActiveOnly || (userData['isActive'] == true);

                  return matchesSearch && matchesFilter;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 50, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No matching users found",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          "Try adjusting your search or filters",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    await Future.delayed(Duration(seconds: 1));
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(10),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var userData =
                          users[index].data() as Map<String, dynamic>;
                      String userId = users[index].id;

                      return _buildUserCard(context, userData, userId);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
      BuildContext context, Map<String, dynamic> userData, String userId) {
    String name = userData['name'] ?? "Unknown";
    String profilePic = userData['profilePic'] ?? "";
    bool isActive = userData['isActive'] ?? false;
    String phone = userData['phone'] ?? "";
    String interest = userData['interest'] ?? "Not specified";
    double? latitude = userData['latitude']?.toDouble();
    double? longitude = userData['longitude']?.toDouble();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailProfilePage(userId: userId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'profile-$userId',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      (profilePic != null && profilePic!.isNotEmpty)
                          ? NetworkImage(profilePic!)
                          : AssetImage('assets/default_profile.png')
                              as ImageProvider,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name ?? "Unknown", // Handling null name
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isActive ?? false)
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (isActive ?? false)
                                    ? Icons.circle
                                    : Icons.circle_outlined,
                                color: (isActive ?? false)
                                    ? Colors.green
                                    : Colors.grey,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                (isActive ?? false) ? "Active" : "Inactive",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (isActive ?? false)
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      interest ?? "No Interests", // Handling null interest
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.phone,
                          color: AppTheme.primaryColor,
                          onPressed: () => _makeCall(phone),
                        ),
                        SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.location_on,
                          color: Colors.red,
                          onPressed: () {
                            if (latitude != null && longitude != null) {
                              _openGoogleMaps(latitude, longitude);
                            }
                          },
                          disabled: latitude == null || longitude == null,
                        ),
                        SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.message,
                          color: Colors.teal,
                          onPressed: () => _sendMessage(userData),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool disabled = false,
  }) {
    return IconButton(
      icon: Icon(icon),
      color: disabled ? Colors.grey : color,
      onPressed: disabled ? null : onPressed,
      splashRadius: 20,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(),
    );
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Filter Options"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text("Show active users only"),
                    value: _showActiveOnly,
                    onChanged: (value) {
                      setState(() {
                        _showActiveOnly = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No phone number available")),
      );
      return;
    }

    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch phone app")),
      );
    }
  }

  Future<void> _openGoogleMaps(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location not available")),
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
        SnackBar(content: Text("Could not launch maps")),
      );
    }
  }

  void _sendMessage(Map<String, dynamic> user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to message')),
      );
      return;
    }

    List<String> userIds = [currentUser.uid, user['id']];
    userIds.sort();
    final chatId = userIds.join('_');

    FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': {
        currentUser.uid: true,
        user['id']: true,
      },
      'participantNames': {
        currentUser.uid: currentUser.displayName ?? 'You',
        user['id']: user['name'] ?? 'User',
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

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
}
