import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/blynk_service_simple.dart';
import 'screens/simple_login_screen.dart';
import 'screens/simple_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BlynkServiceSimple()),
      ],
      child: MaterialApp(
        title: 'Blynk WebSocket Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SimpleLoginScreen(),
          '/dashboard': (context) => const SimpleDashboardScreen(),
        },
      ),
    );
  }
}
