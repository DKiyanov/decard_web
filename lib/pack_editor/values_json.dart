import 'dart:convert';

Map<String, String> getJsonFieldValues(String fieldName){
  final result = <String, String>{};

  final valuesMap = _kJsonValuesMap[fieldName] as Map<String, dynamic>;
  for (var element in valuesMap.entries) {
    result[element.key] = element.value;
  }

  return result;
}

final _kJsonValuesMap = jsonDecode(_valuesJsonStr);

const _valuesJsonStr = '''
 {
  "license": {
    "AFL-3.0"            : "Academic Free License v3.0 (AFL-3.0)",
    "Apache-2.0"         : "Apache license 2.0 (Apache-2.0)",
    "Artistic-2.0"       : "Artistic license 2.0 (Artistic-2.0)",
    "BSL-1.0"            : "Boost Software License 1.0 (BSL-1.0)",
    "BSD-2-Clause"       : "BSD 2-clause 'Simplified' license (BSD-2-Clause)",
    "BSD-3-Clause"       : "BSD 3-clause 'New' or 'Revised' license (BSD-3-Clause)",
    "BSD-3-Clause-Clear" : "BSD 3-clause Clear license (BSD-3-Clause-Clear)",
    "BSD-4-Clause"       : "BSD 4-clause 'Original' or 'Old' license (BSD-4-Clause)",
    "0BSD"               : "BSD Zero-Clause license (0BSD)",
    "CC"                 : "Creative Commons license family (CC)",
    "CC0-1.0"            : "Creative Commons Zero v1.0 Universal (CC0-1.0)",
    "CC-BY-4.0"          : "Creative Commons Attribution 4.0 (CC-BY-4.0)",
    "CC-BY-SA-4.0"       : "Creative Commons Attribution ShareAlike 4.0 (CC-BY-SA-4.0)",
    "WTFPL"              : "Do What The F*ck You Want To Public License (WTFPL)",
    "ECL-2.0"            : "Educational Community License v2.0 (ECL-2.0)",
    "EPL-1.0"            : "Eclipse Public License 1.0 (EPL-1.0)",
    "EPL-2.0"            : "Eclipse Public License 2.0 (EPL-2.0)",
    "EUPL-1.1"           : "European Union Public License 1.1 (EUPL-1.1)",
    "AGPL-3.0"           : "GNU Affero General Public License v3.0 (AGPL-3.0)",
    "GPL"                : "GNU General Public License family (GPL)",
    "GPL-2.0"            : "GNU General Public License v2.0 (GPL-2.0)",
    "GPL-3.0"            : "GNU General Public License v3.0 (GPL-3.0)",
    "LGPL"               : "GNU Lesser General Public License family (LGPL)",
    "LGPL-2.1"           : "GNU Lesser General Public License v2.1 (LGPL-2.1)",
    "LGPL-3.0"           : "GNU Lesser General Public License v3.0 (LGPL-3.0)",
    "ISC"                : "ISC (ISC)",
    "LPPL-1.3c"          : "LaTeX Project Public License v1.3c (LPPL-1.3c)",
    "MS-PL"              : "Microsoft Public License (MS-PL)",
    "MIT"                : "MIT (MIT)",
    "MPL-2.0"            : "Mozilla Public License 2.0 (MPL-2.0)",
    "OSL-3.0"            : "Open Software License 3.0 (OSL-3.0)",
    "PostgreSQL"         : "PostgreSQL License (PostgreSQL)",
    "OFL-1.1"            : "SIL Open Font License 1.1 (OFL-1.1)",
    "NCSA"               : "University of Illinois/NCSA Open Source License (NCSA)",
    "Unlicense"          : "The Unlicense (Unlicense)",
    "Zlib"               : "zLib License (Zlib)"    
  },
  "answerInputMode": {
    "ddList"         : "Выпадающий список",
    "vList"          : "Список",
    "hList"          : "Последовательно",
    "input"          : "Поле ввода",
    "inputDigit"     : "Поле ввода, только цифры",
    "widgetKeyboard" : "Наборная клавиатура"
  },
  "answerVariantAlign": {
    "left"   : "левое",
    "center" : "по центру",
    "right"  : "правое"
  },
  "difficulty": {
    "0": "На запоминание", 
    "1": "Очень простое", 
    "2": "Простое", 
    "3": "Нужно подумать", 
    "4": "Сложное", 
    "5": "Очень сложное"
  }
 } 
''';