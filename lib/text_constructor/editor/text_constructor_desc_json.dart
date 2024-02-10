const textConstructorDescJson = {

  "styles" : {
    "title": "Стили объектов",
    "body" : {
      "bodyName" : {
        "title": "Стиль объекта",
      },
      "charColor" : {
        "title" : "Цвет текста"
      },
      "backgroundColor" : {
        "title" : "Цвет фона"
      },
      "frameColor" : {
        "title" : "Цвет рамки"
      },
      "fontBold" : {
        "title" : "Жирный шрифт"
      },
      "fontItalic": {
        "title" : "Курсив"
      },

      "linePos" : {
        "title" : "Расположение линии"
      },
      "lineStyle" : {
        "title" : "Стиль линии"
      },
      "lineColor" : {
        "title" : "Цвет"
      },
    }
  },

  "style" : {
    "title": "Стиль объекта",
    "body" : {
      "charColor" : {
        "title" : "Цвет текста"
      },
      "backgroundColor" : {
        "title" : "Цвет фона"
      },
      "frameColor" : {
        "title" : "Цвет рамки"
      },
      "fontBold" : {
        "title" : "Жирный шрифт"
      },
      "fontItalic": {
        "title" : "Курсив"
      },

      "linePos" : {
        "title" : "Расположение линии"
      },
      "lineStyle" : {
        "title" : "Стиль линии"
      },
      "lineColor" : {
        "title" : "Цвет"
      },
    }
  },

  "options" : {
    "title": "Настройки",
    "body" : {
      "markStyle" : {
        "title": "Стиль для выделения"
      },
      "randomMixWord" : {
        "title": "Перемешать слова случайным образом"
      },
      "randomDelWord" : {
        "title": "Удалить слова случайным образом"
      },

      "notDelFromBasement" : {
        "title": "Не удалть слова из подвала"
      },
      "canMoveWord" : {
        "title": "Можно перемещать слова"
      },
      "noCursor" : {
        "title": "Не выводить курсор"
      },
      "focusAsCursor" : {
        "title": "Использовать позицию фокуса как позицию курсора"
      },
      "fontSize" : {
        "title": "Размер шрифта"
      },
      "boxHeight" : {
        "title": "Высота элемента"
      },
      "btnKeyboard" : {
        "title": "Кнопка 'Клавиатура'"
      },
      "btnUndo" : {
        "title": "Кнопка 'Отменить шаг'"
      },
      "btnRedo" : {
        "title": "Кнопка 'Вернуть шаг'"
      },
      "btnBackspace" : {
        "title": "Кнопка 'Backspace'"
      },
      "btnDelete" : {
        "title": "Кнопка 'Удалить'"
      },
      "btnClear" : {
        "title": "Кнопка 'Отчистить'"
      },
    }
  },

  "other" : {
    "title": "Потом решим нужно оно или нет и как вывести",
    "body" : {
      "text" : {
        "title": "начальный текст в конструкторе",
      },
      "objects" : {
        "title": ""
      },
      "answerList" : {
        "title": "Список правильных ответов"
      },
      "audioMap" : {
        "title": ""
      },
      "basement" : {
        "title": "Подвал"
      },
    },
  }

};

const Map<String, Map<String, String>> textConstructorFieldValues = {
  "color" : {
    "noValue" : "не указано",
    "red"     : "Красный",
    "green"   : "Зелёный",
    "blue"    : "Голубой",
    "yellow"  : "Жёлтый",
    "orange"  : "Оранжевый",
    "black"   : "Чёрный",
    "white"   : "Белый",
  },
  "linePos" : {
    "noValue"     : "не указано",
    "underline"   : "Под строкой",
    "lineThrough" : "Зачёркивание",
  },
  "lineStyle" :{
    "noValue": "не указано",
    "solid"  : "Одинарная",
    "wavy"   : "Волнистая",
    "double" : "Двойная",
    "dashed" : "Пунктирная",
    "dotted" : "Точечная",
  }
};

const testTextConstructorJson = {
  "text" : "начальный #объект-3 в конструкторе @keyboard #0|символ",

  "basement" : "",

  "objects": [

    {
      "name" :  "символ",
      "viewIndex": 1,
      "notDelete": true,
      "views": ["2|", "3|"]
    },

    {
      "name" :  "объект-3",
      "viewIndex": 1,
      "views": ["2|вариант-3", "3|вариант-4"]
    }

  ],

  "styles": ["i", "b", "ccr,bcb", "ccb,bcr,l~g"],
//  "markStyle" : 3,

  "randomMixWord" : false,
  "randomView" : false,
  "notDelFromBasement" : false,

  "canMoveWord"   : true,
  "noCursor"      : false,
  "focusAsCursor" : true,

  "btnKeyboard"  : true,
  "btnUndo"      : true,
  "btnRedo"      : true,
  "btnBackspace" : true,
  "btnDelete"    : true,
  "btnClear"     : true
};