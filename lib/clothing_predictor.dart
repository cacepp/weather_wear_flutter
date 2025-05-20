import 'package:tflite_flutter/tflite_flutter.dart';

class ClothingPredictor {
  late Interpreter _interpreter;

  // final List<String> _outputLabels = [
  //   'coat', 'jacket', 'windbreaker', 'umbrella',
  //   'boots', 'gloves', 'scarf', 'sunglasses',
  //   'face_mask', 'thermal_underwear', 'raincoat',
  //   'sunhat', 'winter_hat', 'high_visibility',
  //   'stay_indoors', 'fleece_jacket', 'waterproof_pants',
  //   'neck_gaiter', 'hand_warmers', 'ice_cleats',
  //   'mosquito_net', 'sunscreen', 'moisturizer',
  //   'lip_balm', 'earmuffs', 'poncho',
  //   'hiking_shoes', 'cycling_gloves', 'ski_goggles',
  //   'sun_shirt', 'windproof_pants', 'insulated_bottle',
  //   'cooling_scarf', 'bug_spray', 'formal_coat',
  //   'running_tights', 'hydration_pack', 'snow_gaiters'
  // ];

  final List<String> _outputLabels = [
    'пальто',
    'зимняя шапка',
    'термобелье',
    'зимние рукавицы',
    'шарф',
    'меховые наушники',
    'зимние ботинки',
    'зимняя куртка',
    'куртка',
    'демисезонные штаны',
    'водонепроницаемые штаны',
    'ветровка',
    'легкие перчатки',
    'легкие штаны',
    'походные ботинки',
    'шляпа от солнца',
    'солнцезащитные очки'
    'легкая рубашка',
    'майка',
    'шорты',
    'легкие кроссовки',
    'платье',
    'теплая куртка',
    'шапка',
    'плотные штаны',
    'водоотталкивающая обувь',
    'рубашка',
    'кроссовки',
    'перчатки',
    'зонт',
    'дождевик',
    'остаться дома',
  ];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/clothing_model_ru.tflite');
    print('Модель загружена. '
        'Входы: ${_interpreter.getInputTensors()}, '
        'Выходы: ${_interpreter.getOutputTensors()}'
    );
  }

  List<double> predict(List<double> input) {
    // 1. Проверка размера входных данных
    final inputSize = _interpreter.getInputTensor(0).shape[1];
    if (input.length != inputSize) {
      throw ArgumentError('Ожидается $inputSize признаков, получено ${input.length}');
    }

    // 2. Подготовка буферов
    final inputBuffer = [input];
    final outputBuffer = List<List<double>>.generate(1, (_) => List.filled(32, 0.0));

    // 3. Выполнение предсказания
    _interpreter.run(inputBuffer, outputBuffer);

    // 4. Возврат результатов
    return outputBuffer[0];
  }

  void close() => _interpreter.close();

  String formatOutput(List<double> output) {
    final result = StringBuffer();
    for (int i = 0; i < output.length; i++) {
      if (output[i] > 0.5) { // Порог можно настроить
        result.writeln(_outputLabels[i]);
      }
    }
    return result.toString();
  }
}

