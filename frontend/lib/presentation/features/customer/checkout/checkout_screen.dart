import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/presentation/common/widgets/loading_widgets.dart';
import 'package:mca_project/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';
import 'package:mca_project/services/stripe_service.dart';

import '../../../../data/models/cart.dart';
import '../../../../data/repositories/customer/customer_data_repository.dart';
import '../cart/cart_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemDetails> cartItemDetailst;
  const CheckoutScreen({super.key, required this.cartItemDetailst});
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late int customerId;
  bool showLoadingScreen = false;
  @override
  void initState() {
    //delete the items from db
    customerId = context.read<CustomerDataRepository>().customer!.id!;
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  String _shippingAddress = '';
  String _billingAddress = '';
  String _phoneNumber = '';

  String _paymentMethod = 'Debit Card';

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: showLoadingScreen
          ? LoadingWidgets.SpinKitFading(deviceWidth)
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildOrderSummary(widget.cartItemDetailst),
                    _buildShippingInformation(),
                    _buildBillingInformation(),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contact Number',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Divider(),
                            TextFormField(
                              keyboardType: TextInputType.phone,
                              decoration:
                                  InputDecoration(labelText: 'Phone Number'),
                              validator: (value) {
                                if (value!.length < 10) {
                                  return 'Please enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                              onSaved: (value) => _phoneNumber = value!,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // _buildPaymentInformation(),
                    // _buildPromoCode(),
                    // _buildOrderReview(),
                    _buildPlaceOrderButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderSummary(List<CartItemDetails> cartItemDetailsList) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            ...cartItemDetailsList.map((cartItemDetails) {
              return ListTile(
                title: Text(cartItemDetails.product.name),
                trailing: Text(
                    '₹${cartItemDetails.product.price * cartItemDetails.quantity}'),
              );
            }).toList(),
            ListTile(
              title: Text('Shipping'),
              trailing: Text('₹100'),
            ),
            ListTile(
              title: Text('Total'),
              trailing: Text(
                  '₹${(calculateTotalPrice(cartItemDetailsList) + 100)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipping Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            TextFormField(
              decoration: InputDecoration(labelText: 'Shipping Address'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter your shipping address';
                }
                return null;
              },
              onSaved: (value) => _shippingAddress = value!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Billing Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            TextFormField(
              decoration: InputDecoration(labelText: 'Billing Address'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter your billing address';
                }
                return null;
              },
              onSaved: (value) => _billingAddress = value!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: InputDecoration(labelText: 'Payment Method'),
              items: <String>['Credit Card', 'Debit Card', 'Net Banking', 'UPI']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderReview() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            Text('Shipping Address: $_shippingAddress'),
            Text('Billing Address: $_billingAddress'),
            Text('Payment Method: $_paymentMethod'),
            Text("Phone Number: $_phoneNumber"),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: ElevatedButton(
          onPressed: _placeOrder,
          child: Text('Place Order'),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        showLoadingScreen = true;
      });
      // Here you can add the logic to handle the order placement
      final result = await StripeService.makePayment(PaymentData(
        buyerName: 'Jenny Rosen',
        amount: calculateTotalPrice(widget.cartItemDetailst),
        currency: 'INR',
        shippingAddress: _shippingAddress,
        billingAddress: _billingAddress,
        phoneNumber: _phoneNumber,
        customerId: customerId,
        shopId: widget.cartItemDetailst.first.product.shop.id!,
        orderItems: widget.cartItemDetailst
            .map((e) => OrderItem.fromCartItemDetails(cartItemDetails: e))
            .toList(),
      ));

      setState(() {
        showLoadingScreen = false;
      });
      //if result is false add the items back to db
      if (result == false) {}
      if (result == true) {
        context.read<CustomerDataRepository>().cartItemDetails = [];
        context.read<CustomerDataRepository>().customer!.cartItems = [];
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Order Status',
              style:
                  TextStyle(color: result == true ? Colors.green : Colors.red)),
          content: result == true
              ? Text('Your order has been placed successfully!')
              : Text('Your order could not be placed!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
