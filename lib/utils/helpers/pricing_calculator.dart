class TPricingCalculator {
  /// --  Calculate price based on tax and discount

  static double calculateTotalPrice(double productPrice, String location) {
    double taxRate = getTaxRateForLocation(location);
    double taxAmount = productPrice * taxRate;

    double shippingCost = getShippingCost(location);

    double totalPrice = productPrice + taxAmount + shippingCost;
    return totalPrice;
  }

  /// -- Calculate shipping cost based on location
  static String calculateShippingCost(double productPrice, String location) {
    double shippingCost = getShippingCost(location);
    return shippingCost.toStringAsFixed(2);
  }

  /// -- Calculate tax
  static String calculateTax(double productPrice, String location) {
    double taxRate = getTaxRateForLocation(location);
    double taxAmount = productPrice * taxRate;
    return taxAmount.toStringAsFixed(2);
  }

  static double getTaxRateForLocation(String location) {
    /// Lookup tax rate for the given location from a tax rate database or API.
    /// Return the appropriate tax rate based on the location.
    /// Example: US - 6%, UK - 5%, CA - 7%, Others - 10%
    if (location == 'US') {
      return 0.06;
    } else if (location == 'UK') {
      return 0.05;
    } else if (location == 'CA') {
      return 0.07;
    } else {
      return 0.10; // Default tax rate for other locations example
    }
  }

  static double getShippingCost(String location) {
    /// Lookup shipping cost for the given location from a shipping cost database or API.
    /// Calculate the shpping cost based on various factors like distance, weight, etc.
    if (location == 'US') {
      return 5.0;
    } else if (location == 'UK') {
      return 7.0;
    } else if (location == 'CA') {
      return 6.0;
    } else {
      return 5.0; // Default shipping cost for other locations example
    }
  }

  /// -- Sum all cart values and return the total amount
  /// static double calculateCartTotal(CartModel cart) {
  /// return cart.items.map((e) => e.price).fold(0, (previousPrice, currentPrice) => previousPrice + (currentPrice ?? 0));
  /// }
}
