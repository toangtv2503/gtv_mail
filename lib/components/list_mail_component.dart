import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mail.dart';
import '../services/mail_service.dart';
import '../utils/app_theme.dart';
import '../utils/image_default.dart';

class ListMailComponent extends StatefulWidget {
  ListMailComponent(
      {super.key, required this.category, required this.userEmail});
  String category;
  String userEmail;

  @override
  State<ListMailComponent> createState() => _ListMailComponentState();
}

class _ListMailComponentState extends State<ListMailComponent>
    with SingleTickerProviderStateMixin {
  late final controller = SlidableController(this);
  late SharedPreferences prefs;
  late Map<String, dynamic> displayMode = {
    'mode': 'Basic',
    'isShowAvatar': false,
    'isShowAttachment': false,
  };
  Timer? _displayModeListener;
  late Map<String, MyUser> userCache = Map();

  void init() async {
    prefs = await SharedPreferences.getInstance();
    userCache = await userService.fetchSenderCached();

    displayMode = jsonDecode(prefs.getString('default_display_mode') ??
        jsonEncode({
          'mode': 'Basic',
          'isShowAvatar': true,
          'isShowAttachment': false,
        }));

    await _fetchDisplayMode();
    _listenDisplayModeChange();
    setState(() {});
  }

  @override
  void dispose() {
    _displayModeListener?.cancel();
    super.dispose();
  }

  Future<void> _fetchDisplayMode() async {
    final defaultDisplayMode = jsonEncode({
      'mode': 'Basic',
      'isShowAvatar': true,
      'isShowAttachment': false,
    });
    displayMode = jsonDecode(prefs.getString('default_display_mode') ?? defaultDisplayMode);
    if (mounted) {
      setState(() {
        // Update state
      });
    }

  }

  void _listenDisplayModeChange() {
    _displayModeListener = Timer.periodic(const Duration(seconds: 5), (_) async {
      final defaultDisplayMode = jsonEncode({
        'mode': 'Basic',
        'isShowAvatar': true,
        'isShowAttachment': false,
      });
      final newDisplayMode = jsonDecode(prefs.getString('default_display_mode') ?? defaultDisplayMode);

      if (!mapEquals(newDisplayMode, displayMode)) {
        displayMode = newDisplayMode;
        setState(() {});
      }
    });
  }

  void _handleUndoDelete(Mail mailDelete) async {
    mailDelete.isDelete = false;
    await mailService.updateMail(mailDelete);
  }

  void listenChange() {
    final id = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection("users").doc(id);
    docRef.snapshots().listen(
      (event) {
        init();
      },
      onError: (error) => print("Listen failed: $error"),
    );
  }

  @override
  void initState() {
    init();
    listenChange();
    super.initState();
  }

  void _handleDetailMail(Mail mail, MyUser senderInfo) async {
    if (widget.category == 'Drafts') {
      var result = await context.pushNamed('compose',
          queryParameters: {'type': 'draft'}, extra: {'id': mail.uid!});
    } else {
      var result = await context.pushNamed('detail',
          pathParameters: {'id': mail.uid!},
          extra: {'mail': mail, 'senderInfo': senderInfo});

      if (result.runtimeType == Mail) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('1 item has been moved to the trash.'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
                label: 'Undo',
                onPressed: () => _handleUndoDelete(result as Mail)),
          ),
        );
      }
    }
  }

  void _handleStaredMail(Mail mail) async {
    mail.isStarred = !mail.isStarred;
    await mailService.updateMail(mail);
  }

  Stream<List<Mail>> streamMailByCategory(String userEmail, String category) {
    switch (category) {
      case 'All inboxes':
        return mailService.getAllInboxes(userEmail);
      case 'Primary':
        return mailService.getPrimaryMails(userEmail);
      case 'Social':
        return mailService.getSocialPromotionUpdateMails(userEmail, 'social');
      case 'Promotion':
        return mailService.getSocialPromotionUpdateMails(
            userEmail, 'promotion');
      case 'Update':
        return mailService.getSocialPromotionUpdateMails(userEmail, 'update');
      case 'Starred':
        return mailService.getStarredMails(userEmail);
      case 'Snoozed':
        return mailService.getHiddenMails(userEmail);
      case 'Important':
        return mailService.getImportantMails(userEmail);
      case 'Sent':
        return mailService.getSentMails(userEmail);
      case 'Drafts':
        return mailService.getDraftMails(userEmail);
      case 'All mail':
        return mailService.getAllMails(userEmail);
      case 'Spam':
        return mailService.getSpamMails(userEmail);
      default:
        return Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Mail>>(
      stream: streamMailByCategory(widget.userEmail, widget.category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
              child: Center(
            child: SizedBox(
              width: 50,
              child: Lottie.asset(
                'assets/lottiefiles/circle_loading.json',
                fit: BoxFit.fill,
              ),
            ),
          ));
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Text(
            'Error: ${snapshot.error}',
            style: Theme.of(context).textTheme.displaySmall,
          )));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(),
                SizedBox(
                  width: 400,
                  child: Lottie.asset(
                    'assets/lottiefiles/empty_animation.json',
                    fit: BoxFit.fill,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "No thing in ${widget.category}",
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        } else {
          final List<Mail> mails = snapshot.data!;

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Column(
                  children: [
                    Slidable(
                      key: ValueKey(index),
                      child: ListTile(
                        style: ListTileStyle.list,
                        onTap: () => _handleDetailMail(
                            mails[index], userCache[mails[index].from]!),
                        leading: displayMode['isShowAvatar'] ? CircleAvatar(
                          backgroundColor: AppTheme.blueColor,
                          child: CachedNetworkImage(
                            imageUrl: userCache[mails[index].from]?.imageUrl! ??
                                DEFAULT_AVATAR,
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
                        ) : null,
                        title: Text(
                          userCache[mails[index].from]?.name! ?? 'Sender',
                          style: (mails[index].isRead
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.titleLarge)
                              ?.merge(TextStyle(
                                  color: mails[index].isRead
                                      ? Colors.grey
                                      : Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mails[index].subject!,
                              style: (mails[index].isRead
                                      ? Theme.of(context).textTheme.titleSmall
                                      : Theme.of(context).textTheme.titleMedium)
                                  ?.merge(TextStyle(
                                      color: mails[index].isRead
                                          ? Colors.grey
                                          : Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if(displayMode['isShowAttachment']) SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: mails[index].attachments?.map((att) {
                                      int colorIndex = mails[index]
                                          .attachments!
                                          .indexOf(att);
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Chip(
                                          backgroundColor: [
                                            AppTheme.redColor,
                                            AppTheme.greenColor,
                                            AppTheme.yellowColor,
                                            AppTheme.blueColor
                                          ][colorIndex % 4],
                                          avatar: Image.asset(
                                            "assets/images/${att.extension}.png",
                                            height: 20,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Image.asset(
                                              "assets/images/unknown.png",
                                              height: 20,
                                            ),
                                          ),
                                          label: Text(att.extension!),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }).toList() ??
                                    [],
                              ),
                            )
                          ],
                        ),
                        trailing: SizedBox(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(mails[index].sentDate!),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              IconButton(
                                onPressed: () =>
                                    _handleStaredMail(mails[index]),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: mails[index].isStarred
                                    ? const Icon(
                                        Icons.star,
                                        color: AppTheme.yellowColor,
                                      )
                                    : const Icon(Icons.star_border_outlined),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (index < mails.length - 1)
                      const Divider(
                        endIndent: 80,
                        indent: 70,
                        color: Colors.grey,
                      ),
                  ],
                );
              },
              childCount: mails.length,
            ),
          );
        }
      },
    );
  }
}
