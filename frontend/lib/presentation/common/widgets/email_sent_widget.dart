import 'package:flutter/material.dart';

class EmailSentWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  const EmailSentWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(Icons.email, size: 60.0, color: Colors.blue),
          ),
          const Text(
            'Verification Email Sent!',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Text(
              'A verification email has been sent to your address. Please check your inbox and click the link to verify your Email.',
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton(
            onPressed: onPressed,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
