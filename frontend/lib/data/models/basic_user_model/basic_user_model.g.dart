// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basic_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BasicUserModel _$BasicUserModelFromJson(Map<String, dynamic> json) =>
    BasicUserModel(
      id: (json['id'] as num?)?.toInt(),
      username: json['username'] as String,
      password: json['password'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$BasicUserModelToJson(BasicUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'password': instance.password,
      'email': instance.email,
    };
