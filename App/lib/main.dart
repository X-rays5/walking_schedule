import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog walking calendar',
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
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

  _LoginPageState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _AuthStateChange(user);
    });
    FirebaseAuth.instance.idTokenChanges().listen((User? user) {
      _AuthStateChange(user);
    });
  }

  void _AuthStateChange(User? user) {
    if (user == null) {
      setState(() {
        _authState = AuthState.kLoggedOut;
      });
    } else {
      setState(() {
        _authState = AuthState.kLoggedIn;
      });
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
        return HomePage(firebaseAuth);
      case AuthState.kLoggedOut:
        return Scaffold(
          appBar: AppBar(
            title: const Center(child: Text("Login")),
          ),
          body: Center(
              child: InkWell(
                onTap: () {_HandleSignIn();},
                child: Ink(
                  color: Color(0xFF397AF3),
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Image.asset("assets/logos/google/g-round.png", height: 30.0),
                        SizedBox(width: 12),
                        Text('Sign in with Google'),
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