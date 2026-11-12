import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../domain/contact.dart';

/// Scoped projection from the `getGroupContacts` callable. Phone numbers are
/// never read from user documents and never logged.
class FirebaseContactsRepository implements ContactsRepository {
  FirebaseContactsRepository(this.functions);

  final FirebaseFunctions functions;

  @override
  Future<List<GroupContact>> groupContacts(String groupId) => guardFirebase(() async {
    final r = await functions.httpsCallable('getGroupContacts').call<Map<String, dynamic>>({'groupId': groupId});
    final list = (r.data['contacts'] as List?) ?? const [];
    return [for (final m in list) GroupContact.fromMap(Map<String, dynamic>.from(m as Map))];
  });
}
