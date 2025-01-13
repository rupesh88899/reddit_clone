import 'package:flutter/foundation.dart';

//since this is our main class and with (fianal) means values cannot change
class UserModel {
  final String name;
  final String profilePic;
  final String banner;
  final String uid;
  final bool isAuthenticated; // if guest or not
  final int karna;
  final List<String> awards;
  UserModel({
    required this.name,
    required this.profilePic,
    required this.banner,
    required this.uid,
    required this.isAuthenticated,
    required this.karna,
    required this.awards,
  });

//so we use copywith feature to change names and other final values
  UserModel copyWith({
    String? name,
    String? profilePic,
    String? banner,
    String? uid,
    bool? isAuthenticated,
    int? karna,
    List<String>? awards,
  }) {
    return UserModel(
      name: name ?? this.name,
      profilePic: profilePic ?? this.profilePic,
      banner: banner ?? this.banner,
      uid: uid ?? this.uid,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      karna: karna ?? this.karna,
      awards: awards ?? this.awards,
    );
  }

//since we want to store or data into firebase we need to make our data in map formet so this will help
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'profilePic': profilePic,
      'banner': banner,
      'uid': uid,
      'isAuthenticated': isAuthenticated,
      'karna': karna,
      'awards': awards,
    };
  }

//through this what even value we have passed into map is converted into user model class extracting the values from it
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
        name: map['name'] ?? '',
        profilePic: map['profilePic'] ?? '',
        banner: map['banner'] ?? '',
        uid: map['uid'] ?? '',
        isAuthenticated: map['isAuthenticated'] ?? '',
        karna: map['karna'] ?? 0,
        awards: List<String>.from(
          (map['awards'] ?? ''),
        ));
  }

// as we knwo if we use userModel.toString(); this will give instane but we want value so this toString function will give us value directly
  @override
  String toString() {
    return 'UserModel(name: $name, profilePic: $profilePic, banner: $banner, uid: $uid, isAuthenticated: $isAuthenticated, karna: $karna, awards: $awards)';
  }

//from this this == erual to and next functonn has code we dont need but lest keep it just if we need
  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.profilePic == profilePic &&
        other.banner == banner &&
        other.uid == uid &&
        other.isAuthenticated == isAuthenticated &&
        other.karna == karna &&
        listEquals(other.awards, awards);
  }

  @override
  int get hashCode {
    return name.hashCode ^
        profilePic.hashCode ^
        banner.hashCode ^
        uid.hashCode ^
        isAuthenticated.hashCode ^
        karna.hashCode ^
        awards.hashCode;
  }
}
