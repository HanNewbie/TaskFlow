import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:tubes/core/theme/app_theme.dart';
import 'package:tubes/data/datasources/firebase_auth_datasource.dart';
import 'package:tubes/data/datasources/firebase_notes_datasource.dart';
import 'package:tubes/data/repositories/auth_repository_impl.dart';
import 'package:tubes/data/repositories/notes_repository_impl.dart';
import 'package:tubes/presentation/providers/auth_provider.dart';
import 'package:tubes/presentation/providers/notes_provider.dart';
import 'package:tubes/presentation/screens/splash_screen.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('ƒo. Firebase initialized successfully');
    await NotificationService.instance.init();
  } catch (e) {
    print('ƒ?O Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authDataSource = FirebaseAuthDataSource();
    final notesDataSource = FirebaseNotesDataSource();
    
    final authRepository = AuthRepositoryImpl(authDataSource: authDataSource);
    final notesRepository = NotesRepositoryImpl(notesDataSource: notesDataSource);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => NotesProvider(
            notesRepository: notesRepository,
            notesDataSource: notesDataSource,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Notes App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
