import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/presentation/common/widgets/email_sent_widget.dart';
import '/presentation/common/widgets/form_widget.dart';

import '../view_model/customer_auth_bloc.dart';

enum FormType { login, register, forgotpassword }

class CustomerLogin extends StatefulWidget {
  const CustomerLogin({super.key});

  @override
  State<CustomerLogin> createState() => _CustomerLoginState();
}

class _CustomerLoginState extends State<CustomerLogin> {
  @override
  void initState() {
    context.read<CustomerAuthBloc>().add(CustomerAuthInitialEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CustomerAuthBloc, CustomerAuthState>(
          listener: (context, state) {
        if (state is CustomerAuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
          ));
        } else if (state is CustomerAuthLoggedInState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
        }
      }, builder: (context, state) {
        if (state is CustomerAuthRegisteredState) {
          return EmailSentWidget(
            onPressed: () => context
                .read<CustomerAuthBloc>()
                .add(CustomerAuthInitialEvent()),
          );
        }

        // The form stays mounted while the request is in flight, with the
        // spinner laid over it. Swapping it out for a bare
        // CircularProgressIndicator disposed the TextFormFields, so a failed
        // login came back to a freshly built, empty form.
        return Stack(
          children: [
            _buildForm(context),
            if (state is CustomerAuthLoadingState)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildForm(BuildContext context) {
    return FormWidget(
      userType: UserType.customer,
      registerCallback: (
        _, {
        required email,
        required password,
        required username,
      }) =>
          BlocProvider.of<CustomerAuthBloc>(context).add(
        CustomerRegisterEvent(
            name: username, email: email, password: password),
      ),
      loginCallback: ({
        required email,
        required password,
      }) =>
          BlocProvider.of<CustomerAuthBloc>(context).add(
        CustomerLoginEvent(email: email, password: password),
      ),
    );
  }
}
//...........//
