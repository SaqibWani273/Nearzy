import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '/constants/rest_api_const.dart';
import '/utils/exceptions/custom_exception.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart' as IC;

const maxImageSizeForCloudinary = 10485760; //10mb

class CloudinaryService {
  static Future<String> uploadImage(Object image) async {
    try {
      //compressing image for cloudinary upload
      final compressedImageObject = kIsWeb
          ? await compressImageUsingUnit8List(image as Uint8List)
          : await compressImageUsingPath(image as String);
      var request = http.MultipartRequest(
          'POST', Uri.parse(CloudinaryApiConst.cloudinaryImageUploadUrl));
      request.fields['public_id'] = DateTime.now().toString();

      request.fields['api_key'] = CloudinaryApiConst.cloudinaryApiKey;
      request.fields['upload_preset'] = 'test_preset';
      // final imageBytes = await ImageData(category.image).data;
      // final imageBytes = await (category.image as XFile).readAsBytes();
      var multipartFile =
          // await kIsWeb ?
          http.MultipartFile.fromBytes(
              'file', compressedImageObject as Uint8List,
              filename: "test ${DateTime.now()}");
      // : await http.MultipartFile.fromPath(
      //     'file', compressedImageObject as String,
      //     filename: "test ${DateTime.now()}");

      request.files.add(multipartFile);
      final response = await request.send();
      final decodeResponse = await http.Response.fromStream(response);

      if (response.statusCode == 400) {
        log(decodeResponse.body);
        throw CustomException(
            message: decodeResponse.body, errorType: ErrorType.unknown);
      }
      if (response.statusCode != 200) {
        log("${response.statusCode} -> ${decodeResponse.body}");
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message:
                'Something went wrong! Please check your internet connection.');
      }
      log("${response.statusCode} -> ${decodeResponse.body}");
      final json = jsonDecode(decodeResponse.body);
      return json['url'];
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<String>> uploadMultipleImages(List<Object> images) async {
    try {
      final List<String> urls =
          await Future.wait(images.map((e) => uploadImage(e)));
      return urls;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Uint8List> compressImageUsingPath(String imagePath) async {
    try {
      Uint8List compressesdImage;
      do {
        final result =
            await IC.FlutterImageCompress.compressWithFile(imagePath);
        compressesdImage = result!;
      } while (compressesdImage.length > maxImageSizeForCloudinary);

      return compressesdImage;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Uint8List> compressImageUsingUnit8List(
      Uint8List unit8List) async {
    try {
      Uint8List compressesdImage;
      do {
        final result =
            await IC.FlutterImageCompress.compressWithList(unit8List);
        compressesdImage = result;
      } while (compressesdImage.length > maxImageSizeForCloudinary);

      return compressesdImage;
    } catch (e) {
      rethrow;
    }
  }
}
