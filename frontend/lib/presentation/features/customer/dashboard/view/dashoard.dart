import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mca_project/constants/rest_api_const.dart';
import 'package:mca_project/data/models/shop_model/shop_model1.dart';
import 'package:mca_project/presentation/common/screens/error_screen.dart';
import '../../../../../data/models/product.dart';
import '../../../../../services/api_service.dart';
import '../../../shop/inventory/shop_inventory_screen.dart';
import '/presentation/common/widgets/loading_widgets.dart';
import '/presentation/common/widgets/show_cupertino_alert_dialog.dart';
import '/presentation/features/customer/dashboard/view/widgets/shop_loading_screen.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '/presentation/features/customer/product/view/product_details_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../common/widgets/my_text_field_widget.dart';
import '/data/repositories/customer/customer_data_repository.dart';
import '/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  TextEditingController locationController = TextEditingController();
  final _pagingController = PagingController<int, Product>(firstPageKey: 0);

  LocationInfo? locationInfo;
  @override
  void initState() {
    context.read<CustomerDataBloc>().add(LoadCustomerDataEvent());
    context.read<CustomerDataRepository>().products = [];
    context.read<CustomerDataRepository>().globalPagingController =
        _pagingController;
    _pagingController.addPageRequestListener((int pageKey) {
      context
          .read<CustomerDataBloc>()
          .add(CustomerDataLoadProductsEvent(pageKey: pageKey));
    });
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    // context.read<CustomerDataRepository>().globalPagingController.dispose();
    locationController.dispose();

    super.dispose();
  }

  Widget AddressWidget(double height) {
    return Container(
      alignment: Alignment.center,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      color: Colors.grey.shade300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 30,
                  color: Colors.purple,
                ),
                Text(
                  context
                              .read<CustomerDataRepository>()
                              .currentSelectedLocation ==
                          null
                      ? "Global"
                      : context
                          .read<CustomerDataRepository>()
                          .currentSelectedLocation!
                          .shortAddress,
                  // softWrap: true,
                  // overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
          ElevatedButton(
              style: ButtonStyle(
                elevation: WidgetStateProperty.all(0.0),
                backgroundColor:
                    WidgetStateProperty.all(Colors.blue.withOpacity(0.2)),
              ),
              onPressed: () {
                showCupertinoAlertDialog(
                    context: context,
                    controller: locationController,
                    title: "Change Location",
                    content: "Enter Valid Location Name Here");
              },
              child: const Text(
                'Change Location',
                style: TextStyle(color: Colors.black),
              )),
          //images
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: BlocConsumer<CustomerDataBloc, CustomerDataState>(
          listener: (context, state) {
        // if(state is CustomerDataSearchProductState){

        // }
      }, builder: (context, state) {
        if (state is CustomerDataErrorState) {
          return Scaffold(
            body: Center(child: Text(state.error)),
          );
        }
        if (state is CustomerDataLoadingState) {
          //show shimmer loading here
          // return const Center(child: CircularProgressIndicator());
          return ShopLocalLoadingScreen();
        }
        if (state is CustomerDataLocationErrorState) {
          return ErrorScreen(
              customException: state.error,
              onTryAgainPressed: () {
                context.read<CustomerDataBloc>().add(LoadCustomerDataEvent());
              });
        }
        if (state is CustomerDataLoadedState) {
          // final products = state.searchProducts ??
          //     context.read<CustomerDataRepository>().products;

          return CustomScrollView(slivers: [
            // const SliverAppBar(),
            SliverList(
              delegate: SliverChildListDelegate([
                //search bar here
                MyTextFieldWidget(
                  onChanged: (fieldVal) {
                    context
                        .read<CustomerDataBloc>()
                        .add(CustomerDataSearchProductEvent(keyword: fieldVal));
                    // log(fieldVal);
                  },
                  hintText: 'Search for everything,styles and brands',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [Icon(Icons.mic), Icon(Icons.camera_alt)],
                    ),
                  ),
                ),
                //address here
                if (state.isChangingLocation == true)
                  //placeholder while changing location
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: AddressWidget(deviceHeight * 0.15),
                  ),
                if (state.isChangingLocation == null)
                  AddressWidget(deviceHeight * 0.15),
              ]),
            ),
            // SliverList(delegate: SliverChildListDelegate([])),
            if (state.loadingProducts == true)
              //progress indicator while loading products
              SliverPadding(
                  padding: EdgeInsets.all(8.0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                        margin: EdgeInsets.only(top: deviceHeight * 0.2),
                        child: LoadingWidgets.SpinKitFading(deviceWidth)),
                  )),

//show search results here
            if (state.loadingProducts == null && state.searchProducts != null)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = state.searchProducts![index];
                    return InkWell(
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                  product: product,
                                ),
                              ),
                            ),
                        child: ProductCard(product: product));
                  },
                  childCount: state.searchProducts!.length,
                ),
              ),

//show main dashboard here
            if (state.loadingProducts == null && state.searchProducts == null)
              SliverPadding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                  sliver: PagedSliverGrid<int, Product>(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: deviceHeight * 0.3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    pagingController: context
                        .read<CustomerDataRepository>()
                        .globalPagingController,
                    builderDelegate: PagedChildBuilderDelegate<Product>(
                      animateTransitions: true,
                      firstPageProgressIndicatorBuilder: (context) =>
                          LoadingWidgets.SpinKitFading(deviceWidth),
                      newPageProgressIndicatorBuilder: (context) =>
                          LoadingWidgets.SpinKitFading(deviceWidth),
                      noItemsFoundIndicatorBuilder: (_) => Container(
                        margin: EdgeInsets.only(top: deviceHeight * 0.2),
                        child: Center(
                            child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined),
                            SizedBox(
                              height: 10,
                            ),
                            Text("No Products Found"),
                          ],
                        )),
                      ),
                      itemBuilder: (context, item, index) {
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
                                      Column(
                                        children: [
                                          if (item.disCountedPrice < item.price)
                                            Text("₹" +
                                                item.disCountedPrice
                                                    .toString()),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: Text(
                                              "₹" + item.price.toString(),
                                              style: item.disCountedPrice <
                                                      item.price
                                                  ? TextStyle(
                                                      color: Colors.grey,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      decorationColor:
                                                          Colors.grey)
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ))
          ]);
        }
        return LoadingWidgets.SpinKitFading(deviceWidth);
      }),
    );
  }
}
