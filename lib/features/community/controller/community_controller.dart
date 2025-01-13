import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:reddit_clone/core/Providers/storage_repository_provider.dart';
import 'package:reddit_clone/core/constants/constants.dart';
import 'package:reddit_clone/core/failure.dart';
import 'package:reddit_clone/core/utils.dart';
import 'package:reddit_clone/features/auth/controller/auth_controller.dart';
import 'package:reddit_clone/features/community/repository/communitory_repositary.dart';
import 'package:reddit_clone/models/community_model.dart';
import 'package:reddit_clone/models/post_model.dart';
import 'package:routemaster/routemaster.dart';

final userCommunitiesProvider = StreamProvider((ref) {
  final communityController = ref.watch(communityControllerProvider.notifier);
  return communityController.getUserCommunities();
});

final communityControllerProvider =
    StateNotifierProvider<CommunityController, bool>((ref) {
  final communitoryRepositary = ref.watch(communityRepositaryProvider);
  final storageRepository = ref.watch(storageRepositoryProvider);
  return CommunityController(
    communitoryRepositary: communitoryRepositary,
    storageRepository: storageRepository,
    ref: ref,
  );
});

final getCommunityByNameProvider = StreamProvider.family((ref, String name) {
  return ref
      .watch(communityControllerProvider.notifier)
      .getCommunityByName(name);
});

final searchCommunityProvider = StreamProvider.family((ref, String query) {
  return ref.watch(communityControllerProvider.notifier).searchCommunity(query);
});


final getCommunityPostsProvider = StreamProvider.family((ref, String name) {
  return ref.read(communityControllerProvider.notifier).getCommunityPosts(name);
});


class CommunityController extends StateNotifier<bool> {
  final CommunitoryRepositary _communitoryRepositary;

  //ref is used bacause we want to communicate to userProvider to get uid and all stuff to create admin and all things
  final Ref _ref;

  //instance of storage repository
  final StorageRepository _storageRepository;

  CommunityController({
    required CommunitoryRepositary communitoryRepositary,
    required Ref ref,
    required StorageRepository storageRepository,
  })  : _communitoryRepositary = communitoryRepositary,
        _ref = ref,
        _storageRepository = storageRepository,
        super(false); //initially loading is false

//build context to show snackbar
  void createCommunity(String name, BuildContext context) async {
    state = true; // when we press to create community to start loading

    final uid = _ref.read(userProvider)?.uid ?? '';

    Community community = Community(
      id: name,
      name: name,
      banner: Constants.bannerDefault,
      avator: Constants.avatarDefault,
      members: [uid],
      mods: [uid],
    );

    final res = await _communitoryRepositary.createCommunity(community);

    state = false; // when we have result then loading is closed

    //fold to check community already exist or not
    res.fold((l) => showSnackBar(context, l.message), (r) {
      showSnackBar(context, 'Community created successfully');
      Routemaster.of(context).pop();
    });
  }

  //this help in join community
  void joinCommunity(Community community, BuildContext context) async {
    final user = _ref.read(userProvider)!;
    Either<Failure, void> res;
    if (community.members.contains(user.uid)) {
      res =
          await _communitoryRepositary.leaveCommunity(community.name, user.uid);
    } else {
      res =
          await _communitoryRepositary.joinCommunity(community.name, user.uid);
    }

    res.fold((l) => showSnackBar(context, l.message), (r) {
      if (community.members.contains(user.uid)) {
        showSnackBar(context, 'Community left successfully!');
      } else {
        showSnackBar(context, 'Community joined successfully');
      }
    });
  }

  Stream<List<Community>> getUserCommunities() {
    final uid = _ref.read(userProvider)!.uid;
    return _communitoryRepositary.getUserCommunities(uid);
  }

  Stream<Community> getCommunityByName(String name) {
    return _communitoryRepositary.getCommunityByName(name);
  }

//this controller is used to save new data of this comunity like banner and profile pic
//since community already exists then we want to add data to community
  void editCommunity({
    required File? profileFile,
    required File? bannerFile,
    required BuildContext context,
    required Community community,
  }) async {
    state = true;
    if (profileFile != null) {
      //this will save file to ex-->> communities/profile/memes
      final res = await _storageRepository.storeFile(
        path: 'communities/profile',
        id: community.name,
        file: profileFile,
      );

      //this res.fold give us url to download avator if success means when (r)
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) => community = community.copyWith(avator: r),
      );
    }

    if (bannerFile != null) {
      //this will save file to ex-->> communities/banner/memes
      final res = await _storageRepository.storeFile(
        path: 'communities/banner',
        id: community.name,
        file: bannerFile,
      );

      //this res.fold give us url to download banner pic if success means when (r)
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) => community = community.copyWith(banner: r),
      );
    }

    //naw save this to communinty repository
    final res = await _communitoryRepositary.editCommunity(community);

    state = false;

    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) => Routemaster.of(context).pop(),
    );
  }

// this controller is for suggestions in search bar for community suggestion
  Stream<List<Community>> searchCommunity(String query) {
    return _communitoryRepositary.searchCommunity(query);
  }

//this help to update moderators of the communities
  void addMods(
      String communityName, List<String> uids, BuildContext context) async {
    final res = await _communitoryRepositary.addMods(communityName, uids);
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) => Routemaster.of(context).pop(),
    );
  }

  //help to get posts of profile
  Stream<List<Post>> getCommunityPosts(String name) {
    return _communitoryRepositary.getCommunityPosts(name);
  }

}
