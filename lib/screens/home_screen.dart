import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:go_router/go_router.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/components/list_mail_component.dart';
import 'package:gtv_mail/models/answer_template.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/template_service.dart';
import 'package:gtv_mail/utils/image_default.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mail.dart';
import '../services/mail_service.dart';
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
  late SharedPreferences prefs;
  late int currentIndex = 2;
  late String currentCategoryName = "Primary";
  late MyUser? user = MyUser();
  late bool isAutoReply = false;

  void init() async {
    prefs = await SharedPreferences.getInstance();

    user = await userService.getLoggedUser();
    if (!kIsWeb) {
      await notificationService.updateBadge();
    }
    final docRef =
        FirebaseFirestore.instance.collection("users").doc(user!.uid);

    docRef.snapshots().listen(
      (event) async {
        setState(() {});
      },
      onError: (error) => print("Listen failed: $error"),
    );

    FirebaseFirestore.instance
        .collection("mails")
        .where('to', arrayContains: user!.email)
        .snapshots()
        .listen((querySnapshot) async {
      for (var change in querySnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data();
          if (data == null) continue;

          var newMail = Mail.fromJson(data);

          DateTime sentDate = newMail.sentDate!;

          if (sentDate
              .isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
            continue;
          }

          if (newMail.isDraft) continue;

          if (!kIsWeb) {
            NotificationService.showInstantNotification(
                newMail.from!, newMail.subject!);
            await notificationService.updateBadge();
          }

          isAutoReply = prefs.getBool('auto_answer_mode') ?? false;
          if (isAutoReply) {
            AnswerTemplate? template = await templateService.getTemplateByEmail(user!.email!);
            if (template != null) {
              await mailService.sendAutoAnswerMail(template, newMail.from!);
            }

          }

        }
      }
    });

    setState(() {});
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  void _handleDiscardDraft(Mail draft) async {
    await mailService.deleteMail(draft);
  }

  _handleComposeMail() async {
    var result =
        await context.pushNamed('compose', queryParameters: {'type': 'new'});

    if (result.runtimeType == Mail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft saved'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
              label: 'Discard',
              onPressed: () => _handleDiscardDraft(result as Mail)),
        ),
      );
    }
  }

  void _handleSignOut() async {
    if (!kIsWeb) {
      await FlutterAppBadgeControl.updateBadgeCount(0);
    }
    await FirebaseAuth.instance.signOut();
  }

  void _handleOpenProfile() async {
    MyUser? user = await userService.getLoggedUser();
    if (user != null) {
      context.pushNamed('profile', pathParameters: {'id': user.uid!});
    }
  }

  void _handleDrawerMenu(int index, Map<String, dynamic> option) async {
    if (option['title'] == "Settings") {
      context.pushNamed('setting');
      return;
    }
    setState(() {
      currentIndex = index;
    });
    Navigator.pop(context);

    setState(() {
      currentCategoryName = option['title'];
    });
  }

  void _handleHardDelete() async {
    final result = await showOkCancelAlertDialog(
        context: context,
        message:
            'You are about to permanently delete all these emails. Do you want to continue?',
        cancelLabel: "Cancel");

    if (result.name == "ok") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emptying the trash...'),
          duration: Duration(seconds: 1),
        ),
      );
      await mailService.deleteAllMail(user!.email!);
    }
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
                  imageUrl: user?.imageUrl ?? DEFAULT_AVATAR,
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
              accountName: Text(user?.name ?? "FullName"),
              accountEmail: Text(user?.email ?? "Email"),
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
                        imageUrl: user?.imageUrl ?? DEFAULT_AVATAR,
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
          if (currentCategoryName == 'Trash')
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text(
                    "Items in the trash for more than 30 days will be automatically deleted."),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: _handleHardDelete,
                      child: const Text("Empty the trash now."),
                    ),
                  ],
                ),
              ),
            ),
          ListMailComponent(
              category: currentCategoryName, userEmail: user?.email ?? "Email")
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleComposeMail,
        child: const Icon(Icons.add),
      ),
    );
  }
}
