import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';

// ignore: must_be_immutable
class ProgressPage extends StatefulWidget {
  String? userId;
  ProgressPage({super.key , this.userId});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;  
    final userId = widget.userId ?? args?['userId'];
    print(userId);
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Column(
        children: [
          Center(child: Text('progress page')),
          
        ],
      ),);
  }
}