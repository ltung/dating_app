import 'dart:io';

import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImageSourceSheet extends StatelessWidget {
  // Constructor
  ImageSourceSheet({required this.onImageSelected});

  // Callback function to return image file
  final Function(File?) onImageSelected;
  // ImagePicker instance
  final picker = ImagePicker();

  Future<void> selectedImage(BuildContext context, File? image) async {
    // init i18n
    final i18n = AppLocalizations.of(context);

    // Check file
    if (image != null) {
      final croppedImage = await ImageCropper.cropImage(
          sourcePath: image.path,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          maxWidth: 400,
          maxHeight: 400,
          androidUiSettings: AndroidUiSettings(
            toolbarTitle: i18n.translate("edit_crop_image"),
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
          ));
      onImageSelected(croppedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return BottomSheet(
        onClosing: () {},
        builder: ((context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                /// Select image from gallery
                TextButton.icon(
                  icon: Icon(Icons.photo_library, color: Colors.grey, size: 27),
                  label: Text(i18n.translate("gallery"),
                      style: TextStyle(fontSize: 16)),
                  onPressed: () async {
                    // Get image from device gallery
                    final pickedFile = await picker.getImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile == null) return;
                    selectedImage(context, File(pickedFile.path));
                  },
                ),

                /// Capture image from camera
                TextButton.icon(
                  icon: SvgIcon("assets/icons/camera_icon.svg",
                      width: 20, height: 20),
                  label: Text(i18n.translate("camera"),
                      style: TextStyle(fontSize: 16)),
                  onPressed: () async {
                    // Capture image from camera
                    final pickedFile = await picker.getImage(
                      source: ImageSource.camera,
                    );
                    if (pickedFile == null) return;
                    selectedImage(context, File(pickedFile.path));
                  },
                ),
              ],
            )));
  }
}
