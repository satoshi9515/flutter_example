import 'package:zenly_like/components/auth_modal/auth_modal.dart';
import 'package:flutter/material.dart';
import 'package:zenly_like/components/app_loading.dart';

class SignOutButton extends StatelessWidget {
  const SignOutButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: isLoading ? const AppLoading() : const Icon(Icons.logout),
    );
  }
}