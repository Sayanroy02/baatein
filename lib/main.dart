import 'package:baatein/core/constants/firebase_constants.dart';
import 'package:baatein/core/theme/app_theme.dart';
import 'package:baatein/data/repositories/auth_repository.dart';
import 'package:baatein/presentation/bloc/bloc/auth_bloc.dart';
import 'package:baatein/presentation/pages/home_screen.dart';
import 'package:baatein/presentation/pages/signup_page.dart';
import 'package:baatein/presentation/screens/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: FirebaseConstants.firebaseApiKey,
      appId: FirebaseConstants.firebaseAppID,
      messagingSenderId: FirebaseConstants.firebaseSenderID,
      projectId: FirebaseConstants.firebaseProjectID,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        ),
        child: MaterialApp(
          title: 'Baatein',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: AuthWrapper(),
        ),
      ),
    );
  }
}
