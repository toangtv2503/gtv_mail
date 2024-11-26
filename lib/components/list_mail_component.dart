import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

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

  late Map<String, MyUser> userCache = Map();

  late List<Mail> drafts;

  void init() async {
    userCache = await userService.fetchSenderCached();
    drafts = await mailService.getDrafts(widget.userEmail);

    listenDraft();
    setState(() {});
  }

  void listenDraft() {
    FirebaseFirestore.instance
        .collection("mails")
        .where("from", isEqualTo: widget.userEmail)
        .where('isDraft', isEqualTo: true)
        .snapshots()
        .listen((querySnapshot) async {
      for (var change in querySnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data();
          if (data == null) continue;

          var newMail = Mail.fromJson(data);

          DateTime sentDate = newMail.sentDate!;

          if (sentDate.isBefore(DateTime.now().subtract(const Duration(seconds: 60)))) {
            continue;
          }

          drafts = await mailService.getDrafts(widget.userEmail);
          setState(() {});
        }
      }
    });
  }

  void _handleUndoDelete(Mail mailDelete)async {
    mailDelete.isDelete = false;
    await mailService.updateMail(mailDelete);
  }

  @override
  void initState() {
    init();
    final id = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection("users").doc(id);
    docRef.snapshots().listen(
      (event) {
        init();
      },
      onError: (error) => print("Listen failed: $error"),
    );
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
            action: SnackBarAction(label: 'Undo', onPressed: () => _handleUndoDelete(result as Mail)),
          ),
        );
      }

    }

  }

  void _handleStaredMail(Mail mail) async {
    mail.isStarred = !mail.isStarred;
    await mailService.updateMail(mail);
  }

  List<Mail> getMails(AsyncSnapshot<List<Mail>> snapshot){
    switch (widget.category) {
      case 'All inboxes':
        return [...snapshot.data!
        .where((mail) => !mail.isReplyMail  && !mail.isDelete)
        , ...drafts.toList().reversed];
      case 'Primary':
        return snapshot.data!
            .where((mail) => mailService.isPrimaryMail(mail) && !mail.isReplyMail && !mail.isDraft && !mail.isDelete)
            .toList();
      case 'Social':
        return snapshot.data!
            .where((mail) => mailService.isSocialMail(mail) && !mail.isReplyMail && !mail.isDraft && !mail.isDelete)
            .toList();
      case 'Promotion':
        return snapshot.data!
            .where((mail) => mailService.isPromotionalMail(mail) && !mail.isReplyMail && !mail.isDraft && !mail.isDelete)
            .toList();
      case 'Update':
        return snapshot.data!
            .where((mail) => mailService.isUpdateMail(mail) && !mail.isReplyMail && !mail.isDraft && !mail.isDelete)
            .toList();
      case 'Starred':
        return snapshot.data!
            .where((mail) => mailService.isPrimaryMail(mail) && !mail.isReplyMail && !mail.isDraft && mail.isStarred&& !mail.isDelete)
            .toList();
      case 'Drafts':
        return drafts.toList().reversed.toList();
      case 'Snoozed':
        return [];
      case 'Important':
        return [];
      case 'Sent':
        return snapshot.data!
            .where((mail) => mail.from == widget.userEmail && !mail.isReplyMail && !mail.isDraft && !mail.isDelete)
            .toList();
      case 'Scheduled':
        return [];
      case 'Trash':
        return snapshot.data!
            .where((mail) => mail.isDelete)
            .toList();
      default:
        return [];
    }

  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Mail>>(
      stream: mailService.streamMailsByUser(widget.userEmail),
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

        } else if (!snapshot.hasData || snapshot.data!.isEmpty || getMails(snapshot).isEmpty) {
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
          final mails = getMails(snapshot);

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Slidable(
                  key: ValueKey(index),
                  startActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    // dismissible: DismissiblePane(onDismissed: () {}),
                    children: [
                      SlidableAction(
                        onPressed: (context) {},
                        backgroundColor: Color(0xFFFE4A49),
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                      SlidableAction(
                        onPressed: (context) {},
                        backgroundColor: Color(0xFF21B7CA),
                        foregroundColor: Colors.white,
                        icon: Icons.share,
                        label: 'Share',
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        flex: 2,
                        onPressed: (_) => controller.openEndActionPane(),
                        backgroundColor: const Color(0xFF7BC043),
                        foregroundColor: Colors.white,
                        icon: Icons.archive,
                        label: 'Archive',
                      ),
                      SlidableAction(
                        onPressed: (_) => controller.close(),
                        backgroundColor: const Color(0xFF0392CF),
                        foregroundColor: Colors.white,
                        icon: Icons.save,
                        label: 'Save',
                      ),
                    ],
                  ),
                  child: ListTile(
                    style: ListTileStyle.list,
                    onTap: () => _handleDetailMail(
                        mails[index], userCache[mails[index].from]!),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.blueColor,
                      child: CachedNetworkImage(
                        imageUrl: userCache[mails[index].from]?.imageUrl! ?? DEFAULT_AVATAR,
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
                    title: Text(
                      userCache[mails[index].from]?.name! ?? 'Sender',
                      style: (mails[index].isRead ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.titleLarge)
                          ?.merge(TextStyle(color: mails[index].isRead ? Colors.grey : Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      mails[index].subject!,
                      style: (mails[index].isRead ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.titleMedium)
                          ?.merge(TextStyle(color: mails[index].isRead ? Colors.grey : Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                            onPressed: () => _handleStaredMail(mails[index]),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: mails[index].isStarred ? const Icon(Icons.star, color: AppTheme.yellowColor,) : const Icon(Icons.star_border_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
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
