# Road_Signs_Recognition
Road signs recognition project for DL on practise course at ITMO University

## Данные

### Датасет с 4 классами:
[ссылка](https://www.kaggle.com/datasets/valentynsichkar/traffic-signs-dataset-in-yolo-format)
дополненный собственными данными

- train\images - 1315
- train\labels - 1315
- val\images - 319
- val\labels - 319

Детектируемые классы:
- 0 - prohibitory # запретительный
- 1 - danger # опасность
- 2 - mandatory # обязательный
- 3 - main_road # главная дорога/уступи дорогу

## Выбранная модель

YOLOv8n

Распределение количества данных по классам
![Распределение количества данных по классам](https://github.com/Maria-Ul/Road_Signs_Recognition/blob/main/images/v8n_labels.jpg)


Нормализованная матрица ошибок
![Нормализованная матрица ошибок](https://github.com/Maria-Ul/Road_Signs_Recognition/blob/main/images/v8n_confusion_matrix_normalized.png)


F1 - кривая
![F1 кривая](https://github.com/Maria-Ul/Road_Signs_Recognition/blob/main/images/v8n_F1_curve.png)


### Датасет с шведскими знаками:
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


По распределению видно, что данные не сбалансированны. Но для того, чтобы охватить большее число знаков мы решили не удалять малочисленные классы и оставить датасет в первоначальном виде.

## Выбранная модель


YOLOv8

Нормализованная матрица ошибок
![Нормализованная матрица ошибок](https://github.com/Maria-Ul/Road_Signs_Recognition/blob/main/images/confusion_matrix_normalized.png)


F1 - кривая
![F1 кривая](https://github.com/Maria-Ul/Road_Signs_Recognition/blob/main/images/F1_curve.png)

По графику  F1- кривой видно, что модель обучилась лучше всего на самых многочисленных классах.

## Подбор гиперпараметров


Основная проблема в решении задачи - подобрать верный набор данных. Мы рассмотрели два датасета: с небольшим числом обобщенных классов () и с большим числом классов (шведские знаки), но несбалансированных. 




## Интеграция в приложение

1. Экспорт весов модели в формат tflite `yolo export model=model_name.pt format=tflite`
2. Для мобильного приложения использовался фреймворк [flutter](https://docs.flutter.dev/get-started/install)
3. Для интеграции модели в приложение использовалась библиотека [tflite_flutter](https://pub.dev/packages/tflite_flutter)
4. Для доступа к камере устройства использовалась библиотека [camera](https://pub.dev/packages/camera)
5. Процесс обработки изображений происходит следующим образом:
  - создается отдельный Isolate (процесс/поток) для работы модели и обработки изображений
  - из видеопотока камеры возвращается изображение
  - изображение конвертируется в зависимости от его формата (формат изображения зависит от устройства)
  - изображение преобразуется в inputTensor
  - осуществляется работа модели
  - полученный outputTensor обрабатывается при помощи NMS (Non Maximum Suppression)
  - outputTensor конвертируется в список BoxModel с полями: className, xCenter, yCenter, width, height

### Average Inference Time:

- Xiaomi Redmi 8: 2200 ms
- OPPO Reno5 Lite: 1200 ms
- Pixel 6 Pro: 240 ms
- iPhone 12 mini: 90 ms

## Результат работы сети 

Предсказание модели, обученной на 4х классах.
[Инференс 4 класса]
[ссылка](https://drive.google.com/file/d/1ALKQGH6weKxGl3DEC3QB8kTw7k-RSM4x/view?usp=drive_link)

Предсказание модели, обученной на 20ти классах.

[Инференс 20 классов](ссылку сюда)


