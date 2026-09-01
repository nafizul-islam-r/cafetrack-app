import 'package:cafetrack_flutter/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cafetrack_flutter/login_screen.dart';
import 'services/mongo_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MongoService.connect();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CafeTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (MongoService.currentUser != null) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
