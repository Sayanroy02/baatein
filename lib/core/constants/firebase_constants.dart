import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConstants {
  static final String firebaseApiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
  static final String firebaseAppID = dotenv.env['FIREBASE_APP_ID'] ?? '';
  static final String firebaseSenderID = dotenv.env['FIREBASE_SENDER_ID'] ?? '';
  static final String firebaseProjectID =
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
}
