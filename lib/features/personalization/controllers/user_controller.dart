// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:runap/features/personalization/models/user_model.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  final Rx<UserModel> currentUser = UserModel.empty().obs;
  final RxBool isLoading = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }
  
  // Método para obtener los datos del usuario actual
  Future<void> fetchUserData() async {
    try {
      isLoading.value = true;
      
      // Obtener el usuario autenticado actual
      final User? user = _auth.currentUser;
      
      if (user == null) {
        isLoading.value = false;
        return;
      }
      
      // Buscar el documento del usuario en Firestore
      final docSnapshot = await _db.collection("Users").doc(user.uid).get();
      
      if (docSnapshot.exists) {
        // Convertir los datos del documento a un modelo de usuario
        currentUser.value = UserModel.fromSnapshot(docSnapshot);
      } else {
        // Si no existe el documento, crear un usuario con datos básicos
        final newUser = UserModel(
          id: user.uid,
          firstName: user.displayName?.split(' ').first ?? 'Usuario',
          lastName: user.displayName?.split(' ').last ?? '',
          username: user.displayName?.toLowerCase().replaceAll(' ', '_') ?? 'usuario',
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? '',
          porfilePicture: user.photoURL ?? '',
        );
        
        // Guardar el nuevo usuario en Firestore
        await _db.collection("Users").doc(user.uid).set(newUser.toJson());
        
        // Actualizar el usuario actual
        currentUser.value = newUser;
      }
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Obtener el nombre completo del usuario
  String get fullName => currentUser.value.fullName;
  
  // Obtener el email del usuario
  String get email => currentUser.value.email;
  
  // Obtener la URL de la imagen de perfil
  String get profilePicture => currentUser.value.porfilePicture;
} 