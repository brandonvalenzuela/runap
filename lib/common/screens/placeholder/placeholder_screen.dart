import 'package:flutter/material.dart';
import 'package:runap/common/widgets/appbar/appbar.dart'; // Assuming TAppBar exists

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: Text(title),
        showBackArrow: true, // Show back arrow by default
      ),
      body: Center(
        child: Text(
          'Placeholder for "$title" screen.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 