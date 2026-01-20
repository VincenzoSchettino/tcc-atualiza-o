import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final Timestamp dataCriacao; // Agora como Timestamp direto

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.dataCriacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'dataCriacao': dataCriacao,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      dataCriacao: map['dataCriacao'], // Já vem como Timestamp
    );
  }
}
