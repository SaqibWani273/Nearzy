import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/customer/dashboard/view_model/customer_data_bloc.dart';

void showCupertinoAlertDialog({
  required BuildContext context,
  // required VoidCallback onPressed,
  required String title,
  required String content,
  required TextEditingController controller,
}) {
  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Column(
          children: [
            const Divider(),
            //Global no location boundary
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                  onPressed: () {
                    context.read<CustomerDataBloc>().add(
                        ChangeCustomerCurrentLocationEvent(
                            currentLocation: 'global'));
                    Navigator.pop(context);
                  },
                  label: Text(
                    "Global",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  icon: Icon(
                    Icons.location_off,
                    size: MediaQuery.of(context).size.height * 0.03,
                  ),
                ),
                SizedBox(width: 5),
                Expanded(child: Text("No Location Boundary"))
              ],
            ),
            const Divider(),
            //use current location
            TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
                onPressed: () {
                  context.read<CustomerDataBloc>().add(
                      ChangeCustomerCurrentLocationEvent(
                          currentLocation: 'current'));
                  Navigator.pop(context);
                },
                label: Text(
                  "Fetch Current Location",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                icon: Icon(
                  Icons.location_on,
                  size: MediaQuery.of(context).size.height * 0.03,
                )),
            const Divider(),
            CupertinoTextField(
              placeholder: content,
              controller: controller,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
              child: const Text('Submit'),
              onPressed: () {
                context.read<CustomerDataBloc>().add(
                    ChangeCustomerCurrentLocationEvent(
                        currentLocation: controller.text.trim()));

                Navigator.pop(context);
              }),
        ],
      );
    },
  );
}
