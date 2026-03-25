// ...existing code...
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart'; // to access `supabase`
import 'package:flutter_application_1/pages/home.dart'; // added

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  Timer? _timer;
  bool _userExists = false;
  String? _uid; // added to keep uid to pass to HomePage

  @override
  void initState() {
    super.initState();
    _checkUidAndStartTimer();
  }

  Future<void> _checkUidAndStartTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      _uid = uid; // store uid

      if (uid == null) {
        _userExists = false;
      } else {
        // query users table to see if a row with auth_id == uid exists
        final result = await supabase
            .from('users')
            .select('auth_id')
            .eq('auth_id', uid)
            .limit(1)
            .maybeSingle();
        _userExists = result != null;
      }
    } catch (e) {
      _userExists = false;
    }

    // show splash for 10 seconds then navigate
    _timer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_userExists) {
        // pass the uid into HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(uid: _uid)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        top: true,
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Fitness App',
                      style: TextStyle(
                        color: AppColors.darkBlueColor,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'main',
                      ),
                    ),
                    Text(
                      'the way to start your healthy life',
                      style: TextStyle(
                        color: AppColors.darkBlueColor,
                        fontSize: 18,
                        fontFamily: 'main',
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset('lib/assets/splash.png'),
            ],
          ),
        ),
      ),
    );
  }
}
// ...existing code...