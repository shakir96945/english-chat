import 'dart:io';
import 'package:flutter/material';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/services/firebase_service.dart';
import '../core/services/zego_call_service.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseService.auth;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _userModel;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _auth.currentUser;
  UserModel? get userModel => _userModel;

  Future<void> fetchUserProfile() async {
    if (currentUser == null) return;
    final doc = await FirebaseService.usersCollection.doc(currentUser!.uid).get();
    if (doc.exists) {
      _userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String country,
    required String gender,
    required String dateOfBirth,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        UserModel newUser = UserModel(
          uid: credential.user!.uid,
          fullName: fullName,
          username: username,
          email: email,
          profilePic: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&h=120&fit=crop',
          bio: 'English Chat Premium Member',
          country: country,
          gender: gender,
          dateOfBirth: dateOfBirth,
          isOnline: true,
          lastSeen: DateTime.now(),
          dateJoined: DateTime.now(),
          blockedUsers: [],
          showOnlinePresence: true,
        );

        await FirebaseService.usersCollection
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        await credential.user!.updateDisplayName(fullName);
        _userModel = newUser;

        ZegoCallService.initZegoService(
          userId: credential.user!.uid,
          userName: fullName,
        );

        _setLoading(false);
        return true;
      }
    } catch (e) {
      _errorMessage = FirebaseService.handleException(e);
    }
    _setLoading(false);
    return false;
  }

  Future<bool> loginWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (cred.user != null) {
        await FirebaseService.usersCollection.doc(cred.user!.uid).update({
          'isOnline': true,
          'lastSeen': DateTime.now(),
        });
        await fetchUserProfile();

        ZegoCallService.initZegoService(
          userId: cred.user!.uid,
          userName: _userModel?.fullName ?? "Golden Chat User",
        );

        _setLoading(false);
        return true;
      }
    } catch (e) {
      _errorMessage = FirebaseService.handleException(e);
    }
    _setLoading(false);
    return false;
  }

  Future<void> updatePresence(bool online) async {
    if (currentUser == null) return;
    await FirebaseService.usersCollection.doc(currentUser!.uid).update({
      'isOnline': online,
      'lastSeen': DateTime.now(),
    });
    if (_userModel != null) {
      _userModel = UserModel(
        uid: _userModel!.uid,
        fullName: _userModel!.fullName,
        username: _userModel!.username,
        email: _userModel!.email,
        profilePic: _userModel!.profilePic,
        bio: _userModel!.bio,
        country: _userModel!.country,
        isOnline: online,
        lastSeen: DateTime.now(),
        dateJoined: _userModel!.dateJoined,
        blockedUsers: _userModel!.blockedUsers,
        showOnlinePresence: _userModel!.showOnlinePresence,
      );
      notifyListeners();
    }
  }

  Future<bool> editProfile({
    required String fullName,
    required String username,
    required String bio,
    required String country,
    required String gender,
    required String dateOfBirth,
  }) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      await FirebaseService.usersCollection.doc(currentUser!.uid).update({
        'fullName': fullName,
        'username': username,
        'bio': bio,
        'country': country,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
      });
      await fetchUserProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<bool> uploadProfilePicture(File imageFile) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      final ref = FirebaseService.storage
          .ref()
          .child('avatars')
          .child('${currentUser!.uid}.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      await FirebaseService.usersCollection.doc(currentUser!.uid).update({
        'profilePic': downloadUrl,
      });
      await fetchUserProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<void> togglePrivacySetting(bool showPresence) async {
    if (currentUser == null) return;
    await FirebaseService.usersCollection.doc(currentUser!.uid).update({
      'showOnlinePresence': showPresence,
    });
    await fetchUserProfile();
  }

  Future<void> blockUser(String blockUid) async {
    if (currentUser == null || _userModel == null) return;
    List<String> list = List.from(_userModel!.blockedUsers);
    if (!list.contains(blockUid)) {
      list.add(blockUid);
      await FirebaseService.usersCollection.doc(currentUser!.uid).update({
        'blockedUsers': list,
      });
      await fetchUserProfile();
    }
  }

  Future<void> unblockUser(String unblockUid) async {
    if (currentUser == null || _userModel == null) return;
    List<String> list = List.from(_userModel!.blockedUsers);
    if (list.contains(unblockUid)) {
      list.remove(unblockUid);
      await FirebaseService.usersCollection.doc(currentUser!.uid).update({
        'blockedUsers': list,
      });
      await fetchUserProfile();
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final AuthProvider googleProvider = GoogleAuthProvider();
      final UserCredential credential = await _auth.signInWithProvider(googleProvider);
      
      if (credential.user != null) {
        final doc = await FirebaseService.usersCollection.doc(credential.user!.uid).get();
        if (!doc.exists) {
          UserModel newUser = UserModel(
            uid: credential.user!.uid,
            fullName: credential.user!.displayName ?? "Google User",
            username: credential.user!.email?.split('@').first ?? "google_user",
            email: credential.user!.email ?? "",
            profilePic: credential.user!.photoURL ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&h=120&fit=crop',
            bio: 'English Chat Premium Member via Google',
            country: 'US',
            isOnline: true,
            lastSeen: DateTime.now(),
            dateJoined: DateTime.now(),
            blockedUsers: [],
            showOnlinePresence: true,
          );
          await FirebaseService.usersCollection.doc(credential.user!.uid).set(newUser.toMap());
        }
        await fetchUserProfile();
        ZegoCallService.initZegoService(
          userId: credential.user!.uid,
          userName: _userModel?.fullName ?? "Google User",
        );
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await fetchUserProfile();
          onVerificationCompleted(credential);
          _setLoading(false);
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = e.message;
          onVerificationFailed(e);
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
          _setLoading(false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> signInWithPhoneNumber(String verificationId, String smsCode) async {
    _setLoading(true);
    _clearError();
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCred = await _auth.signInWithCredential(credential);
      if (userCred.user != null) {
        final doc = await FirebaseService.usersCollection.doc(userCred.user!.uid).get();
        if (!doc.exists) {
          UserModel newUser = UserModel(
            uid: userCred.user!.uid,
            fullName: "Phone User",
            username: "phone_${userCred.user!.phoneNumber?.replaceAll('+', '')}",
            email: "",
            profilePic: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&h=120&fit=crop',
            bio: 'English Chat Premium Member via Phone',
            country: 'US',
            isOnline: true,
            lastSeen: DateTime.now(),
            dateJoined: DateTime.now(),
            blockedUsers: [],
            showOnlinePresence: true,
          );
          await FirebaseService.usersCollection.doc(userCred.user!.uid).set(newUser.toMap());
        }
        await fetchUserProfile();
        ZegoCallService.initZegoService(
          userId: userCred.user!.uid,
          userName: _userModel?.fullName ?? "Phone User",
        );
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<void> logOut() async {
    await updatePresence(false);
    ZegoCallService.deinitZegoService();
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
