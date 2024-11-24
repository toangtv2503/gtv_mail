import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/components/register_form.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

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

  void init() async {
    userCache = await userService.fetchSenderCached();
    setState(() {});
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

  void _handleDetailMail(Mail mail, MyUser senderInfo) {
    if (widget.category == 'Drafts') {
      context.pushNamed('compose', queryParameters: {'draft': mail.uid});
    } else {
      context.pushNamed('detail',
          pathParameters: {'id': mail.uid!},
          extra: {'mail': mail, 'senderInfo': senderInfo});
    }

  }

  List<Mail> getMails(AsyncSnapshot<List<Mail>> snapshot){
    if (widget.category == 'Primary') {
      return snapshot.data!
          .where((mail) => mailService.isPrimaryMail(mail) && !mail.isReplyMail)
          .toList();
    }
    if (widget.category == 'Drafts') {
      return snapshot.data!
          .where((mail) => mail.isDraft)
          .toList();
    }
    return [];
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
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      mails[index].subject!,
                      style: Theme.of(context).textTheme.titleSmall,
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
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.star_border_outlined,
                            ),
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
