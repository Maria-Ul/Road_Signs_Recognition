# Road_Signs_Recognition
Road signs recognition project for DL on practise course at ITMO University

## Данные

Датасет с шведскими знаками:
[ссылка](https://www.cvl.isy.liu.se/research/datasets/traffic-signs-dataset/)

Детектируемые классы:
- INFORMATION_PRIORITY_ROAD
- MANDATORY_PASS_EITHER_SIDE
- MANDATORY_PASS_RIGHT_SIDE
- WARNING_GIVE_WAY
- PROHIBITORY_70_SIGN
- PROHIBITORY_90_SIGN
- OTHER_OTHER
- PROHIBITORY_80_SIGN
- PROHIBITORY_50_SIGN
- INFORMATION_PEDESTRIAN_CROSSING
- PROHIBITORY_60_SIGN
- PROHIBITORY_30_SIGN
- PROHIBITORY_NO_PARKING
- MANDATORY_PASS_LEFT_SIDE
- PROHIBITORY_110_SIGN
- PROHIBITORY_STOP
- PROHIBITORY_100_SIGN
- PROHIBITORY_NO_STOPPING_NO_STANDING
- UNREADABLE_URDBL
- PROHIBITORY_120_SIGN

Распределение количества данных по классам


![Распределение количества данных по классам](https://github.com/Maria-Ul/Road_Signs_Recognition/blob/main/images/labels.jpg)


## Выбранная модель


YOLOv8

Нормализованная матрица ошибок
![Нормализованная матрица ошибок](https://github.com/Maria-Ul/Road_Signs_Recognition/blob/main/images/confusion_matrix_normalized.png)


F1 - кривая
![F1 кривая](https://github.com/Maria-g](https://github.com/Maria-Ul/Road_Signs_Recognition/blob/main/images/F1_curve.png)

По графику  F1- кривой видно, что модель обучилась лучше всего на самых многочисленных классах.

## Подбор гиперпараметров


Основная проблема в решении задачи - подобрать верный набор данных. Мы рассмотрели два датасета: с небольшим числом обобщенных классов () и с большим числом классов (шведские знаки), но несбалансированных. 


## Интеграция в приложение

