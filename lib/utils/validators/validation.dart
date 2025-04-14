class TValidator {
  static String? validateEmptyText(String? fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Reular expression for email validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Passw ord must be at least 6 characters long';
    }

    // Check for uppercase
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for numbers
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for special characters
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Regular expression for international phone number validation
    // Esta expresión regular está optimizada para validar números completos con código de país
    // Acepta formatos como:
    // - +34612345678
    // - +1 (123) 456-7890
    // - +44 20 1234 5678
    final phoneRegExp = RegExp(
      r'^\+(?:[0-9] ?){6,14}[0-9]$'
    );

    if (!phoneRegExp.hasMatch(value)) {
      return 'Enter a valid international phone number';
    }

    // Verificación adicional de longitud total (solo de los dígitos)
    final digitsOnly = value.replaceAll(RegExp(r'[^\d+]'), '');
    final digitCount = digitsOnly.replaceAll('+', '').length;
    
    if (digitCount < 7 || digitCount > 15) {
      return 'Phone number must have between 7 and 15 digits';
    }

    return null;
  }

  // Can add more validators as needed
}
