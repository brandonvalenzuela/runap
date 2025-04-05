import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:get_storage/get_storage.dart';

class UserProfileHeader extends StatefulWidget {
  final Color textColor;
  final Color avatarBgColor;
  final Color avatarIconColor;
  final VoidCallback? onAvatarTap;

  const UserProfileHeader({
    super.key,
    this.textColor = TColors.fontColor,
    this.avatarBgColor = TColors.backgroundButton,
    this.avatarIconColor = TColors.colorBlack,
    this.onAvatarTap,
  });

  @override
  State<UserProfileHeader> createState() => _UserProfileHeaderState();
}

class _UserProfileHeaderState extends State<UserProfileHeader> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _fadeInAnimation;
  bool _showWelcomeAnimation = false;
  final GetStorage _storage = GetStorage();
  final String _appStateKey = 'app_is_running';

  @override
  void initState() {
    super.initState();
    // Registrar el observer para detectar cambios en el estado de la app
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Verificar si la aplicación se reinició desde cero
    _checkIfShouldShowWelcome();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // La app se está reanudando, verificar si fue cerrada completamente
      _checkIfShouldShowWelcome();
    } else if (state == AppLifecycleState.paused) {
      // La app está en segundo plano, marcar como en ejecución
      _storage.write(_appStateKey, false);
    }
  }
  
  void _checkIfShouldShowWelcome() {
    // Leer el estado de la app desde storage
    final bool? isRunning = _storage.read<bool>(_appStateKey);
    
    // Si isRunning es null o false, significa que la app se cerró completamente
    if (isRunning == null || isRunning == false) {
      setState(() {
        _showWelcomeAnimation = true;
      });
      
      // Iniciar la animación después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    }
    
    // Marcar la app como en ejecución
    _storage.write(_appStateKey, true);
  }

  @override
  void dispose() {
    // Eliminar el observer cuando se destruye el widget
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nombre del usuario con animación
        Expanded(
          child: Obx(() => userController.isLoading.value
            ? const SkeletonWidget(height: 36, width: 200)
            : _showWelcomeAnimation 
              ? AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Texto de bienvenida
                      Opacity(
                        opacity: _fadeOutAnimation.value,
                        child: Text(
                          "Bienvenido",
                          style: TextStyle(
                            fontSize: TSizes.fontSizeXl,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Nombre del usuario
                      Opacity(
                        opacity: _fadeInAnimation.value,
                        child: Text(
                          userController.fullName,
                          style: TextStyle(
                            fontSize: TSizes.fontSizeXl,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              )
              : Text(
                userController.fullName,
                style: TextStyle(
                  fontSize: TSizes.fontSizeXl,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ),
        ),
        
        // Avatar del usuario
        GestureDetector(
          onTap: widget.onAvatarTap,
          child: Obx(() => userController.isLoading.value
            ? const SkeletonCircle(radius: 24)
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.avatarBgColor,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  image: userController.profilePicture.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(userController.profilePicture),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: userController.profilePicture.isEmpty
                  ? Icon(
                      Icons.person_outline,
                      color: widget.avatarIconColor,
                      size: TSizes.iconXl,
                    )
                  : null,
              ),
          ),
        ),
      ],
    );
  }
} 