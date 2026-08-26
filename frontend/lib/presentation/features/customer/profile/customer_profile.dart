import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/presentation/common/widgets/loading_widgets.dart';
import 'package:mca_project/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';
import '../../shop/orders/orders_screen.dart';
import '/data/repositories/customer/customer_data_repository.dart';
import '/constants/image_constants.dart';
import '/data/models/customer.dart';
import '/data/repositories/customer/customer_profile_repository.dart';
import '/presentation/features/customer/authentication/view/customer_login.dart';

import '../authentication/view_model/customer_auth_bloc.dart';

class CustomerProfile extends StatelessWidget {
  const CustomerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    return BlocBuilder<CustomerAuthBloc, CustomerAuthState>(
        bloc: BlocProvider.of<CustomerAuthBloc>(context),
        builder: (context, state) {
          if (state is CustomerAuthLoadingState) {
            return LoadingWidgets.SpinKitFading(deviceWidth);
          }
          log("$state");
          Customer? customer = context.read<CustomerDataRepository>().customer;
          if (customer != null) {
            if (customer.orders == null) {
              context
                  .read<CustomerAuthBloc>()
                  .add(CustomerDataLoadMyOrdersEvent());
              return LoadingWidgets.SpinKitFading(deviceWidth);
            }
            return Padding(
                padding: const EdgeInsets.all(20.0),
                child: CustomScrollView(slivers: [
                  SliverList(
                      delegate: SliverChildListDelegate([
                    // Centered avatar
                    Center(
                      child: CircleAvatar(
                        radius: 50.0,
                        backgroundImage: const AssetImage(ImageConstants
                            .defaultProfileImage), // Replace with your asset path
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    Center(
                      child: Text(
                        customer!.user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Center(
                      child: Text(
                        customer.user.username,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                        onPressed: () {
                          context
                              .read<CustomerAuthBloc>()
                              .add(CustomerLogoutEvent());
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        )),
                    // ListView.builder(
                    //     itemCount: customer.orders.length,
                    //     itemBuilder: (context, index) {
                    //       return OrderCard(order: customer.orders[index]);
                    //     }),
                  ])),
                  // SliverAppBar(
                  //   title: Column(
                  //     // mainAxisAlignment: MainAxisAlignment.center,

                  //     children: [

                  //     ],
                  //   ),
                  // ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return OrderCard(
                            order: customer.orders![index],
                            role: Roles.ROLE_CUSTOMER);
                      },
                      childCount: customer.orders!.length,
                    ),
                  ),
                ]));
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('You are not logged in'),
                ElevatedButton(
                    onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CustomerLogin()),
                        ),
                    child: Text("Login")),
              ],
            ),
          );
        });
  }
}
