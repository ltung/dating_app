import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating_app/api/likes_api.dart';
import 'package:dating_app/api/matches_api.dart';
import 'package:dating_app/api/messages_api.dart';
import 'package:dating_app/api/notifications_api.dart';
import 'package:dating_app/constants/constants.dart';
import 'package:dating_app/datas/user.dart';
import 'package:dating_app/dialogs/common_dialogs.dart';
import 'package:dating_app/dialogs/progress_dialog.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/screens/profile_screen.dart';
import 'package:dating_app/widgets/chat_message.dart';
import 'package:dating_app/widgets/image_source_sheet.dart';
import 'package:dating_app/widgets/my_circular_progress.dart';
import 'package:dating_app/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  /// Get user object
  final User user;

  ChatScreen({required this.user});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Variables
  final _textController = TextEditingController();
  final _messagesController = ScrollController();
  final _messagesApi = MessagesApi();
  final _matchesApi = MatchesApi();
  final _likesApi = LikesApi();
  final _notificationsApi = NotificationsApi();
  late Stream<QuerySnapshot> _messages;
  bool _isComposing = false;
  late AppLocalizations _i18n;
  late ProgressDialog _pr;

  void _scrollMessageList() {
    /// Scroll to button
    _messagesController.animateTo(0.0,
        duration: Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  /// Get image from camera / gallery
  Future<void> _getImage() async {
    await showModalBottomSheet(
        context: context,
        builder: (context) => ImageSourceSheet(
              onImageSelected: (image) async {
                if (image != null) {
                  await _sendMessage(type: 'image', imgFile: image);
                  // close modal
                  Navigator.of(context).pop();
                }
              },
            ));
  }

  // Send message
  Future<void> _sendMessage(
      {required String type, String? text, File? imgFile}) async {
    String textMsg = '';
    String imageUrl = '';

    // Check message type
    switch (type) {
      case 'text':
        textMsg = text!;
        break;

      case 'image':
        // Show processing dialog
        _pr.show(_i18n.translate("sending"));

        /// Upload image file
        imageUrl = await UserModel().uploadFile(
            file: imgFile!,
            path: 'uploads/messages',
            userId: UserModel().user.userId);

        _pr.hide();
        break;
    }

    /// Save message for current user
    await _messagesApi.saveMessage(
        type: type,
        fromUserId: UserModel().user.userId,
        senderId: UserModel().user.userId,
        receiverId: widget.user.userId,
        userPhotoLink: widget.user.userProfilePhoto, // other user photo
        userFullName: widget.user.userFullname, // other user ful name
        textMsg: textMsg,
        imgLink: imageUrl,
        isRead: true);

    /// Save copy message for receiver
    await _messagesApi.saveMessage(
        type: type,
        fromUserId: UserModel().user.userId,
        senderId: widget.user.userId,
        receiverId: UserModel().user.userId,
        userPhotoLink: UserModel().user.userProfilePhoto, // current user photo
        userFullName: UserModel().user.userFullname, // current user ful name
        textMsg: textMsg,
        imgLink: imageUrl,
        isRead: false);

    /// Send push notification
    await _notificationsApi.sendPushNotification(
        nTitle: APP_NAME,
        nBody: '${UserModel().user.userFullname}, '
            '${_i18n.translate("sent_a_message_to_you")}',
        nType: 'message',
        nSenderId: UserModel().user.userId,
        nUserDeviceToken: widget.user.userDeviceToken);
  }

  @override
  void initState() {
    super.initState();
    _messages = _messagesApi.getMessages(widget.user.userId);
  }

  @override
  void dispose() {
    _messages.drain();
    _textController.dispose();
    _messagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context);

    return Scaffold(
      appBar: AppBar(
        // Show User profile info
        title: GestureDetector(
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 0),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(widget.user.userProfilePhoto),
            ),
            title:
                Text(widget.user.userFullname, style: TextStyle(fontSize: 18)),
          ),
          onTap: () {
            /// Go to profile screen
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    ProfileScreen(user: widget.user, showButtons: false)));
          },
        ),
        actions: <Widget>[
          /// Actions list
          PopupMenuButton<String>(
            initialValue: "",
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              /// Delete Chat
              PopupMenuItem(
                  value: "delete_chat",
                  child: Row(
                    children: <Widget>[
                      SvgIcon("assets/icons/trash_icon.svg",
                          width: 20,
                          height: 20,
                          color: Theme.of(context).primaryColor),
                      SizedBox(width: 5),
                      Text(_i18n.translate("delete_conversation")),
                    ],
                  )),

              /// Delete Match
              PopupMenuItem(
                  value: "delete_match",
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.highlight_off,
                          color: Theme.of(context).primaryColor),
                      SizedBox(width: 5),
                      Text(_i18n.translate("delete_match"))
                    ],
                  )),
            ],
            onSelected: (val) {
              /// Control selected value
              switch (val) {
                case "delete_chat":

                  /// Delete chat
                  confirmDialog(context,
                      title: _i18n.translate("delete_conversation"),
                      message: _i18n.translate("conversation_will_be_deleted"),
                      negativeAction: () => Navigator.of(context).pop(),
                      positiveText: _i18n.translate("DELETE"),
                      positiveAction: () async {
                        // Close the confirm dialog
                        Navigator.of(context).pop();

                        // Show processing dialog
                        _pr.show(_i18n.translate("processing"));

                        /// Delete chat
                        await _messagesApi.deleteChat(widget.user.userId);

                        // Hide progress
                        await _pr.hide();

                      });
                  break;

                case "delete_match":
                  errorDialog(context,
                      title: _i18n.translate("delete_match"),
                      message:
                          "${_i18n.translate("are_you_sure_you_want_to_delete_your_match_with")}: "
                          "${widget.user.userFullname}?\n\n"
                          "${_i18n.translate("this_action_cannot_be_reversed")}",
                      positiveText: _i18n.translate("DELETE"),
                      negativeAction: () => Navigator.of(context).pop(),
                      positiveAction: () async {
                        // Show processing dialog
                        _pr.show(_i18n.translate("processing"));

                        /// Delete match
                        await _matchesApi.deleteMatch(widget.user.userId);

                        /// Delete chat
                        await _messagesApi.deleteChat(widget.user.userId);

                        /// Delete like
                        await _likesApi.deleteLike(widget.user.userId);

                        // Hide progress
                        _pr.hide();
                        // Hide dialog
                        Navigator.of(context).pop();
                        // Close chat screen
                        Navigator.of(context).pop();
                      });
                  break;
              }
              print("Selected action: $val");
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          /// how message list
          Expanded(child: _showMessages()),

          /// Text Composer
          Container(
            color: Colors.grey.withAlpha(50),
            child: ListTile(
                leading: IconButton(
                    icon: SvgIcon("assets/icons/camera_icon.svg",
                        width: 20, height: 20),
                    onPressed: () async {
                      /// Send image file
                      await _getImage();

                      /// Update scroll
                      _scrollMessageList();
                    }),
                title: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                      hintText: _i18n.translate("type_a_message"),
                      border: InputBorder.none),
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.isNotEmpty;
                    });
                  },
                ),
                trailing: IconButton(
                    icon: Icon(Icons.send,
                        color: _isComposing
                            ? Theme.of(context).primaryColor
                            : Colors.grey),
                    onPressed: _isComposing
                        ? () async {
                            /// Get text
                            final text = _textController.text.trim();

                            /// clear input text
                            _textController.clear();
                            setState(() {
                              _isComposing = false;
                            });

                            /// Send text message
                            await _sendMessage(type: 'text', text: text);

                            /// Update scroll
                            _scrollMessageList();
                          }
                        : null)),
          ),
        ],
      ),
    );
  }

  /// Build bubble message
  Widget _showMessages() {
    return StreamBuilder<QuerySnapshot>(
        stream: _messages,
        builder: (context, snapshot) {
          // Check data
          if (!snapshot.hasData)
            return MyCircularProgress();
          else {
            return ListView.builder(
                controller: _messagesController,
                reverse: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  // Get message list
                  final List<DocumentSnapshot> messages =
                      snapshot.data!.docs.reversed.toList();
                  // Get message doc map
                  final Map<String, dynamic> msg = messages[index].data()!;

                  /// Variables
                  bool isUserSender;
                  String userPhotoLink;
                  final bool isImage = msg[MESSAGE_TYPE] == 'image';
                  final String textMessage = msg[MESSAGE_TEXT];
                  final String? imageLink = msg[MESSAGE_IMG_LINK];
                  final String timeAgo =
                      timeago.format(msg[TIMESTAMP].toDate());

                  /// Check user id to get info
                  if (msg[USER_ID] == UserModel().user.userId) {
                    isUserSender = true;
                    userPhotoLink = UserModel().user.userProfilePhoto;
                  } else {
                    isUserSender = false;
                    userPhotoLink = widget.user.userProfilePhoto;
                  }
                  // Show chat bubble
                  return ChatMessage(
                    isUserSender: isUserSender,
                    isImage: isImage,
                    userPhotoLink: userPhotoLink,
                    textMessage: textMessage,
                    imageLink: imageLink,
                    timeAgo: timeAgo,
                  );
                });
          }
        });
  }
}
