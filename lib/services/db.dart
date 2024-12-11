import 'package:sqflite/sqlite_api.dart';

Future<List<Recommendation>> getHistory(Database db) async {
  final List<Map<String, Object?>> historyMaps = await db.query('tbl_history');

  return historyMaps.map((map) {
    return Recommendation(
      id: map['id'] as int,
      Temperature: map['Temperature'] as double,
      Wet: map['Wet'] as double,
      WindDirection: map['WindDirection'] as String,
      WindSpeed: map['WindSpeed'] as double,
      Precipitation: map['Precipitation'] as String,
      FeelingTemperature: map['FeelingTemperature'] as double,
      Date: map['Date'] as String,
      RecommendationText: map['RecommendationText'] as String,
      UserRating: map['UserRating'] as int,
    );
  }).toList();
}

Future<void> addHistoryRecord(Recommendation record, Database db) async {
  // Insert the Dog into the correct table. You might also specify the
  // `conflictAlgorithm` to use in case the same dog is inserted twice.
  //
  // In this case, replace any previous data.
  await db.insert(
    'tbl_history',
    record.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}


class Recommendation {
  final int id;
  final double Temperature;
  final double Wet;
  final String WindDirection;
  final double WindSpeed;
  final String Precipitation;
  final double FeelingTemperature;
  final String Date;
  final String RecommendationText;
  final int UserRating;

  const Recommendation({
    required this.id,
    required this.Temperature,
    required this.Wet,
    required this.WindDirection,
    required this.WindSpeed,
    required this.Precipitation,
    required this.FeelingTemperature,
    required this.Date,
    required this.RecommendationText,
    required this.UserRating,
  });

  Map<String, Object?> toMap() {
    // Convert a Dog into a Map. The keys must correspond to the names of the
    // columns in the database.
    return {
      'id': id,
      'Temperature': Temperature,
      'Wet': Wet,
      'WindDirection': WindDirection,
      'WindSpeed': WindSpeed,
      'Precipitation': Precipitation,
      'FeelingTemperature': FeelingTemperature,
      'Date': Date,
      'RecommendationText': RecommendationText,
      'UserRating': UserRating,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Request[${id}]: [${Temperature}] [${Wet}] [${WindDirection}] '
        '[${WindSpeed}] [${Precipitation}] [${FeelingTemperature}] [${Date}] '
        '[${RecommendationText}] [${UserRating}] ';
  }
}

Future<void> populateDatabase(Database db) async {
  final recommendations = [
    Recommendation(
      id: 1,
      Temperature: 25.0,
      Wet: 60.0,
      WindDirection: 'North',
      WindSpeed: 12.0,
      Precipitation: 'None',
      FeelingTemperature: 24.0,
      Date: '2024-12-11',
      RecommendationText: 'It’s a good day for a walk!',
      UserRating: 5,
    ),
    Recommendation(
      id: 2,
      Temperature: 15.0,
      Wet: 80.0,
      WindDirection: 'East',
      WindSpeed: 10.0,
      Precipitation: 'Rain',
      FeelingTemperature: 12.0,
      Date: '2024-12-10',
      RecommendationText: 'Carry an umbrella!',
      UserRating: 4,
    ),
  ];

  for (var recommendation in recommendations) {
    await addHistoryRecord(recommendation, db);
  }
}