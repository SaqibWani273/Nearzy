import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';
import '../../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../common/widgets/loading_widgets.dart';
import 'category_screen.dart';
import '/presentation/common/widgets/my_text_field_widget.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    context.read<CustomerDataBloc>().add(CustomerDataFetchCategoriesEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    return BlocBuilder<CustomerDataBloc, CustomerDataState>(
      builder: (context, state) {
        final categories = context.read<CustomerDataRepository>().categories;
        if (state is CustomerDataLoadedState &&
            state.loadedCategories == true) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MyTextFieldWidget(
                  hintText: 'Search For Categories',
                  prefixIcon: Icon(
                    Icons.search,
                  ),
                ),
                //create a common gridview widget later
                Expanded(
                  child: categories == null || categories.isEmpty
                      ? const Center(
                          child: Text("No Categories"),
                        )
                      : GridView(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 15,
                                  crossAxisSpacing: 15,
                                  childAspectRatio: 1.0),
                          // physics: NeverScrollableScrollPhysics(),
                          children: categories
                              // .where((element) => !element.isTopProductCategory)
                              .map((e) => InkWell(
                                    onTap: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (context) =>
                                          CategoryScreen(category: e),
                                    )),
                                    child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: Image.network(
                                                e.image,
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(e.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium!
                                                    .copyWith(fontSize: 24.0),
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ],
                                        )),
                                  ))
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        } else {
          return LoadingWidgets.SpinKitFading(deviceWidth);
        }
      },
    );
  }
}
