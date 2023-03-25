import 'package:flutter/material.dart';
// importは省略しています
class AuthModalImage extends StatelessWidget {
  const AuthModalImage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 100,
      child: Image.asset('assets/images/globe.png'),
    );
  }
}