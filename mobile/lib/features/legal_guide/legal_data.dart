class LegalGuideline {
  final String id;
  final String title;
  final String actSection;
  final String description;
  final List<String> initialSteps;
  final List<String> legalActionSteps;
  final List<String> evidenceRequired;

  const LegalGuideline({
    required this.id,
    required this.title,
    required this.actSection,
    required this.description,
    required this.initialSteps,
    required this.legalActionSteps,
    required this.evidenceRequired,
  });
}

const List<LegalGuideline> legalGuidelines = [
  LegalGuideline(
    id: 'L001',
    title: 'කල් ඉකුත් වූ ආහාර විකිණීම (Selling Expired Food)',
    actSection: '1980 අංක 26 දරණ ආහාර පනතේ 2 වැනි වගන්තිය',
    description: 'මිනිස් පරිභෝජනයට නුසුදුසු, කල් ඉකුත් වූ හෝ නරක් වූ ආහාර ද්‍රව්‍ය ගබඩා කර තැබීම හෝ විකිණීම.',
    initialSteps: [
      'අදාළ ආහාර ද්‍රව්‍ය වහාම විකිණීමෙන් ඉවත් කිරීම.',
      'අවවාද කර (H800 පෝරමය) සති 2ක කාලයක් ලබා දීම.',
      'කඩේ අයිතිකරුට රතු නිවේදනයක් (Red Notice) නිකුත් කිරීම.',
    ],
    legalActionSteps: [
      'මහේස්ත්‍රාත් අධිකරණයට "බී" වාර්තාවක් (B-Report) මගින් කරුණු ඉදිරිපත් කිරීම.',
      'ආහාර පනත යටතේ නඩු පැවරීම.',
    ],
    evidenceRequired: [
      'කල් ඉකුත් වූ දිනය පෙනෙන සේ ගත් භාණ්ඩයේ ඡායාරූප.',
      'මිලදී ගත් බිල්පත (ඇත්නම්).',
      'ස්ථානයේ සාක්ෂිකරුවන්ගේ ප්‍රකාශ.',
    ],
  ),
  LegalGuideline(
    id: 'L002',
    title: 'අපිරිසිදු මුළුතැන්ගෙය / ආහාර පිළියෙළ කිරීම',
    actSection: '1980 අංක 26 දරණ ආහාර පනත (සනීපාරක්ෂක රෙගුලාසි)',
    description: 'ආහාර පිළියෙළ කරන ස්ථානය අපිරිසිදුව පවත්වාගෙන යාම, මැස්සන්/මීයන් ගැවසීම සහ සේවකයින්ගේ අපිරිසිදුතාවය.',
    initialSteps: [
      'ස්ථානය පරීක්ෂා කර H800 පෝරමය මගින් දින 14ක කාලයක් ලබා දීම.',
      'පොදු සෞඛ්‍යයට දැඩි තර්ජනයක් නම් තාවකාලිකව ව්‍යාපාරය වසා දැමීමට උපදෙස් දීම.',
    ],
    legalActionSteps: [
      'ලබාදුන් කාලය තුළ අඩුපාඩු සකසා නැත්නම් නඩු පැවරීම.',
      'ප්‍රාදේශීය සෞඛ්‍ය වෛද්‍ය නිලධාරී (MOH) හරහා වසා දැමීමේ නියෝග (Closure Order) ගැනීම.',
    ],
    evidenceRequired: [
      'අපිරිසිදු බව ඔප්පු වන ඡායාරූප (Evidence Photos).',
      'පෙර නිකුත් කළ H800 පෝරමයේ පිටපත.',
      'සේවකයින්ගේ වෛද්‍ය සහතික නොමැති බවට සටහන්.',
    ],
  ),
  LegalGuideline(
    id: 'L003',
    title: 'ආහාර හසුරුවන්නන්ගේ වෛද්‍ය සහතික නොමැති වීම',
    actSection: 'ආහාර (ආහාර හසුරුවන්නන්ගේ) රෙගුලාසි',
    description: 'ආහාර සකසන සහ බෙදාහරින සේවකයින් වාර්ෂික වෛද්‍ය පරීක්ෂණයෙන් (PHI Medical Certificate) සමත් වී නොතිබීම.',
    initialSteps: [
      'අදාළ සේවකයින්ට වහාම ආහාර හැසිරවීමෙන් ඉවත් වීමට උපදෙස් දීම.',
      'MOH කාර්යාලය හරහා වෛද්‍ය පරීක්ෂණයට යොමු කිරීම.',
    ],
    legalActionSteps: [
      'අයිතිකරුට එරෙහිව සනීපාරක්ෂක රෙගුලාසි කඩකිරීම යටතේ නඩු පැවරීම.',
    ],
    evidenceRequired: [
      'සේවකයින්ගේ නාමලේඛනය.',
      'පරීක්ෂා කළ දින සහ වේලාව.',
    ],
  ),
  LegalGuideline(
    id: 'L004',
    title: 'මදුරුවන් බෝවන ස්ථාන පවත්වාගෙන යාම',
    actSection: 'මදුරු මර්දන පනත / පොදු පීඩා ආඥා පනත',
    description: 'ඩෙංගු හෝ වෙනත් රෝග වාහක මදුරුවන් බෝවන ආකාරයට ජලය රැඳෙන භාජන, ටයර්, හෝ පරිසරය පවත්වාගෙන යාම.',
    initialSteps: [
      'ස්ථානය වහාම පිරිසිදු කිරීමට උපදෙස් දීම.',
      'අවවාදාත්මක නිවේදනයක් නිකුත් කිරීම.',
    ],
    legalActionSteps: [
      'දින 3ක් ඇතුළත පිරිසිදු කර නොමැති නම් පොලීසිය සමඟ එක්ව නඩු පැවරීම.',
      'මහේස්ත්‍රාත් අධිකරණයේ දඩ ගැසීම.',
    ],
    evidenceRequired: [
      'මදුරු කීටයන් සිටින ජල භාජන වල ඡායාරූප (GPS සහිත).',
      'කීට විද්‍යා නිලධාරීන්ගේ (Entomologist) වාර්තාව.',
    ],
  ),
];
