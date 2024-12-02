import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/models/attachment.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/file_service.dart';
import 'package:gtv_mail/services/mail_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/mail.dart';
import '../models/user_label.dart';
import '../services/label_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../utils/app_theme.dart';

class DetailMail extends StatefulWidget {
  DetailMail(
      {super.key, required this.id, required this.mail, required this.sender});

  String id;
  Mail mail;
  MyUser sender;

  @override
  State<DetailMail> createState() => _DetailMailState();
}

class _DetailMailState extends State<DetailMail> {
  bool isShow = false;
  Map<String, bool> loadingState = {};
  final QuillController _bodyController = QuillController.basic();
  late UserLabel? userLabel = UserLabel(id: "", mail: "");
  late MyUser? user = MyUser();

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    user = await userService.getLoggedUser();
    userLabel = await labelService.getLabels(user!.email!);
    Mail mail = await mailService.getMailById(widget.id);
    mail.isRead = true;
    await mailService.updateMail(mail);
    await notificationService.updateBadge();
    var empty = Document();
    empty.insert(0, "  ");
    _bodyController.document =
        (widget.mail.body!.isEmpty()) ? empty : widget.mail.body!;
    loadReplies();
  }

  List<QuillController> controllers = [];

  void loadReplies() {
    if (widget.mail.replies?.isNotEmpty ?? false) {
      setState(() {
        controllers = widget.mail.replies!.where((mail) => mail.from == user!.email).map((rep) {
          var controller = QuillController.basic();
          controller.document = rep.body!;
          return controller;
        }).toList();
      });
    }
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleUnread() async {
    Mail mail = await mailService.getMailById(widget.id);
    mail.isRead = false;
    await mailService.updateMail(mail).then(
          (_) => Navigator.pop(context),
        );
  }

  void _handleDelete() async {
    Mail mail = await mailService.getMailById(widget.id);
    if (mail.isDelete) {
      final result = await showOkCancelAlertDialog(
          context: context,
          message:
              'You are about to permanently delete this mail. Do you want to continue?',
          cancelLabel: "Cancel");

      if (result.name == "ok") {
        await mailService.deleteMail(mail).then(
              (_) => Navigator.pop(context, true),
            );
      }
    } else {
      mail.isDelete = true;
      await mailService.updateMail(mail).then(
            (_) => Navigator.pop(context, mail),
          );
    }
  }

  String _handleToCcBcc() {
    final message = <String>[
      if (widget.mail.to?.isNotEmpty ?? false)
        "to ${widget.mail.to!.first.substring(0, 4)}",
      if (widget.mail.cc?.isNotEmpty ?? false)
        "cc: ${widget.mail.cc!.first.substring(0, 4)}",
      // if (widget.mail.bcc?.isNotEmpty ?? false)
      //   "bcc: ${widget.mail.bcc!.first.substring(0, 4)}",
    ];

    return message.join(", ");
  }

  String _listToText(List<String> list) {
    return list.join("\n");
  }

  void _handleReply() async {
    var result = await context.pushNamed('compose',
        queryParameters: {'type': 'reply'}, extra: {'id': widget.id});
  }

  void _handleReplyAll() async{
    var result = await context.pushNamed('compose',
        queryParameters: {'type': 'reply'}, extra: {'id': widget.id});
  }

  void _handleForward() async {
    var result = await context.pushNamed('compose',
        queryParameters: {'type': 'forward'}, extra: {'id': widget.id});
  }

  Future<void> _openFile(Attachment attachment) async {
    setState(() {
      loadingState[attachment.fileName!] = true;
    });

    try {
      if (attachment.url != null) {
        final uri = Uri.parse(attachment.url!);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final tempFilePath = '${tempDir.path}/${attachment.fileName}';

          final file = File(tempFilePath);
          await file.writeAsBytes(response.bodyBytes);

          final result = await OpenFile.open(tempFilePath);

          if (result.type != ResultType.done) {
            showOkAlertDialog(
              context: context,
              title: "Error",
              message: "Could not open the file.",
            );
          }
        }
      }
    } catch (e) {
      showOkAlertDialog(
        context: context,
        title: "Error",
        message: "An error occurred while opening the file.",
      );
    } finally {
      setState(() {
        loadingState[attachment.fileName!] = false;
      });
    }
  }

  void _handleStaredMail() async {
    var mail = widget.mail;
    mail.isStarred = !mail.isStarred;
    await mailService.updateMail(mail);
    setState(() {});
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

      }
    }
  }

  void _handleOptionMenu() async {
    if (userLabel == null || (userLabel!.labels?.isEmpty ?? true)) {
      _handleCreateLabel();
      return;
    }

    final result = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(50, 50, 0, 0),
      items: userLabel!.labels!
          .map(
            (label) {
          final isSelected = userLabel!.labelMail?[label]?.contains(widget.mail.uid) ?? false;
          return PopupMenuItem<String>(
            value: label,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                if (isSelected) const Icon(Icons.check, color: Colors.green),
              ],
            ),
          );
        },
      )
          .toList(),
      elevation: 8.0,
    );

    if (result != null) {
      final isCurrentlyAssigned = userLabel!.labelMail?[result]?.contains(widget.mail.uid) ?? false;

      try {
        if (isCurrentlyAssigned) {
          await labelService.removeLabelFromMail(user!.email!, result, widget.mail.uid!);
          userLabel!.labelMail?[result]?.remove(widget.mail.uid);
          if (userLabel!.labelMail?[result]?.isEmpty ?? false) {
            userLabel!.labelMail?.remove(result);
          }
        } else {
          await labelService.assignLabelToMail(user!.email!, result, widget.mail.uid!);
          if (userLabel!.labelMail?.containsKey(result) == false) {
            userLabel!.labelMail?[result] = [];
          }
          userLabel!.labelMail?[result]?.add(widget.mail.uid!);
        }

        setState(() {});
      } catch (e) {
        print('Error updating label: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: _handleBack, icon: const Icon(Icons.arrow_back_ios)),
        actions: [
          // IconButton(
          //     onPressed: () {}, icon: const Icon(Icons.archive_outlined)),
          IconButton(
              onPressed: _handleDelete,
              icon: const Icon(Icons.delete_outline_outlined)),
          IconButton(
              onPressed: _handleUnread, icon: const Icon(Icons.mail_outline)),
          IconButton(
              onPressed: _handleOptionMenu, icon: const Icon(Icons.more_horiz))
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        widget.mail.subject!,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      trailing: IconButton(
                          onPressed: _handleStaredMail,
                          icon: widget.mail.isStarred
                              ? const Icon(
                                  Icons.star,
                                  color: AppTheme.yellowColor,
                                )
                              : const Icon(Icons.star_border_outlined)),
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.blueColor,
                        child: CachedNetworkImage(
                          imageUrl: widget.sender.imageUrl!,
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
                      title: Text(widget.sender.name!),
                      subtitle: Row(
                        children: [
                          Text(
                            _handleToCcBcc(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                isShow = !isShow;
                              });
                            },
                            child: Icon(isShow
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down),
                          )
                        ],
                      ),
                    ),
                    if (isShow)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Theme.of(context).primaryColor,
                          border: const Border(
                            bottom: BorderSide(color: Colors.black),
                            right: BorderSide(color: Colors.black),
                            top: BorderSide(color: Colors.black),
                            left: BorderSide(color: Colors.black),
                          ),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Text("From"),
                              title: Text(widget.mail.from!),
                            ),
                            if (widget.mail.to?.isNotEmpty ?? false)
                              ListTile(
                                leading: const Text("To"),
                                title: Text(_listToText(widget.mail.to!)),
                              ),
                            if (widget.mail.cc?.isNotEmpty ?? false)
                              ListTile(
                                leading: const Text("Cc"),
                                title: Text(_listToText(widget.mail.cc!)),
                              ),
                            ListTile(
                              leading: const Text("Date"),
                              title: Text(
                                DateFormat('h:mm a, dd MMMM, yyyy')
                                    .format(widget.mail.sentDate!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Flexible(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 600,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Theme.of(context).primaryColor,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: QuillEditor.basic(
                            focusNode: FocusNode(canRequestFocus: false),
                            controller: _bodyController,
                            configurations: QuillEditorConfigurations(
                              showCursor: false,
                              placeholder: "Loading content...",
                              checkBoxReadOnly: true,
                              enableInteractiveSelection: false,
                              onLaunchUrl: (url) async {
                                await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if ((widget.mail.replies?.isNotEmpty ?? false) && controllers.isNotEmpty)
                      Flexible(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            height: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context).primaryColor,
                            ),
                            child: ListView.separated(
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                thickness: 2,
                                color: Colors.black,
                                endIndent: 100,
                                indent: 100,
                              ),
                              itemCount: controllers.length,
                              itemBuilder: (context, index) {
                                final controller = controllers[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Container(
                                    // height: 580,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: QuillEditor.basic(
                                      focusNode:
                                          FocusNode(canRequestFocus: false),
                                      controller: controller,
                                      configurations: QuillEditorConfigurations(
                                        showCursor: false,
                                        placeholder: "Body",
                                        checkBoxReadOnly: true,
                                        enableInteractiveSelection: false,
                                        onLaunchUrl: (url) async {
                                          await launchUrl(
                                            Uri.parse(url),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    if (widget.mail.attachments?.isNotEmpty ?? false)
                      Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    widget.mail.attachments!.map((attachment) {
                                  return GestureDetector(
                                    onTap: () => _openFile(attachment),
                                    child: SingleChildScrollView(
                                      child: SizedBox(
                                        height: 100,
                                        width: 100,
                                        child: Card(
                                          elevation: 5.0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                if (loadingState[
                                                        attachment.fileName!] ==
                                                    true)
                                                  SizedBox(
                                                      width: 42,
                                                      child: Lottie.asset(
                                                        'assets/lottiefiles/circle_loading.json',
                                                        fit: BoxFit.fill,
                                                      ))
                                                else
                                                  Image.asset(
                                                    "assets/images/${attachment.extension}.png",
                                                    height: 42,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        Image.asset(
                                                      "assets/images/unknown.png",
                                                      height: 42,
                                                    ),
                                                  ),
                                                Text(
                                                  attachment.fileName!,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(fileService.formatFileSize(
                                                    attachment.size!)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          )),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            Expanded(
                                child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, bottom: 16),
                              child: ElevatedButton(
                                  onPressed: _handleReply,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.turn_left),
                                      Text("Reply")
                                    ],
                                  )),
                            )),
                            if (widget.mail.cc?.isNotEmpty ?? false)
                              Expanded(
                                  child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8, right: 8, bottom: 16),
                                child: ElevatedButton(
                                    onPressed: _handleReplyAll,
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.reply_all),
                                        Text("Reply all")
                                      ],
                                    )),
                              )),
                            Expanded(
                                child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, bottom: 16),
                              child: ElevatedButton(
                                  onPressed: _handleForward,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.turn_right),
                                      Text("Forward")
                                    ],
                                  )),
                            )),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
