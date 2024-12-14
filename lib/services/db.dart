import 'package:sqflite/sqlite_api.dart';

Future<List<Recommendation>> getHistory(Database db) async {
  // Query the table for all the dogs.
  final List<Map<String, Object?>> historyMaps = await db.query('tbl_history');

  // Convert the list of each dog's fields into a list of `Dog` objects.
  return [
    for (final {
      'id': id as int,
      'Temperature': Temperature as double,
      'Wet': Wet as double,
      'WindDirection': WindDirection as String,
      'WindSpeed': WindSpeed as double,
      'Precipitation': Precipitation as String,
      'FeelingTemperature': FeelingTemperature as double,
      'Date': Date as String,
      'RecommendationText': RecommendationText as String,
      'UserRating': UserRating as int,
    } in historyMaps)
      Recommendation(
        id: id,
        Temperature: Temperature,
        Wet: Wet,
        WindDirection: WindDirection,
        WindSpeed: WindSpeed,
        Precipitation: Precipitation,
        FeelingTemperature: FeelingTemperature,
        Date: Date,
        RecommendationText: RecommendationText,
        UserRating: UserRating
      ),
  ];
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