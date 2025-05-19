import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/controllers/fcm_controllers.dart';
import 'package:chat/controllers/local_saved_data.dart';
import 'package:chat/firebase_options.dart';
import 'package:chat/providers/chat_provider.dart';
import 'package:chat/providers/user_data_provider.dart';
import 'package:chat/providers/status_provider.dart';
import 'package:chat/views/chat_page.dart';
import 'package:chat/views/create_or_update_group.dart';
import 'package:chat/views/email_update_profile.dart';
import 'package:chat/views/explore_groups.dart';
import 'package:chat/views/group_chat_page.dart';
import 'package:chat/views/group_details.dart';
import 'package:chat/views/home.dart';
import 'package:chat/views/invite_members.dart';
import 'package:chat/views/phone_login.dart';
import 'package:chat/views/profile.dart';
import 'package:chat/views/search_users.dart';
import 'package:chat/views/update_profile.dart';
import 'package:chat/views/email_login.dart';
import 'package:chat/views/view_profile.dart';
import 'package:chat/views/welcome_screen.dart';

import 'providers/group_message_provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

const kPrimaryColor = Colors.blueAccent;

// function to listen to background changes
Future _firebaseBackgroundMessage(RemoteMessage message) async {
  if (message.notification != null) {
    print("Some notification Received in background...");
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check if navigatorKey.currentState exists before trying to use it
    if (navigatorKey.currentState == null) return;

    // Get the provider without throwing an error if not available
    final provider = Provider.of<UserDataProvider>(
      navigatorKey.currentState!.context,
      listen: false,
    );

    // Only proceed if we have a userId
    final currentUserId = provider.getUserId;
    if (currentUserId == null || currentUserId.isEmpty) return;

    switch (state) {
      case AppLifecycleState.resumed:
        updateOnlineStatus(status: true, userId: currentUserId);
        print("app resumed");
        break;
      case AppLifecycleState.inactive:
        updateOnlineStatus(status: false, userId: currentUserId);
        print("app inactive");
        break;
      case AppLifecycleState.paused:
        updateOnlineStatus(status: false, userId: currentUserId);
        print("app paused");
        break;
      case AppLifecycleState.detached:
        updateOnlineStatus(status: false, userId: currentUserId);
        print("app detched");
        break;
      case AppLifecycleState.hidden:
        updateOnlineStatus(status: false, userId: currentUserId);
        print("app hidden");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(LifecycleEventHandler());

  // More robust Firebase initialization
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // Get existing instance
    }
  } catch (e) {
    // If error still occurs, get the existing Firebase instance
    print("Firebase initialization error: $e");
    Firebase.app();
  }

  await LocalSavedData.init();

  // initialize firebase messaging
  await PushNotifications.init();

  // initialize local notifications
  await PushNotifications.localNotiInit();
  // Listen to background notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);

  // on background notification tapped
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.notification != null) {
      print("Background Notification Tapped");
      navigatorKey.currentState!.pushNamed("/message", arguments: message);
    }
  });

// to handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    String payloadData = jsonEncode(message.data);
    print("Got a message in foreground");
    if (message.notification != null) {
      PushNotifications.showSimpleNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
          payload: payloadData);
    }
  });

  // for handling in terminated state
  final RemoteMessage? message =
      await FirebaseMessaging.instance.getInitialMessage();

  if (message != null) {
    print("Launched from terminated state");
    Future.delayed(Duration(seconds: 1), () {
      navigatorKey.currentState!.pushNamed(
        "/home",
      );
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserDataProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => GroupMessageProvider()),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'FastChat App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
            primary: kPrimaryColor,
          ),
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kPrimaryColor),
            ),
          ),
        ),
        routes: {
          "/": (context) => CheckUserSessions(),
          "/welcome": (context) => WelcomeScreen(),
          "/login": (context) => PhoneLogin(),
          "/email_login": (context) => EmailLogin(),
          "/email_update": (context) => EmailUpdateProfile(),
          "/home": (context) => HomePage(),
          "/chat": (context) => ChatPage(),
          "/profile": (context) => ProfilePage(),
          "/update": (context) => UpdateProfile(),
          "/search": (context) => SearchUsers(),
          "/modify_group": (context)=> CreateOrUpdateGroup(),
          "/read_group_message": (context)=> GroupChatPage(),
          "/invite_members":(context)=>InviteMembers(),
          "/group_detail":(context)=> GroupDetails(),
          "/explore_groups":(context)=> ExploreGroups(),
          "/email_update":(context)=> const EmailUpdateProfile(),
          "/view_profile":(context)=> ViewProfile(
            userId: (ModalRoute.of(context)?.settings.arguments as Map)['userId'] ?? '',
          ),
        },
      ),
    );
  }
}

class CheckUserSessions extends StatefulWidget {
  const CheckUserSessions({super.key});

  @override
  State<CheckUserSessions> createState() => _CheckUserSessionsState();
}

class _CheckUserSessionsState extends State<CheckUserSessions> {
  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      Provider.of<UserDataProvider>(context, listen: false).loadDatafromLocal();
    });

    checkSessions().then((value) {
      final userName =
          Provider.of<UserDataProvider>(context, listen: false).getUserName;
      print("username :$userName");
      if (value) {
        if (userName != null && userName != "") {
          Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, "/update", (route) => false,
              arguments: {"title": "add"});
        }
      } else {
        // Navigate to welcome screen instead of login directly
        Navigator.pushNamedAndRemoveUntil(context, "/welcome", (route) => false);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
