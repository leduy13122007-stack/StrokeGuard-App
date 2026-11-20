import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyLinkService {
  FamilyLinkService._();

  static final FamilyLinkService instance = FamilyLinkService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please sign in first.');
    return user.uid;
  }

  Future<void> sendInvitation({
    required String email,
    required String relationship,
  }) async {
    final sender = _auth.currentUser;
    if (sender == null) throw Exception('Please sign in first.');

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Enter a valid email address.');
    }
    if (normalizedEmail == sender.email?.toLowerCase()) {
      throw Exception('You cannot invite your own account.');
    }

    final result = await _db
        .collection('users')
        .where('emailLower', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      throw Exception('No StrokeGuard account was found for this email.');
    }

    final recipientUid = result.docs.first.id;
    final existingLinks = await _db
        .collection('familyLinks')
        .where('memberUids', arrayContains: sender.uid)
        .get();

    for (final link in existingLinks.docs) {
      final members = List<String>.from(link.data()['memberUids'] ?? []);
      if (members.contains(recipientUid)) {
        throw Exception('These accounts are already linked.');
      }
    }

    final sentInvitations = await _db
        .collection('familyInvitations')
        .where('fromUid', isEqualTo: sender.uid)
        .get();

    if (sentInvitations.docs.any((doc) =>
        doc.data()['toUid'] == recipientUid &&
        doc.data()['status'] == 'pending')) {
      throw Exception('An invitation is already pending.');
    }

    await _db.collection('familyInvitations').add({
      'fromUid': sender.uid,
      'fromEmail': sender.email ?? '',
      'fromName': sender.displayName ?? sender.email?.split('@').first ?? 'User',
      'toUid': recipientUid,
      'toEmail': normalizedEmail,
      'relationship': relationship,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchIncomingInvitations(String uid) {
    return _db
        .collection('familyInvitations')
        .where('toUid', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLinks(String uid) {
    return _db
        .collection('familyLinks')
        .where('memberUids', arrayContains: uid)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();
    return snapshot.data();
  }

  Future<void> acceptInvitation(String invitationId) async {
    final currentUid = _uid;
    final invitationRef = _db.collection('familyInvitations').doc(invitationId);

    await _db.runTransaction((transaction) async {
      final invitation = await transaction.get(invitationRef);
      if (!invitation.exists) throw Exception('Invitation no longer exists.');

      final data = invitation.data()!;
      if (data['toUid'] != currentUid) {
        throw Exception('You are not allowed to accept this invitation.');
      }
      if (data['status'] != 'pending') {
        throw Exception('This invitation has already been processed.');
      }

      final senderUid = data['fromUid'] as String;
      final members = [senderUid, currentUid]..sort();
      final linkId = '${members[0]}_${members[1]}';
      final linkRef = _db.collection('familyLinks').doc(linkId);

      transaction.set(linkRef, {
        'memberUids': members,
        'invitationId': invitationId,
        'createdAt': FieldValue.serverTimestamp(),
        'relationshipByUid': {
          senderUid: data['relationship'] ?? 'Family',
          currentUid: 'Family',
        },
      });
      transaction.update(invitationRef, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectInvitation(String invitationId) async {
    final currentUid = _uid;
    final invitationRef = _db.collection('familyInvitations').doc(invitationId);
    final snapshot = await invitationRef.get();

    if (!snapshot.exists || snapshot.data()?['toUid'] != currentUid) {
      throw Exception('Invitation not found or access denied.');
    }
    if (snapshot.data()?['status'] != 'pending') {
      throw Exception('This invitation has already been processed.');
    }

    await invitationRef.update({
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unlink(String linkId) async {
    final reference = _db.collection('familyLinks').doc(linkId);
    final snapshot = await reference.get();
    if (!snapshot.exists) return;

    final members = List<String>.from(snapshot.data()?['memberUids'] ?? []);
    if (!members.contains(_uid)) {
      throw Exception('You are not allowed to unlink this account.');
    }
    await reference.delete();
  }
}
