class PhoneContact {
  final String deviceId;
  final String displayName;
  final String givenName;
  final String familyName;
  final String organization;
  final String jobTitle;
  final String notes;
  final bool isStarred;
  final List<Map<String, String>> phones;
  final List<Map<String, String>> emails;
  final List<Map<String, String>> addresses;
  final List<String> groups;

  const PhoneContact({
    required this.deviceId,
    required this.displayName,
    this.givenName = '',
    this.familyName = '',
    this.organization = '',
    this.jobTitle = '',
    this.notes = '',
    this.isStarred = false,
    this.phones = const [],
    this.emails = const [],
    this.addresses = const [],
    this.groups = const [],
  });

  String get primaryPhone =>
      phones.isEmpty ? '' : (phones.first['number'] ?? '');

  String get primaryEmail =>
      emails.isEmpty ? '' : (emails.first['address'] ?? '');

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'display_name': displayName,
        'given_name': givenName,
        'family_name': familyName,
        'organization': organization,
        'job_title': jobTitle,
        'notes': notes,
        'is_starred': isStarred,
        'phones': phones,
        'emails': emails,
        'addresses': addresses,
        'groups': groups,
      };

  PhoneContact copyWith({List<String>? groups}) => PhoneContact(
        deviceId: deviceId,
        displayName: displayName,
        givenName: givenName,
        familyName: familyName,
        organization: organization,
        jobTitle: jobTitle,
        notes: notes,
        isStarred: isStarred,
        phones: phones,
        emails: emails,
        addresses: addresses,
        groups: groups ?? this.groups,
      );
}
