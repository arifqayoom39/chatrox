import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/providers/user_data_provider.dart';

class PhoneLogin extends StatefulWidget {
  const PhoneLogin({super.key});

  @override
  State<PhoneLogin> createState() => _PhoneLoginState();
}

class _PhoneLoginState extends State<PhoneLogin> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String countryCode = "+91";
  bool showOtpWidget = false;
  String userId = "";

  void handleOtpSubmit() {
    if (_otpFormKey.currentState!.validate()) {
      loginWithOtp(otp: _otpController.text, userId: userId).then((value) {
        if (value) {
          // setting and saving data locally
          Provider.of<UserDataProvider>(context, listen: false)
              .setUserId(userId);
          Provider.of<UserDataProvider>(context, listen: false)
              .setUserPhone(countryCode + _phoneNumberController.text);

          Navigator.pushNamedAndRemoveUntil(
              context, "/update", (route) => false,
              arguments: {"title": "add"});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid verification code. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  void sendOtp() {
    if (_phoneFormKey.currentState!.validate()) {
      createPhoneSession(phone: countryCode + _phoneNumberController.text)
          .then((value) {
        if (value != "login_error") {
          setState(() {
            userId = value;
            showOtpWidget = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to send verification code. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color signalBlue = const Color(0xFF2C6BED); // Exact Signal blue color
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: showOtpWidget 
            ? const Text('Verification', 
                style: TextStyle(
                  color: Colors.black87, 
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ))
            : null,
          centerTitle: true,
          leading: showOtpWidget 
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: () {
                  setState(() {
                    showOtpWidget = false;
                  });
                },
              )
            : null,
        ),
      ),
      body: SafeArea(
        child: showOtpWidget 
            ? OtpVerificationWidget(
                otpFormKey: _otpFormKey,
                otpController: _otpController,
                onSubmit: handleOtpSubmit,
                phoneNumber: countryCode + _phoneNumberController.text,
                signalBlue: signalBlue,
              )
            : PhoneInputWidget(
                phoneFormKey: _phoneFormKey,
                phoneNumberController: _phoneNumberController,
                countryCode: countryCode,
                onCountryCodeChanged: (code) {
                  setState(() {
                    countryCode = code;
                  });
                },
                onSubmit: sendOtp,
                signalBlue: signalBlue,
              ),
      ),
    );
  }
}

class PhoneInputWidget extends StatelessWidget {
  final GlobalKey<FormState> phoneFormKey;
  final TextEditingController phoneNumberController;
  final String countryCode;
  final Function(String) onCountryCodeChanged;
  final VoidCallback onSubmit;
  final Color signalBlue;

  const PhoneInputWidget({
    required this.phoneFormKey,
    required this.phoneNumberController,
    required this.countryCode,
    required this.onCountryCodeChanged,
    required this.onSubmit,
    required this.signalBlue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: signalBlue.withOpacity(0.08),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: signalBlue,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Enter your phone number",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Please confirm your country code and enter your phone number.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Form(
              key: phoneFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          ),
                          child: CountryCodePicker(
                            onChanged: (value) {
                              onCountryCodeChanged(value.dialCode!);
                            },
                            initialSelection: "IN",
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: phoneNumberController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: "Phone number",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              fillColor: Colors.transparent,
                              filled: false,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Phone number is required";
                              }
                              if (value.length != 10) {
                                return "Invalid phone number";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We will send you a verification code",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: signalBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "By continuing, you agree to our Terms of Service and Privacy Policy",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class OtpVerificationWidget extends StatelessWidget {
  final GlobalKey<FormState> otpFormKey;
  final TextEditingController otpController;
  final VoidCallback onSubmit;
  final String phoneNumber;
  final Color signalBlue;

  const OtpVerificationWidget({
    required this.otpFormKey,
    required this.otpController,
    required this.onSubmit,
    required this.phoneNumber,
    required this.signalBlue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: signalBlue.withOpacity(0.08),
              ),
              child: Icon(
                Icons.sms_outlined,
                color: signalBlue,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Verification code",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter the 6-digit code we sent to",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              phoneNumber,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Form(
              key: otpFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 26,
                      letterSpacing: 28,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "• • • • • •",
                      hintStyle: TextStyle(
                        fontSize: 26,
                        letterSpacing: 14,
                        color: Colors.grey.shade400,
                      ),
                      counter: const SizedBox.shrink(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: signalBlue, width: 1.5),
                      ),
                      errorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Verification code is required";
                      }
                      if (value.length != 6) {
                        return "Please enter all 6 digits";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't receive code? ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Resend OTP logic here
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: signalBlue,
                  ),
                  child: const Text(
                    "Resend",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: signalBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
