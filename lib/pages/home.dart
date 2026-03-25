import 'package:flutter/material.dart';
import 'package:flutter_application_1/customs/custom.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/pages/daily.dart';
import 'package:flutter_application_1/pages/profile.dart';
import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter_application_1/pages/settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);

class HomePage extends StatefulWidget {
  final String? uid; // added

  const HomePage({super.key, this.uid}); // accept optional uid

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RealtimeChannel _userChannel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _userData;
  bool _loadingUser = false;

  void _onNavTap(int index) {
    if (selectedIndexNotifier.value == index) return;
    selectedIndexNotifier.value = index;
  }

  void _openMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    super.initState();
    // try to fetch user data using passed uid or from local storage
    if (widget.uid != null) {
      _fetchUserByUid(widget.uid!);
      _subscribeToUserChanges(widget.uid!); // 👈 ADD THIS
    } else {
      _loadUidFromPrefsAndFetch();
    }
  }

  Future<void> _loadUidFromPrefsAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('uid');
      if (savedUid != null) {
        await _fetchUserByUid(savedUid);
        _subscribeToUserChanges(savedUid); // 👈 ADD THIS
      }
    } catch (e) {
      // ignore
    }
  }

  void _subscribeToUserChanges(String uid) {
    _userChannel = Supabase.instance.client.channel('public:users')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'users',
        filter: PostgresChangeFilter(
          column: 'auth_id',
          value: uid,
          type: PostgresChangeFilterType.eq,
        ),
        callback: (payload) {
          final newRecord = payload.newRecord;
          setState(() {
            _userData = Map<String, dynamic>.from(newRecord);
          });
        },
      )
      ..subscribe();
  }

  // function to fetch user row by auth uid and store in _userData
  Future<void> _fetchUserByUid(String uid) async {
    setState(() => _loadingUser = true);
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('auth_id', uid)
          .maybeSingle();
      // response will be a Map<String, dynamic> or null
      if (response != null) {
        // try to get avatar from users table first, then fallback to auth user metadata
        final currentUser = Supabase.instance.client.auth.currentUser;
        String? avatar;
        if (response.containsKey('avatar_url')) {
          avatar = response['avatar_url'] as String?;
        }
        avatar ??= currentUser?.userMetadata?['avatar_url'] as String?;
        avatar ??= currentUser?.userMetadata?['picture'] as String?;
        setState(() {
          _userData = Map<String, dynamic>.from(response);
          if (avatar != null) _userData!['avatar_url'] = avatar;
        });
      } else {
        // try to use auth user metadata even if no row exists
        final currentUser = Supabase.instance.client.auth.currentUser;
        final avatar =
            currentUser?.userMetadata?['avatar_url'] as String? ??
            currentUser?.userMetadata?['picture'] as String?;
        setState(() {
          _userData = avatar != null ? {'avatar_url': avatar} : null;
        });
      }
    } catch (e) {
      setState(() {
        _userData = null;
      });
    } finally {
      setState(() => _loadingUser = false);
    }
  }

  @override
  void dispose() {
    _userChannel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final userId = widget.uid ?? args?['uid'];
    // panels that will be swapped inside the white container
    final panels = <Widget>[
      MyHomeContent(
        onMenuPressed: _openMenu,
        userName: _userData != null ? (_userData!['name'] as String?) : null,
        loadingUser: _loadingUser,
      ),
      DailyPage(userId: userId ?? ''),
      ProfilePage(
        userAge: _userData != null ? (_userData!['age'] as int?) : null,
        userHeight: _userData != null ? (_userData!['height'] as int?) : null,
        userWeight: _userData != null ? (_userData!['weight'] as int?) : null,
        userGender: _userData != null
            ? (_userData!['gender'] as String?)
            : null,
        userEmail: _userData != null ? (_userData!['email'] as String?) : null,
        userAvatar: _userData != null
            ? (_userData!['avatar_url'] as String?)
            : null,
        userUid: _userData != null ? (_userData!['auth_id'] as String?) : null,
        userName: _userData != null ? (_userData!['name'] as String?) : null,
        loadingUser: _loadingUser,
      ),
      const settingsPage(),
    ];
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.darkBlueColor,
      drawer: Drawer(
        backgroundColor: AppColors.whiteColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: SafeArea(
          child: DrawerWidget(
            userName: _userData != null
                ? (_userData!['name'] as String?)
                : null,
            loadingUser: _loadingUser,
            userAvatar: _userData != null
                ? (_userData!['avatar_url'] as String?)
                : null,
            userEmail: _userData != null
                ? (_userData!['email'] as String?)
                : null,
            userId: _userData != null
                ? (_userData!['auth_id'] as String?)
                : null,
          ),
        ),
      ),
      body: SafeArea(
        top: true,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(100),
            bottomRight: Radius.circular(100),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: width,
            height: height / 1.15,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
            child: ValueListenableBuilder<int>(
              valueListenable: selectedIndexNotifier,
              builder: (context, index, _) {
                return IndexedStack(index: index, children: panels);
              },
            ),
          ),
        ),
      ),
      // floating rounded bottom navigation bar
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: selectedIndexNotifier,
        builder: (context, selectedIndex, _) {
          return CustomNavigationBar(
            icons: const [
              AmazingIconOutlined.home,
              AmazingIconOutlined.watchStatus,
              AmazingIconOutlined.profileTick,
              AmazingIconOutlined.setting2,
            ],
            currentIndex: selectedIndex,
            onTap: _onNavTap,
            height: height * 0.085,
            margin: const EdgeInsets.all(0),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            elevation: 0,
          );
        },
      ),
    );
  }
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------
class MyHomeContent extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final String? userName;
  final bool loadingUser;

  const MyHomeContent({
    super.key,
    required this.onMenuPressed,
    this.userName,
    this.loadingUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return ListView(
      children: [
        // show loading or username if available
        if (loadingUser)
          Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.darkBlueColor,
            ),
          )
        else
          Container(
            padding: EdgeInsets.symmetric(
              vertical: height / 80,
              horizontal: width / 25,
            ),
            width: width,
            height: height / 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  alignment: Alignment.center,
                  onPressed: onMenuPressed,
                  icon: Icon(
                    AmazingIconOutlined.menu1,
                    color: AppColors.darkBlueColor,
                    size: 35,
                  ),
                ),
                Text(
                  'Home',
                  style: TextStyle(
                    color: AppColors.darkBlueColor,
                    fontFamily: 'header',
                    fontSize: 22,
                  ),
                ),
                IconButton(
                  alignment: Alignment.center,
                  onPressed: () {},
                  icon: Icon(
                    AmazingIconOutlined.notificationBing,
                    color: AppColors.darkBlueColor,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: width,
          padding: EdgeInsets.symmetric(
            vertical: height / 80,
            horizontal: width / 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi 👋',
                style: TextStyle(
                  color: AppColors.darkBlueColor,
                  fontFamily: 'main',
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' ${userName ?? 'there'}',
                style: TextStyle(
                  color: AppColors.darkBlueColor,
                  fontFamily: 'main',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  wordSpacing: 0.05,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
        ),
        AppTextBox(
          bordernum: 30,
          hintText: 'Search',
          labelText: 'Search',
          prefixIcon: Icon(AmazingIconOutlined.searchNormal),
        ),
        Container(
          width: width,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.symmetric(horizontal: width / 20),
          height: height / 5,
          decoration: BoxDecoration(
            border: BoxBorder.all(color: AppColors.darkBlueColor, width: 2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome !',
                    style: TextStyle(
                      color: AppColors.darkBlueColor,
                      fontFamily: 'main',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "let's schedule your diet",
                    style: TextStyle(
                      color: AppColors.lightBlueColor,
                      fontFamily: 'main',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      wordSpacing: 0.05,
                    ),
                  ),
                ],
              ),
              Image.asset('lib/assets/splash.png', width: width / 3),
            ],
          ),
        ),
        // Grid with 2 containers per row
        GridView.count(
          shrinkWrap: true, // let GridView size itself inside the ListView
          physics:
              const NeverScrollableScrollPhysics(), // ListView handles scrolling
          crossAxisCount: 1, // 2 items per row
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          padding: EdgeInsets.symmetric(horizontal: width / 20, vertical: 12),
          childAspectRatio: 4.5, // adjust to change width/height ratio of items
          children: List.generate(4, (index) {
            if (index == 0) {
              return GestureDetector(
                onTap: () async {
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final savedUid = prefs.getString('uid');
                    if (savedUid != null) {
                      Navigator.pushNamed(
                        context,
                        '/progress',
                        arguments: {'userId': supabase.auth.currentUser!.id},
                      );
                    }
                  } catch (e) {
                    // ignore
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkBlueColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Icon(
                              AmazingIconOutlined.dash,
                              color: AppColors.whiteColor,
                              size: 50,
                            ),
                            SizedBox(width: width / 30),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'my progress',
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'main',
                                  ),
                                ),
                                Text(
                                  'tap to see details',
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w200,
                                    fontFamily: 'main',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          bottom: 15.0,
                        ),
                        child: Text(
                          '2 days ago',
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w200,
                            fontFamily: 'main',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          AmazingIconOutlined.arrowRight1,
                          color: AppColors.whiteColor,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (index == 1) {
              {
                return GestureDetector(
                  onTap: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final savedUid = prefs.getString('uid');
                      if (savedUid != null) {
                        Navigator.pushNamed(
                          context,
                          '/calculate',
                          arguments: {'userId': supabase.auth.currentUser!.id},
                        );
                      }
                    } catch (e) {
                      // ignore
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: BoxBorder.all(
                        color: AppColors.lightBlueColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(
                                AmazingIconOutlined.coffee,
                                color: AppColors.whiteColor,
                                size: 50,
                              ),
                              SizedBox(width: width / 30),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Day meals',
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'main',
                                    ),
                                  ),
                                  Text(
                                    'tap to see details',
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w200,
                                      fontFamily: 'main',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 10.0,
                            bottom: 15.0,
                          ),
                          child: Text(
                            '2 days ago',
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w200,
                              fontFamily: 'main',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            AmazingIconOutlined.arrowRight1,
                            color: AppColors.whiteColor,
                            size: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
            if (index == 2) {
              {
                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: BoxBorder.all(
                        color: AppColors.lightBlueColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(
                                AmazingIconOutlined.heartSlash,
                                color: AppColors.whiteColor,
                                size: 50,
                              ),
                              SizedBox(width: width / 30),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'heart rate',
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'main',
                                    ),
                                  ),
                                  Text(
                                    'tap to see details',
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w200,
                                      fontFamily: 'main',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 10.0,
                            bottom: 15.0,
                          ),
                          child: Text(
                            '2 days ago',
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w200,
                              fontFamily: 'main',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            AmazingIconOutlined.arrowRight1,
                            color: AppColors.whiteColor,
                            size: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            } else {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(18),
                    border: BoxBorder.all(
                      color: AppColors.lightBlueColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Icon(
                              AmazingIconOutlined.heartSlash,
                              color: AppColors.whiteColor,
                              size: 50,
                            ),
                            SizedBox(width: width / 30),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'heart rate',
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'main',
                                  ),
                                ),
                                Text(
                                  'tap to see details',
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w200,
                                    fontFamily: 'main',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          bottom: 15.0,
                        ),
                        child: Text(
                          'days ago',
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w200,
                            fontFamily: 'main',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          AmazingIconOutlined.arrowRight1,
                          color: AppColors.whiteColor,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ); // empty container for other indices
            }
          }),
        ),
        SizedBox(height: height / 20),
      ],
    );
  }
}

//-------------------------------------------------------------------------------
class DrawerWidget extends StatefulWidget {
  final String? userName;
  final String? userId;
  final String? userEmail;
  final bool loadingUser;
  final String? userAvatar; // added

  const DrawerWidget({
    super.key,
    this.userName,
    required this.loadingUser,
    this.userAvatar,
    this.userEmail,
    this.userId, // added
  });

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: AppColors.darkBlueColor),
          child: Row(
            children: [
              // name and subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      widget.userName ?? 'User',
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 15,
                        fontFamily: 'main',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.userEmail ?? 'email',
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 12,
                        fontFamily: 'main',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // avatar / loading / placeholder
              if (widget.loadingUser)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.whiteColor,
                  ),
                )
              else if (widget.userAvatar != null &&
                  widget.userAvatar!.isNotEmpty)
                CircleAvatar(
                  radius: 45,
                  backgroundImage: NetworkImage(widget.userAvatar!),
                  backgroundColor: Colors.transparent,
                )
              else
                CircleAvatar(
                  radius: 45,
                  child: Icon(
                    AmazingIconFilled.userSquare,
                    color: AppColors.darkBlueColor,
                  ),
                ),

              const SizedBox(width: 12),
            ],
          ),
        ),
        ListTile(
          leading: Icon(
            AmazingIconOutlined.home,
            color: AppColors.darkBlueColor,
          ),
          title: Text(
            'Home',
            style: TextStyle(
              color: AppColors.darkBlueColor,
              fontFamily: 'main',
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            setState(() => selectedIndexNotifier.value = 0);
          },
        ),
        ListTile(
          leading: Icon(
            AmazingIconOutlined.watchStatus,
            color: AppColors.darkBlueColor,
          ),
          title: Text(
            'Daily',
            style: TextStyle(
              color: AppColors.darkBlueColor,
              fontFamily: 'main',
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            setState(() => selectedIndexNotifier.value = 1);
          },
        ),
        ListTile(
          leading: Icon(
            AmazingIconOutlined.profileTick,
            color: AppColors.darkBlueColor,
          ),
          title: Text(
            'Profile',
            style: TextStyle(
              color: AppColors.darkBlueColor,
              fontFamily: 'main',
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            setState(() => selectedIndexNotifier.value = 2);
          },
        ),
        ListTile(
          leading: Icon(
            AmazingIconOutlined.infoCircle,
            color: AppColors.darkBlueColor,
          ),
          title: Text(
            'About Us',
            style: TextStyle(
              color: AppColors.darkBlueColor,
              fontFamily: 'main',
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/aboutus');
          },
        ),
        ListTile(
          leading: Icon(
            AmazingIconOutlined.message,
            color: AppColors.darkBlueColor,
          ),
          title: Text(
            'Feedbacks',
            style: TextStyle(
              color: AppColors.darkBlueColor,
              fontFamily: 'main',
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            setState(() => selectedIndexNotifier.value = 2);
          },
        ),
        const Spacer(),
        ListTile(
          leading: Icon(
            AmazingIconOutlined.logout1,
            color: AppColors.darkBlueColor,
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              color: AppColors.darkBlueColor,
              fontFamily: 'main',
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () async {
            await AuthService.signOut(context);
          },
        ),
      ],
    );
  }
}

//-----------------------------------------------------------------------------------------------
class AuthService {
  /// Signs out the current user, clears stored uid and navigates to the login screen.
  static Future<void> signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      // log but continue to clear local state
      // ignore: avoid_print
      print('Sign out error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('uid');
    } catch (e) {
      // ignore prefs errors
      // ignore: avoid_print
      print('Error clearing prefs: $e');
    }

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}
