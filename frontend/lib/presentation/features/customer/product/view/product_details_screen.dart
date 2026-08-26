import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/data/models/shop_model/shop_model1.dart';
import 'package:mca_project/presentation/common/widgets/loading_widgets.dart';
import '/data/repositories/customer/customer_data_repository.dart';
import '/data/repositories/customer/customer_profile_repository.dart';
import '/presentation/features/customer/cart/cart_screen.dart';
import '/utils/utils.dart';
import '../../../../../data/models/customer.dart';
import '../../../../../data/models/product.dart';
import '../../appbar_widget.dart';
import '../../authentication/view/customer_login.dart';
import '../../dashboard/view/widgets/large_sliding_images_widget.dart';
import '../../dashboard/view_model/customer_data_bloc.dart';

enum StockAvailability { IN_STOCK, OUT_OF_STOCK }

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    var deviceWidth = MediaQuery.of(context).size.width;
    Customer? customer = context.read<CustomerDataRepository>().customer;
    return Scaffold(
      body: BlocConsumer<CustomerDataBloc, CustomerDataState>(
        listener: (context, state) {
          if (state is CustomerDataLoadedState && state.canAddToCart == false) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Product Not Added',
                    style: TextStyle(color: Colors.deepOrangeAccent)),
                content: Text("All the Cart items must belong to same shop !"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ok'))
                ],
              ),
            );
          }
          if (state is CustomerDataLoadedState && state.canAddToCart == true) {
            Utils.showScaffoldMessage(
                message: "Added to Cart",
                context: context,
                actionWidget: TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return CartScreen();
                    }));
                  },
                  child: Text("View Cart"),
                ));
          }
        },
        builder: (context, state) {
          if (state is CustomerDataLoadedState) {
            customer = context.read<CustomerDataRepository>().customer;
            return Stack(children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 48.0, left: 8.0, right: 8.0, bottom: 8.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.arrow_back_sharp,
                                    size: 30,
                                  ),
                                ),
                                CartIcon(customer: customer)
                              ]),
                        ),
                        Hero(
                          tag: product.id!,
                          child: SizedBox(
                            //my custom widget using CourselSlider
                            child: ImagesWidget(
                              slidingImages: product.images,
                              indicatorColor: Colors.grey.shade700,
                              indicatorWidth: 8.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                        delegate: SliverChildListDelegate([
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        "STOCK AVAILABILITY: ${product.available ? "IN STOCK" : "OUT OF STOCK"}",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        product.shortDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          if (product.disCountedPrice < product.price)
                            Text(
                              "₹" + product.disCountedPrice.toString(),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "₹" + product.price.toString(),
                              style: product.disCountedPrice < product.price
                                  ? TextStyle(
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.grey)
                                  : Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                      // Text(
                      //   "₹ ${product.price}",
                      //   style: Theme.of(context).textTheme.headlineMedium,
                      // ),
                      const SizedBox(
                        height: 20,
                      ),
                      // if (product.colors.isNotEmpty)
                      //   SingleChildScrollView(
                      //     scrollDirection: Axis.horizontal,
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.start,
                      //       children: product.colors
                      //           .map((e) => Container(
                      //                 height: 40,
                      //                 width: 40,
                      //                 margin: EdgeInsets.symmetric(
                      //                     horizontal: deviceWidth * 0.03),
                      //                 decoration: BoxDecoration(
                      //                   color: Colors.green,
                      //                   shape: BoxShape.circle,
                      //                   // borderRadius: BorderRadius.circular(24.0),
                      //                 ),
                      //               ))
                      //           .toList(),
                      //     ),
                      //   ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        product.completeDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Shop Details:",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      buildShopDetails(product.shop),
                      //reviews
                      // if (product.reviews != null && product.reviews!.isNotEmpty)
                      //   Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Padding(
                      //         padding: const EdgeInsets.all(8.0),
                      //         child: Text(
                      //           "Reviews",
                      //           style: Theme.of(context).textTheme.headlineSmall,
                      //         ),
                      //       ),
                      //       ...product.reviews!.map((e) => Column(
                      //               crossAxisAlignment: CrossAxisAlignment.start,
                      //               children: [
                      //                 Text(
                      //                   e.username,
                      //                   style:
                      //                       Theme.of(context).textTheme.headlineSmall,
                      //                 ),
                      //                 //to do : add uploadDateTime feild to
                      //                 // review model
                      //                 Text(DateTime.now().dayMonthYearFormatted),
                      //                 const SizedBox(
                      //                   height: 10,
                      //                 ),

                      //                 Row(
                      //                   children: List.generate(
                      //                       5,
                      //                       (index) => Icon(
                      //                             Icons.star,
                      //                             color: index >= e.rating
                      //                                 ? Colors.grey
                      //                                 : Colors.blue,
                      //                           )),
                      //                 ),
                      //                 if (e.image != null)
                      //                   Center(
                      //                     child: Padding(
                      //                       padding: const EdgeInsets.all(8.0),
                      //                       child: Image.asset(
                      //                         e.image!,
                      //                         alignment: Alignment.center,
                      //                         width: deviceWidth * 0.7,
                      //                       ),
                      //                     ),
                      //                   ),
                      //                 Padding(
                      //                   padding:
                      //                       const EdgeInsets.symmetric(vertical: 8.0),
                      //                   child: Text(e.review),
                      //                 ),
                      //                 const Divider()
                      //               ])),
                      //     ],
                      //   )
                    ])),
                  )
                ],
              ),
              // Positioned(
              //   bottom: 0,
              //   child:
              // )
            ]);
          } else {
            return Center(
              child: LoadingWidgets.SpinKitFading(deviceWidth),
            );
          }
        },
      ),
      bottomNavigationBar: Container(
        // color: Colors.white,
        width: deviceWidth,
        child: Row(
          children: [
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () async {
                  //not logged in
                  if (customer == null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CustomerLogin()),
                    );
                  } else {
                    if (!product.available) {
                      Utils.showScaffoldMessage(
                          message: "Product is out of stock", context: context);
                      return;
                    }
                    //logged in
                    context.read<CustomerDataBloc>().add(
                        CustomerDataAddProductToCartEvent(product: product));
                  }
                },
                child: Text(
                  "Add to Cart",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(Colors.grey.shade300),
                ),
              ),
            )),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: null,
                child: const Text(
                  "Buy Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                ),
              ),
            ))
          ],
        ),
      ),
    );
  }
}

Widget buildShopDetails(ShopModel1 shop) {
  return Column(
    children: [
      const SizedBox(height: 10),
      ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(shop.ownerPicUrl),
        ),
        title: Text(shop.ownerName),
        subtitle: Text(shop.description),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8.0,
        children: shop.categories
            .map((category) => Chip(
                  label: Text(category),
                ))
            .toList(),
      ),
      const SizedBox(height: 10),
      ListTile(
        leading: Icon(Icons.location_on),
        title: Text(shop.address),
        subtitle: Text(shop.phoneNumber),
      ),
      const SizedBox(height: 10),
      Image.network(shop.shopPicUrl),
      Divider(color: Colors.grey),
      const SizedBox(height: 5),
      Text(
        "Shop Rating: Not Implemented Yet", // Add rating display logic
        // style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}
