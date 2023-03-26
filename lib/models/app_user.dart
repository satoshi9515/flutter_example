import 'package:zenly_like/types/image_type.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AppUser {
  AppUser({
    this.id,
    this.name = '',
    this.profile = '',
    this.imageType = ImageType.lion,
    this.location,
  });

  final String? id;
  final String name;
  final String profile;
  final ImageType imageType;
  final GeoPoint? location;

    factory AppUser.fromDoc(String id, Map<String, dynamic> json) => AppUser(
        id: id,
        name: json['name'],
        profile: json['profile'],
        imageType: ImageType.fromString(json['image_type']),
        location: json['location'],
      );
}
