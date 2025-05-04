// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'constants/constants.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Namaste Messenger',
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFF900C3F), // Updated to #900C3F
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF900C3F)),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFF900C3F),
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home:
          Supabase.instance.client.auth.currentUser == null
              ? const LoginScreen()
              : const HomeScreen(),
    );
  }
}
