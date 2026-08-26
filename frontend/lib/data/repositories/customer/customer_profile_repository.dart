// // ignore_for_file: public_member_api_docs, sort_constructors_first

// import '/services/customer_profile_service.dart';

// import '../../models/customer.dart';
// //merge it with CustomerDataRepository
// class CustomerProfileRepository {
//   Customer? customer;
//   CustomerProfileRepository({
//     this.customer,
//   });
//   // set customer(Customer? customer) => _customer = customer;
//   // Customer? get customer => _customer;

//   Future<void> registerCustomer(
//       String name, String email, String password) async {
//     try {
//       await CustomerProfileService().registerCustomer(name, email, password);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> loginCustomer(String email, String password) async {
//     try {
//       await CustomerProfileService().loginCustomer(email, password);
//       await isCustomerLoggedIn();
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> isCustomerLoggedIn() async {
//     try {
//       customer = await CustomerProfileService().isCustomerLoggedIn();
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> logoutCustomer() async {
//     await CustomerProfileService().logoutCustomer();
//     customer = null;
//   }
// }
