import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:runap/utils/formatters/formatter.dart';

class UserModel {
  // Keep those values final which you do not want to update
  final String id;
  String firstName;
  String lastName;
  final String username;
  final String email;
  String phoneNumber;
  String porfilePicture;

  // New survey fields
  String? gender;
  String? age;
  String? height; // Consider double/int?
  String? currentWeight; // Consider double/int?
  String? idealWeight; // Consider double/int?
  String? mainGoal;
  String? pace; // e.g., 'Slowly', 'Middle', 'Fast'
  // Add other fields if needed (e.g., howHeard, loseWeightReasons)

  // Constructor for UserModel
  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.porfilePicture,
    // Initialize new fields
    this.gender,
    this.age,
    this.height,
    this.currentWeight,
    this.idealWeight,
    this.mainGoal,
    this.pace,
  });

  /// Helper function to get the full name.
  String get fullName => '$firstName $lastName';

  /// Helper function to format the phone number.
  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  /// Static function to split full name into first and last   name.
  static List<String> nameParts(fullName) => fullName.split(' ');

  /// Static function to generate a username from the full name.
  static String generateUsername(fullName) {
    List<String> nameParts = fullName.split(' ');
    String firstName = nameParts[0].toLowerCase();
    String lastName = nameParts.length > 1 ? nameParts[1].toLowerCase() : '';

    String camelCaseUsername =
        '$firstName$lastName'; // Combine first name and last name
    String usernameWithPrefix =
        'cwt_$camelCaseUsername'; // Add prefix 'cwt_' to the username
    return usernameWithPrefix;
  }

  /// Static function to create an empty user model.
  static UserModel empty() => UserModel(
        id: '',
        firstName: '',
        lastName: '',
        username: '',
        email: '',
        phoneNumber: '',
        porfilePicture: '',
      );

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'Username': username,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'ProfilePicture': porfilePicture,
      'Gender': gender,
      'Age': age,
      'Height': height,
      'CurrentWeight': currentWeight,
      'IdealWeight': idealWeight,
      'MainGoal': mainGoal,
      'Pace': pace,
    };
  }

  /// Factory method to create a UserModel from a Firebase document snapshot
  factory UserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data != null) {
      return UserModel(
        id: document.id,
        firstName: data['FirstName'] ?? '',
        lastName: data['LastName'] ?? '',
        username: data['Username'] ?? '',
        email: data['Email'] ?? '',
        phoneNumber: data['PhoneNumber'] ?? '',
        porfilePicture: data['ProfilePicture'] ?? '',
        gender: data['Gender'] as String?,
        age: data['Age'] as String?,
        height: data['Height'] as String?,
        currentWeight: data['CurrentWeight'] as String?,
        idealWeight: data['IdealWeight'] as String?,
        mainGoal: data['MainGoal'] as String?,
        pace: data['Pace'] as String?,
      );
    }
    throw Exception('Document data is null');
  }
}
