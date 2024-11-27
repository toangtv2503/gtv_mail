import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:lottie/lottie.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_theme.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  var _keyEmail = GlobalKey<FormState>();
  var _keyOTP = GlobalKey<FormState>();
  var _keyResetPassword = GlobalKey<FormState>();

  String? _email;
  late String _phoneNumber = '+84*********';
  String? password;
  String? confirmPassword;
  String? _otp;
  int _activeStep = 0;
  int _remainingTime = 60;
  late Timer _timer;
  late SharedPreferences prefs;
  late String vId = "";

  var _controller = TextEditingController();

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
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
      }
    });
  }

  void _handleEmail() async {
    if (_keyEmail.currentState?.validate() ?? false) {
      bool isEmailExisted = await userService.checkEmailExisted(_email!);

      if (!isEmailExisted) {
        showOkAlertDialog(context: context, title: "Your email does not exist");
      } else {
        MyUser user = await userService.getUserByEmail(_email!);
        setState(() {
          _controller = TextEditingController();
          _phoneNumber = user.phone!;
          _remainingTime = 60;
          _startCountdown();
          _activeStep = 1;
        });

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: _phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (_) {},
          verificationFailed: (FirebaseAuthException e) {
            showOkAlertDialog(
              context: context,
              title: "Verification Failed",
              message: "An error occurred. Please try again.",
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            vId = verificationId;
          },
          codeAutoRetrievalTimeout: (_) {},
        );
      }
    }
  }

  void _handleOTP() async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: vId,
      smsCode: _otp!,
    );

    try {
      var result = await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() {
        _timer.cancel();
        _activeStep = 2;
      });
    } catch (e) {
      showOkAlertDialog(
        context: context,
        title: "Verification Failed",
        message: "The verification OTP is invalid",
      );
    }
  }

  void _resendOTP() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (FirebaseAuthException e) {
        showOkAlertDialog(
          context: context,
          title: "Verification Failed",
          message: "An error occurred. Please try again.",
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        vId = verificationId;
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    setState(() {
      _remainingTime = 60;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('OTP code has been resent.'),
      backgroundColor: AppTheme.greenColor,
    ));
  }

  void _handleChangeEmail() async {
    setState(() {
      _timer.cancel();
      _activeStep = 0;
    });
  }

  void _handleResetPassword() async {
    if (_keyResetPassword.currentState?.validate() ?? false) {
      MyUser user = await userService.getUserByEmail(_email!);
      user.password = BCrypt.hashpw(password!, BCrypt.gensalt());
      await userService.updateUser(user);

      setState(() {
        _activeStep = 4;
        Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context),);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(onPressed: () {
          FirebaseAuth.instance.signOut();
          Navigator.pop(context);
        }, icon: const Icon(Icons.arrow_back)),
      ),
      body: SingleChildScrollView(
          child: Column(
        children: [
          EasyStepper(
            activeStep: _activeStep,
            showLoadingAnimation: true,
            stepRadius: 24,
            showStepBorder: false,
            enableStepTapping: false,
            unreachedStepBackgroundColor: AppTheme.blueColor,
            unreachedStepIconColor: AppTheme.whiteColor,
            unreachedStepTextColor: AppTheme.blueColor,
            activeStepBackgroundColor: AppTheme.yellowColor,
            activeStepIconColor: AppTheme.whiteColor,
            activeStepTextColor: AppTheme.yellowColor,
            finishedStepBackgroundColor: AppTheme.greenColor,
            finishedStepIconColor: AppTheme.whiteColor,
            finishedStepTextColor: AppTheme.greenColor,
            steps: const [
              EasyStep(
                title: "Step-1",
                icon: Icon(Icons.mail_outline),
              ),
              EasyStep(
                  title: "Step-2", icon: Icon(Icons.password), topTitle: true),
              EasyStep(title: "Step-3", icon: Icon(Icons.wifi_protected_setup)),
              EasyStep(title: "Done", icon: Icon(Icons.check), topTitle: true),
            ],
            onStepReached: (index) {
              _controller = TextEditingController();
              setState(() => _activeStep = index);
              if (_activeStep == 1) {
                _startCountdown();
              }
            },
          ),
          if (_activeStep == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _keyEmail,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recover password",
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Email",
                          hintText: "Enter your email"),
                      autofocus: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your email';
                        } else if (value!.length > 256) {
                          return 'Your email so long';
                        } else if (!EmailValidator.validate(value)) {
                          return "Your email is invalid";
                        }
                        _email = value;
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    ElevatedButton(
                        onPressed: _handleEmail,
                        child: const Text("Recover password"))
                  ],
                ),
              ),
            ),
          if (_activeStep == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                Text(
                  "Check your OTP",
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(
                  height: 24,
                ),
                Text(
                  "We've sent the OTP code to ${_phoneNumber.replaceRange(3, _phoneNumber.length - 4, "*****")}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(
                  height: 24,
                ),
                Form(
                  key: _keyOTP,
                  child: PinCodeTextField(
                    autoFocus: true,
                    controller: _controller,
                    appContext: context,
                    length: 6,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(5),
                      fieldHeight: 50,
                      fieldWidth: 50,
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
                      _otp = value;
                      return null;
                    },
                    onSaved: (value) => _otp = value,
                    keyboardType: TextInputType.number,
                  ),
                ),
                Text(
                  'Time remaining: $_remainingTime seconds',
                ),
                const SizedBox(
                  height: 8,
                ),
                if (_remainingTime == 0)
                  TextButton(onPressed: _resendOTP, child: const Text("Resend OTP")),
                ElevatedButton(
                    onPressed: _handleOTP, child: const Text("Verify")),
                const SizedBox(
                  height: 24,
                ),
                ElevatedButton(
                  onPressed: _handleChangeEmail,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor),
                  child: Text(
                    "Cancel",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              ]),
            ),
          if (_activeStep == 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _keyResetPassword,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reset password",
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your password';
                        } else if (value!.length > 256) {
                          return 'Your password so long';
                        }
                        password = value;
                        return null;
                      },
                      onSaved: (value) => password = value,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.check),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please confirm your password';
                        } else if (value != password) {
                          return 'Your password does not matched';
                        }
                        return null;
                      },
                      onSaved: (value) => confirmPassword = value,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    ElevatedButton(
                        onPressed: _handleResetPassword,
                        child: const Text("Reset password"))
                  ],
                ),
              ),
            ),
          if (_activeStep >= 3)
            Column(
              children: [
                Center(
                  child: Lottie.asset(
                    'assets/lottiefiles/done_animation.json',
                    fit: BoxFit.fill,
                  ),
                ),
                Text("Congratulations!", style: Theme.of(context).textTheme.displayMedium)
              ],
            )
        ],
      )),
    );
  }
}
