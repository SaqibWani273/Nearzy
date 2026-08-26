class CustomerException implements Exception {
  final String message;

  CustomerException(this.message);
}

enum CustomerAuthExceptionType {
  emailAlreadyInUse,
  invalidEmail,
  userNotFound,
  usernameAlreadyInUse,
  wrongPassword,
  emailNotVerified,
}

String getCustomerAuthExceptionMessage(
    CustomerAuthExceptionType exceptionType) {
  switch (exceptionType) {
    case CustomerAuthExceptionType.emailAlreadyInUse:
      return "Email already in use";
    case CustomerAuthExceptionType.invalidEmail:
      return "Invalid email";
    case CustomerAuthExceptionType.userNotFound:
      return "User not found";
    case CustomerAuthExceptionType.usernameAlreadyInUse:
      return "Username already in use";
    case CustomerAuthExceptionType.wrongPassword:
      return "Wrong password";
    case CustomerAuthExceptionType.emailNotVerified:
      return "Email not verified";
    default:
      return "Something went wrong";
  }
}
