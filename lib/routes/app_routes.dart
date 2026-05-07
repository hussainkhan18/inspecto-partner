import 'package:flutter/material.dart';
import 'package:techno_shield/views/delivery_user_screens/delivery_tabs.dart';
import 'package:techno_shield/views/delivery_user_screens/ongoing_orders.dart';
import 'package:techno_shield/views/delivery_user_screens/orders_history.dart';
import 'package:techno_shield/views/delivery_user_screens/staff_personel_info.dart';
import 'package:techno_shield/views/login_signup_screens/login.dart';
import 'package:techno_shield/views/login_signup_screens/signup.dart';
import 'package:techno_shield/views/splash_and_welcome_screen/splash_screen.dart';
import 'package:techno_shield/views/splash_and_welcome_screen/welcome.dart';

import 'package:techno_shield/views/user_screens/account.dart';
import 'package:techno_shield/views/user_screens/checkout.dart';
import 'package:techno_shield/views/user_screens/order-success.dart';
import 'package:techno_shield/views/user_screens/personal-info.dart';
import 'package:techno_shield/views/user_screens/product-detail.dart';
import 'package:techno_shield/views/user_screens/tabs.dart';

import '../views/user_screens/cart.dart';
import '../views/user_screens/shop.dart';

class AppRoutes {
  static const String splashScreen = '/';
  static const String welcomePage = '/welcome';
  static const String loginPage = '/login';
  static const String signupPage = '/signup';
  static const String userTabs = '/userTabs';
  static const String shopPage = '/shop';
  static const String cartPage = '/cart';
  static const String orderPage = '/order';
  static const String accountPage = '/account';
  static const String deliveryTabs = '/deliveryTabs';
  static const String ongoingOrders = '/ongoingOrders';
  static const String orderHistoryPage = '/orderHistory';
  static const String personalInfoPage = '/personalInfo';
  static const String staffPersonalInfoPage = '/staffPersonalInfo';
  static const String productDetailPage = '/productDetail';
  static const String checkoutPage = '/checkout';
  static const String orderSuccessPage = '/orderSuccessPage';


  

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashScreen:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case welcomePage:
        return MaterialPageRoute(builder: (_) => WelcomePage());
      case loginPage:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case signupPage:
        return MaterialPageRoute(builder: (_) => SignupPage());
      case userTabs:
        final Map<String, dynamic>? args =
            settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UserTabs(
            initialIndex: args?['index'] ?? 0, // Directly using the index
          ),
        );

      case shopPage:
        return MaterialPageRoute(builder: (_) => ShopPage());

      case cartPage:
        return MaterialPageRoute(builder: (_) => CartPage());
      case checkoutPage:
        return MaterialPageRoute(builder: (_) => CheckoutPage());
      // case orderPage:
      //   return MaterialPageRoute(builder: (_) => OrderPage());
      case accountPage:
        return MaterialPageRoute(builder: (_) => AccountPage());
      case deliveryTabs:
        return MaterialPageRoute(builder: (_) => DeliveryTabs());
      case ongoingOrders:
        return MaterialPageRoute(builder: (_) => OngoingOrders());
      case orderHistoryPage:
        return MaterialPageRoute(builder: (_) => OrderHistoryPage());
      case orderSuccessPage:
        return MaterialPageRoute(builder: (_) => OrderSuccessPage());
      case personalInfoPage:
        return MaterialPageRoute(builder: (_) => PersonalInfoPage());
      case staffPersonalInfoPage:
        return MaterialPageRoute(builder: (_) => StaffPersonalInfoPage());


        
      case productDetailPage:
        final Map<String, dynamic>? args =
            settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            itemImage: args?['itemImage'] ?? '',
            id: args?['id'] ?? '',
            itemName: args?['itemName'] ?? '',
            itemPrice: args?['itemPrice'] ?? '',
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => SplashScreen());
    }
  }
}
