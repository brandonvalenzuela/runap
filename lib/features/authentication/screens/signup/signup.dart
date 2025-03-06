import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/common/widgets/login_signup/form_divider.dart';
import 'package:runap/common/widgets/login_signup/social_buttons.dart';
import 'package:runap/features/authentication/screens/signup/widget/signup_form.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/constants/text_strings.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE
              Text(TTexts.signupTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// FORM
              const TSIgnupForm(),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// DIVIDER
              TFormDevider(dividerText: TTexts.orSignUpWith.capitalize!),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// SOCIAL BUTTONS
              const TSocialButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
