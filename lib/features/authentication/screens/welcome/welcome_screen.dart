import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/features/authentication/screens/login/login.dart';
import 'package:runap/features/authentication/screens/onboarding/onboarding.dart';
import 'package:runap/utils/constants/sizes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener modo oscuro para posible ajuste de logo
    // final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo (Ajusta la ruta de imagen según tu proyecto)
              // Image(
              //   height: 150,
              //   image: AssetImage(dark ? TImages.darkAppLogo : TImages.lightAppLogo),
              // ),
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // Título y Subtítulo (Ajusta los textos)
              Text(
                "RunAP", // O TTexts.welcomeTitle
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                "Tu compañero de running personalizado", // O TTexts.welcomeSubtitle
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 3),

              // Botón Start
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Navegar a OnBoardingScreen al presionar Start
                  onPressed: () => Get.off(() => const OnBoardingScreen()), 
                  child: const Text("Start"), // O TTexts.start
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Botón/Texto Log in
              TextButton(
                // Navegar a LoginScreen al presionar Log in
                onPressed: () => Get.to(() => const LoginScreen()), 
                child: Text("Already have an account? Log in"), // O TTexts.alreadyHaveAccount
              ),
            ],
          ),
        ),
      ),
    );
  }
} 