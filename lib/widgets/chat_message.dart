import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  // Variables
  final bool isUserSender;
  final String userPhotoLink;
  final bool isImage;
  final String? imageLink;
  final String? textMessage;
  final String timeAgo;

  ChatMessage(
      {required this.isUserSender,
      required this.userPhotoLink,
      required this.timeAgo,
      this.isImage = false,
      this.imageLink,
      this.textMessage});

  @override
  Widget build(BuildContext context) {
    /// User profile photo
    final _userProfilePhoto = CircleAvatar(
      backgroundColor: Theme.of(context).primaryColor,
      backgroundImage: NetworkImage(userPhotoLink),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Row(
        children: <Widget>[
          /// User receiver photo Left
          !isUserSender ? _userProfilePhoto : Container(width: 0, height: 0),

          SizedBox(width: 10),

          /// User message
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isUserSender
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                /// Message container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: !isUserSender

                          /// Color for receiver
                          ? Colors.grey.withAlpha(70)

                          /// Color for sender
                          : Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(25)),
                  child: isImage
                      ? GestureDetector(
                          onTap: () {
                            // Show full image
                            Navigator.of(context).push(
                              new MaterialPageRoute(
                                builder: (context) => _ShowFullImage(imageLink!))
                            );
                          },
                          child: Card(
                            /// Image
                            semanticContainer: true,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            margin: const EdgeInsets.all(0),
                            color: Colors.grey.withAlpha(70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                                width: 200,
                                height: 200,
                                child: Hero(
                                  tag: imageLink!,
                                  child: Image.network(imageLink!))),
                          ),
                        )

                      /// Text message
                      : Text(
                          textMessage ?? "",
                          style: TextStyle(
                              fontSize: 18,
                              color:
                                  isUserSender ? Colors.white : Colors.black),
                          textAlign: TextAlign.center,
                        ),
                ),

                SizedBox(height: 5),

                /// Message time ago
                Container(
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    child: Text(timeAgo)),
              ],
            ),
          ),
          SizedBox(width: 10),

          /// Current User photo right
          isUserSender ? _userProfilePhoto : Container(width: 0, height: 0),
        ],
      ),
    );
  }
}

// Show chat image on full screen
class _ShowFullImage extends StatelessWidget {
  // Param
  final String imageUrl;

  _ShowFullImage(this.imageUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
