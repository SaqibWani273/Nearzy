import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../utils/image_picker.dart';

class ImageUploadField extends StatefulWidget {
  final double imageHeight;
  final double placeholderHeight;
  final String hintText;
  final ImagePicker picker;
  final Function(Object? imgObject) onUpload;
  const ImageUploadField({
    super.key,
    required this.onUpload,
    required this.hintText,
    required this.imageHeight,
    required this.placeholderHeight,
    required this.picker,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  late final ImagePicker _picker;
  late final double imageHeight;
  late final double placeholderHeight;
  late final String hintText;
  XFile? _pic;
  Future<void> _getImage() async {
    final image = await getImage(_picker);

    if (image != null) {
      final imgUni8List = await image.readAsBytes();
      setState(() {
        _pic = image;
        widget.onUpload(kIsWeb ? imgUni8List : image.path);
      });
    } else {
      return;
    }
  }

  @override
  void initState() {
    _picker = widget.picker;
    imageHeight = widget.imageHeight;
    placeholderHeight = widget.placeholderHeight;
    hintText = widget.hintText;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: GestureDetector(
        onTap: _getImage,
        child: _pic == null
            ? Container(
                height: placeholderHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  // border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image),
                      Text(hintText),
                    ],
                  ),
                ),
              )
            : Container(
                height: imageHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: kIsWeb
                      ? Image.network(_pic!.path)
                      : Image.file(File(_pic!.path)),
                ),
              ),
      ),
    );
  }
}
