import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/auth_error.dart';
import '../../../utils/exceptions/custom_exception.dart';
import '../../common/widgets/form_widget.dart';

/// Admin sign-in.
///
/// `ApiService.adminLogin` and `/admin/login` have both existed for a while
/// with nothing calling them, so `AdminHomePage` was unreachable: an admin
/// could not sign in from the app at all. This is the missing screen, reached
/// from the account switcher's "Add an account" sheet.
///
/// No bloc: there is exactly one action, and a signed-in admin is picked up by
/// the session event that rebuilds the app shell onto [AdminHomePage].
/// Registration is deliberately absent — `/admin/register` requires a secret
/// code and is not a self-serve flow.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn(String email, String password) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ApiService.adminLogin(email, password);
      // Nothing to navigate to: the session event rebuilds the shell onto the
      // admin home and takes this route with it.
    } on CustomException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorFromException(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        leading: const BackButton(),
      ),
      body: Stack(
        children: [
          FormWidget(
            userType: UserType.admin,
            errorMessage: _error,
            onDismissError: () {
              if (_error != null) setState(() => _error = null);
            },
            loginCallback: ({required email, required password}) =>
                _signIn(email, password),
            // Unreachable: UserType.admin hides every path to the register
            // form. Required by the shared widget, so it stays a no-op.
            registerCallback: (
              _, {
              required email,
              required password,
              required username,
            }) {},
          ),
          if (_busy)
            const Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
