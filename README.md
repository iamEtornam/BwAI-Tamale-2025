# Session 0 - Flutter for the Creative: Image to Story Generator with Gemini

- **Speakers**: @iamEtornam

## About the session

Building a Flutter app where users select about 5 images, and Gemini creates a
story from them. This workshop focuses on using the Gemini multi-modal
capabilities to analyze multiple images and then using its text generation
capabilities to weave a narrative connecting the visual elements. The final
result would be an engaging story produced entirely by AI based on the user's
image selections.

## Links

- [Slides](https://docs.google.com/presentation/d/1QN33cR7K8D9gvY_sYVmgjP3iJV5ZragtM68ye6xri3Y/edit?usp=sharing)
- [Demo](https://youtu.be/sVrqqU0Dcd0)

## Setup Process

### Prerequisites

1. Flutter SDK (3.7.2 or higher)
2. Dart SDK (3.7.2 or higher)
3. Firebase account
4. Google Cloud account with Gemini API access

### Installation Steps

1. Clone the repository
   ```bash
   git clone [repository URL]
   cd story_teller
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Firebase Setup
   - Install the required command line tools
     ```bash
     dart pub global activate flutterfire_cli
     ```
   - Create a new Firebase project in the
     [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication with Google Sign-in
   - Configure your Flutter app with Firebase:
     ```bash
     flutterfire configure
     ```
     This will guide you through selecting your Firebase project and platforms
     (iOS, Android, web) and generate the necessary configuration files
     (`google-services.json` and `GoogleService-Info.plist`)

   - Initialize Firebase in your app by editing your `lib/main.dart` file:
     ```dart
     import 'package:firebase_core/firebase_core.dart';
     import 'firebase_options.dart';

     // Inside your main function
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     ```

   - Add Firebase plugins to your app by running:
     ```bash
     flutter pub add firebase_core
     flutter pub add firebase_auth
     flutter pub add firebase_ai
     ```

4. Gemini API Setup
   - Create a project in Firebase Console
   - Go to (Google Cloud Platform)[https://console.cloud.google.com/welcome]
   - Go to billing manager at the left panel and attach the billing account to the project you created on Firebase Console
   - Return to Firebase console and Go to AI Logic
   - Enable Gemini API
   - Enable Vertex ai

5. Run the application
   ```bash
   flutter run
   ```

### Project Structure

- `lib/screens/`: Contains all app screens
- `lib/services/`: API and Firebase services
- `lib/widgets/`: Reusable UI components
- `assets/`: Contains images and icons
