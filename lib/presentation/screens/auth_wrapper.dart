import 'package:baatein/presentation/bloc/bloc/auth_bloc.dart';
import 'package:baatein/presentation/pages/home_screen.dart';
import 'package:baatein/presentation/pages/signup_page.dart';
import 'package:baatein/presentation/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Baatein',
                    style: GoogleFonts.amita(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          );
        }

        // Show signup screen if user is not authenticated
        if (!snapshot.hasData) {
          return const SignUpScreen();
        }

        // User is authenticated, check if profile is complete
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userDoc) {
            if (userDoc.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }

            // Check if user profile exists and is complete
            if (!userDoc.hasData ||
                !userDoc.data!.exists ||
                userDoc.data!.get('isProfileComplete') != true) {
              // Profile needs to be set up
              context.read<AuthBloc>().add(const ProfileSetupCompleted());
              return const ProfileSetupScreen();
            }

            // Profile is complete, show home screen
            return const HomeScreen();
          },
        );
      },
    );
  }
}
