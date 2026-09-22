import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/core/utils/delivery_address_ocr_parser.dart';

void main() {
  group('DeliveryAddressOcrParser — UK delivery labels', () {
    test('Full UK postcode: SW1A 1AA with warnings and name', () {
      final result = DeliveryAddressOcrParser.parse(
        'FRAGILE\n'
        'Miss Jane Smith\n'
        'COLLECTION SERVICE\n'
        '10 Downing Street\n'
        'London\n'
        'SW1A 1AA',
      );

      expect(result.recipientName, 'Jane Smith');
      expect(result.address, contains('10 Downing Street'));
      expect(result.address, contains('London'));
      expect(result.address, contains('SW1A 1AA'));
      expect(result.address, isNot(contains('FRAGILE')));
      expect(result.address, isNot(contains('COLLECTION SERVICE')));
    });

    test('Short/partial postcode: B13', () {
      final result = DeliveryAddressOcrParser.parse(
        'Keep out of reach & sight of children\n'
        'Miss Fajer Al-Mutari\n'
        'COLLECTION SERVICE\n'
        '287 Brook Lane\n'
        'Birmingham\n'
        'B13',
      );

      expect(result.address, contains('287 Brook Lane'));
      expect(result.address, contains('Birmingham'));
      expect(result.address, contains('B13'));
      expect(result.address, isNot(contains('Keep out of reach')));
      expect(result.address, isNot(contains('COLLECTION SERVICE')));
      expect(result.recipientName, 'Fajer Al-Mutari');
    });

    test('Flat/Unit address', () {
      final result = DeliveryAddressOcrParser.parse(
        'Royal Mail Tracked\n'
        'To: Mr Ahmed Khan\n'
        'Flat 4\n'
        '287 Brook Lane\n'
        'Birmingham\n'
        'B13 8HE',
      );

      expect(result.address, contains('Flat 4'));
      expect(result.address, contains('287 Brook Lane'));
      expect(result.address, contains('Birmingham'));
      expect(result.address, contains('B13 8HE'));
      expect(result.address, isNot(contains('Royal Mail')));
      expect(result.address, isNot(contains('Tracked')));
      expect(result.recipientName, 'Ahmed Khan');
    });

    test('Street + City + Full Postcode', () {
      final result = DeliveryAddressOcrParser.parse(
        'DPD Next Day\n'
        'Mrs Fatima Zahra\n'
        '42 Oxford Road\n'
        'Manchester\n'
        'M1 5GA',
      );

      expect(result.address, contains('42 Oxford Road'));
      expect(result.address, contains('Manchester'));
      expect(result.address, contains('M1 5GA'));
      expect(result.address, isNot(contains('DPD')));
      expect(result.address, isNot(contains('Next Day')));
      expect(result.recipientName, 'Fatima Zahra');
    });

    test('EC1A 1BB postcode with warnings and tracking', () {
      final result = DeliveryAddressOcrParser.parse(
        'SIGNED FOR\n'
        'ORDER #ORD-12345\n'
        'To: Dr Ali Hassan\n'
        '123 City Road\n'
        'London\n'
        'EC1A 1BB',
      );

      expect(result.address, contains('123 City Road'));
      expect(result.address, contains('London'));
      expect(result.address, contains('EC1A 1BB'));
      expect(result.address, isNot(contains('SIGNED FOR')));
      expect(result.address, isNot(contains('ORDER')));
      expect(result.referenceId, 'ORD-12345');
      expect(result.recipientName, 'Ali Hassan');
    });

    test('Warning + pharmacy instructions excluded', () {
      final result = DeliveryAddressOcrParser.parse(
        'CONTROLLED DRUG\n'
        'KEEP REFRIGERATED\n'
        'TEMPERATURE CONTROLLED\n'
        'Not suitable for children\n'
        'Mr John Wilson\n'
        '78 Abbey Lane\n'
        'Bristol\n'
        'BS1 4DJ',
      );

      expect(result.address, contains('78 Abbey Lane'));
      expect(result.address, contains('Bristol'));
      expect(result.address, contains('BS1 4DJ'));
      expect(result.address, isNot(contains('CONTROLLED')));
      expect(result.address, isNot(contains('REFRIGERATED')));
      expect(result.address, isNot(contains('TEMPERATURE')));
      expect(result.address, isNot(contains('Not suitable')));
    });

    test('Hermes/Evri label with safe-place instruction', () {
      final result = DeliveryAddressOcrParser.parse(
        'Evri ParcelShop\n'
        'LEAVE WITH NEIGHBOUR\n'
        'Recipient: Sarah Jones\n'
        '5 Station Road\n'
        'Leeds\n'
        'LS1 5QT',
      );

      expect(result.address, contains('5 Station Road'));
      expect(result.address, contains('Leeds'));
      expect(result.address, contains('LS1 5QT'));
      expect(result.address, isNot(contains('Evri')));
      expect(result.address, isNot(contains('ParcelShop')));
      expect(result.address, isNot(contains('LEAVE WITH')));
    });

    test('Unit address with tracking number', () {
      final result = DeliveryAddressOcrParser.parse(
        'TRACKING: TRK-98765432\n'
        'Unit 12\n'
        'Crown Business Park\n'
        'Sheffield\n'
        'S4 7WW',
      );

      expect(result.address, contains('Unit 12'));
      expect(result.address, contains('Crown Business Park'));
      expect(result.address, contains('Sheffield'));
      expect(result.address, contains('S4 7WW'));
      expect(result.address, isNot(contains('TRACKING')));
      expect(result.referenceId, 'TRK-98765432');
    });

    test('Multiple UK street types: Close, Crescent, Drive, Way', () {
      final r1 = DeliveryAddressOcrParser.parse('12 Oak Close\nBristol\nBS5 6TY');
      expect(r1.address, contains('12 Oak Close'));

      final r2 = DeliveryAddressOcrParser.parse('8 Maple Crescent\nExeter\nEX1 2AB');
      expect(r2.address, contains('8 Maple Crescent'));

      final r3 = DeliveryAddressOcrParser.parse('34 Pine Drive\nOxford\nOX1 3PQ');
      expect(r3.address, contains('34 Pine Drive'));

      final r4 = DeliveryAddressOcrParser.parse('9 Elm Way\nCambridge\nCB2 1TN');
      expect(r4.address, contains('9 Elm Way'));
    });

    test('W1A postcode (London)', () {
      final result = DeliveryAddressOcrParser.parse(
        'POSTNL International\n'
        'Fragile\n'
        'Ms Amina Begum\n'
        '1 Great Portland Street\n'
        'London\n'
        'W1W 8QP',
      );

      expect(result.address, contains('1 Great Portland Street'));
      expect(result.address, contains('London'));
      expect(result.address, contains('W1W 8QP'));
      expect(result.address, isNot(contains('POSTNL')));
      expect(result.address, isNot(contains('Fragile')));
    });

    test('Label with barcode-style line (mostly digits) is excluded', () {
      final result = DeliveryAddressOcrParser.parse(
        '992837465012\n'
        '5 Castle Street\n'
        'Cardiff\n'
        'CF10 1BT',
      );

      expect(result.address, contains('5 Castle Street'));
      expect(result.address, contains('Cardiff'));
      expect(result.address, contains('CF10 1BT'));
      expect(result.address, isNot(contains('992837465012')));
    });

    test('Empty input returns empty result', () {
      final result = DeliveryAddressOcrParser.parse('');
      expect(result.address, isEmpty);
      expect(result.isValid, false);
    });

    test('Only non-address text returns empty address', () {
      final result = DeliveryAddressOcrParser.parse(
        'WARNING\n'
        'KEEP OUT OF REACH\n'
        'COLLECTION SERVICE\n'
        'SIGNED FOR\n'
        'FRAGILE',
      );

      expect(result.address, isEmpty);
      expect(result.isValid, false);
    });

    test('Pakistan address still works', () {
      final result = DeliveryAddressOcrParser.parse(
        'To: Mr Hassan\n'
        'House 45, Street 12\n'
        'Gulberg III\n'
        'Lahore',
      );

      expect(result.address, contains('House 45, Street 12'));
      expect(result.address, contains('Gulberg III'));
      expect(result.address, contains('Lahore'));
    });
  });

  group('DeliveryAddressOcrParser — fix verification', () {
    test('"42 Oxford Road" is recognized as an address', () {
      final result = DeliveryAddressOcrParser.parse(
        'DPD\n'
        '42 Oxford Road\n'
        'Manchester\n'
        'M1 5GA',
      );

      expect(result.address, contains('42 Oxford Road'));
      expect(result.address, contains('Manchester'));
      expect(result.address, contains('M1 5GA'));
      expect(result.address, isNot(contains('DPD')));
    });

    test('"LEAVE WITH NEIGHBOUR" is not an address', () {
      final result = DeliveryAddressOcrParser.parse(
        'Evri\n'
        'LEAVE WITH NEIGHBOUR\n'
        'Recipient: Sarah Jones\n'
        '5 Station Road\n'
        'Leeds\n'
        'LS1 5QT',
      );

      expect(result.address, isNot(contains('LEAVE')));
      expect(result.address, contains('5 Station Road'));
      expect(result.address, contains('Leeds'));
      expect(result.address, contains('LS1 5QT'));
      expect(result.recipientName, 'Sarah Jones');
    });

    test('"DPD Next Day" and "Royal Mail Tracked" are not names', () {
      final result = DeliveryAddressOcrParser.parse(
        'DPD Next Day\n'
        'Royal Mail Tracked\n'
        'To: Emma Thompson\n'
        '22 Rosewood Drive\n'
        'Glasgow\n'
        'G2 3AB',
      );

      expect(result.recipientName, 'Emma Thompson');
      expect(result.recipientName, isNot(contains('DPD')));
      expect(result.recipientName, isNot(contains('Royal Mail')));
      expect(result.address, contains('22 Rosewood Drive'));
      expect(result.address, isNot(contains('DPD')));
      expect(result.address, isNot(contains('Royal Mail')));
    });

    test('Standalone "DPD" and "Royal Mail" lines are not names', () {
      final result = DeliveryAddressOcrParser.parse(
        'DPD\n'
        'Royal Mail\n'
        'To: Omar Farooq\n'
        '7 King Street\n'
        'Bristol\n'
        'BS1 3QP',
      );

      expect(result.recipientName, 'Omar Farooq');
      expect(result.address, contains('7 King Street'));
      expect(result.address, isNot(contains('DPD')));
      expect(result.address, isNot(contains('Royal Mail')));
    });

    test('Recipient name on a later line is detected', () {
      final result = DeliveryAddressOcrParser.parse(
        '10 Downing Street\n'
        'London\n'
        'SW1A 1AA\n'
        'Jane Smith',
      );

      expect(result.recipientName, 'Jane Smith');
      expect(result.address, contains('10 Downing Street'));
      expect(result.address, contains('London'));
      expect(result.address, contains('SW1A 1AA'));
    });
  });

  group('DeliveryAddressOcrParser — User Specified UK OCR Scenarios', () {
    test('Case 1: User label with year, pharma warning, title name, collection service, street, partial postcode', () {
      final input = '''
2026
Keep out of reach & sight of children
Miss Fajer Al-Mutari
COLLECTION SERVICE
287 Brook Lane
B13
''';
      final result = DeliveryAddressOcrParser.parse(input);

      expect(result.address, contains('287 Brook Lane'));
      expect(result.address, contains('B13'));
      expect(result.address, isNot(contains('2026')));
      expect(result.address, isNot(contains('Keep out of reach')));
      expect(result.address, isNot(contains('COLLECTION SERVICE')));
      expect(result.address, isNot(contains('Fajer')));

      expect(result.recipientName, anyOf(equals('Miss Fajer Al-Mutari'), equals('Fajer Al-Mutari')));
      expect(result.notes, contains('Keep out of reach & sight of children'));
      expect(result.postcode, 'B13');
    });

    test('Case 2: Full UK address with flat, street, city, full postcode', () {
      final input = '''
John Smith
Flat 4
287 Brook Lane
Birmingham
B13 8XX
''';
      final result = DeliveryAddressOcrParser.parse(input);

      expect(result.address, contains('Flat 4'));
      expect(result.address, contains('287 Brook Lane'));
      expect(result.address, contains('Birmingham'));
      expect(result.address, contains('B13 8XX'));
      expect(result.address, isNot(contains('John Smith')));
      expect(result.recipientName, 'John Smith');
      expect(result.city, 'Birmingham');
      expect(result.postcode, 'B13 8XX');
    });

    test('Case 3: Recipient, phone, address, city, postcode, and pharma safety warning', () {
      final input = '''
John Smith
0300-1234567
287 Brook Lane
Birmingham
B13 8XX
Keep out of reach & sight of children
''';
      final result = DeliveryAddressOcrParser.parse(input);

      expect(result.address, contains('287 Brook Lane'));
      expect(result.address, contains('Birmingham'));
      expect(result.address, contains('B13 8XX'));
      expect(result.address, isNot(contains('John Smith')));
      expect(result.address, isNot(contains('0300')));
      expect(result.address, isNot(contains('Keep out of reach')));

      expect(result.recipientName, 'John Smith');
      expect(result.phoneNumber, contains('0300'));
      expect(result.notes, contains('Keep out of reach & sight of children'));
    });

    test('Case 4: Fragile tag, tracking ID, recipient, address, city, postcode, safe-place instruction', () {
      final input = '''
FRAGILE
TRACKING: AB123456789GB
Jane Smith
15 High Street
London
SW1A 1AA
Leave in safe place
''';
      final result = DeliveryAddressOcrParser.parse(input);

      expect(result.address, contains('15 High Street'));
      expect(result.address, contains('London'));
      expect(result.address, contains('SW1A 1AA'));
      expect(result.address, isNot(contains('FRAGILE')));
      expect(result.address, isNot(contains('TRACKING')));
      expect(result.address, isNot(contains('Leave in safe place')));

      expect(result.recipientName, 'Jane Smith');
      expect(result.referenceId, 'AB123456789GB');
      expect(result.notes, contains('Leave in safe place'));
    });

    test('Postcode normalization: B138XX -> B13 8XX', () {
      final input = '''
Sarah Connor
10 Downing Street
London
SW1A1AA
''';
      final result = DeliveryAddressOcrParser.parse(input);
      expect(result.postcode, 'SW1A 1AA');
      expect(result.address, contains('SW1A 1AA'));
    });
  });

  group('DeliveryAddressOcrParser — address integrity', () {
    test('Single-word surname above an address is the recipient name, not address text', () {
      final result = DeliveryAddressOcrParser.parse(
        'Al-Mutari\n'
        'COLLECTION SERVICE\n'
        '287 Brook Lane\n'
        'B13',
      );

      expect(result.recipientName, 'Al-Mutari');
      expect(result.address, '287 Brook Lane\nB13');
      expect(result.postcode, 'B13');
      expect(result.address, isNot(contains('Al-Mutari')));
      expect(result.address, isNot(contains('COLLECTION')));
    });

    test('Service text variant that evades the strict noise matcher is never absorbed', () {
      final result = DeliveryAddressOcrParser.parse(
        'Fajer Al-Mutari\n'
        'SERVICE: COLLECTION\n'
        '287 Brook Lane\n'
        'B13',
      );

      expect(result.recipientName, 'Fajer Al-Mutari');
      expect(result.address, '287 Brook Lane\nB13');
      expect(result.address, isNot(contains('SERVICE')));
    });

    test('The postcode terminates the address: lines after it are ignored', () {
      final result = DeliveryAddressOcrParser.parse(
        '287 Brook Lane\n'
        'Birmingham\n'
        'B13\n'
        'Block 2',
      );

      expect(result.address, '287 Brook Lane\nBirmingham\nB13');
      expect(result.address, isNot(contains('Block')));
      expect(result.city, 'Birmingham');
    });

    test('Comma-joined pharmacy label blob keeps only street and postcode', () {
      final result = DeliveryAddressOcrParser.parse(
        '2026, Keep out of reach & sight of children, Miss Fajer Al-Mutari, '
        'COLLECTION SERVICE, 287 Brook Lane, B13',
      );

      expect(result.address, '287 Brook Lane\nB13');
      expect(result.recipientName, 'Fajer Al-Mutari');
      expect(result.postcode, 'B13');
      expect(result.notes, contains('Keep out of reach & sight of children'));
      expect(result.address, isNot(contains('2026')));
      expect(result.address, isNot(contains('COLLECTION')));
      expect(result.address, isNot(contains('Keep out')));
      expect(result.address, isNot(contains('Fajer')));
    });

    test('Space-joined pharmacy label blob still extracts street and postcode', () {
      final result = DeliveryAddressOcrParser.parse(
        '2026 Keep out of reach & sight of children Miss Fajer Al-Mutari '
        'COLLECTION SERVICE 287 Brook Lane B13',
      );

      expect(result.address, contains('287 Brook Lane'));
      expect(result.address, contains('B13'));
      expect(result.recipientName, 'Fajer Al-Mutari');
      expect(result.address, isNot(contains('2026')));
      expect(result.address, isNot(contains('COLLECTION')));
      expect(result.address, isNot(contains('Keep out')));
      expect(result.address, isNot(contains('Fajer')));
    });
  });
}
