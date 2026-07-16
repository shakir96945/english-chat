import 'package:flutter/material';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/shakir_wrapper.dart';
import 'controllers/auth_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/group_controller.dart';
import 'controllers/friend_controller.dart';
import 'controllers/call_controller.dart';
import 'core/services/notification_service.dart';
import 'core/services/zego_call_service.dart';
import 'core/services/firebase_options.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Push Notification services
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProxyProvider<AuthController, ChatController>(
          create: (_) => ChatController(),
          update: (_, auth, chat) => chat!..updateUserId(auth.currentUser?.uid),
        ),
        ChangeNotifierProvider(create: (_) => GroupController()),
        ChangeNotifierProvider(create: (_) => FriendController()),
        ChangeNotifierProvider(create: (_) => CallController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeZegoService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeZegoService() {
    final authController = Provider.of<AuthController>(context, listen: false);
    if (authController.currentUser != null) {
      ZegoCallService.initZegoService(
        userId: authController.currentUser!.uid,
        userName: authController.currentUser!.displayName ?? "Golden User",
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final authController = Provider.of<AuthController>(context, listen: false);
    if (authController.currentUser != null) {
      if (state == AppLifecycleState.resumed) {
        authController.updatePresence(true);
      } else {
        authController.updatePresence(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Default brand experience is luxurious Dark
      builder: (context, child) => ShakirWrapper(child: child!),
      home: const SplashScreen(),
    );
  }
}
