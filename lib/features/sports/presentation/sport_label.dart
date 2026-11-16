import 'package:flutter/widgets.dart';

import '../domain/sport.dart';

/// Localized sport name from the database catalog (v1.7: `names` map).
extension SportLabelX on Sport {
  String label(BuildContext context) => localizedName(Localizations.localeOf(context).languageCode);
}
