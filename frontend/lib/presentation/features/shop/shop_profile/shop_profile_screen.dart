// import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/data/models/shop_model/shop_model1.dart';
import 'package:mca_project/presentation/features/shop/shop_authentication/view_model/shop_auth_bloc.dart';

import '../../../../data/repositories/shop/shop_data_repository.dart';
import '../../../common/widgets/account_switcher_sheet.dart';

import 'package:flutter/material.dart';

class ShopProfileScreen extends StatelessWidget {
  const ShopProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ShopModel1? shop;
    return Scaffold(
      // Sign-out and switching both change which account the whole app is
      // showing, so the shell handles the transition — this screen only opens
      // the switcher.
      body: SafeArea(
        child: BlocBuilder<ShopAuthBloc, ShopAuthState>(
          builder: (context, state) {
            shop = context.read<ShopDataRepository>().shopModel;
            if (shop == null) return const SizedBox.shrink();
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    ShopHeader(
                      shopPicUrl: shop!.shopPicUrl,
                      ownerPicUrl: shop!.ownerPicUrl,
                      ownerName: shop!.ownerName,
                      shopName: shop!.user.username,
                    ),
                    SizedBox(height: 16.0),
                    ShopDescription(description: shop!.description),
                    SizedBox(height: 16.0),
                    ShopDetails(
                      categories: shop!.categories,
                      address: shop!.address,
                      phoneNumber: shop!.phoneNumber,
                      email: shop!.user.email,
                      businessLicense: shop!.businessLicense,
                      pancardPicUrl: shop!.pancardPicUrl,
                      ownerIdPicUrl: shop!.ownerIdPicUrl,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ShopHeader extends StatelessWidget {
  final String shopPicUrl;
  final String? ownerPicUrl;
  final String? ownerName;

  final String shopName;

  const ShopHeader({super.key, 
    required this.shopPicUrl,
    required this.ownerPicUrl,
    required this.ownerName,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isShopProfile = ownerName != null && ownerPicUrl != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(shopPicUrl,
              height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        Center(
          child: Text(
            shopName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        isShopProfile
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 16.0),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(ownerPicUrl!),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          ownerName!,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      // Opens the account switcher rather than signing out
                      // outright: hopping to a shopper account or another shop
                      // is the common case, and signing out lives in there too.
                      onTap: () => AccountSwitcherSheet.show(context),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15.0),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 2)),
                        child: Column(
                          children: [
                            Text("Switch account"),
                            SizedBox(
                              height: 20,
                            ),
                            Icon(Icons.swap_horiz_rounded)
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              )
            : Container()
      ],
    );
  }
}

class ShopDescription extends StatelessWidget {
  final String description;

  const ShopDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          description,
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ShopDetails extends StatelessWidget {
  final List<String> categories;
  final String address;
  final String phoneNumber;
  final String email;
  final String? businessLicense;
  final String? pancardPicUrl;
  final String? ownerIdPicUrl;

  const ShopDetails({super.key, 
    required this.categories,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.businessLicense,
    required this.pancardPicUrl,
    required this.ownerIdPicUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bool isShopProfile = businessLicense != null &&
        pancardPicUrl != null &&
        ownerIdPicUrl != null;
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Categories:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4.0),
            Wrap(
              spacing: 8.0,
              children: categories
                  .map((category) => Chip(label: Text(category)))
                  .toList(),
            ),
            SizedBox(height: 8.0),
            Text('Address:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(address, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8.0),
            Text('Phone:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(phoneNumber, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8.0),
            Text('Email:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(email, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8.0),
            if (isShopProfile)
              Column(
                children: [
                  Text('Business License:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(businessLicense!, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8.0),
                  Text('Pan Card:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Image.network(pancardPicUrl!, height: 100, fit: BoxFit.cover),
                  SizedBox(height: 8.0),
                  Text('Owner ID:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Image.network(ownerIdPicUrl!, height: 100, fit: BoxFit.cover),
                ],
              )
          ],
        ),
      ),
    );
  }
}
