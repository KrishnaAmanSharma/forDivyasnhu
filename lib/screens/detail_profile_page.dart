import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailProfilePage extends StatelessWidget {
  final String userId;

  DetailProfilePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  SizedBox(height: 16),
                  Text("User not found",
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final theme = Theme.of(context);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(userData),
                  collapseMode: CollapseMode.parallax,
                ),
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () => _showOptions(context, userData),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfoSection(userData, theme),
                      SizedBox(height: 24),
                      _buildAboutSection(userData),
                      SizedBox(height: 24),
                      _buildDetailsSection(userData),
                      SizedBox(height: 32),
                      _buildActionButtons(context, userData),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Stack(
      children: [
        // Background image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(userData['coverPhoto'] ?? ''),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Profile content
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Profile picture with status
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          NetworkImage(userData['profilePic'] ?? ''),
                      child: userData['profilePic'] == null
                          ? Icon(Icons.person, size: 50)
                          : null,
                    ),
                    if (userData['isActive'] ?? false)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 16),
                // Name and basic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userData['name'] ?? 'No Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        userData['interest'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection(Map<String, dynamic> userData, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoItem('Trips', '12', Icons.airplanemode_active),
        _buildInfoItem('Companions', '24', Icons.people),
        _buildInfoItem('Rating', '4.8', Icons.star),
      ],
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text(
          userData['bio'] ?? 'No bio available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(Map<String, dynamic> userData) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailItem(Icons.phone, 'Phone', userData['phone'] ?? 'N/A'),
          Divider(height: 24),
          _buildDetailItem(Icons.email, 'Email', userData['email'] ?? 'N/A'),
          Divider(height: 24),
          _buildDetailItem(
            Icons.location_on,
            'Location',
            '${userData['city'] ?? 'Unknown'}, ${userData['country'] ?? ''}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Map<String, dynamic> userData) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.message, size: 20),
            label: Text('Message'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _sendMessage(userData['userId']),
          ),
        ),
        SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.blue),
            onPressed: () => _showOptions(context, userData),
          ),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.phone, color: Colors.blue),
                title: Text('Call'),
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(userData['phone'] ?? '');
                },
              ),
              ListTile(
                leading: Icon(Icons.location_on, color: Colors.blue),
                title: Text('View on Map'),
                onTap: () {
                  Navigator.pop(context);
                  _openGoogleMaps(
                    (userData['latitude'] ?? 0).toDouble(),
                    (userData['longitude'] ?? 0).toDouble(),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.report, color: Colors.red),
                title: Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser(userData['userId']);
                },
              ),
              ListTile(
                leading: Icon(Icons.block, color: Colors.red),
                title: Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(userData['userId']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _makeCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(GlobalKey<NavigatorState>().currentContext!)
          .showSnackBar(SnackBar(content: Text("Could not make call")));
    }
  }

  void _openGoogleMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(GlobalKey<NavigatorState>().currentContext!)
          .showSnackBar(SnackBar(content: Text("Could not open maps")));
    }
  }

  void _sendMessage(String userId) {
    // Implement navigation to chat screen
    print("Messaging user: $userId");
  }

  void _reportUser(String userId) {
    // Implement report functionality
    print("Reporting user: $userId");
  }

  void _blockUser(String userId) {
    // Implement block functionality
    print("Blocking user: $userId");
  }
}
