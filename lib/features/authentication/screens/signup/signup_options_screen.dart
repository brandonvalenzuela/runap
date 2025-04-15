import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/features/authentication/screens/signup/signup.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/constants/text_strings.dart';

class SignupOptionsScreen extends StatelessWidget {
  const SignupOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Podrías usar un controlador específico si necesitas manejar lógica de social sign-in aquí
    // final controller = Get.put(LoginController()); // O un SignupOptionsController

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false), // Sin botón de atrás por defecto
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.spaceBtwSections),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen Superior
              const Image(
                // Usa la imagen apropiada de tus assets
                image: AssetImage(TImages.staticSuccessIllustration), 
                width: double.infinity, // Ajusta tamaño si es necesario
                height: 150,
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              // Título
              Text(
                TTexts.signupTitle, // "Create your account"
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                "Register your account to save your settings.", // Placeholder para TTexts.signupSubTitle
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // Botón Continuar con Google
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  // Placeholder Icono Google
                  icon: const Icon(Iconsax.share), // Usar Icon.share como placeholder genérico 
                  onPressed: () { 
                    print("Google Sign-In presionado");
                  },
                  label: Text("Continue with Google"), 
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Botón Continuar con Facebook
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                   // Placeholder Icono Facebook
                   icon: const Icon(Iconsax.share), // Usar Icon.share como placeholder genérico
                   onPressed: () { 
                     print("Facebook Sign-In presionado");
                   },
                  label: Text("Continue with Facebook"),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Botón Continuar con Email
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.direct_right),
                  onPressed: () => Get.to(() => const SignupScreen()), 
                  // Placeholder para texto Email
                  label: Text("Continue with Email"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, 
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
               const SizedBox(height: TSizes.spaceBtwSections),
              // Mensaje de error (si ocurre alguno)
              // Obx(() => controller.errorMessage.value.isNotEmpty 
              //    ? Text(controller.errorMessage.value, style: TextStyle(color: Colors.red))
              //    : SizedBox.shrink()
              // ),
            ],
          ),
        ),
      ),
    );
  }
} 