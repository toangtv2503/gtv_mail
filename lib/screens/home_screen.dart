import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gtv_mail/components/list_mail_component.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  void _handleSignOut() {
    prefs.remove('currentIndex');
    prefs.remove('email');
    FirebaseAuth.instance.signOut();
  }

  Widget _buildEmailCategoriesMenu() {
    return Column(
      children: emailCategoriesMenu.asMap().map((index, option) {
        return MapEntry(
          index,
          option.containsKey('divider') ? const Divider() : ListTile(
            selected: currentIndex == index,
            style: ListTileStyle.drawer,
            selectedColor: AppTheme.greenColor,
            leading: option['icon'] as Icon,
            title: Text(option['title']),
            onTap: () {
              setState(() {
                currentIndex = index;
                prefs.setInt('currentIndex', index);
              });
              Navigator.pop(context);

              setState(() {
                currentCategoryName = option['title'];
              });
            },
          ),
        );
      }).values.toList(),
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
                child: CachedNetworkImage(
                  imageUrl: userService.getCurrentUser()!.photoURL!,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
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
                child: GestureDetector(
                  onTap: () {},
                  child: CircleAvatar(
                    child: CachedNetworkImage(
                      imageUrl: userService.getCurrentUser()!.photoURL!,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
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
              padding:
              const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                currentCategoryName,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          ListMailComponent(category: currentCategoryName, userEmail: email,)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleComposeMail,
        child: const Icon(Icons.add),
      ),
    );
  }
}
