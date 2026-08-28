import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/constants/bottom_navbar_items.dart';
import 'package:mca_project/presentation/common/widgets/shimmer_loading.dart';
import '../../shop/orders/orders_screen.dart';
import '/data/repositories/customer/customer_data_repository.dart';
import '/constants/image_constants.dart';
import '/data/models/customer.dart';
import '/presentation/features/customer/authentication/view/customer_login.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../authentication/view_model/customer_auth_bloc.dart';

class CustomerProfile extends StatelessWidget {
  const CustomerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerAuthBloc, CustomerAuthState>(
      bloc: BlocProvider.of<CustomerAuthBloc>(context),
      builder: (context, state) {
        if (state is CustomerAuthLoadingState) {
          return ShimmerLoading.productGrid(count: 2);
        }

        Customer? customer = context.read<CustomerDataRepository>().customer;
        if (customer != null) {
          if (customer.orders == null) {
            context
                .read<CustomerAuthBloc>()
                .add(CustomerDataLoadMyOrdersEvent());
            return ShimmerLoading.productGrid(count: 2);
          }

          return Scaffold(
            backgroundColor: AppColors.surface,
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppSpacing.borderRadiusLg,
                      boxShadow: AppSpacing.shadowMedium,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44.0,
                          backgroundColor: AppColors.primarySurface,
                          backgroundImage: const AssetImage(
                              ImageConstants.defaultProfileImage),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          customer.user.username,
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          customer.user.email,
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                context
                                    .read<CustomerAuthBloc>()
                                    .add(CustomerLogoutEvent());
                              },
                              icon: const Icon(Icons.logout_rounded,
                                  size: 18, color: AppColors.error),
                              label: Text(
                                'Logout',
                                style: AppTextStyles.buttonText.copyWith(
                                    color: AppColors.error, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Text(
                      'Your Orders (${customer.orders?.length ?? 0})',
                      style: AppTextStyles.heading3,
                    ),
                  ),
                ),
                if (customer.orders == null || customer.orders!.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined,
                                size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text('No orders yet',
                                style: AppTextStyles.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Orders you place will appear right here.',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return OrderCard(
                            order: customer.orders![index],
                            role: Roles.ROLE_CUSTOMER,
                          );
                        },
                        childCount: customer.orders!.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppSpacing.borderRadiusLg,
                boxShadow: AppSpacing.shadowMedium,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Not Logged In', style: AppTextStyles.heading2),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to view your orders, saved addresses, and profile details.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerLogin(),
                        ),
                      ),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Login / Sign Up'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
