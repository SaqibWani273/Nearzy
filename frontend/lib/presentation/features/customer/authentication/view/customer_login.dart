import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/presentation/common/widgets/email_sent_widget.dart';
import '/presentation/common/widgets/form_widget.dart';
import '../../../../../theme/app_colors.dart';

import '../view_model/customer_auth_bloc.dart';

enum FormType { login, register, forgotpassword }

class CustomerLogin extends StatefulWidget {
  const CustomerLogin({super.key});

  @override
  State<CustomerLogin> createState() => _CustomerLoginState();
}

class _CustomerLoginState extends State<CustomerLogin> {
  /// The failure to show above the form, held here rather than read straight
  /// off the bloc state so dismissing it does not need an event of its own.
  String? _error;

  @override
  void initState() {
    context.read<CustomerAuthBloc>().add(CustomerAuthInitialEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      // This screen is pushed (from the account switcher and the profile
      // tab), so it needs a way back out that does not depend on the device
      // button. It had neither, which left the sheet a dead end.
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        leading: const BackButton(),
      ),
      body: BlocConsumer<CustomerAuthBloc, CustomerAuthState>(
          listener: (context, state) {
        if (state is CustomerAuthErrorState) {
          // Reported in the form itself, not in a snackbar that slides away
          // before it has been read.
          setState(() => _error = state.message);
        } else if (state is CustomerAuthLoadingState) {
          if (_error != null) setState(() => _error = null);
        } else if (state is CustomerAuthLoggedInState) {
          // Signing in publishes a session event and the app shell rebuilds
          // onto the right home screen, taking this route with it — so pop
          // only if it is somehow still standing.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final navigator = Navigator.maybeOf(context);
            if (navigator != null && navigator.canPop()) navigator.pop();
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
      errorMessage: _error,
      onDismissError: () {
        if (_error != null) setState(() => _error = null);
      },
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
