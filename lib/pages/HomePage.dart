import 'dart:io';

import 'package:Capturoca/models/user.dart';
import 'package:Capturoca/pages/CreateAccountPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Capturoca/pages/NotificationsPage.dart';
import 'package:Capturoca/pages/ProfilePage.dart';
import 'package:Capturoca/pages/SearchPage.dart';
import 'package:Capturoca/pages/TimeLinePage.dart';
import 'package:Capturoca/pages/UploadPage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn gSignIn = GoogleSignIn();
final usersReference = Firestore.instance.collection("users");
final StorageReference storageReference =
    FirebaseStorage.instance.ref().child("Post Pictures");
final postsReference = Firestore.instance.collection("posts");
final activityFeedReference = Firestore.instance.collection("feed");
final commentsReference = Firestore.instance.collection("comments");
final followersReference = Firestore.instance.collection("followers");
final followingReference = Firestore.instance.collection("following");
final timelinereference = Firestore.instance.collection("timeline");

final DateTime timestamp = DateTime.now();
User currentUser;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}
// class _HomePageState extends State<HomePage> {
//   bool _isLoggedIn = false;

//   GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

//   _login() async{
//     try{
//       await _googleSignIn.signIn();
//       setState(() {
//         _isLoggedIn = true;
//       });
//     } catch (err){
//       print(err);
//     }
//   }

//   _logout(){
//     _googleSignIn.signOut();
//     setState(() {
//       _isLoggedIn = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//
//     return MaterialApp(
//       home: Scaffold(
//         body: Center(
//             child: _isLoggedIn
//                 ? Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: <Widget>[
//                       Image.network(_googleSignIn.currentUser.photoUrl, height: 50.0, width: 50.0,),
//                       Text(_googleSignIn.currentUser.displayName),
//                       OutlineButton( child: Text("Logout"), onPressed: (){
//                         _logout();
//                       },)
//                     ],
//                   )
//                 : Center(
//                     child: OutlineButton(
//                       child: Text("Login with Google"),
//                       onPressed: () {
//                         _login();
//                       },
//                     ),
//                   )),
//       ),
//     );
//   }
// }
class _HomePageState extends State<HomePage> {
  bool isSignedIn = false;
  PageController pageController;
  int getPageIndex = 0;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  //  GoogleSignIn _googleSignIn = GoogleSignIn();

  //  _login() async {
  //    try {
  //      await _googleSignIn.signIn();
  //      setState(() {
  //        isLoggedIn=true;
  //      });
  //    }
  //    catch(err){
  //      print(err);
  //    }
  //  }

  //  _logout() async{
  //    _googleSignIn.signOut();
  //    setState(() {
  //      isLoggedIn =false;
  //    });
  //  }
  void initState() {
    super.initState();

    pageController = PageController();

    gSignIn.onCurrentUserChanged.listen((gSigninAccount) {
      controlSignIn(gSigninAccount);
    }, onError: (gError) {
      print("Error Message: " + gError);
    });

    // gSignIn.signIn().then((gSignInAccount){
    //   controlSignIn(gSignInAccount);
    // });
  }

  controlSignIn(GoogleSignInAccount signInAccount) async {
    if (signInAccount != null) {
      await saveUserInfoToFirestore();
      setState(() {
        isSignedIn = true;
      });
      configureRealTimePushNotification();
    } else {
      setState(() {
        isSignedIn = false;
      });
    }
  }

  configureRealTimePushNotification() {
    final GoogleSignInAccount gUser = gSignIn.currentUser;
    if (Platform.isIOS) {
      getIOSPermission();
    }
    _firebaseMessaging.getToken().then((token) {
      usersReference
          .document(gUser.id)
          .updateData({"androidNotificationsToken": token});
    });
    _firebaseMessaging.configure(onMessage: (Map<String, dynamic> msg) async {
      final String recipientId = msg["data"]["recipient"];
      final String body = msg["notifications"]["body"];

      if (recipientId == gUser.id) {
        SnackBar snackBar = SnackBar(
          content: Text(
            body,
            style: TextStyle(color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.grey,
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    });
  }

  getIOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Setting Registered: $settings");
    });
  }

  saveUserInfoToFirestore() async {
    final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
    DocumentSnapshot documentSnapshot =
        await usersReference.document(gCurrentUser.id).get();

    if (!documentSnapshot.exists) {
      final username = await Navigator.push(context,
          MaterialPageRoute(builder: (context) => CreateAccountPage()));

      usersReference.document(gCurrentUser.id).setData({
        "id": gCurrentUser.id,
        "profileName": gCurrentUser.displayName,
        "username": username,
        "url": gCurrentUser.photoUrl,
        "email": gCurrentUser.email,
        "bio": "",
        "timestamp": timestamp,
      });
      await followersReference
          .document(gCurrentUser.id)
          .collection("userFollowers")
          .document(gCurrentUser.id)
          .setData({});

      documentSnapshot = await usersReference.document(gCurrentUser.id).get();
    }

    currentUser = User.fromDocument(documentSnapshot);
  }

  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  loginUser() {
    gSignIn.signIn();
  }

  logoutUser() {
    gSignIn.signOut();
  }

  whenPageChanges(int pageIndex) {
    setState(() {
      this.getPageIndex = pageIndex;
    });
  }

  onTabChangePage(int pageIndex) {
    pageController.jumpToPage(pageIndex);
  }

  Scaffold buildHomeScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLinePage(gCurrentUser: currentUser),
          // RaisedButton.icon(onPressed: logoutUser, icon: Icon(Icons.close), label: Text("Sign Out")),
          SearchPage(),
          // RaisedButton.icon(onPressed: logoutUser, icon: Icon(Icons.close), label: Text("Sign Out")),
          UploadPage(gCurrentUser: currentUser),
          NotificationsPage(),
          ProfilePage(userProfileId: currentUser.id),
        ],
        controller: pageController,
        onPageChanged: whenPageChanges,
        // physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: getPageIndex,
        onTap: onTabChangePage,
        backgroundColor: Colors.cyan,
        activeColor: Colors.white,
        inactiveColor: Colors.indigoAccent,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.photo_camera,
            size: 37.0,
          )),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite, color: Colors.red)),
          BottomNavigationBarItem(icon: Icon(Icons.person)),
        ],
      ),
    );
    //return RaisedButton.icon(onPressed: logoutUser, icon: Icon(Icons.close), label: Text("Sign Out"));
  }

  Scaffold buildSignInScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).accentColor,
                Theme.of(context).primaryColor
              ]),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Capturoca",
              style: TextStyle(
                  fontSize: 92.0,
                  color: Colors.lightBlueAccent,
                  fontFamily: "Signatra"),
            ),
            GestureDetector(
              onTap: () => loginUser(),
              child: Container(
                  width: 270.0,
                  height: 65.0,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                    image: AssetImage("assets/images/google_signin_button.png"),
                    fit: BoxFit.cover,
                  ))),
            ),
            Container(height: 100),
            Text(
              "by  A.R",
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.blueAccent,
                  fontFamily: "Signatra"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSignedIn) {
      return buildHomeScreen();
    } else {
      return buildSignInScreen();
    }
  }
}
