import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/data/models/product.dart';
import 'package:mca_project/data/repositories/shop/shop_data_repository.dart';
import 'package:mca_project/presentation/common/widgets/loading_widgets.dart';
import 'package:mca_project/presentation/features/shop/product_upload/view/upload_product_screen.dart';
import 'package:mca_project/presentation/features/shop/product_upload/view_model/shop_bloc.dart';

import '../../../common/widgets/my_text_field_widget.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class ShopInventoryScreen extends StatelessWidget {
  const ShopInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<Product> products;
    final double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ShopBloc, ShopState>(
          listener: (context, state) {
            if (state is ShopSearchProductState) {
              products = state.products;
            } else {
              products = context.read<ShopDataRepository>().myUploadedProducts;
            }
          },
          builder: (context, state) {
            if (state is ShopLoadingState) {
              return LoadingWidgets.SpinKitFading(deviceWidth);
            }
            products = state.runtimeType == ShopSearchProductState
                ? (state as ShopSearchProductState).products
                : context.read<ShopDataRepository>().myUploadedProducts;
            if (products.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 80),
                    SizedBox(height: 20),
                    Text('No Products Found'),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    title: MyTextFieldWidget(
                      onChanged: (fieldVal) => context
                          .read<ShopBloc>()
                          .add(ShopSearchProductEvent(keyword: fieldVal)),
                      hintText: 'Enter Product Name or SKU',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return ProductCard(product: product);
                      },
                      childCount: products.length,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        activeBackgroundColor: Colors.red,
        activeForegroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: Icon(Icons.upload),
            label: 'Upload Product',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UploadProductScreen()),
            ),
          ),
          // Add more actions if needed
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Image.network(
              product.images.first,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Brand: ${product.brand}'),
                  Text('Price: \$${product.price}'),
                  Text('Stock: ${product.stockQuantity}'),
                  if (product.discountInPercentage != null)
                    Text('Discount: ${product.discountInPercentage}%'),
                  if (product.rating != null)
                    Row(
                      children: List.generate(
                        product.rating!.toInt(),
                        (index) => Icon(Icons.star, color: Colors.amber),
                      ),
                    ),
                  Text('SKU: ${product.sku}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
