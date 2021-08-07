import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phone_authentication/screens/home_screen.dart';

enum MobileVerificationState {
  SHOW_MOBILE_FORM_STATE,
  SHOW_OTP_FORM_STATE,
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  MobileVerificationState currentState =
      MobileVerificationState.SHOW_MOBILE_FORM_STATE;
  final TextEditingController mobileController = new TextEditingController();
  final TextEditingController otpController = new TextEditingController();

  var verificationId;

  bool showLoading = false;

  FirebaseAuth _auth = FirebaseAuth.instance;

  void signInWithPhoneAuthCredential(
      PhoneAuthCredential phoneCredential) async {
    setState(() {
      showLoading = true;
    });
    try {
      final authCredential = await _auth.signInWithCredential(phoneCredential);
      setState(() {
        showLoading = false;
      });

      if (authCredential.user != null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        showLoading = false;
        print(e.message);
      });
    }
  }

  getMobileFormWidget(context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: mobileController,
          decoration: InputDecoration(
            hintText: "Enter Mobile Number",
          ),
        ),
        SizedBox(height: 15),
        TextButton(
          onPressed: () {
            setState(() {
              showLoading = true;
            });

            _auth.verifyPhoneNumber(
              phoneNumber: mobileController.text,
              verificationCompleted: (phoneAuthCredential) async {
                print("verificationCompleted");
                setState(() {
                  showLoading = false;
                });
              },
              verificationFailed: (verificationFailed) async {
                print("verificationFailed");
                setState(() {
                  showLoading = false;
                });
                print(
                    "VERIFICATION FAILED MESSAGE : $verificationFailed.message ");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(verificationFailed.message ?? ""),
                  ),
                );
              },
              codeSent: (verificationId, resendingToken) async {
                print("CodeSent: $verificationId, $resendingToken");
                setState(() {
                  showLoading = false;
                  currentState = MobileVerificationState.SHOW_OTP_FORM_STATE;
                  this.verificationId = verificationId;
                });
              },
              codeAutoRetrievalTimeout: (verificationId) async {},
            );
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blue),
          ),
          child: Text("get Otp", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  getOtpFormWidget(context) {
    return Column(
      children: [
        TextField(
          controller: otpController,
          decoration: InputDecoration(
            hintText: "otp",
          ),
        ),
        SizedBox(height: 15),
        TextButton(
          onPressed: () async {
            print("onOTPPResend: $verificationId");
            PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
              verificationId: verificationId,
              smsCode: otpController.text,
            );
            signInWithPhoneAuthCredential(phoneCredential);
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blue),
          ),
          child: Text("Verify", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          alignment: Alignment.center,
          child: showLoading
              ? CircularProgressIndicator()
              : currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE
                  ? getMobileFormWidget(context)
                  : getOtpFormWidget(context),
        ),
      ),
    );
  }
}
