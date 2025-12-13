import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/habit_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
      ],
      child: MaterialApp(
        title: 'Life Solver',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<void>? _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = _fakeLoading();
  }

  Future<void> _fakeLoading() async {
    // Artificial delay for splash screen visibility (branding)
    await Future.delayed(Duration(seconds: 2));
    await Future.delayed(Duration(seconds: 2));
    // await Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
    // User requested logout on every app open:
    // await Provider.of<AuthProvider>(context, listen: false).logout();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        return Consumer<AuthProvider>(
          builder: (ctx, auth, _) {
            print(
              'AuthWrapper: Building. isAuthenticated: ${auth.isAuthenticated}',
            );
            return auth.isAuthenticated ? MainScreen() : LoginScreen();
          },
        );
      },
    );
  }
}
