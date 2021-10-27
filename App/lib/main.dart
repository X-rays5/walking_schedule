import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:http/http.dart' as http;

import 'home.dart';

int createUniqueId() {
  return DateTime.now().millisecondsSinceEpoch.remainder(100000);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: createUniqueId(),
      channelKey: 'basic_channel',
      title: message.data['title'],
      body: message.data['body'],
      notificationLayout: NotificationLayout.Default,
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  AwesomeNotifications().initialize('resource://drawable/logo',
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        defaultColor: Colors.black,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
        child: MaterialApp(
          title: 'walking schedule',
          theme: ThemeData(
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
          ),
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          home: LoginPage(),
        ));
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
    checkForInitialMessage();
    super.initState();
  }

  void registerNotification() async {
    _messaging = FirebaseMessaging.instance;
    _messaging.subscribeToTopic('all');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
      // For handling the received notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: createUniqueId(),
            channelKey: 'basic_channel',
            title: message.data['title'],
            body: message.data['body'],
            notificationLayout: NotificationLayout.Default,
          ),
        );
      });
    }
  }

  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: createUniqueId(),
          channelKey: 'basic_channel',
          title: initialMessage.data['title'],
          body: initialMessage.data['body'],
          notificationLayout: NotificationLayout.Default,
        ),
      );
    }
  }

  void _AuthStateChange(User? user) async {
    if (user == null) {
      setState(() {
        _authState = AuthState.kLoggedOut;
      });
    } else {
      var url = Uri.parse('http://192.168.1.18:3000/user/${user.uid}'); //TODO: replace this with a server url
      var res = await http.post(url);
      if (res.statusCode == 200) {
        setState(() {
          _authState = AuthState.kLoggedIn;
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