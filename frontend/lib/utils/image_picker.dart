import 'package:image_picker/image_picker.dart';

Future<XFile?> getImage(ImagePicker picker) async {
  // final ImagePicker _picker = ImagePicker();
  try {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || pickedFile.path.isEmpty) {
      return null;
    }
    // final  imageBytes = await pickedFile.readAsBytes();
    return pickedFile;
  } catch (e) {
    return null;
  }
}
