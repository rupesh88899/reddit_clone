// import 'dart:io';

// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:fpdart/fpdart.dart';
// import 'package:reddit_clone/core/Providers/firebase_provider.dart';
// import 'package:reddit_clone/core/failure.dart';
// import 'package:reddit_clone/core/type_defs.dart';

// final storageRepositoryProvider = Provider(
//   (ref) => StorageRepository(
//     firebaseStorage: ref.watch(storageProvider),
//   ),
// );

// class StorageRepository {
//   final FirebaseStorage _firebaseStorage;

//   StorageRepository({required FirebaseStorage firebaseStorage})
//       : _firebaseStorage = firebaseStorage;

// //FutureEither can means it can be error or string , and string is because we want to upload profilePIc, and banner which are of type String so we get url for download when we upload then to firebase storage
//   FutureEither<String> storeFile({
//     required String path,
//     required String id,
//     required File? file,
//   }) async {
//     try {
//       final ref = _firebaseStorage
//           .ref()
//           .child(path)
//           .child(id); // this will give -->>//user/banner/123

//       UploadTask uploadTask = ref.putFile(file!);

//       final snapShot = await uploadTask;

//       return right(await snapShot.ref.getDownloadURL());
//     } catch (e) {
//       return left(Failure(e.toString()));
//     }
//   }
// }

// from here we are going to start cloudneary code

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:reddit_clone/core/failure.dart';
import 'package:reddit_clone/core/key.dart';
import 'package:reddit_clone/core/type_defs.dart';

final storageRepositoryProvider = Provider(
  (ref) => StorageRepository(),
);

var preset = uploadPreset;
var cName = cloudName;

class StorageRepository {
  final String cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/$cName/image/upload';
  final String uploadPreset = preset;

  FutureEither<String> storeFile({
    required String path,
    required String id,
    required File? file,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..fields['public_id'] = '$path/$id'
        ..files.add(await http.MultipartFile.fromPath('file', file!.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return right(jsonResponse['secure_url']);
      } else {
        return left(
            Failure('Failed to upload image: ${response.reasonPhrase}'));
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
