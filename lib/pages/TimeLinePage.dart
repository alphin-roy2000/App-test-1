import 'package:Capturoca/models/user.dart';
import 'package:Capturoca/pages/HomePage.dart';
import 'package:Capturoca/widgets/HeaderWidget.dart';
import 'package:Capturoca/widgets/PostWidget.dart';
import 'package:Capturoca/widgets/ProgressWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TimeLinePage extends StatefulWidget {
  final User gCurrentUser;
  TimeLinePage({this.gCurrentUser});

  @override
  _TimeLinePageState createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage> {
  List<Post> posts;
  List<String> followingsList = [];

  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    retrieveTimeLine();
    retrieveFollowing();
  }

  retrieveTimeLine() async {
    QuerySnapshot querySnapshot = await timelinereference
        .document(widget.gCurrentUser.id)
        .collection("timelinePosts")
        .orderBy("timestamp", descending: true)
        .getDocuments();
    List<Post> allPosts = querySnapshot.documents
        .map((document) => Post.fromDocument(document))
        .toList();
    setState(() {
      this.posts = allPosts;
      print(posts.length);
    });
  }

  retrieveFollowing() async {
    QuerySnapshot querySnapshot = await followingReference
        .document(currentUser.id)
        .collection("userFollowing")
        .getDocuments();
    setState(() {
      followingsList = querySnapshot.documents
          .map((document) => document.documentID)
          .toList();
    });
  }

  createUserTimeLine() {
    if (posts == null) {
      return circularProgress();
    } else {
      return ListView(
        children: posts,
      );
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
        key: scaffoldKey,
        appBar: header(
          context,
          isAppTitle: true,
        ),
        body: RefreshIndicator(
            child: createUserTimeLine(), onRefresh: () => retrieveTimeLine()));
  }
}
