import 'dart:async';
import 'package:zenly_like/models/app_user.dart';
import 'package:zenly_like/screens/map_screens/components/user_card_list.dart';
import 'package:zenly_like/screens/map_screens/components/profile_button.dart';
import 'package:zenly_like/screens/map_screens/components/sign_in_button.dart';
import 'package:zenly_like/screens/profile_screen/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';



class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  late StreamSubscription<Position> positionStream;
  Set<Marker> markers = {};
  late StreamSubscription usersStream;
  late Position currentUserPosition;
  

  final CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(35.681236, 139.767125),
    zoom: 16.0,
  );

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high, 
    distanceFilter: 5,
   );

  // ------------  Auth  ------------
  late StreamSubscription<User?> authUserStream;
  String currentUserId = '';

  // ------------  State changes  ------------
  bool isSignedIn = false;
  // bool isLoading = false;

  // void _setIsLoading(bool value) {
  //   setState(() {
  //     isLoading = value;
  //   });
  // }

  void setIsSignedIn(bool value) {
      setState(() {
          isSignedIn = value;
      });
  }

   void setCurrentUserId(String value) {
       setState(() {
       currentUserId = value;
       });
   }

  //  void clearUserMarkers() {
  //   setState(() {
  //     markers.removeWhere(
  //       (marker) => marker.markerId != const MarkerId('current_location'),
  //     );
  //   });
  // }

  @override
  void initState() {
    // ログイン状態の変化を監視
    _watchSignInState();
    _watchUsers();
    super.initState();
  }

  @override
  void dispose() {
    mapController.dispose();
    positionStream.cancel();
    authUserStream.cancel();
    usersStream.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
              GoogleMap(
                initialCameraPosition: initialCameraPosition,
                onMapCreated: (GoogleMapController controller) async {
                  mapController = controller;
                  await _requestPermission();
                  await _moveToCurrentLocation();
                  _watchCurrentLocation();
 
                },
                myLocationButtonEnabled: true,
                markers: markers,
              ),
              StreamBuilder(
                stream: getAppUsersStream(),
                builder: (BuildContext context, snapshot) {
                    if (snapshot.hasData && isSignedIn) {
                      // 自分以外のユーザーかつlocationデータを持つユーザー配列を取得
                      final users = snapshot.data!
                          .where((user) => user.id != currentUserId)
                          .where((user) => user.location != null)
                          .toList();

                      return UserCardList(
                        onPageChanged: (index) {
                          //スワイプ後のユーザーの位置情報を取得
                          late GeoPoint location;
                          if (index == 0) {
                            location = GeoPoint(
                              currentUserPosition.latitude,
                              currentUserPosition.longitude,
                            );
                          } else {
                            location = users.elementAt(index - 1).location!;
                          }

                          //スワイプ後のユーザーの座標までカメラを移動
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  location.latitude,
                                  location.longitude,
                                ),
                                zoom: 16.0,
                              ),
                            ),
                          );
                        },      
                        appUsers: users,
                      );
                    }
                    // サインアウト時、ユーザーデータを未取得時に表示するwidget
                    return Container();
                  },
              ),
            ],
        ),


      floatingActionButtonLocation: !isSignedIn
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.endTop,
          floatingActionButton:!isSignedIn 
           ? const SignInButton()
           : ProfileButton(onPressed: () {
              Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }),
    );
  }


// ------------ Methods for Map ------------
  Future<void> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _moveToCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // 現在地を取得
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentUserPosition = position;

        markers.add(Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            position.latitude,
            position.longitude,
          ),
        ));
      });

      // 現在地にカメラを移動
      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    }
  }

    void _watchCurrentLocation() {

      positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) async {
              
              // マーカーピンの位置を更新する処理
              setState(() {
                currentUserPosition = position;
                markers.removeWhere(
                    (marker) => marker.markerId == const MarkerId('current_location'));

                markers.add(Marker(
                  markerId: const MarkerId('current_location'),
                    position: LatLng(
                      position.latitude,
                      position.longitude,
                    ),
                  ));
              });

              // Firestoreに現在地を更新
              await _updateUserLocationInFirestore(position);

              // カメラの位置を更新する処理
              // 現在地にカメラを移動
              await mapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(position.latitude, position.longitude),
                    zoom: 16,
                  ),
                ),
              );
        });
    }


    // ------------  Methods for Auth  ------------
  void _watchSignInState() {
    setState(() {
      authUserStream =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user == null) {
            setIsSignedIn(false);
            markers.clear();
        } else {
          setIsSignedIn(true);
          setCurrentUserId(user.uid);
        }
      });
    });
  }

  // ------------  Methods for Firestore  ------------
  Stream<List<AppUser>> getAppUsersStream() {
    return FirebaseFirestore.instance.collection('app_users').snapshots().map(
          (snp) => snp.docs
              .map((doc) => AppUser.fromDoc(doc.id, doc.data()))
              .toList(),
        );
  }

  // ------------  Methods for Markers  ------------
  void _watchUsers() {
    usersStream = getAppUsersStream().listen((users) {
      
        final otherUsers = 
        users.where((user) => user.id != currentUserId).toList();

        for (final user in otherUsers) {
          if (user.location != null && isSignedIn) {
            final lat = user.location!.latitude;
            final lng = user.location!.longitude;

            setState(() {
              // 既にマーカーが作成されている場合は、取り除く
              if (markers
                  .where((m) => m.markerId == MarkerId(user.id!))
                  .isNotEmpty) {
                    markers.removeWhere(
                      (marker) => marker.markerId == MarkerId(user.id!),
                    );
                  }   

              // 取り除いた上でマーカーを追加
              markers.add(Marker(
                  markerId: MarkerId(user.id!),
                  position: LatLng(lat, lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
              ));
            });

          }
        }
    });
  }

Future<void> _updateUserLocationInFirestore(Position position) async {
   if (isSignedIn) {
     await FirebaseFirestore.instance
         .collection('app_users')
         .doc(currentUserId)
         .update({
       'location': GeoPoint(
         position.latitude,
         position.longitude,
       ),
     });
   }
 } 
} 