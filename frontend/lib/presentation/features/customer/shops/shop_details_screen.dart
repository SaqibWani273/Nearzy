import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mca_project/data/models/product.dart';
import 'package:mca_project/data/models/shop_model/shop_model1.dart';
import 'package:mca_project/presentation/common/screens/error_screen.dart';
import 'package:mca_project/presentation/common/widgets/loading_widgets.dart';
import 'package:mca_project/services/api_service.dart';
import 'package:mca_project/utils/exceptions/custom_exception.dart';

import '../../shop/shop_profile/shop_profile_screen.dart';
import '../product/view/product_details_screen.dart';

class ShopDetailsScreen extends StatelessWidget {
  final ShopModel1 shop;

  const ShopDetailsScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    var deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: FutureBuilder(
        future: ApiService.fetchProductsByShopId(shop.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingWidgets.SpinKitFading(deviceWidth);
          }

          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return ErrorScreen(
                customException: CustomException(
                    message: "Error Loading Data",
                    errorType: ErrorType.unknown),
                onTryAgainPressed: () {},
              );
            }
          }
          log("snap ${snapshot.data}");
          List<Product> products = snapshot.data as List<Product>;

          return CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  ShopHeader(
                    shopPicUrl: shop.shopPicUrl,
                    ownerPicUrl: null,
                    ownerName: null,
                    shopName: shop.user.username,
                  ),
                  ShopDescription(description: shop.description),
                  ShopDetails(
                    categories: shop.categories,
                    address: shop.address,
                    phoneNumber: shop.phoneNumber,
                    email: shop.user.email,
                    businessLicense: null, // shop.businessLicense,
                    pancardPicUrl: null, // shop.pancardPicUrl,
                    ownerIdPicUrl: null, // shop.ownerIdPicUrl,
                  )
                ]),
              ),
              if (products.isNotEmpty)
                SliverGrid.builder(
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
                )
            ],
          );
        },
      ),
    );
  }
}
