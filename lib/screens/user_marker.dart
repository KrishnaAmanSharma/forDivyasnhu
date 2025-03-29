import 'package:flutter/material.dart';

class UserMarker extends StatelessWidget {
  final bool isCurrentUser;
  final String? imageUrl;

  const UserMarker({
    Key? key,
    required this.isCurrentUser,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrentUser ? Colors.blue : Colors.red,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundImage: imageUrl != null
            ? NetworkImage(imageUrl!)
            : AssetImage('assets/default_profile.png') as ImageProvider,
        backgroundColor: Colors.grey[200],
        child: isCurrentUser ? Icon(Icons.person, color: Colors.blue) : null,
      ),
    );
  }
}
