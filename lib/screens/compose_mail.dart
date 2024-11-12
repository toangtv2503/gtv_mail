import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';

class ComposeMail extends StatefulWidget {
  ComposeMail({super.key, this.isDraft = true, this.draftId, required this.from});
  bool? isDraft;
  String? draftId;
  String? from;

  @override
  State<ComposeMail> createState() => _ComposeMailState();
}

class _ComposeMailState extends State<ComposeMail> {
  final QuillController _controller = QuillController.basic();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              GoRouter.of(context).goNamed('home');
            },
            icon: const Icon(Icons.close)),
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
              initialValue: widget.from,
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
