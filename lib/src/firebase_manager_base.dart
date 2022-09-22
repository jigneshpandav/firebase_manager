// TODO: Put public facing types in this file.

/// Checks if you are awesome. Spoiler: you are.
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../utils/urls.dart';

class FirebaseManager {
  String? _token;
  String? _userId;
  User? user;
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool get isAuthenticated {
    return token != null;
  }

  final String apiKey;

  FirebaseManager({
    required this.apiKey,
  });

  String? get token {
    return _token;
  }

  String? get userId {
    return _userId;
  }

  Future signInCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("$loginUrl?key=$apiKey");
      final response = await http.post(
        url,
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future singUpWithCredentials({
    required Map<String, dynamic>? body,
    required Map<String, dynamic>? firebaseUserData,
  }) async {
    try {
      final url = Uri.parse("$signUpUrl?key=$apiKey");
      final response = await http.post(
        url,
        body: jsonEncode(body),
      );
      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      print(_userId);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .set(firebaseUserData!);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future googleSignUp() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    try {
      return googleSignInAccount;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future checkSignInMethodsForEmail({
    required String email,
    required GoogleSignInAccount googleSignInAccount,
  }) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    var d = await auth.fetchSignInMethodsForEmail(googleSignInAccount.email);
    print(d);
    return d;
  }

  Future linkAccWithCredential({
    required String email,
    required String password,
    required GoogleSignInAccount googleSignInAccount,
  }) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    try {
      await signInCredentials(
        email: email,
        password: password,
      ).then((value) async {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential userCredential = await auth.signInWithCredential(
          credential,
        );
        user = userCredential.user;
        _userId = user!.uid;
        _token = googleSignInAuthentication.idToken;

        await auth.currentUser?.linkWithCredential(
          EmailAuthProvider.credential(
            email: email,
            password: password,
          ),
        );
        return user;
      });
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future signUpWithGoogle({
    required GoogleSignInAccount googleSignInAccount,
    required Map<String, dynamic> firebaseUserData,
  }) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );
    try {
      final UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );
      user = userCredential.user;
      _userId = user!.uid;
      _token = googleSignInAuthentication.idToken;
      if (user != null) {
        return await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(firebaseUserData);
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future getUser({
    required String userId,
  }) async {
    try {
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
    } catch (error) {
      rethrow;
    }
  }

  Future create({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await FirebaseFirestore.instance.collection(collection).add(data);
    } catch (err) {
      rethrow;
    }
  }

  Future update({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .update(data);
    } catch (err) {
      rethrow;
    }
  }

  Future delete({
    required String collection,
    required String id,
  }) async {
    try {
      return await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .delete();
    } catch (err) {
      rethrow;
    }
  }

  Future get({
    required String collection,
    String? field,
    bool order = false,
  }) async {
    try {
      var query = FirebaseFirestore.instance.collection(
        collection,
      );

      if (field != null) {
        return await query
            .orderBy(
              field,
              descending: order,
            )
            .get();
      } else {
        return await query.get();
      }
    } catch (err) {
      rethrow;
    }
  }

  Future storeAsset({
    required String collection,
    required String path,
  }) async {
    try {
      return FirebaseStorage.instance.ref().child(collection).child(path);
    } catch (err) {
      rethrow;
    }
  }
}
