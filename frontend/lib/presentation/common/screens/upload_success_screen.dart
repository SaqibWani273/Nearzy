import 'package:flutter/material.dart';

class UploadSuccessScreen extends StatelessWidget {
  final String? msg; // Optional to display uploaded category details

  const UploadSuccessScreen({Key? key, this.msg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.green, size: 60.0),
          const SizedBox(height: 20.0),
          Text(
            ' uploaded successfully!',
            style: TextStyle(fontSize: 20.0, color: Colors.green),
          ),
          if (msg != null) ...[
            // Show category name if provided
            const SizedBox(height: 10.0),
            Text(
              msg!,
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ],
      ),
    );
  }
}
