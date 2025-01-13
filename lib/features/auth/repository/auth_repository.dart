import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reddit_clone/core/Providers/firebase_provider.dart';
import 'package:reddit_clone/core/constants/constants.dart';
import 'package:reddit_clone/core/constants/firebase_constants.dart';
import 'package:reddit_clone/core/failure.dart';
import 'package:reddit_clone/core/type_defs.dart';
import 'package:reddit_clone/models/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
    firestore: ref.read(firestoreProvider),
    auth: ref.read(authProvider),
    googleSignIn: ref.read(googleSignInProvider)));

class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  })  : _firestore = firestore,
        _auth = auth,
        _googleSignIn = googleSignIn;

  /// getter to store data to firestore correctly so to check user properteis from collection of firestore
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  ///another getter -> firebase giving an option to expose stream which allow us to know is user change or not
  Stream<User?> get authStateChange => _auth.authStateChanges();

///// signin pagkage give us email an all and auth help us to store data in our firebase nad since we have to handle error so we use fpdart which gice (Either) feature so we can work withour try cath block Either<String,UserModel>  this means if error then it will be of type String and if success then it will be of type UserModel and after making type_defs we can write this like  FUtureEither<UserModel>
  FutureEither<UserModel> signInWithGoogle(bool isFromLogin) async {
    try {
      UserCredential userCredential;

      ///if we are on web screen
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider
            .addScope('https://www.googleapis.com/auth/contacts.readonly');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        final googleAuth = await googleUser?.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

//if user is an annonmas user then we convert anonmus login to google sign
        if (isFromLogin) {
          userCredential = await _auth.signInWithCredential(credential);
        } else {
          userCredential =
              await _auth.currentUser!.linkWithCredential(credential);
        }
      }

//structure the data to save in firebase if user is new user else dont
      UserModel userModel;

      if (userCredential.additionalUserInfo!.isNewUser) {
        userModel = UserModel(
          name: userCredential.user!.displayName ?? 'No Name',
          profilePic: userCredential.user!.photoURL ?? Constants.avatarDefault,
          banner: Constants.bannerDefault,
          uid: userCredential.user!.uid,
          isAuthenticated: true,
          karna: 0,
          awards: [
            'awesomeAns',
            'gold',
            'platinum',
            'helpful',
            'plusone',
            'rocket',
            'thankyou',
            'til'
          ],
        );
        //now save data to firebase after making constants and getter which can communicate with the help of _user and in this we can set our data in map using toMap which is created with user_model class through which we can send data in map form
        await _users.doc(userCredential.user!.uid).set(userModel.toMap());
      } else {
        //if user is not new then we return userModel which contains the data of the user by asking to firebase and get data using getUserData function
        //here we consume stream
        userModel = await getUserData(userCredential.user!.uid).first;
      }

      return right(userModel);
    }
//if there is any error then we through to authController

    //also to catch any firebase exceptions we can write firebaseException
    on FirebaseException catch (e) {
      throw e.message!;
    } catch (e) {
      //when there is any failure then we can simply call Failure class to show error
      return left(Failure(e.toString()));
    }
  }

  ///// signin pagkage give us email an all and auth help us to store data in our firebase nad since we have to handle error so we use fpdart which gice (Either) feature so we can work withour try cath block Either<String,UserModel>  this means if error then it will be of type String and if success then it will be of type UserModel and after making type_defs we can write this like  FUtureEither<UserModel>
  FutureEither<UserModel> signInAsGuest() async {
    try {
      var userCredential = await _auth.signInAnonymously();

//structure the data to save in firebase if user is new user else dont
      UserModel userModel = UserModel(
        name: 'Guest',
        profilePic: Constants.avatarDefault,
        banner: Constants.bannerDefault,
        uid: userCredential.user!.uid,
        isAuthenticated: false,
        karna: 0,
        awards: [],
      );

      //now save data to firebase after making constants and getter which can communicate with the help of _user and in this we can set our data in map using toMap which is created with user_model class through which we can send data in map form
      await _users.doc(userCredential.user!.uid).set(userModel.toMap());

      return right(userModel);
    }
//if there is any error then we through to authController

    //also to catch any firebase exceptions we can write firebaseException
    on FirebaseException catch (e) {
      throw e.message!;
    } catch (e) {
      //when there is any failure then we can simply call Failure class to show error
      return left(Failure(e.toString()));
    }
  }

  Stream<UserModel> getUserData(String uid) {
    //we go to user -> we snapshot-> then converted to map -> now snapshot in document
    return _users.doc(uid).snapshots().map(
        (event) => UserModel.fromMap(event.data() as Map<String, dynamic>));
  }

  ///this method is used for logging out the account from google
  void logOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
