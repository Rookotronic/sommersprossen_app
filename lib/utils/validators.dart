// Centralized validation functions for the app

bool isAlpha(String value) => RegExp(r"^[\p{L}'\- ]+$", unicode: true).hasMatch(value);

bool isValidEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value);
