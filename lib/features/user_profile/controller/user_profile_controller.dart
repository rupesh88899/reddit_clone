import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reddit_clone/core/Providers/storage_repository_provider.dart';
import 'package:reddit_clone/core/enums/enums.dart';
import 'package:reddit_clone/core/utils.dart';
import 'package:reddit_clone/features/auth/controller/auth_controller.dart';
import 'package:reddit_clone/features/user_profile/repository/user_profile_repository.dart';
import 'package:reddit_clone/models/post_model.dart';
import 'package:reddit_clone/models/user_model.dart';
import 'package:routemaster/routemaster.dart';

//this is  provider
final userProfileControllerProvider =
    StateNotifierProvider<UserProfileController, bool>((ref) {
  final userProfileRepository = ref.watch(userProfileRepositoryProvider);
  final storageRepository = ref.watch(storageRepositoryProvider);
  return UserProfileController(
    userProfileRepository: userProfileRepository,
    storageRepository: storageRepository,
    ref: ref,
  );
});

//stream provider to get posts to profile
final getUserPostsProvider = StreamProvider.family((ref, String uid) {
  return ref.read(userProfileControllerProvider.notifier).getUserPosts(uid);
});

class UserProfileController extends StateNotifier<bool> {
  final UserProfileRepository _userProfileRepositary;

  //ref is used bacause we want to communicate to userProvider to get uid and all stuff to create admin and all things
  final Ref _ref;

  //instance of storage repository
  final StorageRepository _storageRepository;

  UserProfileController({
    required UserProfileRepository userProfileRepository,
    required Ref ref,
    required StorageRepository storageRepository,
  })  : _userProfileRepositary = userProfileRepository,
        _ref = ref,
        _storageRepository = storageRepository,
        super(false); //initially loading is false

//this controller is used to save new data of this comunity like banner and profile pic
//since community already exists then we want to add data to community
  void editCommunity({
    required File? profileFile,
    required File? bannerFile,
    required BuildContext context,
    required String name,
  }) async {
    state = true;
    //this will get access to user
    UserModel user = _ref.read(userProvider)!;

    if (profileFile != null) {
      //this will save file
      final res = await _storageRepository.storeFile(
        path: 'users/profile',
        id: user.uid,
        file: profileFile,
      );

      //this res.fold give us url to download avator if success means when (r)
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) => user = user.copyWith(profilePic: r),
      );
    }

    if (bannerFile != null) {
      //this will save file
      final res = await _storageRepository.storeFile(
        path: 'user/banner',
        id: user.uid,
        file: bannerFile,
      );

      //this res.fold give us url to download banner pic if success means when (r)
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) => user = user.copyWith(banner: r),
      );
    }

    //this help to update the name from textfield in edit profile
    user = user.copyWith(name: name);

    //then save this to communinty repository
    final res = await _userProfileRepositary.editProfile(user);

    state = false;

    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) {
        //before poping we want to update userprovider so our new name is store in my firebasestore
        _ref.read(userProvider.notifier).update((state) => user);
        Routemaster.of(context).pop();
      },
    );
  }

  //help to get posts of profile
  Stream<List<Post>> getUserPosts(String uid) {
    return _userProfileRepositary.getUserPosts(uid);
  }

  //for karma feture - we are updateing it all the time for post ,coment and all
  void updateUserKarma(UserKarna karna) async {
    UserModel user = _ref.read(userProvider)!;
    user = user.copyWith(karna: user.karna + karna.karna);

    final res = await _userProfileRepositary.updateUserKarna(user);

    res.fold((l) => null,
        (r) => _ref.read(userProvider.notifier).update((state) => user));
  }
}
