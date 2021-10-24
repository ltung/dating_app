import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ChatMessage2 extends StatelessWidget {
  // Variables
  final bool isUserSender;
  final String userPhotoLink;
  final bool isImage;
  final String messageType;
  final String? imageLink;
  final String? textMessage;
  final String timeAgo;

  ChatMessage2({required this.isUserSender,
    required this.userPhotoLink,
    required this.timeAgo,
    this.isImage = false,
    required this.messageType,
    this.imageLink,
    this.textMessage});

  @override
  Widget build(BuildContext context) {
    /// User profile photo
    final _userProfilePhoto = CircleAvatar(
      backgroundColor: Theme
          .of(context)
          .primaryColor,
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
                          : Theme
                          .of(context)
                          .primaryColor,
                      borderRadius: BorderRadius.circular(25)),
                  child: messageType == 'image'
                      ? GestureDetector(
                    onTap: () {
                      // Show full image
                      Navigator.of(context).push(new MaterialPageRoute(
                          builder: (context) =>
                              _ShowFullImage(imageLink!)));
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
                      : messageType == 'video'
                      ? GestureDetector(
                    onTap: () {
                      // Show full image
                      Navigator.of(context).push(
                          new MaterialPageRoute(
                              builder: (context) =>
                                  _ShowVideo(imageLink!)));
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
                          width: 100,
                          height: 100,
                          child: Hero(
                              tag: imageLink!,
                              child: Text(imageLink!))),
                    ),
                  )
                      : Text(
                    textMessage ?? "",
                    style: TextStyle(
                        fontSize: 18,
                        color: isUserSender
                            ? Colors.white
                            : Colors.black),
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

class _ShowVideo extends StatelessWidget {
  // Param
  late String imageUrl;
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  late ChewieController chewieController;

  //_ShowVideo(this.imageUrl, this._controller);
  _ShowVideo(String imageUrl) {
    this.imageUrl = imageUrl;
    _controller = VideoPlayerController.network(imageUrl);
    _initializeVideoPlayerFuture = _controller.initialize();

    chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: true,
      looping: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('def');
    debugPrint(imageUrl);
    debugPrint(_controller.dataSource);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        /*child: Center(
          child: Hero(
            tag: imageUrl,
            child: _controller.value.isInitialized
                ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                //child: VideoPlayer(_controller),
                child: Chewie(
                  controller: chewieController,
                )
            )
                : Container(width: 200.0,
              height: 100.0,
              color: Colors.green,
              child: Text('Hello! I am in the container widget',
                  style: TextStyle(fontSize: 25)),),
          ),
        ),
*/
          child: Chewie(
              controller: chewieController)
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

}
