import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:runap/features/personalization/models/user_model.dart';
import 'package:runap/utils/exceptions/exceptions.dart';
import 'package:runap/utils/exceptions/firebase_exceptions.dart';
import 'package:runap/utils/exceptions/format_exceptions.dart';

/// Repository class for user-related operations.
class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ///Function to save user data to Firestore.
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _db.collection("Users").doc(user.id).set(user.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TExceptions(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again'; //const TGenericException();
    }
  }
}
