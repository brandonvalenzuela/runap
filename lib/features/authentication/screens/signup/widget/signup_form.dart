import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:runap/features/authentication/controllers/signup/signup_controller.dart';
import 'package:runap/features/authentication/screens/signup/widget/terms_condition_checkbox.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/constants/text_strings.dart';
import 'package:runap/utils/validators/validation.dart';

class TSIgnupForm extends StatelessWidget {
  const TSIgnupForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignupController>();
    return Form(
      key: controller.signupFormKey,
      child: Column(
        children: [
          /// First & Last Name
          if (controller.shouldShowField('firstName') || controller.shouldShowField('lastName'))
            Column(
              children: [
                Row(
                  children: [
                    if (controller.shouldShowField('firstName'))
                      Expanded(
                        child: TextFormField(
                          controller: controller.firstName,
                          validator: (value) =>
                              TValidator.validateEmptyText('First name', value),
                          expands: false,
                          decoration: const InputDecoration(
                              labelText: TTexts.firstName,
                              prefixIcon: Icon(Iconsax.user),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          ),
                        ),
                      ),
                    if (controller.shouldShowField('firstName') && controller.shouldShowField('lastName'))
                       const SizedBox(width: TSizes.spaceBtwInputFields),
                    if (controller.shouldShowField('lastName'))
                      Expanded(
                        child: TextFormField(
                          controller: controller.lastName,
                          validator: (value) =>
                              TValidator.validateEmptyText('Last name', value),
                          expands: false,
                          decoration: const InputDecoration(
                              labelText: TTexts.lastName,
                              prefixIcon: Icon(Iconsax.user),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          ),
                        ),
                      )
                  ],
                ),
                 const SizedBox(height: TSizes.spaceBtwInputFields),
              ],
            ),
          
          /// USERNAME
          TextFormField(
            controller: controller.username,
            validator: (value) =>
                TValidator.validateEmptyText('Username', value),
            expands: false,
            decoration: const InputDecoration(
                labelText: TTexts.username,
                prefixIcon: Icon(Iconsax.user_edit),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// EMAIL
          TextFormField(
            controller: controller.email,
            validator: (value) => TValidator.validateEmail(value),
            decoration: const InputDecoration(
                labelText: TTexts.email, 
                prefixIcon: Icon(Iconsax.direct),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// PHONE NUMBER
          IntlPhoneField(
            controller: controller.phoneNumber,
            decoration: const InputDecoration(
              labelText: TTexts.phoneNo,
              prefixIcon: Icon(Iconsax.call),
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              isDense: false,
            ),
            initialCountryCode: 'ES',
            showDropdownIcon: true,
            dropdownIconPosition: IconPosition.trailing,
            showCountryFlag: true,
            flagsButtonPadding: EdgeInsets.symmetric(horizontal: 8),
            flagsButtonMargin: EdgeInsets.only(left: 8),
            invalidNumberMessage: 'Enter a valid phone number',
            disableLengthCheck: true,
            onSaved: (phone) {
              if (phone != null) {
                controller.completePhoneNumber = phone.completeNumber;
              }
            },
            validator: (phoneNumber) {
              if (phoneNumber == null) {
                return 'Phone number is required';
              }
              final completeNumber = phoneNumber.completeNumber;
              controller.completePhoneNumber = completeNumber;
              return TValidator.validatePhoneNumber(completeNumber);
            },
            pickerDialogStyle: PickerDialogStyle(
              searchFieldInputDecoration: const InputDecoration(
                labelText: 'Search country',
                prefixIcon: Icon(Icons.search),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// PASSWORD
          Obx(
            () => TextFormField(
              controller: controller.password,
              validator: (value) => TValidator.validatePassword(value),
              obscureText: controller.hidePassword.value,
              decoration: InputDecoration(
                labelText: TTexts.password,
                prefixIcon: const Icon(Iconsax.password_check),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                suffixIcon: IconButton(
                  onPressed: () => controller.hidePassword.value =
                      !controller.hidePassword.value,
                  icon: Icon(controller.hidePassword.value
                      ? Iconsax.eye_slash
                      : Iconsax.eye),
                ),
              ),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          /// TERMS&CONDITIONS CHECKBOX
          const TTermsAndConditionsCheckbox(),

          const SizedBox(height: TSizes.spaceBtwSections),

          /// SIGN UP BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () => controller.signup(),
                child: const Text(TTexts.createAccount)),
          ),
        ],
      ),
    );
  }
}
