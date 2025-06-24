import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deep_link_service/deep_link_service.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../services/auth_service.dart';
import '../../../domain/models/referral.dart';

class ReferralController extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseFirestore _firestore;
  final DeepLinkService _deepLinkService;

  ReferralController({
    required AuthService authService,
    required FirebaseFirestore firestore,
    required DeepLinkService deepLinkService,
  })  : _authService = authService,
        _firestore = firestore,
        _deepLinkService = deepLinkService {
    _init();
  }

  bool _isLoading = true;
  bool _isSharing = false;
  String? _referralCode;
  String? _referralLink;
  List<Referral> _referrals = [];

  bool get isLoading => _isLoading;
  bool get isSharing => _isSharing;
  String? get referralCode => _referralCode;
  String? get referralLink => _referralLink;
  List<Referral> get referrals => _referrals;

  Future<void> _init() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Get or create referral code
      _referralCode = await _getOrCreateReferralCode(user.uid);
      
      // Generate deep link
      _referralLink = await _deepLinkService.createDynamicLink(
        path: '/referral',
        parameters: {'code': _referralCode!},
      );

      // Load referral history
      await _loadReferrals(user.uid);
    } catch (e) {
      debugPrint('Referral init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _getOrCreateReferralCode(String userId) async {
    final doc = await _firestore.collection('user_referrals').doc(userId).get();
    
    if (doc.exists && doc.data()?['code'] != null) {
      return doc.data()!['code'];
    }

    // Generate new code if doesn't exist
    final newCode = _generateReferralCode();
    await _firestore.collection('user_referrals').doc(userId).set({
      'code': newCode,
      'created_at': FieldValue.serverTimestamp(),
      'referral_count': 0,
    }, SetOptions(merge: true));

    return newCode;
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  Future<void> _loadReferrals(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('referrals')
          .where('referrer_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      _referrals = snapshot.docs
          .map((doc) => Referral.fromFirestore(doc))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading referrals: $e');
    }
  }

  void navigateToReferralList() {
    AppRouter.pushNamed('/referrals/list');
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _init();
  }

  set isSharing(bool value) {
    _isSharing = value;
    notifyListeners();
  }
}