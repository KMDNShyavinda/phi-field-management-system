class LegalSuggestion {
  const LegalSuggestion({
    required this.noticeType,
    required this.days,
    required this.provision,
  });

  final String noticeType;
  final int days;
  final String provision;
}

const legalRules = <String, LegalSuggestion>{
  'COLD_STORAGE': LegalSuggestion(
    noticeType: 'improvement_notice',
    days: 14,
    provision: 'Food Act No. 26 of 1980 — temperature control of stored perishable food is inadequate.',
  ),
  'HOT_HOLDING': LegalSuggestion(
    noticeType: 'improvement_notice',
    days: 14,
    provision: 'Food Act No. 26 of 1980 — hot-holding temperature of ready-to-eat food is inadequate.',
  ),
  'PEST_CONTROL': LegalSuggestion(
    noticeType: 'improvement_notice',
    days: 7,
    provision: 'Food Act No. 26 of 1980 — premises must be kept free of pest infestation.',
  ),
  'WATER_SUPPLY': LegalSuggestion(
    noticeType: 'improvement_notice',
    days: 7,
    provision: 'Food Act No. 26 of 1980 — potable water supply for food handling is unsatisfactory.',
  ),
  'WASTE_DISPOSAL': LegalSuggestion(
    noticeType: 'improvement_notice',
    days: 7,
    provision: 'Food Act No. 26 of 1980 — waste storage and disposal arrangements are unsatisfactory.',
  ),
  'PERSONAL_HYGIENE': LegalSuggestion(
    noticeType: 'improvement_notice',
    days: 7,
    provision: 'Food Act No. 26 of 1980 — food handler hygiene and hand-washing facilities are inadequate.',
  ),
  'FOOD_LABELLING': LegalSuggestion(
    noticeType: 'improvement_notice',
    days: 14,
    provision: 'Food Act No. 26 of 1980 — labelling / expiry control of displayed food is unsatisfactory.',
  ),
  'PREP_SURFACES': LegalSuggestion(
    noticeType: 'improvement_notice',
    days: 7,
    provision: 'Food Act No. 26 of 1980 — food contact surfaces are not maintained in a sanitary condition.',
  ),
};

LegalSuggestion suggestNotice(String itemCode) {
  return legalRules[itemCode] ??
      const LegalSuggestion(
        noticeType: 'improvement_notice',
        days: 14,
        provision: 'Food Act No. 26 of 1980 — general sanitary requirement not met.',
      );
}
