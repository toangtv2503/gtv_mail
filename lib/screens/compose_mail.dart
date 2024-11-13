import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComposeMail extends StatefulWidget {
  ComposeMail({super.key, this.isDraft = true, this.draftId});
  bool? isDraft;
  String? draftId;

  @override
  State<ComposeMail> createState() => _ComposeMailState();
}

class _ComposeMailState extends State<ComposeMail> {
  final QuillController _controller = QuillController.basic();
  late SharedPreferences prefs;
  final TextEditingController _fromController = TextEditingController();

  void init() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _fromController.text = prefs.getString('email') ?? '';
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fromController.dispose();
    super.dispose();
  }

  void _handleAttachment() {

  }

  void _handleSend() {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close)),
        actions: [
          IconButton(onPressed: _handleAttachment, icon: const Icon(Icons.attachment)),
          IconButton(onPressed: _handleSend, icon: const Icon(Icons.send_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                prefixText: "From ",
              ),
              controller: _fromController,
            ),
            const SizedBox(
              height: 8,
            ),
            TextFormField(
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(), hintText: "Subject"),
            ),
            const SizedBox(
              height: 8,
            ),
            QuillSimpleToolbar(
              controller: _controller,
              configurations: const QuillSimpleToolbarConfigurations(
                  multiRowsDisplay: false,
                  showSmallButton: true,
                  showLineHeightButton: true,
                  showAlignmentButtons: true,
                  showDirection: true,
                  decoration: BoxDecoration()),
            ),
            const SizedBox(
              height: 8,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).primaryColor,
                ),
                padding: const EdgeInsets.all(8),
                child: QuillEditor.basic(
                  controller: _controller,
                  configurations: const QuillEditorConfigurations(
                    placeholder: "Body",
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
