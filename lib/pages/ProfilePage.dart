import 'package:Capturoca/models/user.dart';
import 'package:Capturoca/pages/HomePage.dart';
import 'package:Capturoca/widgets/HeaderWidget.dart';
import 'package:Capturoca/widgets/PostTileWidget.dart';
import 'package:Capturoca/widgets/PostWidget.dart';
import 'package:Capturoca/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'EditProfilePage.dart';

class ProfilePage extends StatefulWidget {
  final String userProfileId;
  ProfilePage({this.userProfileId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String currentOnlineUserId = currentUser.id;
  bool loading = false;
  int countPost = 0;
  List<Post> postsList = [];
  String postOrientation = "grid";
  int countTotalFollowers = 0;
  int countTotalFollowings = 0;
  bool following = false;

  void initState() {
    super.initState();

    getAllProfilePosts();
    getAllFollowers();
    getAllFollowing();
    checkIfAlreadyFollowing();
  }

  getAllFollowing() async {
    QuerySnapshot querySnapshot = await followingReference
        .document(widget.userProfileId)
        .collection("userFollowing")
        .getDocuments();
    setState(() {
      countTotalFollowings = querySnapshot.documents.length;
    });
  }

  checkIfAlreadyFollowing() async {
    DocumentSnapshot documentSnapshot = await followersReference
        .document(widget.userProfileId)
        .collection("userFollowers")
        .document(currentOnlineUserId)
        .get();
    setState(() {
      following = documentSnapshot.exists;
    });
  }

  getAllFollowers() async {
    QuerySnapshot querySnapshot = await followersReference
        .document(widget.userProfileId)
        .collection("userFollowers")
        .getDocuments();
    setState(() {
      countTotalFollowers = querySnapshot.documents.length;
    });
  }

  createProfileTopView() {
    return FutureBuilder(
      future: usersReference.document(widget.userProfileId).get(),
      builder: (context, dataSnapshot) {
        if (!dataSnapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(dataSnapshot.data);
        return Padding(
          padding: EdgeInsets.all(17.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 45.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.url),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            createColumns("Posts", countPost),
                            createColumns("Followers", countTotalFollowers),
                            createColumns("Following", countTotalFollowings),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            createButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 13.0),
                child: Text(user.username,
                    style: TextStyle(fontSize: 14.0, color: Colors.black)),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 5.0),
                child: Text(user.profileName,
                    style: TextStyle(fontSize: 18.0, color: Colors.black)),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 3.0),
                child: Text(user.bio,
                    style: TextStyle(fontSize: 15.0, color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }

  createColumns(String title, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
              fontSize: 20.0, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 5.0),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w300),
          ),
        ),
      ],
    );
  }

  createButton() {
    bool ownProfile = currentOnlineUserId == widget.userProfileId;
    if (ownProfile) {
      return createButtonTitleAndFunction(
        title: "Edit Profile",
        performFunction: editUserProfile,
      );
    }
    if (following) {
      return createButtonTitleAndFunction(
        title: "Unfollow",
        performFunction: controlUnfollowUser,
      );
    } else if (!following) {
      return createButtonTitleAndFunction(
        title: "Follow",
        performFunction: controlFollowUser,
      );
    }
  }

  controlUnfollowUser() {
    setState(() {
      following = false;
    });
    followersReference
        .document(widget.userProfileId)
        .collection("userFollowers")
        .document(currentOnlineUserId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    followingReference
        .document(currentOnlineUserId)
        .collection("userFollowing")
        .document(widget.userProfileId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });

    activityFeedReference
        .document(widget.userProfileId)
        .collection("feedItems")
        .document(currentOnlineUserId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
  }

  controlFollowUser() {
    setState(() {
      following = true;
    });
    followersReference
        .document(widget.userProfileId)
        .collection("userFollowers")
        .document(currentOnlineUserId)
        .setData({});
    followingReference
        .document(currentOnlineUserId)
        .collection("userFollowing")
        .document(widget.userProfileId)
        .setData({});

    activityFeedReference
        .document(widget.userProfileId)
        .collection("feedItems")
        .document(currentOnlineUserId)
        .setData({
      "type": "follow",
      "ownerId": widget.userProfileId,
      "username": currentUser.username,
      "timestamp": DateTime.now(),
      "userProfileImg": currentUser.url,
      "userId": currentOnlineUserId
    });
  }

// createButtonTitleAndFunction(title: "Edit Profile", performFunction: editUserProfile,);
  createButtonTitleAndFunction({String title, Function performFunction}) {
    return Container(
      child: FlatButton(
        onPressed: performFunction,
        child: Container(
          width: 200.0,
          height: 26.0,
          child: Text(
            title,
            style: TextStyle(
                color: following ? Colors.grey : Colors.red,
                fontWeight: FontWeight.bold),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: following ? Colors.black : Colors.indigo,
            border: Border.all(color: following ? Colors.grey : Colors.white70),
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
      ),
    );
  }

  editUserProfile() async {
    var navigationResult = await Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) =>
                EditProfilePage(currentOnlineUserId: currentOnlineUserId)));
    // Navigator.push(context, MaterialPageRoute(builder: (context)=> new EditProfilePage(currentOnlineUserId: currentOnlinUserId)));
    // Navigator.of(context).push(new MaterialPageRoute(builder: (_)=>new EditProfilePage(currentOnlineUserId: currentOnlinUserId)),);
    if (navigationResult) {
      showDialog(
          context: context,
          builder: (context) {
            Future.delayed(Duration(seconds: 2), () {
              Navigator.of(context).pop(true);
            });
            return AlertDialog(
              title: Text('Succesfully Saved'),
            );
          });
      setState(() {
        // this.l=true;
      });
    } else if (navigationResult == null) {
      showDialog(
          context: context,
          builder: (context) {
            Future.delayed(Duration(seconds: 2), () {
              Navigator.of(context).pop(true);
            });
            return AlertDialog(
              title: Text('Welcome Back'),
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(
        context,
        strTitle: "Profile",
      ),
      body: ListView(
        children: <Widget>[
          createProfileTopView(),
          Divider(),
          createListAndGridPostOrientation(),
          Divider(
            height: 0.0,
          ),
          displayProfilePost(),
        ],
      ),
    );
  }

  displayProfilePost() {
    if (loading) {
      return circularProgress();
    } else if (postsList.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(30.0),
              child: Icon(Icons.photo_library, color: Colors.grey, size: 200.0),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text("No Post",
                  style: TextStyle(
                      color: Colors.indigoAccent,
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTilesList = [];
      postsList.forEach((eachPost) {
        gridTilesList.add(GridTile(child: PostTile(eachPost)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTilesList,
      );
      //   return Column(
      //   children: postsList,
      // );

    } else if (postOrientation == "list") {
      return Column(
        children: postsList,
      );
    }
  }

  getAllProfilePosts() async {
    setState(() {
      loading = true;
    });
    QuerySnapshot querySnapshot = await postsReference
        .document(widget.userProfileId)
        .collection("usersPosts")
        .orderBy("timestamp", descending: true)
        .getDocuments();
    setState(() {
      loading = false;
      countPost = querySnapshot.documents.length;
      postsList = querySnapshot.documents
          .map((documentSnapshot) => Post.fromDocument(documentSnapshot))
          .toList();
    });
  }

  createListAndGridPostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
            icon: Icon(
              Icons.grid_on,
              color: postOrientation == "grid"
                  ? Theme.of(context).accentColor
                  : Colors.grey,
            ),
            onPressed: () => setOrientaton("grid")),
        IconButton(
            icon: Icon(
              Icons.list,
              color: postOrientation == "list"
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            onPressed: () => setOrientaton("list")),
      ],
    );
  }

  setOrientaton(String orientation) {
    setState(() {
      this.postOrientation = orientation;
    });
  }
}
