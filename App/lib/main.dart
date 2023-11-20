import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'util.dart';
import 'home.dart';

int createUniqueId() {
  return DateTime.now().millisecondsSinceEpoch.remainder(100000);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data.isEmpty) {
    return;
  }

  debugPrint('onMessage');

  String title = message.data["title"];
  String body = message.data["body"];

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: createUniqueId(),
      channelKey: 'basic_channel',
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  AwesomeNotifications().initialize('resource://drawable/logo',
    [
      NotificationChannel(
        channelGroupKey: 'all_notifications_group',
        channelKey: 'basic_channel',
        channelName: 'Notifications',
        channelDescription: 'All app notifications are received with this channel',
        defaultColor: Colors.black,
        importance: NotificationImportance.High,
        ledColor: Colors.green,
        channelShowBadge: true,
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(
          channelGroupKey: 'all_notifications_group',
          channelGroupName: 'All notifications')
    ]
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'walking schedule',
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: LoginPage()
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

enum AuthState {
  kLoggedOut,
  kLoggedIn
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  AuthState _authState = AuthState.kLoggedOut;

  late final FirebaseMessaging _messaging;

  _LoginPageState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _AuthStateChange(user);
    });
  }

  @override
  void initState() {
    registerNotification();
    super.initState();
  }

  void registerNotification() async {
    _messaging = FirebaseMessaging.instance;
    _messaging.subscribeToTopic('all');

    _messaging.getToken().then((String? token) {
      assert(token != null);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      debugPrint('clicked');
    });

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        if (message.data.isEmpty) {
          return;
        }
        debugPrint('onMessage');

        String title = message.data["title"];
        String body = message.data["body"];

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: createUniqueId(),
            channelKey: 'basic_channel',
            title: title,
            body: body,
            notificationLayout: NotificationLayout.Default,
          ),
        );
      });
    }
  }

  void _AuthStateChange(User? user) async {
    if (user == null) {
      setState(() {
        _authState = AuthState.kLoggedOut;
      });
      _messaging.unsubscribeFromTopic('admin');
      _messaging.unsubscribeFromTopic('all');
    } else {
      try {
        var url = Uri.parse('https://api.walking-schedule.scheenen.dev/user/${user.uid}');
        var res = await http.post(url);
        if (res.statusCode == 200) {
          setState(() {
            _authState = AuthState.kLoggedIn;
          });
          Map<String, dynamic> body = json.decode(res.body)['data'];
          if (body.containsKey('role') && body['role'] == 'admin') {
            _messaging.subscribeToTopic('admin');
          }
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', 'code: ${res.statusCode}\nbody: ${res.body}'),
          );
        }
      } catch (err) {
        showDialog(
          context: context,
          builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', err.toString()),
        );
        setState(() {
          _authState = AuthState.kLoggedOut;
        });
      }
    }
  }

  void _HandleSignIn() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

    //Create Google Auth credentials to pass to Firebase
    final OAuthCredential googleAuthCredential =
    GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //Authenticate against Firebase with Google credentials
    await firebaseAuth.signInWithCredential(googleAuthCredential);
  }

  @override
  Widget build(BuildContext context) {
    _authState = firebaseAuth.currentUser != null ? AuthState.kLoggedIn : AuthState.kLoggedOut;

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    switch (_authState) {
      case AuthState.kLoggedIn:
        return const HomePage();
      case AuthState.kLoggedOut:
        return Scaffold(
          appBar: AppBar(
            title: const Center(child: Text("Login")),
          ),
          body: Center(
              child: InkWell(
                onTap: () {_HandleSignIn();},
                child: Ink(
                  color: const Color(0xFF397AF3),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Image.asset("assets/logos/google/g-round.png", height: 30.0,),
                        const SizedBox(width: 12),
                        const Text('Sign in with Google'),
                      ],
                    ),
                  ),
                ),
              )
          ),
        );
    }
  }
}