import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/data/repositories/shop/shop_data_repository.dart';

import '../../features/shop/shop_authentication/view_model/shop_auth_bloc.dart';
import '../screens/error_screen.dart';

class ShopLocationWidget extends StatefulWidget {
  const ShopLocationWidget({super.key});

  @override
  State<ShopLocationWidget> createState() => _ShopLocationWidgetState();
}

class _ShopLocationWidgetState extends State<ShopLocationWidget> {
  TextEditingController locationNameController = TextEditingController();
  void fetchAddress(String? address) {
    context
        .read<ShopAuthBloc>()
        .add(ShopAuthLoadLocationEvent(userEnteredLocation: address));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopAuthBloc, ShopAuthState>(
      builder: (context, state) {
        if (state is ShopAuthLoadingLocationState) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state is ShopAuthErrorState &&
            state.error.errorType.name.toLowerCase().contains("location")) {
          return ErrorScreen(
            customException: state.error,
            onTryAgainPressed: () => context
                .read<ShopAuthBloc>()
                .add(ShopAuthLoadLocationEvent(userEnteredLocation: null)),
          );
        }
        final locationInfo = context.read<ShopDataRepository>().locationInfo;
        var deviceWidth = MediaQuery.of(context).size.width;
        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(),
              Text("Proper Shop Location"),
              // if (state.runtimeType == ShopAuthLoadedLocationState)
              if (locationInfo != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    locationInfo.shortAddress,
                    // (state as ShopAuthLoadedLocationState).location,
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                    onPressed: () {
                      fetchAddress(null);
                    },
                    label: Text(
                      "Fetch Current Location",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    icon: Icon(
                      Icons.location_on,
                      size: deviceWidth * 0.1,
                    )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                    child: Text(
                  "or",
                  style: Theme.of(context).textTheme.bodyLarge,
                )),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Enter Location Name',
                        border: OutlineInputBorder(),
                      ),
                      controller: locationNameController,
                      // onSaved: (value) => _locationName = value,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              Colors.blue.withOpacity(0.05)),
                        ),
                        onPressed: () {
                          if (locationNameController.text.isNotEmpty) {
                            fetchAddress(locationNameController.text.trim());
                          }
                        },
                        child: Text(
                          "Fetch",
                          overflow: TextOverflow.ellipsis,
                        )),
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 20.0),
            ],
          ),
        );
      },
    );
  }
}
