import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reddit_clone/core/utils.dart';
import 'package:reddit_clone/features/auth/repository/auth_repository.dart';
import 'package:reddit_clone/models/user_model.dart';

//stateProvider
final userProvider = StateProvider<UserModel?>((ref) =>
    null); //this provider will give us all the data(uid,name,profilePicture, etc) from firebse so we can access data without many api call wich save our cost

//provider
final authControllerProvider = StateNotifierProvider<AuthController, bool>(
  (ref) => AuthController(
    authRepository: ref.watch(authRepositoryProvider),
    ref: ref,
  ),
);

//in this we are contacting to authChangeProvider so we can talk to authStateChange
final authStateChangeProvider = StreamProvider((ref) {
  //final authcontroller is giving instance of autcontroller
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.authStateChange;
});

//this stream provider is of auth_repository class
//when ever we use this provider we must remember that use this as a function so that we can pas the uid of the user
final getUserDataProvider = StreamProvider.family((ref, String uid) {
  //final authcontroller is giving instance of autcontroller
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.getUserData(uid);
});

class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthController({
    required AuthRepository authRepository,
    required Ref ref,
  })  : _authRepository = authRepository,
        _ref = ref,
        super(false); //represent loading in starting false

//new stream to send data to home page
  Stream<User?> get authStateChange => _authRepository.authStateChange;

//function to sign in with google
  void signInWithGoogle(BuildContext context, bool isFromLogin) async {
    state = true; // when loading is happening
    final user = await _authRepository.signInWithGoogle(isFromLogin);
    state = false; // we get value so make it false
// now after making our sign in as Future<Either<String,userModel>>  we can use fold in which l -> failure and r-> success  ////through which now we work on errors //// and if error then show snackbar
    user.fold(
      (l) => showSnackBar(context, l.message),
      (userModel) =>
          _ref.read(userProvider.notifier).update((state) => userModel),
    );
  }

//work for anonmus signin
void signInAsGuest(BuildContext context) async {
    state = true; // when loading is happening
    final user = await _authRepository.signInAsGuest();
    state = false; // we get value so make it false
// now after making our sign in as Future<Either<String,userModel>>  we can use fold in which l -> failure and r-> success  ////through which now we work on errors //// and if error then show snackbar
    user.fold(
      (l) => showSnackBar(context, l.message),
      (userModel) =>
          _ref.read(userProvider.notifier).update((state) => userModel),
    );
  }

  Stream<UserModel> getUserData(String uid) {
    return _authRepository.getUserData(uid);
  }

//help in logging out
  void logOut() async {
    _authRepository.logOut();
  }
}
