import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/cart.dart';
import '../../../../data/models/customer.dart';
import '../checkout/checkout_screen.dart';
import '../authentication/view/customer_login.dart';
import '../../../../services/stripe_service.dart';
import '../product/view/product_details_screen.dart';
import '/data/repositories/customer/customer_data_repository.dart';
import '/presentation/common/screens/error_screen.dart';
import '/presentation/common/widgets/loading_widgets.dart';
import '/presentation/features/customer/cart/widgets/empty_cart_screen.dart';
import '/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Customer? customer;
  bool isCartEmpty = false;
  List<CartItemDetails> cartItemDetailsList = [];
  @override
  void initState() {
    customer = context.read<CustomerDataRepository>().customer;
    cartItemDetailsList =
        context.read<CustomerDataRepository>().cartItemDetails;
    if (customer != null) {
      isCartEmpty = checkIsCartEmpty(customer);
      if (!isCartEmpty && cartItemDetailsList.isEmpty) {
        context.read<CustomerDataBloc>().add(
            CustomerDataFetchCartItemDetailsEvent(
                cartItems: customer!.cartItems!));
      }
    }

    super.initState();
  }

  bool checkIsCartEmpty(Customer? customer) =>
      customer == null ||
      customer.cartItems == null ||
      customer.cartItems!.isEmpty;

  Widget NotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Not Logged In'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerLogin()),
              );
              customer = context.read<CustomerDataRepository>().customer;
              log("customer: " + customer.toString());
              if (customer != null) {
                isCartEmpty = checkIsCartEmpty(customer);
                if (!isCartEmpty) {
                  context.read<CustomerDataBloc>().add(
                      CustomerDataFetchCartItemDetailsEvent(
                          cartItems: customer!.cartItems!));
                }
              }
              // setState(() {
              //   customer = context.read<CustomerDataRepository>().customer;
              // });
            },
            label: Text("Login Here"),
            icon: Icon(Icons.login),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    return BlocBuilder<CustomerDataBloc, CustomerDataState>(
        builder: (context, state) {
      if (customer == null) {
        return Scaffold(body: NotLoggedIn());
      }
      if (state is CustomerDataFetchingCartItemDetailsState) {
        return LoadingWidgets.SpinKitFading(deviceWidth);
      }
      // if(state is CustomerDataLoadingState ){
      //   return LoadingWidgets.SpinKitFading(deviceWidth);
      // }
      if (state is CustomerDataCartErrorState) {
        return Scaffold(
          body: ErrorScreen(
              customException: state.error,
              onTryAgainPressed: () {
                context.read<CustomerDataBloc>().add(
                    CustomerDataFetchCartItemDetailsEvent(
                        cartItems: customer!.cartItems!));
              }),
        );
      }

      if (state is CustomerDataLoadedState) {
        cartItemDetailsList =
            context.read<CustomerDataRepository>().cartItemDetails;
        customer = context.read<CustomerDataRepository>().customer;
        isCartEmpty = checkIsCartEmpty(customer);
        if (cartItemDetailsList.isEmpty) {
          return Scaffold(body: EmptyCartScreen());
        }
        return Scaffold(
          body: ListView.builder(
            itemCount:
                cartItemDetailsList.length, //customer!.cartItems!.length,
            itemBuilder: (context, index) {
              log('${cartItemDetailsList.length}');
              final cartItem = cartItemDetailsList[index];

              return ListTile(
                leading: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailsScreen(product: cartItem.product),
                    ),
                  ),
                  child: Image.network(cartItem.product.images.first),
                ), // Replace with image loading logic
                title: Text(cartItem.product.name),
                subtitle: Text(
                    '${cartItem.product.price} - Quantity: ${cartItem.quantity}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quantity selector (e.g., using a number picker or custom buttons)
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (cartItem.quantity > 1) {
                          context.read<CustomerDataBloc>().add(
                              CustomerDataDecreaseQuantityByOneEvent(
                                  product: cartItem.product));
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => context.read<CustomerDataBloc>().add(
                          CustomerDataIncreaseQuantityByOneEvent(
                              product: cartItem.product)),
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          context.read<CustomerDataBloc>().add(
                              CustomerDataRemoveProductFromCartEvent(
                                  product: cartItem.product));
                        }),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: customer == null || isCartEmpty
              ? null
              : CartBottomBar(cartItemDetailsList: cartItemDetailsList),
        );
      }
//incase any other state is received
      return LoadingWidgets.SpinKitFading(deviceWidth);
    });
  }
}

class CartBottomBar extends StatelessWidget {
  final List<CartItemDetails> cartItemDetailsList;

  const CartBottomBar({super.key, required this.cartItemDetailsList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:'),
                Text('₹${calculateTotalPrice(cartItemDetailsList)}'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Handle checkout
              // await makePayment();
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return CheckoutScreen(cartItemDetailst: cartItemDetailsList);
              }));
            },
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }
}

double calculateTotalPrice(List<CartItemDetails> cartItemDetails) {
  double totalPrice = 0.0;

  for (var cartItemDetails in cartItemDetails) {
    totalPrice += cartItemDetails.product.price * cartItemDetails.quantity;
  }

  return totalPrice;
}
