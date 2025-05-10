import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/connectivity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env loaded");
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      debugPrint("❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY");
      runApp(const EnvErrorApp());
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    debugPrint("✅ Supabase initialized");
    runApp(ConnectivityWrapper(child: const MyApp()));
  } catch (e, stack) {
    debugPrint("❌ Initialization failed: $e");
    debugPrintStack(stackTrace: stack);
    runApp(ConnectionErrorApp(errorMessage: e.toString()));
  }
}

class EnvErrorApp extends StatelessWidget {
  const EnvErrorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Missing env values.'))),
    );
  }
}

class ConnectionErrorApp extends StatelessWidget {
  final String errorMessage;
  const ConnectionErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Error initializing app: $errorMessage')),
      ),
    );
  }
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
        primaryColor: const Color(0xFF900C3F),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF900C3F)),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFF900C3F),
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: Supabase.instance.client.auth.currentUser == null
          ? const LoginScreen()
          : const HomeScreen(),
    );
  }
}
