import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShopLocalLoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 40,
            height: 40,
            color: Colors.grey[300],
          ),
        ),
        title: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 100,
            height: 20,
            color: Colors.grey[300],
          ),
        ),
        actions: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 30,
              height: 30,
              color: Colors.grey[300],
            ),
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 30,
              height: 30,
              color: Colors.grey[300],
            ),
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 30,
              height: 30,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 150,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 100,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: List.generate(4, (index) => _buildShimmerProductCard()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerProductCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.all(8.0),
        color: Colors.grey[300],
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 100,
              color: Colors.grey[300],
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 20,
              color: Colors.grey[300],
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 20,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
