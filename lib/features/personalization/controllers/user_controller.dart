// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:runap/features/personalization/models/user_model.dart';
import 'dart:async'; // Importar async

class UserController extends GetxController {
  static UserController get instance => Get.find();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  final Rx<UserModel> currentUser = UserModel.empty().obs;
  final RxBool isLoading = false.obs; // Iniciar como false, el listener pondrá true
  
  // StreamSubscription para escuchar cambios de Auth
  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    // Eliminar la llamada directa
    // fetchUserData(); 

    // Escuchar cambios de estado de autenticación
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      print("UserController: Auth state changed. User: ${user?.uid}");
      if (user != null) {
        // Usuario autenticado, cargar datos
        fetchUserData(user.uid);
      } else {
        // Usuario deslogueado, resetear estado
        currentUser.value = UserModel.empty();
        isLoading.value = false;
        print("UserController: User is null, state reset.");
      }
    });
  }
  
  // Modificar fetchUserData para aceptar uid y manejar estado loading
  Future<void> fetchUserData([String? userId]) async {
    final uid = userId ?? _auth.currentUser?.uid; // Usar uid pasado o el actual
    if (uid == null) {
       print("UserController.fetchUserData: UID is null, cannot fetch.");
       isLoading.value = false;
       return; // Salir si no hay UID
    }

    try {
      isLoading.value = true;
      print("UserController.fetchUserData: Fetching data for UID: $uid");
      
      // Buscar el documento del usuario en Firestore
      final docSnapshot = await _db.collection("Users").doc(uid).get(); // Usar uid directamente
      
      if (docSnapshot.exists) {
        currentUser.value = UserModel.fromSnapshot(docSnapshot);
        print("UserController.fetchUserData: User data loaded from Firestore.");
      } else {
        // Si no existe, crear usuario básico (esto puede pasar la primera vez después de registro)
        print("UserController.fetchUserData: User document not found in Firestore, creating basic user.");
        final firebaseUser = _auth.currentUser; // Obtener el User de Firebase para datos básicos
        final newUser = UserModel(
          id: uid,
          firstName: firebaseUser?.displayName?.split(' ').first ?? 'Usuario',
          lastName: firebaseUser?.displayName?.split(' ').last ?? '',
          username: firebaseUser?.displayName?.toLowerCase().replaceAll(' ', '_') ?? 'usuario',
          email: firebaseUser?.email ?? '',
          phoneNumber: firebaseUser?.phoneNumber ?? '',
          porfilePicture: firebaseUser?.photoURL ?? '',
        );
        await _db.collection("Users").doc(uid).set(newUser.toJson());
        currentUser.value = newUser;
        print("UserController.fetchUserData: Basic user created and loaded.");
      }
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      currentUser.value = UserModel.empty(); // Resetear en caso de error
    } finally {
      isLoading.value = false;
      print("UserController.fetchUserData: Fetch complete, isLoading set to false.");
    }
  }

  @override
  void onClose() {
    // Cancelar la suscripción al cerrar el controlador
    _authSubscription?.cancel();
    print("UserController: Auth subscription cancelled.");
    super.onClose();
  }
  
  // Obtener el nombre completo del usuario
  String get fullName => currentUser.value.fullName;
  
  // Obtener el email del usuario
  String get email => currentUser.value.email;
  
  // Obtener la URL de la imagen de perfil
  String get profilePicture => currentUser.value.porfilePicture;
} 