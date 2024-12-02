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
import 'package:gtv_mail/models/user_label.dart';
import 'package:gtv_mail/services/label_service.dart';
import 'package:gtv_mail/services/template_service.dart';
import 'package:gtv_mail/utils/image_default.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
  late UserLabel? userLabel = UserLabel(id: "", mail: "");
  List<Widget> labelWidgets = [];

  void init() async {
    prefs = await SharedPreferences.getInstance();
    user = await userService.getLoggedUser();
    userLabel = await labelService.getLabels(user!.email!);
    loadLabels().then((widgets) {
      setState(() {
        labelWidgets = widgets;
      });
    });
    if (!kIsWeb) {
      await notificationService.updateBadge();
    }
    final docRef =
        FirebaseFirestore.instance.collection("users").doc(user!.uid);

    docRef.snapshots().listen(
      (event) async {
        user = await userService.getLoggedUser();
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
            AnswerTemplate? template =
                await templateService.getTemplateByEmail(user!.email!);
            if (template != null) {
              if (newMail.from != user!.email) {
                await mailService.sendAutoAnswerMail(template, newMail.from!);
              }
            }
          }
        }
      }
    });

    FirebaseFirestore.instance
        .collection("labels")
        .where('mail', isEqualTo: user!.email)
        .snapshots()
        .listen((querySnapshot) async {
      userLabel = await labelService.getLabels(user!.email!);
      await _loadLabels();
    });

    setState(() {});
  }

  Future<void> _loadLabels() async {
    final labels = await loadLabels();
    setState(() {
      labelWidgets = labels;
    });
  }

  Future<List<Widget>> loadLabels() async {
    if (userLabel != null) {
      if (userLabel!.labels?.isNotEmpty ?? false) {
        return userLabel!.labels!
            .map(
              (label) => ListTile(
                selected: currentCategoryName == label,
                selectedColor: AppTheme.greenColor,
                leading: const Icon(Icons.label),
                title: Text(label),
                onTap: () => _handleOpenLabel(label),
                onLongPress: () => _handleActionLabel(label),
              ),
            )
            .toList();
      }
    }
    return [];
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  void _handleDiscardDraft(Mail draft) async {
    await mailService.deleteMail(draft);
  }

  void _handleComposeMail() async {
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
    currentIndex = index;
    currentCategoryName = option['title'];
    await _loadLabels();
    setState(() {});
    Navigator.pop(context);
  }

  void _handleSetting() async {
    var result = await context.pushNamed('setting');
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

  void _handleOpenLabel(label) async {
    currentIndex = -1;
    currentCategoryName = label;
    await _loadLabels();
    setState(() {});
    Navigator.pop(context);
  }

  void _handleCreateLabel() async {
    final result = await showTextInputDialog(
      context: context,
      textFields: [
        DialogTextField(
            hintText: 'Enter your label name',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return "Please enter your label name";
              }
              return null;
            }),
      ],
      title: 'Create new label',
    );

    if (result != null) {
      String newLabel = result.first;
      if (await labelService.isExistLabel(user!.email!, newLabel)) {
        final result = await showOkAlertDialog(
          context: context,
          title: 'Error',
          message: 'Your label is existed',
        );
      } else {
        if (userLabel == null) {
          String id = const Uuid().v4();
          UserLabel newUserLabel =
              UserLabel(id: id, mail: user!.email!, labels: [newLabel]);
          await labelService.addLabel(newUserLabel);
          userLabel = await labelService.getLabels(user!.email!);
        } else {
          if (userLabel!.labels?.isEmpty ?? true) {
            userLabel!.labels = [newLabel];
          } else {
            userLabel!.labels!.add(newLabel);
          }
          await labelService.updateLabel(userLabel!);
        }

        _loadLabels();
      }
    }
  }

  void _handleEditLabel(String label) async {
    final result = await showTextInputDialog(
      context: context,
      textFields: [
        DialogTextField(
            initialText: label,
            hintText: 'Enter your label name',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return "Please enter your label name";
              }
              return null;
            }),
      ],
      title: 'Update label',
    );

    if (result != null) {
      if (label != result.first) {
        await labelService.editLabelName(user!.email!, label, result.first);
        userLabel = await labelService.getLabels(user!.email!);
        await _loadLabels();
      }
    }
  }

  void _handleActionLabel(String label) async {
    final result = await showModalActionSheet<String>(
      context: context,
      title: 'Update/Delete Label',
      actions: [
        const SheetAction(
          icon: Icons.edit,
          label: 'Update',
          key: 'Update',
        ),
        const SheetAction(
          icon: Icons.delete_forever,
          label: 'Delete',
          key: 'Delete',
        ),
      ],
    );

    if (result == 'Delete') {
      _handleDeleteLabel(label);
    } else if (result == 'Update') {
      _handleEditLabel(label);
    }
  }

  void _handleDeleteLabel(String label) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: 'Confirm',
      message: "Do you want to delete $label label?",
    );

    if (result.name == 'ok') {
      userLabel!.labels!.remove(label);
      await labelService.updateLabel(userLabel!);
      await labelService.removeLabel(user!.email!, label);
      userLabel = await labelService.getLabels(user!.email!);
      await _loadLabels();
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
                  ? const Divider(
                      thickness: 1,
                    )
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

  void _handleSearch() async{
    context.pushNamed('search', pathParameters: {'userMail': user!.email!});
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
              leading: const Icon(Icons.add),
              title: const Text("Create new"),
              onTap: _handleCreateLabel,
            ),
            ...labelWidgets,
            const Divider(
              thickness: 1,
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: _handleSetting,
            ),
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
                      hintText: "Search Mail",
                      suffixIcon: Icon(Icons.search),
                    ),
                    maxLines: 1,
                    onTap: _handleSearch,
                    enabled: true,
                    readOnly: true,
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
                    "Items in the trash here can be permanent deleted."),
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
              category: currentCategoryName,
              userEmail: user?.email ?? "Email",
              userLabel: userLabel)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleComposeMail,
        child: const Icon(Icons.add),
      ),
    );
  }
}
