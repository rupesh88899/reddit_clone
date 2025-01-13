import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reddit_clone/core/common/loader.dart';
import 'package:reddit_clone/core/common/error_text.dart';
import 'package:reddit_clone/features/auth/controller/auth_controller.dart';
import 'package:reddit_clone/features/community/controller/community_controller.dart';

class AddModsScreen extends ConsumerStatefulWidget {
  final String name;
  const AddModsScreen({
    super.key,
    required this.name,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddModsScreenState();
}

class _AddModsScreenState extends ConsumerState<AddModsScreen> {
  // this set keeps track of all the mods or admins in communities
  Set<String> uids = {};

//this counts no of time check box is rebuild
  int ctr = 0;

//this help to add member to set(uids) when member is mod or admin
  void addUid(String uid) {
    setState(() {
      uids.add(uid);
    });
  }

//this help to remove member to set(uids) when member is mod or admin
  void removeUid(String uid) {
    setState(() {
      uids.remove(uid);
    });
  }

  void saveMods() {
    ref
        .read(communityControllerProvider.notifier)
        .addMods(widget.name, uids.toList(), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () => saveMods(),
              icon: const Icon(Icons.done),
            ),
          ],
        ),
        body: ref.watch(getCommunityByNameProvider(widget.name)).when(
              data: (community) => ListView.builder(
                itemCount: community.members.length,
                itemBuilder: (BuildContext context, int index) {
                  final member = community.members[index];

                  return ref.watch(getUserDataProvider(member)).when(
                        data: (user) {
                          if (community.mods.contains(member) && ctr == 0) {
                            uids.add(member);
                          }
                          ctr++;
                          return CheckboxListTile(
                            value: uids.contains(user.uid),
                            onChanged: (val) {
                              if (val!) {
                                addUid(user.uid);
                              } else {
                                removeUid(user.uid);
                              }
                            },
                            title: Text(user.name),
                          );
                        },
                        error: (error, stackTrace) => ErrorText(
                            error: error.toString(), stackTrace: '$stackTrace'),
                        loading: () => const Loader(),
                      );
                },
              ),
              error: (error, stackTrace) =>
                  ErrorText(error: error.toString(), stackTrace: '$stackTrace'),
              loading: () => const Loader(),
            ));
  }
}
