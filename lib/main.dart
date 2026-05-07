import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:techno_shield/routes/app_routes.dart';
import 'package:techno_shield/services/api_service.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:techno_shield/view_models/cart_view_model.dart';
import 'package:techno_shield/view_models/my_order_view_model.dart';
import 'package:techno_shield/view_models/staff_task_checklist.dart';
import 'package:techno_shield/view_models/staff_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable rotation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final apiService =
      ApiService(baseUrl: 'http://jalmanagement.stageserverofbss.com');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyOrderViewModel(apiService)),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => StaffViewModel()),
         ChangeNotifierProvider(create: (_) => ChecklistProvider()),

      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: AppRoutes.splashScreen,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
