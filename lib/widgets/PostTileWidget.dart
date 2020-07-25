

import 'package:Capturoca/pages/PostScreenPage.dart';
import 'package:Capturoca/widgets/PostWidget.dart';
import 'package:flutter/material.dart';

class PostTile extends StatelessWidget {
   
   displayFullPost(context){
     Navigator.push(context, MaterialPageRoute(builder:  (context)=>PostScreenPage(postId: post.postId, userId: post.ownerId)));
   }




  final Post post;
  PostTile(this.post);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=> displayFullPost(context),
      child: Image.network(post.url),
    );
  }
}
