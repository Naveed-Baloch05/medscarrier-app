class DeliveryOcrResult {
  const DeliveryOcrResult({
    required this.rawText,
    required this.address,
    this.recipientName = '',
    this.phoneNumber = '',
    this.referenceId = '',
    this.city = '',
    this.postcode = '',
    this.notes = '',
  });

  final String rawText;
  final String address;
  final String recipientName;
  final String phoneNumber;
  final String referenceId;
  final String city;
  final String postcode;
  final String notes;

  bool get isValid => address.trim().length >= 4;

  @override
  String toString() {
    return 'DeliveryOcrResult('
        'name: $recipientName, '
        'phone: $phoneNumber, '
        'address: $address, '
        'city: $city, '
        'postcode: $postcode, '
        'notes: $notes, '
        'ref: $referenceId)';
  }
}

class DeliveryAddressOcrParser {
  DeliveryAddressOcrParser._();

  static const List<String> _knownCities = [
    // UK Cities & Major Towns
    'London',
    'Birmingham',
    'Manchester',
    'Leeds',
    'Glasgow',
    'Liverpool',
    'Bristol',
    'Sheffield',
    'Newcastle',
    'Nottingham',
    'Leicester',
    'Coventry',
    'Bradford',
    'Southampton',
    'Plymouth',
    'Reading',
    'Norwich',
    'Oxford',
    'Cambridge',
    'York',
    'Edinburgh',
    'Cardiff',
    'Swansea',
    'Belfast',
    'Derby',
    'Bournemouth',
    'Brighton',
    'Hull',
    'Stoke',
    'Wolverhampton',
    'Sunderland',
    'Middlesbrough',
    'Blackpool',
    'Ipswich',
    'Peterborough',
    'Stockport',
    'Bolton',
    'Preston',
    'Warrington',
    'Wigan',
    'Barnsley',
    'Rotherham',
    'Blackburn',
    'Milton Keynes',
    'Luton',
    'Swindon',
    'Aberdeen',
    'Dundee',
    'Exeter',
    'Bath',
    'Canterbury',
    'Chelmsford',
    'Colchester',
    'Gloucester',
    'Lincoln',
    'Northampton',
    'Portsmouth',
    'Salford',
    'Southend',
    'St Albans',
    'Telford',
    'Wakefield',
    'Worcester',
    'Solihull',
    'Dudley',
    'Walsall',
    'West Bromwich',
    'Sutton Coldfield',
    'Halesowen',
    'Stourbridge',

    // Pakistan fallback
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Gujranwala',
  ];

  /// Unambiguous street-type suffixes. A whole-word match on any of
  /// these is treated as strong, standalone evidence that a line is
  /// part of a postal address.
  static const List<String> _strongAddressKeywords = [
    'street',
    'st',
    'road',
    'rd',
    'lane',
    'avenue',
    'ave',
    'close',
    'cl',
    'drive',
    'dr',
    'way',
    'court',
    'ct',
    'place',
    'pl',
    'terrace',
    'ter',
    'walk',
    'row',
    'mews',
    'gardens',
    'garden',
    'square',
    'sq',
    'parade',
    'wharf',
    'yard',
    'meadow',
    'grove',
    'grv',
    'crescent',
    'cres',
    'boulevard',
    'blvd',
    'circuit',
    'circle',
    'flat',
    'unit',
    'apartment',
    'apt',
    'suite',
    'floor',
    'sector',
    'block',
    'phase',
    'colony',
    'scheme',
    'cantt',
    'gulberg',
  ];

  /// Generic English words that also happen to appear in addresses
  /// (e.g. "Hill", "Park", "Green", "House"). On their own these are
  /// too common in ordinary sentences / delivery notes ("leave in
  /// porch area", "ring bell at side door", "green bin") to be trusted
  /// as address evidence. They only count when paired with extra
  /// evidence (a digit in the line, or the line reading like a proper
  /// noun / place name rather than a full sentence).
  static const List<String> _weakAddressKeywords = [
    'hill',
    'gate',
    'park',
    'view',
    'rise',
    'green',
    'croft',
    'glen',
    'dene',
    'side',
    'end',
    'bridge',
    'chase',
    'field',
    'heath',
    'moor',
    'vale',
    'cottage',
    'villa',
    'house',
    'building',
    'bldg',
    'town',
    'estate',
    'area',
    'district',
    'borough',
    'suburb',
    'quarter',
    'dha',
  ];

  static const List<String> _addressKeywords = [
    ..._strongAddressKeywords,
    ..._weakAddressKeywords,
  ];

  /// Regex for a full UK postcode.
  ///
  /// Examples:
  /// B13 8XX
  /// SW1A 1AA
  /// EC1A 1BB
  /// M1 1AA
  /// W1A 1AA
  static final RegExp _ukPostcodeFullRegex = RegExp(
    r'\b([A-Z]{1,2}\d[A-Z\d]?)\s*(\d[A-Z]{2})\b',
    caseSensitive: false,
  );

  /// Regex for UK outward code on its own.
  ///
  /// Examples:
  /// B13
  /// SW1A
  /// M1
  /// EC1A
  /// W1A
  static final RegExp _ukOutcodeRegex = RegExp(
    r'^[A-Z]{1,2}\d[A-Z\d]?$',
    caseSensitive: false,
  );

  /// UK phone numbers.
  static final RegExp _phoneRegex = RegExp(
    r'(?:(?:\+44\s?|0044\s?|0)(?:7\d{3}|[1238]\d{2,3})[\s\-]?\d{3,4}[\s\-]?\d{3,4}|\b03\d{2}[\s\-]?\d{7}\b|\b0300[\s\-]?\d{7}\b|\b0\d{10}\b)',
    caseSensitive: false,
  );

  /// Tracking / order references.
  static final RegExp _trackingRegex = RegExp(
    r'\b[A-Z]{2}\d{9}[A-Z]{2}\b',
    caseSensitive: false,
  );

  static final RegExp _orderRefPrefixRegex = RegExp(
    r'\b(?:tracking|order|ref|invoice|id|ord|trk|pkg)'
    r'[\s#:\-]*([A-Za-z0-9\-]{4,20})',
    caseSensitive: false,
  );

  /// House/building number followed by a real street-like name
  /// (at least two more words), e.g. "287 Brook Lane" or
  /// "10 Downing Street". Deliberately requires 2+ trailing words so
  /// that unrelated short numeric phrases like "4 items", "2 tablets"
  /// or "3 units" are NOT mistaken for an address line.
  static final RegExp _houseNumberStreetRegex = RegExp(
    r'^\d+[a-z]?\s+[a-z]+\s+[a-z]+',
    caseSensitive: false,
  );

  /// A line that looks like a proper-noun / place-name phrase rather
  /// than a full sentence, e.g. "Gulberg Green" or "Fox Hill Estate".
  /// Used to gate weak address keywords.
  static final RegExp _properNounPhraseRegex = RegExp(
    r"^[A-Z][A-Za-z0-9\-']*(\s+[A-Z0-9][A-Za-z0-9\-']*){0,4}$",
  );

  static const String _streetTypeAlternation =
      r'street|st|road|rd|lane|avenue|ave|close|cl|drive|dr|way|'
      r'court|ct|place|pl|terrace|ter|walk|row|mews|gardens|garden|'
      r'square|sq|parade|wharf|yard|meadow|grove|grv|crescent|cres|'
      r'boulevard|blvd|circuit|circle';

  /// House number + street name inside a larger OCR blob.
  static final RegExp _embeddedStreetRegex = RegExp(
    r'\b(\d+[a-z]?\s+[A-Za-z][A-Za-z0-9\-]*(?:\s+[A-Za-z][A-Za-z0-9\-]*){0,3}'
    r'\s+(?:' +
        _streetTypeAlternation +
        r'))\b',
    caseSensitive: false,
  );

  static final RegExp _flatUnitRegex = RegExp(
    r'\b(?:flat|unit|apartment|apt|suite|room|floor)\s+[0-9a-z\-]+\b',
    caseSensitive: false,
  );

  static final RegExp _titledNameRegex = RegExp(
    r"\b(?:Miss|Mrs\.?|Ms\.?|Mr\.?|Dr\.?|Mx\.?|Sir|Lady|Lord|Prof\.?)\s+[A-Z][A-Za-z\-']+(?:\s+[A-Z][A-Za-z\-']+){0,3}\b",
  );

  static final RegExp _trailingOutcodeRegex = RegExp(
    r'\b([A-Z]{1,2}\d[A-Z\d]?)$',
    caseSensitive: false,
  );

  /// Normalizes a UK postcode.
  static String normalizeUKPostcode(String raw) {
    final clean = raw.trim().toUpperCase();

    final match = _ukPostcodeFullRegex.firstMatch(clean);

    if (match != null) {
      final outcode = match.group(1)!;
      final incode = match.group(2)!;

      return '$outcode $incode';
    }

    if (_ukOutcodeRegex.hasMatch(clean)) {
      return clean;
    }

    return clean;
  }

  /// Checks whether a string contains a UK postcode.
  static bool containsUKPostcode(String text) {
    if (_ukPostcodeFullRegex.hasMatch(text)) {
      return true;
    }

    final trimmed = text.trim();

    return _ukOutcodeRegex.hasMatch(trimmed) && trimmed.length <= 5;
  }

  /// Checks if a line is courier / service / label noise.
  static bool isCourierNoise(String line) {
    final lower = line.toLowerCase().trim();

    if (lower.isEmpty) {
      return false;
    }

    // Isolated year or date.
    if (RegExp(
      r'^(?:20\d\d|\d{1,2}[/-]\d{1,2}[/-]\d{2,4})$',
    ).hasMatch(lower)) {
      return true;
    }

    // Mostly numeric barcode / tracking line.
    final digitsOnly = lower.replaceAll(RegExp(r'[^0-9]'), '');

    final compactLine = lower.replaceAll(
      RegExp(r'[\s\-]'),
      '',
    );

    if (digitsOnly.length >= 8 &&
        digitsOnly.length == compactLine.length) {
      return true;
    }

    const noisePhrases = [
      'collection service',
      'service collection',
      'service: collection',
      'service - collection',
      'service collection',
      'delivery service',
      'service: delivery',
      'return service',
      'service: return',
      'return address',
      'returns',
      'royal mail',
      'royal mail tracked',
      'tracked 24',
      'tracked 48',
      'special delivery',
      'signed for',
      'next day',
      'first class',
      'second class',
      'dpd',
      'dpd next day',
      'hermes',
      'evri',
      'evri parcelshop',
      'parcelshop',
      'yodel',
      'parcelforce',
      'ups',
      'fedex',
      'amazon',
      'shipping label',
      'dispatch',
      'dispatched',
      'medscarrier',
      'prescription',
      'dispensing label',
      'patient pack',
      'rx only',
      'postnl international',
      'postnl',
      'barcode',
    ];

    for (final phrase in noisePhrases) {
      if (lower == phrase ||
          lower.startsWith('$phrase ') ||
          lower.endsWith(' $phrase') ||
          lower.contains(' $phrase ') ||
          lower.contains('$phrase:') ||
          lower.startsWith('$phrase:')) {
        return true;
      }
    }

    // Generic service labels.
    //
    // These are intentionally restricted to lines that look like labels.
    // We do NOT reject every line containing "service" or "collection"
    // because those words could theoretically occur in a real address.
    if (RegExp(
      r'^(?:service|type|method|shipping|delivery|dispatch|collection)'
      r'\s*[:\-]\s*[a-z ]+$',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return true;
    }

    if (RegExp(
      r'^(?:service|collection|delivery|dispatch)'
      r'\s+(?:service|only|label|method)$',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return true;
    }

    // Purely numeric-with-unit lines, e.g. "2 tablets", "4 items",
    // "24 hours", "3 units". These match the old loose house-number
    // regex but are never real address lines.
    if (RegExp(
      r'^\d+\s*(?:x\s*)?(?:item|items|tablet|tablets|capsule|capsules|'
      r'unit|units|box|boxes|pack|packs|pcs|piece|pieces|qty|hour|'
      r'hours|day|days|kg|g|mg|ml|l)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return true;
    }

    return false;
  }

  /// Checks if a line is a safety warning or delivery instruction.
  static bool isPharmaOrDeliveryNote(String line) {
    final lower = line.toLowerCase().trim();

    const notePhrases = [
      'keep out of reach',
      'sight of children',
      'reach & sight',
      'reach and sight',
      'leave in safe place',
      'leave in porch',
      'leave with neighbour',
      'leave with neighbor',
      'leave at reception',
      'leave behind gate',
      'safe place',
      'do not leave',
      'signature required',
      'fragile',
      'handle with care',
      'keep refrigerated',
      'controlled drug',
      'temperature controlled',
      'not suitable for children',
      'store below 25',
      'store in refrigerator',
      'protect from light',
      'for external use only',
      'take with food',
      'ring bell',
      'ring the bell',
      'side door',
      'back door',
      'front door',
      'porch area',
      'bin area',
      'gate code',
      'buzzer',
      'intercom',
    ];

    return notePhrases.any(
          (phrase) => lower.contains(phrase),
    );
  }

  /// Checks if a line is likely a recipient person name.
  static bool isLikelyPersonName(String line) {
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      return false;
    }

    if (isCourierNoise(trimmed) ||
        isPharmaOrDeliveryNote(trimmed)) {
      return false;
    }

    final prefixMatch = RegExp(
      r'^(?:to|recipient|customer|deliver\s+to|attn)'
      r'[\s:\-]+',
      caseSensitive: false,
    ).firstMatch(trimmed);

    final textWithoutPrefix = prefixMatch != null
        ? trimmed.substring(prefixMatch.end).trim()
        : trimmed;

    if (textWithoutPrefix.isEmpty) {
      return false;
    }

    // Names should not contain digits or address punctuation.
    if (textWithoutPrefix.contains(
      RegExp(
        r'[0-9@#\$%^&*()_+={}\[\]|;:"<>\/?\\]',
      ),
    )) {
      return false;
    }

    if (isCourierNoise(textWithoutPrefix) ||
        isPharmaOrDeliveryNote(textWithoutPrefix)) {
      return false;
    }

    // Formal title.
    if (RegExp(
      r'^(?:Miss|Mrs\.?|Ms\.?|Mr\.?|Dr\.?|Mx\.?|Sir|Lady|Lord|Prof\.?)\b',
      caseSensitive: false,
    ).hasMatch(textWithoutPrefix)) {
      return true;
    }

    final lower = textWithoutPrefix.toLowerCase();

    final hasStreet = _addressKeywords.any(
          (kw) => RegExp(r'\b' + RegExp.escape(kw) + r'\b')
          .hasMatch(lower),
    );

    final hasCity = _knownCities.any(
          (c) => lower == c.toLowerCase(),
    );

    if (hasStreet || hasCity) {
      return false;
    }

    // Explicit recipient labels are strong evidence.
    if (prefixMatch != null) {
      return true;
    }

    final words = textWithoutPrefix
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.length >= 2 &&
        words.length <= 4 &&
        textWithoutPrefix.length >= 4 &&
        textWithoutPrefix.length <= 35) {
      final allLetters = words.every(
            (w) => RegExp(
          r"^[A-Z][A-Za-z\-\.']+$",
        ).hasMatch(w),
      );

      if (allLetters) {
        return true;
      }
    }

    return false;
  }

  /// Checks if a line is likely to be a genuine address component.
  static bool isLikelyAddressLine(String line) {
    final lower = line.toLowerCase().trim();

    if (lower.isEmpty) {
      return false;
    }

    // Never allow known noise into the address.
    if (isCourierNoise(line) ||
        isPharmaOrDeliveryNote(line)) {
      return false;
    }

    // Postcode.
    if (containsUKPostcode(line)) {
      return true;
    }

    // Known city/town.
    for (final city in _knownCities) {
      if (lower == city.toLowerCase()) {
        return true;
      }
    }

    // Flat / Unit / Apartment / Suite / Room / Floor / Building.
    if (RegExp(
      r'^(?:flat|unit|apartment|apt|suite|room|floor|building)'
      r'\s+[0-9a-z\-]+',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return true;
    }

    // House/building number followed by a real street name.
    //
    // Examples:
    // 287 Brook Lane
    // 15 High Street
    // 10 Downing Street
    //
    // Requires 2+ trailing words so that non-address numeric phrases
    // like "4 items" or "2 tablets" are rejected (they are also
    // caught earlier by isCourierNoise, this is a second safety net).
    if (_houseNumberStreetRegex.hasMatch(lower)) {
      return true;
    }

    // Locality / sector / block.
    if (RegExp(
      r'\b(?:phase|sector|block|gulberg|dha|cantt)'
      r'\s+[0-9a-zivx\-]+',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return true;
    }

    // Strong, unambiguous street suffix / address keyword.
    final hasStrongKeyword = _strongAddressKeywords.any(
          (kw) => RegExp(
        r'\b' + RegExp.escape(kw) + r'\b',
      ).hasMatch(lower),
    );

    if (hasStrongKeyword) {
      return true;
    }

    // Weak / generic keyword (e.g. "Hill", "Park", "Green", "House").
    // Only trust these when there's extra evidence the line is a
    // place name rather than an ordinary sentence or delivery note:
    // either it contains a digit (house/plot number, sector number),
    // or the whole line reads like a proper-noun phrase (each word
    // capitalized, short, no sentence punctuation).
    final hasWeakKeyword = _weakAddressKeywords.any(
          (kw) => RegExp(
        r'\b' + RegExp.escape(kw) + r'\b',
      ).hasMatch(lower),
    );

    if (hasWeakKeyword) {
      final hasDigit = RegExp(r'\d').hasMatch(line);
      final looksLikeProperNoun =
          _properNounPhraseRegex.hasMatch(line.trim()) &&
              line.trim().split(RegExp(r'\s+')).length <= 5;

      if (hasDigit || looksLikeProperNoun) {
        return true;
      }
    }

    return false;
  }

  /// Splits ML Kit output into label-sized tokens.
  ///
  /// Pharmacy labels are often returned as one comma-joined blob
  /// instead of one field per line. Each token is then expanded if
  /// it still mixes name / warning / street / postcode together.
  static List<String> _tokenizeOcrText(String rawText) {
    final pieces = <String>[];

    for (final row in rawText.split(RegExp(r'\r?\n'))) {
      final trimmed = row.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final parts = trimmed
          .split(RegExp(r'\s*[,;|•·]\s*'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      if (parts.length >= 3 && _isMixedLabelParts(parts)) {
        for (final part in parts) {
          pieces.addAll(_expandMixedToken(part));
        }
      } else {
        pieces.addAll(_expandMixedToken(trimmed));
      }
    }

    return pieces;
  }

  static bool _isMixedLabelParts(List<String> parts) {
    var hasAddress = false;
    var hasOther = false;

    for (final part in parts) {
      if (isPharmaOrDeliveryNote(part) ||
          isCourierNoise(part) ||
          isLikelyPersonName(part)) {
        hasOther = true;
      } else if (isLikelyAddressLine(part) ||
          containsUKPostcode(part) ||
          _embeddedStreetRegex.hasMatch(part)) {
        hasAddress = true;
      }
    }

    return hasAddress && hasOther;
  }

  static List<String> _expandMixedToken(String token) {
    if (!_shouldExpandMixedToken(token)) {
      return [token];
    }

    final spans = <({int start, int end, String text})>[];

    void collect(RegExp regex) {
      for (final match in regex.allMatches(token)) {
        final text = match.group(0)?.trim() ?? '';
        if (text.isEmpty) {
          continue;
        }
        spans.add((start: match.start, end: match.end, text: text));
      }
    }

    collect(_titledNameRegex);
    collect(_embeddedStreetRegex);
    collect(_flatUnitRegex);
    collect(_ukPostcodeFullRegex);

    final fullPostcodeRanges = _ukPostcodeFullRegex
        .allMatches(token)
        .map((m) => (start: m.start, end: m.end))
        .toList();

    final originalOutcode = RegExp(
      r'\b([A-Z]{1,2}\d[A-Z\d]?)\s*$',
      caseSensitive: false,
    ).firstMatch(token);
    if (originalOutcode != null) {
      final outcode = originalOutcode.group(1)!;
      final overlapsFull = fullPostcodeRanges.any(
            (r) => originalOutcode.start < r.end && originalOutcode.end > r.start,
      );
      if (!overlapsFull && !_ukOutcodeRegex.hasMatch(token.trim())) {
        spans.add((
        start: originalOutcode.start,
        end: originalOutcode.end,
        text: outcode.toUpperCase(),
        ));
      }
    }

    if (spans.isEmpty) {
      return [token];
    }

    spans.sort((a, b) => a.start.compareTo(b.start));

    final merged = <({int start, int end, String text})>[];
    for (final span in spans) {
      if (merged.isEmpty || span.start >= merged.last.end) {
        merged.add(span);
      }
    }

    final fragments = <String>[];
    var cursor = 0;
    for (final span in merged) {
      final gap = token.substring(cursor, span.start).trim();
      if (gap.isNotEmpty) {
        fragments.add(gap);
      }
      fragments.add(span.text);
      cursor = span.end;
    }

    final tail = token.substring(cursor).trim();
    if (tail.isNotEmpty) {
      fragments.add(tail);
    }

    return fragments.isEmpty ? [token] : fragments;
  }

  static bool _shouldExpandMixedToken(String token) {
    final trimmed = token.trim();
    final words = trimmed.split(RegExp(r'\s+'));
    final hasStreet = _embeddedStreetRegex.hasMatch(trimmed);
    final hasTitleName = _titledNameRegex.hasMatch(trimmed);
    final hasNote = isPharmaOrDeliveryNote(trimmed);
    final hasNoise = isCourierNoise(trimmed);
    final hasFullPostcode = _ukPostcodeFullRegex.hasMatch(trimmed);
    final hasTrailingOutcode = _trailingOutcodeRegex.hasMatch(trimmed) &&
        !_ukOutcodeRegex.hasMatch(trimmed) &&
        !hasFullPostcode;

    if (words.length <= 4 &&
        !hasNote &&
        !hasNoise &&
        !hasTitleName &&
        !hasTrailingOutcode) {
      return false;
    }

    final signals = [
      hasStreet,
      hasTitleName,
      hasNote,
      hasNoise,
      hasFullPostcode,
      hasTrailingOutcode,
    ].where((s) => s).length;

    if (signals >= 2) {
      return true;
    }

    if (hasStreet) {
      final street = _embeddedStreetRegex.firstMatch(trimmed)?.group(0) ?? '';
      if (trimmed.length > street.length + 4) {
        return true;
      }
    }

    return hasTrailingOutcode && hasStreet;
  }

  /// Main parser.
  ///
  /// IMPORTANT:
  /// The address result is deliberately restricted to the strongest
  /// contiguous delivery-address block. OCR text such as names, phone
  /// numbers, tracking IDs, courier labels and delivery instructions
  /// is never allowed to become part of the address.
  static DeliveryOcrResult parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const DeliveryOcrResult(
        rawText: '',
        address: '',
      );
    }

    final rawLines = _tokenizeOcrText(rawText);

    String extractedName = '';
    String extractedPhone = '';
    String extractedRef = '';
    String extractedPostcode = '';
    String extractedCity = '';

    final notesList = <String>[];

    // ============================================================
    // METADATA PASS
    // ============================================================

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();

      if (line.isEmpty) {
        continue;
      }

      // ----------------------------------------------------------
      // Tracking / Reference ID
      // ----------------------------------------------------------

      if (extractedRef.isEmpty) {
        final trackingMatch = _trackingRegex.firstMatch(line);

        if (trackingMatch != null) {
          extractedRef = trackingMatch.group(0)!;
          continue;
        }

        final refMatch = _orderRefPrefixRegex.firstMatch(line);

        if (refMatch != null) {
          extractedRef = refMatch.group(1)?.trim() ?? '';
          continue;
        }
      }

      // ----------------------------------------------------------
      // Phone
      // ----------------------------------------------------------

      if (extractedPhone.isEmpty) {
        final phoneMatch = _phoneRegex.firstMatch(line);

        if (phoneMatch != null) {
          extractedPhone = phoneMatch
              .group(0)
              ?.replaceAll(RegExp(r'\s+'), ' ')
              .trim() ??
              '';

          // A phone-only line is never an address.
          final remainder = line
              .replaceAll(_phoneRegex, '')
              .replaceAll(RegExp(r'[\s:#\-]+'), '')
              .trim();

          if (remainder.length < 4) {
            continue;
          }
        }
      }

      // ----------------------------------------------------------
      // Notes / warnings
      // ----------------------------------------------------------

      if (isPharmaOrDeliveryNote(line)) {
        notesList.add(line);
        continue;
      }

      // ----------------------------------------------------------
      // Recipient
      // ----------------------------------------------------------

      if (extractedName.isEmpty) {
        if (isLikelyPersonName(line)) {
          extractedName = _cleanRecipientName(line);
        } else if (_isSingleWordNameAboveAddressLine(
          line,
          rawLines,
          i,
        )) {
          extractedName = _cleanRecipientName(line);
        }
      }
    }

    // ============================================================
    // ADDRESS EXTRACTION
    // ============================================================

    final candidateBlocks = <List<String>>[];

    // ------------------------------------------------------------
    // CASE 1: POSTCODE EXISTS
    // ------------------------------------------------------------
    //
    // A postcode is a very strong address anchor. We start there
    // and walk upward, collecting only genuine address lines.
    //
    // Anything after the postcode is ignored.
    // Anything unrelated above the address stops the block.
    // ------------------------------------------------------------

    final postcodeIndex = _lastPostcodeIndex(rawLines);

    if (postcodeIndex != null) {
      final block = <String>[];

      final postcodeLine = rawLines[postcodeIndex];

      extractedPostcode = normalizeUKPostcode(postcodeLine);

      if (extractedPostcode.isNotEmpty) {
        block.add(extractedPostcode);
      }

      for (int i = postcodeIndex - 1; i >= 0; i--) {
        final line = rawLines[i].trim();

        if (line.isEmpty) {
          continue;
        }

        // Never allow metadata/noise into the address.
        if (_containsPhone(line) ||
            _containsReference(line) ||
            isCourierNoise(line) ||
            isPharmaOrDeliveryNote(line)) {
          continue;
        }

        // Recipient is the upper boundary of the address.
        if (isLikelyPersonName(line)) {
          break;
        }

        // Only genuine address-looking lines are accepted.
        if (isLikelyAddressLine(line)) {
          block.insert(0, line);

          extractedCity =
              _cityInLine(line) ?? extractedCity;

          continue;
        }

        // Unknown OCR text ends this address block.
        break;
      }

      // A postcode by itself is not enough unless there is some
      // additional address evidence.
      final hasNonPostcodeLine = block.any(
            (line) => !containsUKPostcode(line),
      );

      if (hasNonPostcodeLine) {
        candidateBlocks.add(block);
      }
    }

    // ------------------------------------------------------------
    // CASE 2: NO POSTCODE
    // ------------------------------------------------------------
    //
    // Search for the strongest address block instead of accepting
    // every address-looking line independently.
    // ------------------------------------------------------------

    if (candidateBlocks.isEmpty) {
      List<String>? bestBlock;
      var bestScore = 0;

      for (int start = 0; start < rawLines.length; start++) {
        final block = <String>[];
        var score = 0;

        for (int i = start; i < rawLines.length; i++) {
          final line = rawLines[i].trim();

          if (line.isEmpty) {
            continue;
          }

          // Metadata/noise can never be part of the address.
          if (_containsPhone(line) ||
              _containsReference(line) ||
              isCourierNoise(line) ||
              isPharmaOrDeliveryNote(line)) {
            if (block.isNotEmpty) {
              break;
            }
            continue;
          }

          // A recipient starts a different section.
          if (isLikelyPersonName(line)) {
            if (block.isNotEmpty) {
              break;
            }
            continue;
          }

          if (isLikelyAddressLine(line)) {
            block.add(line);

            // Strongest evidence gets the highest score.
            if (_embeddedStreetRegex.hasMatch(line)) {
              score += 10;
            } else if (_houseNumberStreetRegex.hasMatch(line)) {
              score += 10;
            } else if (_strongAddressKeywords.any(
                  (kw) => RegExp(
                r'\b' + RegExp.escape(kw) + r'\b',
                caseSensitive: false,
              ).hasMatch(line),
            )) {
              score += 6;
            } else if (_weakAddressKeywords.any(
                  (kw) => RegExp(
                r'\b' + RegExp.escape(kw) + r'\b',
                caseSensitive: false,
              ).hasMatch(line),
            )) {
              score += 3;
            } else {
              score += 1;
            }

            continue;
          }

          // Do not copy arbitrary OCR text into the address.
          if (block.isNotEmpty) {
            break;
          }
        }

        if (block.isNotEmpty) {
          // Prefer a block containing more than one address signal.
          if (block.length >= 2) {
            score += 5;
          }

          if (score > bestScore) {
            bestScore = score;
            bestBlock = List<String>.from(block);
          }
        }
      }

      if (bestBlock != null && bestBlock.isNotEmpty) {
        candidateBlocks.add(bestBlock);
      }
    }

    // ============================================================
    // FINAL ADDRESS
    // ============================================================

    final candidateAddressLines = candidateBlocks.isNotEmpty
        ? candidateBlocks.first
        : <String>[];

    // Detect city only from the selected address block.
    for (final line in candidateAddressLines) {
      extractedCity =
          _cityInLine(line) ?? extractedCity;
    }

    final finalAddress = _assembleUKAddress(
      candidateAddressLines,
      extractedPostcode,
    );

    return DeliveryOcrResult(
      rawText: rawText,
      address: finalAddress,
      recipientName: extractedName,
      phoneNumber: extractedPhone,
      referenceId: extractedRef,
      city: extractedCity,
      postcode: extractedPostcode,
      notes: notesList.join(', '),
    );
  }



  /// Returns true when a line contains a phone number.
  static bool _containsPhone(String line) {
    return _phoneRegex.hasMatch(line);
  }

  /// Returns true when a line contains a tracking/order reference.
  static bool _containsReference(String line) {
    return _trackingRegex.hasMatch(line) ||
        _orderRefPrefixRegex.hasMatch(line);
  }

  /// Returns the index of the final postcode.
  static int? _lastPostcodeIndex(
      List<String> lines,
      ) {
    for (int i = lines.length - 1; i >= 0; i--) {
      if (containsUKPostcode(lines[i])) {
        return i;
      }
    }

    return null;
  }

  /// Returns the canonical known-city name.
  static String? _cityInLine(String line) {
    final lower = line.trim().toLowerCase();

    for (final c in _knownCities) {
      if (lower == c.toLowerCase()) {
        return c;
      }
    }

    return null;
  }

  /// Detects a single capitalized word immediately above an address.
  static bool _isSingleWordNameAboveAddressLine(
      String line,
      List<String> lines,
      int index,
      ) {
    final trimmed = line.trim();

    if (!RegExp(
      r"^[A-Z][A-Za-z\-\.']+$",
    ).hasMatch(trimmed)) {
      return false;
    }

    final lower = trimmed.toLowerCase();

    if (_knownCities.any(
          (c) => lower == c.toLowerCase(),
    )) {
      return false;
    }

    if (_addressKeywords.any(
          (kw) => RegExp(
        r'\b' + RegExp.escape(kw) + r'\b',
      ).hasMatch(lower),
    )) {
      return false;
    }

    if (containsUKPostcode(line)) {
      return false;
    }

    if (isCourierNoise(line) ||
        isPharmaOrDeliveryNote(line)) {
      return false;
    }

    // Find the next meaningful line.
    for (int j = index + 1; j < lines.length; j++) {
      final next = lines[j];

      if (isCourierNoise(next) ||
          isPharmaOrDeliveryNote(next)) {
        continue;
      }

      return isLikelyAddressLine(next);
    }

    return false;
  }

  /// Cleans and assembles the final address.
  static String _assembleUKAddress(
      List<String> lines,
      String postcode,
      ) {
    if (lines.isEmpty) {
      return '';
    }

    final cleaned = <String>[];
    final seen = <String>{};

    for (final raw in lines) {
      final line = _cleanAddressLine(raw);

      if (line.isEmpty) {
        continue;
      }

      final key = line.toLowerCase();

      if (!seen.contains(key)) {
        seen.add(key);
        cleaned.add(line);
      }
    }

    // Ensure normalized postcode is present exactly once.
    if (postcode.isNotEmpty) {
      final hasPostcode = cleaned.any(
            (l) => l.toUpperCase() ==
            postcode.toUpperCase(),
      );

      if (!hasPostcode) {
        cleaned.add(postcode);
      }
    }

    return cleaned.join('\n');
  }

  /// Cleans recipient name.
  static String _cleanRecipientName(String raw) {
    return raw
        .replaceAll(
      RegExp(
        r'^(?:to|recipient|customer|deliver\s+to|attn)'
        r'[\s:\-]+',
        caseSensitive: false,
      ),
      '',
    )
        .replaceAll(
      RegExp(
        r'^(?:Miss|Mrs\.?|Ms\.?|Mr\.?|Dr\.?|Mx\.?|Sir|Lady|Lord|Prof\.?)'
        r'\s+',
        caseSensitive: false,
      ),
      '',
    )
        .replaceAll(
      RegExp(r'[,:\-]+$'),
      '',
    )
        .trim();
  }

  /// Cleans one address line.
  static String _cleanAddressLine(
      String line,
      ) {
    var clean = line
        .replaceAll(
      RegExp(
        r'^(?:address|delivery address|ship to|dropoff)'
        r'[\s:\-]+',
        caseSensitive: false,
      ),
      '',
    )
        .replaceAll(
      RegExp(r'[,;\s]+$'),
      '',
    )
        .trim();

    // Normalize a full postcode if it occurs inside the line.
    final pcMatch =
    _ukPostcodeFullRegex.firstMatch(clean);

    if (pcMatch != null) {
      final fullMatch = pcMatch.group(0)!;

      final normalized =
          '${pcMatch.group(1)!} ${pcMatch.group(2)!}';

      clean = clean.replaceFirst(
        fullMatch,
        normalized,
      );
    }

    return clean;
  }
}
