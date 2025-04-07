import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travelcompanionfinder/theme.dart';
import 'custom_appbar.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? profilePic;
  String? bio;
  String? email;
  String? phone;
  String? interest;
  bool? isActive;
  double? latitude;
  double? longitude;
  bool isLoading = true;
  bool isProfileComplete = false;
  bool isUpdatingLocation = false;
  bool isUpdatingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            name = userDoc['name'];
            profilePic = userDoc['profilePic'];
            bio = userDoc['bio'];
            email = userDoc['email'] ?? user.email;
            phone = userDoc['phone'];
            interest = userDoc['interest'];
            isActive = userDoc['isActive'] ?? false;
            latitude = userDoc['latitude'];
            longitude = userDoc['longitude'];
            isProfileComplete = name != null &&
                bio != null &&
                profilePic != null &&
                phone != null &&
                interest != null;
            isLoading = false;
          });
        } else {
          // Create a basic user document if it doesn't exist
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': false,
            'profilePic': null,
            'name': 'please update',
            'bio': 'please update',
            'phone': 'please update',
            'interest': 'please update',
            'latitude': null,
            'longitude': null,
            'lastLocationUpdate': null,

          });

          setState(() {
            isLoading = false;
            isProfileComplete = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user data: ${e.toString()}")),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isUpdatingLocation = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Location permissions are permanently denied")),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _updateUserLocation(position.latitude, position.longitude);

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isUpdatingLocation = false;
      });
    }
  }

  Future<void> _updateUserLocation(double lat, double lng) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'latitude': lat,
          'longitude': lng,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location updated successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating location: ${e.toString()}")),
      );
    }
  }

  Future<void> _toggleActiveStatus(bool value) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'isActive': value});

        setState(() {
          isActive = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(value ? "You're now active!" : "You're now inactive")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: ${e.toString()}")),
      );
    }
  }

  Future<String?> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploading image...")),
        );

        File compressedImage = await compressImage(File(image.path));
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String imageId = DateTime.now().millisecondsSinceEpoch.toString();

        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pics/$userId/$imageId.jpg');

        UploadTask uploadTask = storageRef.putFile(
          compressedImage,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'uploadedBy': userId},
          ),
        );

        TaskSnapshot snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          String imageUrl = await snapshot.ref.getDownloadURL();

          // Update user document
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'profilePic': imageUrl});

          // Update the parent widget's state
          if (mounted) {
            setState(() {
              profilePic = imageUrl;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Profile picture updated successfully!")),
          );

          return imageUrl;
        }
      }
    } catch (e, stackTrace) {
      print('Image upload error: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: ${e.toString()}")),
      );
    }
    return null;
  }

  Future<File> compressImage(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      file.absolute.path + '_compressed.jpg',
      quality: 70, // Adjust quality as needed
      minWidth: 800, // Set maximum width
      minHeight: 800, // Set maximum height
    );
    return File(result!.path);
  }

  void _showEditProfileDialog() {
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController bioController = TextEditingController(text: bio);
    TextEditingController phoneController = TextEditingController(text: phone);
    TextEditingController interestController =
        TextEditingController(text: interest);
    TextEditingController profilePicUrlController =
        TextEditingController(text: profilePic);

    String? newProfilePic = profilePic;
    bool isUploadingImage = false;
    bool isUpdatingProfile = false;

    bool isValidUrl(String url) {
      try {
        final uri = Uri.parse(url);
        return uri.hasAbsolutePath &&
            (uri.scheme == 'http' || uri.scheme == 'https');
      } catch (_) {
        return false;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Update Profile"),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          setState(() => isUploadingImage = true);
                          String? imageUrl = await _pickAndUploadImage();
                          if (imageUrl != null) {
                            setState(() {
                              newProfilePic = imageUrl;
                              profilePicUrlController.text = '';
                            });
                          }
                          setState(() => isUploadingImage = false);
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: (newProfilePic != null &&
                                      newProfilePic!.isNotEmpty)
                                  ? NetworkImage(newProfilePic!)
                                  : const AssetImage(
                                          'assets/default_profile.png')
                                      as ImageProvider,
                              child: (newProfilePic == null ||
                                      newProfilePic!.isEmpty)
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.white)
                                  : null,
                              onBackgroundImageError: (exception, stackTrace) {
                                setState(() => newProfilePic = null);
                              },
                            ),
                            if (isUploadingImage)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: bioController,
                        decoration: const InputDecoration(
                          labelText: "Bio",
                          border: OutlineInputBorder(),
                          counterText: 'Max 200 characters',
                        ),
                        maxLines: 3,
                        maxLength: 200,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length < 8) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: profilePicUrlController,
                        decoration: const InputDecoration(
                          labelText: "Or enter profile picture URL",
                          border: OutlineInputBorder(),
                          hintText: "https://example.com/image.jpg",
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: (value) {
                          if (value.isNotEmpty && isValidUrl(value)) {
                            setState(() => newProfilePic = value);
                          } else {
                            setState(() => newProfilePic = null);
                          }
                        },
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!Uri.tryParse(value)!.hasAbsolutePath) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: interestController,
                        decoration: const InputDecoration(
                          labelText: "Interests",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your interests';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    setState(() => isUpdatingProfile = true);

                    try {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final profilePicToSave =
                            profilePicUrlController.text.isNotEmpty
                                ? profilePicUrlController.text
                                : newProfilePic ?? profilePic;

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                          'name': nameController.text,
                          'bio': bioController.text,
                          'phone': phoneController.text,
                          'interest': interestController.text,
                          'profilePic': profilePicToSave,
                          'updatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                        if (mounted) {
                          setState(() {
                            name = nameController.text;
                            bio = bioController.text;
                            interest = interestController.text;
                            phone = phoneController.text;
                            profilePic = profilePicToSave;
                            isProfileComplete = true;
                          });
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Profile updated successfully!")),
                        );
                        _fetchUserData();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Error updating profile: ${e.toString()}")),
                      );
                    } finally {
                      setState(() => isUpdatingProfile = false);
                    }
                  },
                  child: isUpdatingProfile
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? "Not set",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Profile",
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: (profilePic != null &&
                                        profilePic!.isNotEmpty)
                                    ? NetworkImage(profilePic!)
                                    : const AssetImage(
                                            'assets/default_profile.png')
                                        as ImageProvider,
                                child:
                                    (profilePic == null || profilePic!.isEmpty)
                                        ? const Icon(Icons.person,
                                            size: 50, color: Colors.white)
                                        : null,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  color: Colors.white,
                                  onPressed: _showEditProfileDialog,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name ?? "No Name",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (bio != null && bio!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              bio!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          _buildInfoRow(Icons.email, "Email", email),
                          _buildInfoRow(Icons.phone, "Phone", phone),
                          _buildInfoRow(Icons.interests, "Interest", interest),
                          _buildInfoRow(
                            Icons.location_on,
                            "Location",
                            latitude != null && longitude != null
                                ? "${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}"
                                : "Not set",
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Active Status",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Switch(
                                value: isActive ?? false,
                                onChanged: _toggleActiveStatus,
                                activeColor: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.location_on,
                                      size: 20, color: Colors.white),
                                  label: Text(
                                    isUpdatingLocation
                                        ? "Updating..."
                                        : "Update Location",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  onPressed: isUpdatingLocation
                                      ? null
                                      : _getCurrentLocation,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit,
                                      size: 20, color: Colors.white),
                                  label: const Text("Edit Profile",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.1,
                                      )),
                                  onPressed: _showEditProfileDialog,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    backgroundColor: Colors.blueGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isProfileComplete) ...[
                    const SizedBox(height: 20),
                    Card(
                      color: Colors.orange[50],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text(
                                  "Profile Incomplete",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Please complete your profile to get the best experience. "
                              "Add your name, bio, profile picture, phone number, and interests.",
                              style: TextStyle(
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
