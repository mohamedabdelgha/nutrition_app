import 'dart:async';

import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/customs/custom.dart';
import 'package:flutter_application_1/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _showSnack(String text) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.whiteColor, content: Text(text,style: TextStyle(color: AppColors.darkBlueColor,fontSize: 16,fontFamily: 'main'),)));
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    setState(() => _loading = true);
    try {
      // check if user exists in users table
      final existing = await supabase
          .from('users')
          .select('auth_id')
          .eq('email', email).eq('password', password)
          .limit(1)
          .select('password')
          .maybeSingle();

      if (existing == null) {
        await _showSnack('No account found for that email.');
        return;
      }

      // // attempt sign in with Supabase Auth
      //  await supabase.auth.signInWithPassword(
      //   email: email,
      //   password: password,
      // );

      final user = sb.Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // save uid locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', user.id);

        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        
        await _showSnack('Sign in failed. Please check credentials.');
      }
    } catch (e) {
      await _showSnack('Login error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.darkBlueColor,
      body: Container(
        width: width,
        height: height / 1.1,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius:
              const BorderRadius.only(bottomLeft: Radius.circular(100), bottomRight: Radius.circular(100)),
        ),
        child: ListView(
          children: [
            Container(
              height: height / 4,
              width: width,
              decoration: BoxDecoration(color: AppColors.darkBlueColor, borderRadius: BorderRadius.only(bottomRight: Radius.circular(300))),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Login',
                      style: TextStyle(
                          color: AppColors.whiteColor, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'main')),
                  Text("welcome , let's start new life",
                      style: TextStyle(color: AppColors.whiteColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'main')),
                ]),
              ),
            ),
            SizedBox(height: height / 15),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextBox(
                    controller: _emailCtrl,
                    hintText: 'Username or Email',
                    labelText: 'Enter your email',
                    prefixIcon: Icon(AmazingIconOutlined.email),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
                  ),
                  AppTextBox(
                    controller: _passCtrl,
                    hintText: 'Password',
                    labelText: 'Enter your password',
                    prefixIcon: Icon(AmazingIconOutlined.passwordCheck),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? 'Enter password (6+ chars)' : null,
                  ),
                  const SizedBox(height: 12),
                  ButtonBox(
                    width: width / 1.5,
                    height: height / 15,
                    labelText: _loading ? 'Signing in...' : 'Login',
                    ontap: _loading ? null : _handleLogin,
                  ),
                  const SizedBox(height: 12),
                  Text('OR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBlueColor)),
                  const SizedBox(height: 12),

                  // Google button (unchanged)
                  GestureDetector(
            onTap: () async {
                final completer = Completer<sb.User?>();
                final sub = sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
                  final session = data.session;
                  if (session?.user != null) completer.complete(session!.user);
                });

                try {
                  await supabase.auth.signInWithOAuth(
                    sb.OAuthProvider.google,
                    redirectTo: 'io.supabase.flutterdemo://login-callback/',
                  );

                  // Wait for the user object (timeout to avoid indefinite wait)
                  final user = await completer.future.timeout(const Duration(seconds: 20), onTimeout: () => null);
                  await sub.cancel();

                  if (user != null) {
                    // final email = user.email ?? '';
                    // final name = (user.userMetadata != null && user.userMetadata?['name'] != null)
                    //     ? user.userMetadata!['name'] as String
                    //     : (email.split('@').first);

                    // store uid locally
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('uid', user.id);

                    // check if a row with this auth_id exists
                    final existing = await supabase
                        .from('users')
                        .select()
                        .eq('auth_id', user.id)
                        .limit(1)
                        .maybeSingle();

                    if (existing == null) {

                      // navigate to data page with uid
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          '/user_data',
                          arguments: {
                            'userUid': user.id,
                            'email': user.email,
                            'name': user.userMetadata!['name'] as String,
                            'avatar': user.userMetadata!['avatar_url'] as String?,
                          
                          },
                        );
                      }

                      print('First-time sign-in. Redirecting to data page...');
                    } else {
                     
                      // navigate to home page
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }

                      print('Returning user. Redirecting to home page...');
                    }
                  } else {
                    print('Google sign-in did not complete or was cancelled.');
                  }
                } catch (e) {
                  await sub.cancel();
                  print('Google sign-in error: $e');
                }
          },                    child: Container(
                      height: height / 16,
                      width: width / 1.25,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.darkBlueColor, width: 2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        Icon(AmazingIconFilled.google1, color: AppColors.darkBlueColor, size: 30),
                        Text('Continue with Google', style: TextStyle(color: AppColors.darkBlueColor, fontSize: 18, fontWeight: FontWeight.w500))
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {},
                    child: Container(
                      height: height / 16,
                      width: width / 1.25,
                      decoration: BoxDecoration(border: Border.all(color: AppColors.darkBlueColor, width: 2), borderRadius: BorderRadius.circular(30)),
                      child:
                          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Icon(AmazingIconFilled.facebook, color: AppColors.darkBlueColor, size: 30), Text('Continue with facebook', style: TextStyle(color: AppColors.darkBlueColor, fontSize: 18, fontWeight: FontWeight.w500))]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: height / 30),
          ],
        ),
      ),
    );
  }
}