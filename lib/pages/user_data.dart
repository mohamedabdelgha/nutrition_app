import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/customs/custom.dart';
import 'package:flutter_application_1/main.dart';

    final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);
class UserDataPage extends StatelessWidget {
  final String? userUid;
  final String? email;
  final String? name;
  final String? avatar;
  const UserDataPage({super.key, this.userUid, this.email, this.name, this.avatar});
  
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
  final uid = args?['userUid'];
  final email = args?['email'];
  final name = args?['name'];
  final avatar = args?['avatar'];

    final panels = <Widget>[
      CreatePass(userUid: uid),
      UserInfo(userid: uid,email: email,name: name,avatar: avatar,),
    ];
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: ValueListenableBuilder<int>(
              valueListenable: selectedIndex,
              builder: (context, index, _) {
                return IndexedStack(
                  index: index,
                  children: panels,
                );
              },
            ),
    );
  }
}

class CreatePass extends StatelessWidget {
  final String? userUid;
  const CreatePass({super.key, required this.userUid});
  @override
  Widget build(BuildContext context) {
  final TextEditingController passCtrl = TextEditingController(); 
  final formKey = GlobalKey<FormState>();
  final double width = MediaQuery.of(context).size.width;
  final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
        top: true,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(children: [
             Padding(
              padding: EdgeInsets.only(left:8.0),
              child: Text('Create your Password',style: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18),),
            ),
            
            AppTextBox(
              controller: passCtrl,
                hintText: 'Password',
                labelText: 'Enter your password',
                prefixIcon: const Icon(AmazingIconOutlined.passwordCheck),
                // obscureText: true,
                // validator: (v) => (v == null || v.length < 6) ? 'Enter password (6+ chars)' : null,
                ),
            ],),
                Container(
                  width: width,
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap:(){
                    // if (!(_formKey.currentState?.validate() ?? false)) return;
                          // final password = _passCtrl.text;
                          selectedIndex.value=1;
                          
                  },
                    child: Container(
                    width: width / 4,
                    height: height / 15,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
               ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Next',style: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18,fontWeight: FontWeight.w600),),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.darkBlueColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(AmazingIconOutlined.arrowRight,color: AppColors.whiteColor,size: 30,),
                          ),
                        ],
                      ),
                    
                                  ),
                  ),
                ),
          ],)),
      ),
    );
  }
}

class UserInfo extends StatefulWidget {
  final String? userid;
  final String? email;
  final String? name;
  final String? avatar;
  const UserInfo({super.key , required this.userid, this.email, this.name, this.avatar});

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {

  @override
  Widget build(BuildContext context) {
      final TextEditingController namectrl = TextEditingController(); 
  final TextEditingController genderctrl = TextEditingController(); 
  final TextEditingController agectrl = TextEditingController(); 
  final TextEditingController weightctrl = TextEditingController(); 
  final TextEditingController heightctrl = TextEditingController(); 
  namectrl.text = widget.name!;
  genderctrl.text = 'male';
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
      final formKey = GlobalKey<FormState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30.0),
          child: Row(
            children: [
              IconButton(onPressed: (){selectedIndex.value=0;}, icon: Icon(AmazingIconOutlined.arrowLeft,color: AppColors.darkBlueColor,size: 35,)),
              Text( 'User Information',style: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 20,fontWeight: FontWeight.bold),),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 30),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                          radius: 80,
                          backgroundImage: NetworkImage(widget.avatar!),
                          backgroundColor: Colors.transparent,
                        ),
                AppTextBox(
                  
                  controller: namectrl,
                  hintText: '',
                  labelText: 'name',
                  prefixIcon: const Icon(AmazingIconOutlined.user),
                  // obscureText: true,
                  validator: (v) => (v == null ) ? 'Enter your name' : null,
                ),
                AppTextBox(
                  controller: genderctrl,
                  hintText: 'gender',
                  labelText: '',
                  prefixIcon: const Icon(AmazingIconOutlined.messageQuestion),
                  // obscureText: true,
                  validator: (v) => (v == null  ) ? 'Enter your gender' : null,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: AppTextBox(
                        keyboardType:TextInputType.number,
                        inputFormatters:[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        controller: agectrl,
                        hintText: '',
                        labelText: 'age',
                        prefixIcon: const Icon(AmazingIconOutlined.nem),
                        // obscureText: true,
                        validator: (v) => (v == null  ) ? 'age cant be uder 15' : null,
                      ),
                    ),
                    Text( 'years',style: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18),),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: AppTextBox(
                        keyboardType:TextInputType.number,
                        inputFormatters:[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        controller: weightctrl,
                        hintText: '',
                        labelText: 'weight',
                        prefixIcon: const Icon(AmazingIconOutlined.weight1),
                      ),
                    ),
                    Text( 'kg',style: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18),),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: AppTextBox(
                        keyboardType:TextInputType.number,
                        inputFormatters:[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        controller: heightctrl,
                        hintText: '',
                        labelText: 'height',
                        prefixIcon: const Icon(AmazingIconOutlined.ruler),
                      ),
                    ),
                    Text( 'cm',style: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18),),
                  ],
                ),
                SizedBox(height: height/10,),
                Container(
                    width: width,
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onTap:()async{
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        await supabase.from('users').insert({
                          'email':widget.email ,
                          'name': namectrl.text ,
                          'age': agectrl.text ,
                          'weight': weightctrl.text,
                          'auth_id': widget.userid!,
                          'height': heightctrl.text,
                        });
                            // navigate to home page
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                      child: Container(
                      width: width / 4,
                      height: height / 15,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Finish',style: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18,fontWeight: FontWeight.w600),),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.darkBlueColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(AmazingIconOutlined.verify,color: AppColors.whiteColor,size: 30,),
                            ),
                          ],
                        ),
                      
                                    ),
                    ),
                  ),
                    
                
                
              ],
            ),
          ),
        ),
      ],
    );
  }
}