import 'dart:async';

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

  late Timer _timer;
  int _remainingTime = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        Navigator.pop(context);
      }
    });
  }

  void _handleVerify() async {
    if (_key.currentState!.validate()) {
      _key.currentState!.save();
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otp!,
      );

      Navigator.pop(context, credential);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter OTP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Form(
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
          const SizedBox(height: 10),
          Text(
            'Time remaining: $_remainingTime seconds',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _handleVerify,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
