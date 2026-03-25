import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/customs/custom.dart';
import 'package:flutter_application_1/main.dart';

// ignore: must_be_immutable
class ProfilePage extends StatelessWidget {
String? userUid;
  final String? userName;
  final String? userGender;
  final int? userAge;
  final int? userWeight;
  final int? userHeight;
  final String? userEmail;
  final bool loadingUser;
    final String? userAvatar; // added
   ProfilePage({super.key, this.userUid, this.userName, required this.loadingUser, this.userAvatar, this.userEmail, this.userGender, this.userAge, this.userWeight, this.userHeight});

  @override
  Widget build(BuildContext context) {
    final double BMR=calculateBMR(weightKg: userWeight?? 0, heightCm: userHeight?? 0, age: userAge?? 0, gender: userGender?? '').toDouble();
Future<void> showCustomDialog({
  required String title,
  required String message,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppColors.whiteColor,
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.darkBlueColor,
            fontFamily: 'main',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: AppColors.darkBlueColor,
            fontFamily: 'main',
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppColors.lightBlueColor,
                fontFamily: 'main',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}

//---------------------------------------------------------------------------------------------------------
    return ListView(
      children:[ loadingUser
          ?  CircularProgressIndicator(color: AppColors.darkBlueColor,)
          : Column(
              mainAxisAlignment: MainAxisAlignment.start, 
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
               // avatar / loading / placeholder
              Column(
                mainAxisAlignment: MainAxisAlignment.start, 
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
      
              const SizedBox(
                width: 56,
                height: 56,
              ),
                if (loadingUser)
               SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBlueColor),
              )
            else if (userAvatar != null && userAvatar!.isNotEmpty)
              Center(
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: NetworkImage(userAvatar!),
                  backgroundColor: Colors.transparent,
                ),
              )
            else
      
              Center(
                child: CircleAvatar(
                  radius: 100,
                  child: Icon(AmazingIconFilled.userSquare, color: AppColors.darkBlueColor),
                ),
              ),
              SizedBox(height: 20,),
              Center(
                child: Text(
                  userName ?? 'Guest User',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: AppColors.darkBlueColor,fontFamily: 'main'),
                ),
              ),
              Center(
                child: Text(
                  userEmail ?? 'Guest email',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500,color: AppColors.darkBlueColor,fontFamily: 'main'),
                ),
              ),
              ],),
              Container(height: 1,color: AppColors.darkBlueColor,width: double.infinity,margin: EdgeInsets.symmetric(vertical:10),),
              Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left:8.0),
                child: Row(
                  children: [
                    Icon(AmazingIconOutlined.information,size: 24,color: AppColors.darkBlueColor,),
                    SizedBox(width: 8,),
                    Text('Personal Information',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: AppColors.darkBlueColor,fontFamily: 'main'),),
                  ],
                ),
              ),
              GridView.count(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true, // let GridView size itself inside the ListView
                physics: const NeverScrollableScrollPhysics(), // ListView handles scrolling
                crossAxisCount: 1, // 2 items per row
                crossAxisSpacing: 0,
                mainAxisSpacing: 3,
                childAspectRatio: 5,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(AmazingIconOutlined.radar,size: 24,color: AppColors.darkBlueColor,),
                          SizedBox(width: 8,),
                      Text(
                        'BMR: ',
                        style: TextStyle(fontSize: 18, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$BMR',
                        style: TextStyle(fontSize: 16, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w400),
                      ),
                        ],
                      ),
                      
                    ],
                  ),  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(AmazingIconOutlined.nebulas,size: 24,color: AppColors.darkBlueColor,),
                          SizedBox(width: 8,),
                          Text(
                            'Age: ',
                            style: TextStyle(fontSize: 16, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w600),
                          ),
                      Text(
                        '$userAge years',
                        style: TextStyle(fontSize: 18, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w400),
                      ),
                      ],
                      ),
                      IconButton(
                        onPressed:(){
                        showCustomDialog(title: 'Edit Age', message: 'Age editing not implemented yet.');
                        },
                        icon: Icon(AmazingIconFilled.edit2,size: 25,color: AppColors.darkBlueColor,),
                      ) 
                    ],
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(AmazingIconOutlined.ruler,size: 24,color: AppColors.darkBlueColor,),
                          SizedBox(width: 8,),
                      Text(
                        'Height: ',
                        style: TextStyle(fontSize: 18, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$userHeight cm',
                        style: TextStyle(fontSize: 16, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w400),
                      ),
                        ],
                      ),
                      IconButton(
                        onPressed:(){                 
                            showCustomDialog(title: 'Edit Height', message: 'Height editing not implemented yet.');
                        },
                        icon: Icon(AmazingIconFilled.edit2,size: 25,color: AppColors.darkBlueColor,),
                      ) 
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(AmazingIconOutlined.weight1,size: 24,color: AppColors.darkBlueColor,),
                          SizedBox(width: 8,),
                      Text(
                        'Weight: ',
                        style: TextStyle(fontSize: 18, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$userWeight kg',
                        style: TextStyle(fontSize: 16, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w400),
                      ),
                        ],
                      ),
                      IconButton(onPressed: () {
                        showCustomDialog(title: 'Edit Weight', message: 'Weight editing not implemented yet.');

                      }, icon: Icon(AmazingIconFilled.edit2,size: 25,color: AppColors.darkBlueColor,)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(AmazingIconOutlined.weight1,size: 24,color: AppColors.darkBlueColor,),
                          SizedBox(width: 8,),
                      Text(
                        'Gender: ',
                        style: TextStyle(fontSize: 18, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$userGender',
                        style: TextStyle(fontSize: 16, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w400),
                      ),
                        ],
                      ),
                      IconButton(onPressed: () {
                        showCustomDialog(title: 'Edit Weight', message: 'Weight editing not implemented yet.');

                      }, icon: Icon(AmazingIconFilled.edit2,size: 25,color: AppColors.darkBlueColor,)),
                    ],
                  ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //       children: [
                  //     Icon(AmazingIconOutlined.nebulas,size: 24,color: AppColors.darkBlueColor,),
                  //     Text(
                  //       'Age: ',
                  //       style: const TextStyle(fontSize: 16, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w600),
                  //     ),
                  //     Text(
                  //       '25',
                  //       style: const TextStyle(fontSize: 16, color: AppColors.darkBlueColor,fontFamily: 'main',fontWeight: FontWeight.w400),
                  //     ),
                  //     ]),
                  //     IconButton(
                  //       onPressed:(){},
                  //       icon: Icon(AmazingIconFilled.edit2,size: 25,color: AppColors.darkBlueColor,),
                  //     ) 
                  //   ],
                  // ),
                ],
              ),
              
              ],
            ),
    ]);
  }
}