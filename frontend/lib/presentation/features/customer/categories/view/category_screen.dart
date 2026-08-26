import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/data/repositories/customer/customer_data_repository.dart';
import '../../../../../data/models/category/product_category/product_category.dart';
import '../../../../../data/models/product.dart';
import '../../../../../services/api_service.dart';
import '../../../../../utils/exceptions/custom_exception.dart';
import '../../../../common/screens/error_screen.dart';
import '../../../../common/widgets/loading_widgets.dart';
import '../../product/view/product_details_screen.dart';

class CategoryScreen extends StatelessWidget {
  final ProductCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final products = context
        .read<CustomerDataRepository>()
        .products
        .where((product) => product.category.name == category.name)
        .toSet()
        .toList();
    double deviceWidth = MediaQuery.of(context).size.width;
    var deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        body: products.isEmpty
            ? Center(child: Text("No Products Available"))
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: deviceHeight * 0.3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  var item = products[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(product: item),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            flex: deviceHeight < 550 ? 1 : 0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30.0),
                                  topRight: Radius.circular(30.0)),
                              child: Hero(
                                tag: item.id!,
                                child: Image.network(
                                    fit: BoxFit.fill,
                                    height: deviceHeight * 0.2,
                                    // width: deviceWidth * 0.4,
                                    item.images.first),
                              ),
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0, right: 10.0, bottom: 20.0),
                            child: Row(
                              children: [
                                Expanded(child: Text(item.name)),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text("₹" + item.price.toString()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ));
  }
}
