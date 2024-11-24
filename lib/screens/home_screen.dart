import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:go_router/go_router.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/components/list_mail_component.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../utils/app_theme.dart';
import '../utils/drawer_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _handleComposeMail() async {
    context.pushNamed('compose', queryParameters: {'draft': 'new'});
  }

  late String email = '';
  late SharedPreferences prefs;
  late int currentIndex = -1;
  late String currentCategoryName = "Primary";

  void init() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? '';
      currentIndex = prefs.getInt('currentIndex') ?? 2;
    });

    final id = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection("users").doc(id);
    docRef.snapshots().listen(
      (event) {
        setState(() {});
        notificationService.updateBadge(email);
      },
      onError: (error) => print("Listen failed: $error"),
    );

    FirebaseFirestore.instance
        .collection("mails")
        .where('to', arrayContains: email)
        .snapshots()
        .listen((querySnapshot) {
      for (var change in querySnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          NotificationService.showInstantNotification("GTV Mail", "New email had been sent to you");
        }
      }
    });

    FirebaseFirestore.instance
        .collection("mails")
        .where('cc', arrayContains: email)
        .snapshots()
        .listen((querySnapshot) {
      for (var change in querySnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          NotificationService.showInstantNotification("GTV Mail", "New email had been sent to you");
        }
      }
    });

    FirebaseFirestore.instance
        .collection("mails")
        .where('bcc', arrayContains: email)
        .snapshots()
        .listen((querySnapshot) {
      for (var change in querySnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          NotificationService.showInstantNotification("GTV Mail", "New email had been sent to you");
        }
      }
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  void _handleSignOut() {
    prefs.remove('currentIndex');
    prefs.remove('email');
    FlutterAppBadgeControl.updateBadgeCount(0);
    FirebaseAuth.instance.signOut();
  }

  void _handleOpenProfile() async {
    User? user = userService.getCurrentUser();
    context.pushNamed('profile', pathParameters: {'id': user!.uid});
  }

  void _handleDrawerMenu(int index, Map<String, dynamic> option) async {
    if (option['title'] == "Settings") {
      context.pushNamed('setting');
      return;
    }
    setState(() {
      currentIndex = index;
      prefs.setInt('currentIndex', index);
    });
    Navigator.pop(context);

    setState(() {
      currentCategoryName = option['title'];
    });
  }

  Widget _buildEmailCategoriesMenu() {
    return Column(
      children: emailCategoriesMenu
          .asMap()
          .map((index, option) {
            return MapEntry(
              index,
              option.containsKey('divider')
                  ? const Divider()
                  : ListTile(
                      selected: currentIndex == index,
                      style: ListTileStyle.drawer,
                      selectedColor: AppTheme.greenColor,
                      leading: option['icon'] as Icon,
                      title: Text(option['title']),
                      onTap: () => _handleDrawerMenu(index, option),
                    ),
            );
          })
          .values
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.blueColor,
                child: CachedNetworkImage(
                  imageUrl: userService.getCurrentUser()!.photoURL!,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      border: const GradientBoxBorder(
                        gradient: LinearGradient(colors: [
                          AppTheme.redColor,
                          AppTheme.greenColor,
                          AppTheme.yellowColor,
                          AppTheme.blueColor
                        ]),
                      ),
                      shape: BoxShape.circle,
                      image: DecorationImage(image: imageProvider),
                    ),
                  ),
                  placeholder: (context, url) => Lottie.asset(
                    'assets/lottiefiles/circle_loading.json',
                    fit: BoxFit.fill,
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              accountName: Text(userService.getCurrentUser()!.displayName!),
              accountEmail: Text(email),
            ),
            _buildEmailCategoriesMenu(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: _handleSignOut,
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            toolbarHeight: 64,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleOpenProfile,
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      backgroundColor: AppTheme.blueColor,
                      child: CachedNetworkImage(
                        imageUrl: userService.getCurrentUser()!.photoURL!,
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            border: const GradientBoxBorder(
                              gradient: LinearGradient(colors: [
                                AppTheme.redColor,
                                AppTheme.greenColor,
                                AppTheme.yellowColor,
                                AppTheme.blueColor
                              ]),
                            ),
                            shape: BoxShape.circle,
                            image: DecorationImage(image: imageProvider),
                          ),
                        ),
                        placeholder: (context, url) => Lottie.asset(
                          'assets/lottiefiles/circle_loading.json',
                          fit: BoxFit.fill,
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              )
            ],
            floating: true,
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: SizedBox(
                height: 300,
                child: Lottie.asset(
                  'assets/lottiefiles/mail_animation.json',
                  fit: BoxFit.fill,
                ),
              ),
              centerTitle: true,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 72.0),
                child: SizedBox(
                  height: 24,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      hintText: "Search In Mail",
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                currentCategoryName,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          ListMailComponent(
            category: currentCategoryName,
            userEmail: email,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleComposeMail,
        child: const Icon(Icons.add),
      ),
    );
  }
}
