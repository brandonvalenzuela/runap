import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:runap/features/personalization/models/user_model.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';

/// Repository class for user-related operations.
class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ///Function to save user data to Firestore.
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _db.collection("Users").doc(user.id).set(user.toJson());
    } on FirebaseException catch (e) {
      throw e;
    } on FormatException catch (_) {
      rethrow;
    } on PlatformException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Something went wrong while saving user record. Please try again.');
    }
  }

  /// Function to fetch user details based on user ID.
  Future<UserModel> fetchUserData() async {
    try {
      final userId = AuthenticationRepository.instance.currentUserId;
      if (userId == null || userId.isEmpty) {
        print("⚠️ UserRepository.fetchUserData: User not logged in.");
        return UserModel.empty();
      }
      
      print("ℹ️ UserRepository.fetchUserData: Fetching data for UID: $userId");
      final documentSnapshot = await _db.collection("Users").doc(userId).get();
      
      if(documentSnapshot.exists){
        print("✅ UserRepository.fetchUserData: Document found.");
        return UserModel.fromSnapshot(documentSnapshot);
      } else {
        print("ℹ️ UserRepository.fetchUserData: Document not found for UID: $userId");
        return UserModel.empty();
      }
    } on FirebaseException catch (e) {
       print("❌ UserRepository.fetchUserData: FirebaseException - Code: ${e.code}, Message: ${e.message}");
      throw e;
    } on FormatException catch (_) {
      print("❌ UserRepository.fetchUserData: FormatException");
      rethrow;
    } on PlatformException catch (e) {
      print("❌ UserRepository.fetchUserData: PlatformException - Code: ${e.code}, Message: ${e.message}");
      throw e;
    } catch (e, stackTrace) {
      print("❌ UserRepository.fetchUserData: Unexpected error - $e\n$stackTrace");
      throw Exception('Something went wrong while fetching user data. Please try again.');
    }
  }
}
