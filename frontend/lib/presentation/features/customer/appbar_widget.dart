import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mca_project/presentation/features/customer/customer_home_page.dart';

import '../../../data/models/customer.dart';
import '../../../data/repositories/customer/customer_data_repository.dart';
import 'cart/cart_screen.dart';
import 'dashboard/view_model/customer_data_bloc.dart';

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: BlocBuilder<CustomerDataBloc, CustomerDataState>(
        builder: (context, state) {
          if (state is CustomerDataLoadedState) {
            Customer? customer =
                context.read<CustomerDataRepository>().customer;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const CustomerHomePage(),
                    )),
                    child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                          // color: Colors.blueGrey.withOpacity(0.8)
                        ),
                        child: Text(
                          'LocalEzy',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.purple,
                            fontFamily: GoogleFonts.aBeeZeeTextTheme()
                                .headlineLarge
                                ?.fontFamily,
                          ),
                        )),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                        onPressed: () {},
                        icon:
                            const Icon(size: 30, Icons.notifications_outlined)),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                            size: 30, Icons.favorite_outline_outlined)),
                    CartIcon(customer: customer),
                  ],
                )
              ],
            );
          }

          return const Text('LocalEzy');
        },
      ),
    );
  }
}

class CartIcon extends StatelessWidget {
  const CartIcon({
    super.key,
    required this.customer,
  });

  final Customer? customer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return CartScreen();
              }));
            },
            icon: const Icon(size: 30, Icons.shopping_cart_outlined)),
        Positioned(
          child: Text(
            customer == null ||
                    customer!.cartItems == null ||
                    customer!.cartItems!.isEmpty
                ? '0'
                : customer!.cartItems!.length.toString(),
            style: TextStyle(color: Colors.purple),
          ),
          right: 0,
          top: 0,
        )
      ],
    );
  }
}
