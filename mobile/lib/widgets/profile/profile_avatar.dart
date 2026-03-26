import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String avatarUrl;
  final bool isEditing;
  final VoidCallback? onCameraTap;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    this.isEditing = false,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF80ed99);

    return Hero(
      tag: 'profile_avatar',
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF80ed99), Color(0xFF57cc99)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                image: DecorationImage(
                  image: NetworkImage(avatarUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (isEditing)
            Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: onCameraTap,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 5, right: 5),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black87,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
