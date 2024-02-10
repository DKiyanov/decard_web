const regulatorDescJson = {
  "options" : {
    "title" : "Настройки системы",
    "body"  : {

      "hotDayCount" : {
        "title" : "Количество дней, за которые рассчитывается статистика"
      },

      "hotCardQualityTopLimit" : {
        "title" : "Карточки более низкого качества считаются активно изучаемыми"
      },
      "maxCountHotCard" : {
        "title" : "Максимальное количество карточек в активном изучении"
      },

      "hotGroupDetermine" : {
        "title" : "Лимиты, определяющие активность группы",
        "body"  : {
          "hotGroupMinQualityTopLimit" : {
            "title" : "Минимальное качество",
            "help"  : "Минимальное качество для карточек, входящих в группу"
          },
          "hotGroupAvgQualityTopLimit" : {
            "title" : "Среднее качество",
            "help"  : "Среднее качество карточек, входящих в группу"
          },
        }
      },

      "minCountHotQualityGroup" : {
        "title" : "Mинимальное количество активно изучаемых групп карточек",
        "help"  : "Если количество активно изучаемых групп меньше лимита - система пытается выбрать карту из новой группы"
      },

      "lowGroupAvgQualityTopLimit" : {
        "title" : "Верхний предел среднего качества для групп начального уровня качества",
      },

      "maxCountLowQualityGroup" : {
        "title" : "Максимальное количество групп начального уровня качества",
        "help"  : "Если количество групп с начальным уровнем качества равно лимиту - система выбирает карточки из уже изучаемых групп"
      },

      "lowParamQualityLimit" : {
        "title" : "Ограничители роста качества",
        "body"  : {
          "lowTryCount" : {
            "title" : "Минимальное количество тестов",
          },
          "lowDayCount" : {
            "title" : "Минимальное количество дней",
            "help"  : "Если последний ответ по карточке был не правильный - качество устанавливается в это значение"
          },
        }
      },

      "negativeLastResultMaxQualityLimit" : {
        "title" : "Максимально возможное качество с отрицательным последним результатом",
      },
      "minEarnTransferMinutes" : {
        "title" : "Минимальное количество заработанного времени которое может быть зафиксировано",
      }

    }
  },

  "setList" : {
    "title" : "Настройка пакета карточек",
    "body"  : {
      "cards" : {
        "title" : "Идентификаторы карточек"
      },
      "groups" : {
        "title" : "Группы"
      },
      "tags" : {
        "title" : "Теги"
      },
      "andTags" : {
        "title" : "Теги через И"
      },
      "difficultyLevels" : {
        "title" : "Уровни сложности"
      },
      "exclude" : {
        "title" : "Исключить"
      },
      "difficultyLevel" : {
        "title" : "Сложность"
      },
      "style" : {
        "title" : "Стиль"
      },
    }
  },

  "difficultyList" : {
    "title" : "Список уровней сложности",
    "body"  : {

      "cost": {
        "title" : "Стоимость",
        "body"  : {
          "maxCost" : {
            "title" : "Максимальная"
          },
          "minCost" : {
            "title" : "Минимальная"
          }
        }
      },

      "penalty": {
        "title" : "Штраф",
        "body"  : {
          "maxPenalty" : {
            "title" : "Максимальный"
          },
          "minPenalty" : {
            "title" : "Минимальный"
          },
        }
      },

      "tryCount": {
        "title" : "Количество попыток",
        "body"  : {
          "maxTryCount" : {
            "title" : "Максимальное"
          },
          "minTryCount" : {
            "title" : "Минимальное"
          },
        }
      },

      "duration": {
        "title" : "Длительность",
        "body"  : {
          "maxDuration" : {
            "title" : "Максимальная"
          },
          "minDuration" : {
            "title" : "Минимальная"
          }
        }
      },

      "durationLowCostPercent" : {
        "title" : "Процент снижения стоимости",
        "body"  : {
          "maxDurationLowCostPercent" : {
            "title" : "Максимальный"
          },
          "minDurationLowCostPercent" : {
            "title" : "Минимальный"
          },
        }
      },

    }
  }

};