import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/user_provider.dart';
import 'package:shop_app/providers/sales_provider.dart';

import 'package:shop_app/providers/inventory_provider.dart';
import 'package:shop_app/services/mongodb_service.dart';
import 'package:shop_app/screens/login_screen.dart';
import 'package:shop_app/screens/home_screen.dart';
import 'package:shop_app/screens/add_sale_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // await Firebase.initializeApp(); // Init Firebase
    await MongoDatabase.connect();
  } catch (e) {
    debugPrint("CRITICAL DATABASE ERROR: $e");
    // Continue to run app to show error UI if needed
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: MaterialApp(
        title: 'Shop App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/add-sale': (context) => const AddSaleScreen(),
        },
      ),
    );
  }
}
