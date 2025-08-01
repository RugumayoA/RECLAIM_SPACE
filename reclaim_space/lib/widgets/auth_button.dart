import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onPressed;
  final bool dark;
  //final String? imagePath; 

  const AuthButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.dark = false,
    //this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 6),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? Colors.grey[850] : Colors.white,
          foregroundColor: dark ? Colors.white : Colors.black,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        // icon: imagePath != null
        //     ? Image.asset(imagePath!, height: 24, width: 24)
        //     : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
