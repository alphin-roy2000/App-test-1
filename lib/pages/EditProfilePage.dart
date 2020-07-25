import 'package:Capturoca/models/user.dart';
import 'package:Capturoca/pages/HomePage.dart';

import 'package:Capturoca/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";

class EditProfilePage extends StatefulWidget {
  final String currentOnlineUserId;
  EditProfilePage({this.currentOnlineUserId});
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController profileTextEditingController = TextEditingController();
  TextEditingController bioTextEditingController = TextEditingController();
  final _scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  bool loading = false;
  User user;
  bool _bioValid = true;
  bool _profileNameValid = true;

  void initState() {
    super.initState();

    getAndDisplayUserInformation();
  }

  getAndDisplayUserInformation() async {
    setState(() {
      loading = true;
    });

    DocumentSnapshot documentSnapshot =
        await usersReference.document(widget.currentOnlineUserId).get();
    user = User.fromDocument(documentSnapshot);

    profileTextEditingController.text = user.profileName;
    bioTextEditingController.text = user.bio;
    setState(() {
      loading = false;
    });
  }

  updateUserData() {
    setState(() {
      profileTextEditingController.text.trim().length < 3 ||
              profileTextEditingController.text.isEmpty
          ? _profileNameValid = false
          : _profileNameValid = true;
      (bioTextEditingController.text.trim().length > 110)
          ? _bioValid = false
          : _bioValid = true;
    });
    if (_bioValid && _profileNameValid) {
      usersReference.document(widget.currentOnlineUserId).updateData({
        "profileName": profileTextEditingController.text,
        "bio": bioTextEditingController.text,
      });
      SnackBar successSnackBar =
          SnackBar(content: Text('Profile has been updated successfully'));
      _scaffoldGlobalKey.currentState.showSnackBar(successSnackBar);
    }
  }

  profile() {
    return Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldGlobalKey,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.done, color: Colors.white, size: 30.0),
            onPressed: () async {
              Navigator.pop(context, true);
              return false;
            },
          )
        ],
      ),
      body: loading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 7.0),
                        child: CircleAvatar(
                          radius: 52.0,
                          backgroundImage: CachedNetworkImageProvider(user.url),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            createProfileNameTextField(),
                            createBioTextField()
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.only(top: 29.0, left: 50.0, right: 50.0),
                        child: RaisedButton(
                            onPressed: updateUserData,
                            child: Text("Update",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 16.0))),
                      ),
                      Padding(
                        padding: EdgeInsets.all(50),
                        child: RaisedButton(
                            onPressed: logoutUser,
                            color: Colors.red,
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.chat_bubble_outline),
                                Text("Logout",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16.0)),
                              ],
                            )),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  logoutUser() async {
    await gSignIn.signOut();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  Column createBioTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            "Bio",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          style: TextStyle(color: Colors.black),
          controller: bioTextEditingController,
          decoration: InputDecoration(
            hintText: "Write bio here",
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black)),
            hintStyle: TextStyle(color: Colors.grey),
            errorText: _bioValid ? null : "bio is short ",
          ),
        ),
      ],
    );
  }

  Column createProfileNameTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            "Profile Name",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          style: TextStyle(color: Colors.black),
          controller: profileTextEditingController,
          decoration: InputDecoration(
            hintText: "Write profilename here",
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black)),
            hintStyle: TextStyle(color: Colors.grey),
            errorText: _profileNameValid ? null : "Profile Name is short ",
          ),
        ),
      ],
    );
  }
}
