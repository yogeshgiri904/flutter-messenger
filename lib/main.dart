import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/connectivity.dart';
import 'notifiers/message_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final env = await loadEnv();

    if (env['supabaseUrl'] == null || env['supabaseAnonKey'] == null) {
      debugPrint("❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY");
      runApp(const EnvErrorApp());
      return;
    }

    await Supabase.initialize(
      url: env['supabaseUrl']!,
      anonKey: env['supabaseAnonKey']!,
    );
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

Future<Map<String, String?>> loadEnv() async {
  if (kIsWeb) {
    return {
      'supabaseUrl': const String.fromEnvironment('SUPABASE_URL'),
      'supabaseAnonKey': const String.fromEnvironment('SUPABASE_ANON_KEY'),
    };
  } else {
    final dotenv = await importDotenv();
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env loaded");
    return {
      'supabaseUrl': dotenv.env['SUPABASE_URL'],
      'supabaseAnonKey': dotenv.env['SUPABASE_ANON_KEY'],
    };
  }
}

// This uses Dart's dynamic import workaround to avoid flutter_dotenv on web
Future<dynamic> importDotenv() async {
  // ignore: implementation_imports
  final dotenv = await Future.microtask(() async {
    // Dart does not support conditional imports with different APIs,
    // so we dynamically load the library only on supported platforms.
    return await importLib('package:flutter_dotenv/flutter_dotenv.dart');
  });
  return dotenv;
}

// This helper uses mirrors-like logic (but works with pub libraries)
Future<dynamic> importLib(String lib) async {
  return Future.sync(() => throw UnsupportedError('Dynamic import failed'));
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
