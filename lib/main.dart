import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/connectivity.dart';
import 'notifiers/message_notifier.dart';

import 'package:flutter/foundation.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    String? url;
    String? anonKey;
    if (kIsWeb) {
      // Use values from --dart-define for web
      url = const String.fromEnvironment('SUPABASE_URL');
      anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    } else {
      // Use .env file for local dev (mobile/desktop)
      await dotenv.load(fileName: ".env");
      debugPrint("✅ .env loaded");
      url = dotenv.env['SUPABASE_URL'];
      anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    }

    if (url == null || anonKey == null) {
      debugPrint("❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY");
      runApp(const EnvErrorApp());
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    debugPrint("✅ Supabase initialized");

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MessageNotifier()),
        ],
        child: ConnectivityWrapper(child: const MyApp()),
      ),
    );
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
      home: Scaffold(
        body: Center(child: Text('Missing env values.')),
      ),
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
