import 'package:flutter/material.dart';

class EmptyCartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset('assets/images/empty_cart.png'),
            ),
          ), // Replace with your image path
          Expanded(
            child: Column(children: [
              Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: () {
              //     // Navigate back to product list or home screen
              //     Navigator.pop(context);
              //   },
              //   child: Text('Start Shopping'),
              // ),
            ]),
          )
        ],
      ),
    );
  }
}
