import 'package:flutter/material.dart';
import 'package:runap/common/styles/spacing_styles.dart';
import 'package:runap/common/widgets/login_signup/form_divider.dart';
import 'package:runap/common/widgets/login_signup/social_buttons.dart';
import 'package:runap/features/authentication/screens/login/widgets/login_form.dart';
import 'package:runap/features/authentication/screens/login/widgets/login_header.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/constants/text_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              /// Logo, Title & Sub-Title con animación
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: const TLoginHeader(),
                ),
              ),

              /// Form con animación
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: const TLoginForm(),
                ),
              ),

              /// Divider con animación
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: TFormDevider(dividerText: TTexts.orSignInWith),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Social Buttons con animación
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: const TSocialButtons(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
