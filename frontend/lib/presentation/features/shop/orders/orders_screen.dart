import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:mca_project/presentation/common/widgets/loading_widgets.dart';
import 'package:mca_project/presentation/features/shop/product_upload/view_model/shop_bloc.dart';

import '../../../../data/models/Order.dart';
import '../../../../data/repositories/shop/shop_data_repository.dart';

enum Roles { ROLE_CUSTOMER, ROLE_SHOP }

class OrdersScreen extends StatefulWidget {
  final Roles role;
  const OrdersScreen({super.key, required this.role});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late List<Order> orders;
  @override
  void initState() {
    orders = context.read<ShopDataRepository>().myOrders;
    if (orders.isEmpty) {
      context.read<ShopBloc>().add(ShopLoadMyOrdersEvent());
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(),
        body: BlocConsumer<ShopBloc, ShopState>(
            listener: (context, state) {},
            builder: (context, state) {
              if (state is ShopLoadingState) {
                return LoadingWidgets.SpinKitFading(deviceWidth);
              }
              orders = context.read<ShopDataRepository>().myOrders;
              if (orders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard_outlined, size: 80),
                      Text('No Orders Found'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return OrderCard(order: orders[index], role: widget.role);
                  });
            }));
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final Roles role;

  OrderCard({required this.order, required this.role});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: EdgeInsets.all(8.0),
      child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Order ID: ${order.id}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '\₹${order.totalPrice}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${order.customerName}'),
              Row(
                children: [
                  Text(
                    'Order Status: ',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: colorForOrderStatus(order.status),
                        borderRadius: BorderRadius.circular(15.0),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Text(
                        '${order.status}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      )),
                ],
              ),
              Text('Created Date: ${order.createdDate}'),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.0),
                  Text('Phone: ${order.customerPhone}'),
                  Text('Shipping Address: ${order.shippingAddress}'),
                  Text('Total Price: \$${order.totalPrice}'),
                  Text('Order Status: ${order.status}'),
                  Text('Payment Status: ${order.paymentStatus}'),
                  SizedBox(height: 8.0),
                  Text('Order Items:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...order.orderItems
                      .map((item) => OrderItemCard(orderItem: item)),
                  SizedBox(height: 8.0),
                  Center(
                      child: role == Roles.ROLE_SHOP
                          ? Row(
                              children: [
                                Expanded(
                                    child: Text("Update Order Status to ")),
                                Spacer(),
                                InkWell(
                                  child: InkWell(
                                    onTap: () => showDialog(
                                      builder: (context) {
                                        return AlertDialog(
                                          // title: Text('Change Status'),
                                          content: Text('Are you sure?'),

                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                // Handle change status
                                                context.read<ShopBloc>().add(
                                                    ShopUpdateOrderStatus(
                                                        orderId: order.id,
                                                        status:
                                                            getNextOrderStatus(
                                                                order.status)));
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Confirm'),
                                            ),
                                          ],
                                        );
                                      },
                                      context: context,
                                    ),
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0,
                                          vertical: 5.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorForOrderStatus(
                                              getNextOrderStatus(order.status)),
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                          border: Border.all(
                                              color: Colors.grey.shade300,
                                              width: 2),
                                        ),
                                        child: Text(
                                          '${getNextOrderStatus(order.status)}',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white),
                                        )),
                                  ),
                                ),
                              ],
                            )
                          : order.status == OrderStatus.PENDING.name ||
                                  order.status == OrderStatus.PROCESSING.name
                              ? InkWell(
                                  onTap: () => showDialog(
                                    builder: (context) {
                                      return AlertDialog(
                                        // title: Text('Change Status'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Are you sure?'),
                                            order.status ==
                                                    OrderStatus.PENDING.name
                                                ? Text(
                                                    'This Process Will Cancel your Order')
                                                : Text(
                                                    'Order process has already started.You"ll be charged the shipping charges'),
                                          ],
                                        ),

                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              // Handle change status
                                            },
                                            child: Text('Cancel Order'),
                                          ),
                                        ],
                                      );
                                    },
                                    context: context,
                                  ),
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                        vertical: 5.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 2),
                                      ),
                                      child: Text(
                                        'Cancel Order',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white),
                                      )),
                                )
                              : Container())
                ],
              ),
            ),
          ]),
    );
  }
}

class OrderItemCard extends StatelessWidget {
  final ShopOrderItem orderItem;

  OrderItemCard({required this.orderItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        children: [
          ClipRect(
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey.shade200,
              ),
              child: Row(
                children: [
                  Image.network(
                    orderItem.images.first,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderItem.productName,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('Quantity: ${orderItem.quantity}'),
                        Text('Price per Unit: ₹${orderItem.pricePerUnit}'),
                        Text('Total Price: ₹${orderItem.totalPrice}'),
                        Text('SKU: ${orderItem.sku}'),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${orderItem.totalPrice}',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      // if (double.tryParse(orderItem.totalPrice) > 100)
                      //   Icon(Icons.local_offer, color: Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
