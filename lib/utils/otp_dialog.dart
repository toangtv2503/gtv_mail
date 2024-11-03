import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gtv_mail/utils/app_theme.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpDialog extends StatefulWidget {
  final String verificationId;
  const OtpDialog({super.key, required this.verificationId});

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final _key = GlobalKey<FormState>();
  String? _otp;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter OTP'),
      content: Form(
        key: _key,
        child: PinCodeTextField(
          focusNode: _focusNode,
          autoFocus: true,
          controller: _controller,
          appContext: context,
          length: 6,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(5),
            fieldHeight: 40,
            fieldWidth: 30,
            activeColor: AppTheme.blueColor,
            inactiveColor: AppTheme.greyColor,
            selectedColor: AppTheme.greenColor,
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return "Please enter your otp";
            } else if (value!.length < 6) {
              return "OTP must have 6 digits";
            }
            return null;
          },
          onSaved: (value) => _otp = value,
          keyboardType: TextInputType.number,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_key.currentState!.validate()) {
              _key.currentState!.save();
              PhoneAuthCredential credential = PhoneAuthProvider.credential(
                verificationId: widget.verificationId,
                smsCode: _otp!,
              );

              Navigator.pop(context, credential);
            }
          },
          child: Text('Verify'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
