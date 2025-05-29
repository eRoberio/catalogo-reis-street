import 'package:catalogo_reinstreet/home_page.dart';
import 'package:catalogo_reinstreet/providers/cart_provider.dart';
import 'package:catalogo_reinstreet/screens/login_screen.dart';
import 'package:catalogo_reinstreet/screens/register_screen.dart';
import 'package:catalogo_reinstreet/screens/reset_pass_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyB839tj2Hxg6a59C7ytM0DtIXmqrn8Pnd4',
      appId: '1:156214626284:android:6f7f1e5a925ae7f8c922c9',
      messagingSenderId: '156214626284',
      projectId: 'reisstreet-bc6a7',
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catálogo Digital',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFD0D3D2),
        fontFamily: 'Arial',
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/reset': (context) => ResetPasswordScreen(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

