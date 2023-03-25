import 'package:flutter/material.dart';
import 'package:zenly_like/screens/profile_screen/profile_screen.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({
    super.key,
    required this.onPressed,
  });
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.person),
    );
  }
}