import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/presentation/common/widgets/loading_widgets.dart';
import 'package:mca_project/presentation/features/customer/authentication/view_model/customer_auth_bloc.dart';
import '../../features/customer/customer_home_page.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: BlocBuilder<CustomerAuthBloc, CustomerAuthState>(
        builder: (context, state) {
          if (state is CustomerAuthLoadingState) {
            return LoadingWidgets.spinKitFading(deviceWidth);
          }
          if (state is CustomerAuthVerifiedState) {
            // Capture the navigator before the delay so the context is not
            // reached for across the async gap.
            final navigator = Navigator.of(context);
            Future.delayed(Durations.extralong1).then(
              (value) => navigator.pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const CustomerHomePage())),
            );
            return LoadingWidgets.spinKitFading(deviceWidth);
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.signal_wifi_connected_no_internet_4_sharp,
                  size: 60,
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text('No Internet Connection'),
                const SizedBox(
                  height: 50,
                ),
                TextButton(
                    onPressed: () {
                      context
                          .read<CustomerAuthBloc>()
                          .add(CustomerAuthVerificationEvent());
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
                          Colors.blue.withValues(alpha: 0.4)),
                    ),
                    child: const Text('Retry')),
              ],
            ),
          );
        },
      ),
    );
  }
}
