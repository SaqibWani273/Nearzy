import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/presentation/common/widgets/loading_widgets.dart';
import 'package:mca_project/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';
import 'package:mca_project/presentation/features/customer/shops/shop_details_screen.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  @override
  void initState() {
    context.read<CustomerDataBloc>().add(CustomerDataFetchNearbyShopsEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    var deviceHeight = MediaQuery.of(context).size.height;
    return BlocBuilder<CustomerDataBloc, CustomerDataState>(
      builder: (context, state) {
        if (state is CustomerDataLoadedState && state.shops != null) {
          return GridView.builder(
            itemCount: state.shops!.length,
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: deviceHeight * 0.3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              var item = state.shops![index];
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShopDetailsScreen(
                      shop: item,
                    ),
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
                                item.shopPicUrl),
                          ),
                        ),
                      ),
                      Spacer(),
                      Padding(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 10.0, bottom: 20.0),
                          child: Center(child: Text(item.user.username))),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return LoadingWidgets.SpinKitFading(deviceWidth);
        }
      },
    );
  }
}
