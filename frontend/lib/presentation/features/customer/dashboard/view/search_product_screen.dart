import 'package:flutter/material.dart';

import '../../../../../data/models/product.dart';
import '../../../shop/inventory/shop_inventory_screen.dart';

class SearchProductScreen extends StatelessWidget {
  final List<Product> products;
  const SearchProductScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return products.isEmpty
        ? Center(
            child: Text("No Products Found"),
          )
        : ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) =>
                ProductCard(product: products[index]));
  }
}
