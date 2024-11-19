import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mail.dart';

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
  final QuillController _bodyController = QuillController.basic();

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() {
    _bodyController.document = widget.mail.body!;
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleIsRead() {}

  void _handleDelete() {}

  String _handleToCcBcc() {
    final message = <String>[
      if (widget.mail.to?.isNotEmpty ?? false)
        "to ${widget.mail.to!.first.substring(0, 4)}",
      if (widget.mail.cc?.isNotEmpty ?? false)
        "cc: ${widget.mail.cc!.first.substring(0, 4)}",
      if (widget.mail.bcc?.isNotEmpty ?? false)
        "bcc: ${widget.mail.bcc!.first.substring(0, 4)}",
    ];

    return message.join(", ");
  }

  String _listToText(List<String> list) {
    return list.join("\n");
  }

  void _handleReply() {}

  void _handleReplyAll() {}

  void _handleForward() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: _handleBack, icon: const Icon(Icons.arrow_back_ios)),
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.archive_outlined)),
          IconButton(
              onPressed: _handleDelete,
              icon: const Icon(Icons.delete_outline_outlined)),
          IconButton(
              onPressed: _handleIsRead, icon: const Icon(Icons.mail_outline)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(
              widget.mail.subject!,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            trailing: IconButton(
                onPressed: () {}, icon: const Icon(Icons.star_border)),
          ),
          ListTile(
            leading: CircleAvatar(
              child: CachedNetworkImage(
                imageUrl: widget.sender.imageUrl!,
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
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Text("From"),
                    title: Text(widget.mail.from!),
                  ),
                  if (widget.mail.to?.isNotEmpty ?? false)
                    ListTile(
                        leading: const Text("To"),
                        title: Text(_listToText(widget.mail.to!))),
                  if (widget.mail.cc?.isNotEmpty ?? false)
                    ListTile(
                        leading: const Text("Cc"),
                        title: Text(_listToText(widget.mail.cc!))),
                  if (widget.mail.bcc?.isNotEmpty ?? false)
                    ListTile(
                        leading: const Text("Bcc"),
                        title: Text(_listToText(widget.mail.bcc!))),
                  ListTile(
                      leading: const Text("Date"),
                      title: Text(DateFormat('h:mm a, dd MMMM, yyyy')
                          .format(widget.mail.sentDate!))),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).primaryColor,
                ),
                padding: const EdgeInsets.all(8),
                child: QuillEditor.basic(
                  controller: _bodyController,
                  configurations: QuillEditorConfigurations(
                    placeholder: "Body",
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding:
                        const EdgeInsets.only(left: 8, right: 8, bottom: 16),
                    child: ElevatedButton(
                        onPressed: _handleReply,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.turn_left), Text("Reply")],
                        )),
                  )),
                  if (widget.mail.cc?.isNotEmpty ?? false)
                    Expanded(
                        child: Padding(
                      padding:
                          const EdgeInsets.only(left: 8, right: 8, bottom: 16),
                      child: ElevatedButton(
                          onPressed: _handleReplyAll,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.reply_all),
                              Text("Reply all")
                            ],
                          )),
                    )),
                  Expanded(
                      child: Padding(
                    padding:
                        const EdgeInsets.only(left: 8, right: 8, bottom: 16),
                    child: ElevatedButton(
                        onPressed: _handleForward,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.turn_right), Text("Forward")],
                        )),
                  )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
