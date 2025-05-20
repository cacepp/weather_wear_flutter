import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

Future<List<Map<String, Object?>>> getHistory(Database db) async {
  return await db.query('tbl_history', orderBy: "id DESC");
}

Future<void> addRecord(Recommendation record, Database db) async {
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

void createTableHistory(Batch batch) {
  batch.execute('DROP TABLE IF EXISTS tbl_history');
  batch.execute('''CREATE TABLE tbl_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    Temperature REAL,
    Wet REAL,
    WindDirection TEXT,
    WindSpeed REAL,
    Precipitation TEXT,
    FeelingTemperature REAL,
    Date TEXT,
    RecommendationText TEXT,
    UserRating INTEGER
  )''');
}


class Recommendation {
  final int? id;
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
    this.id,
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
    Recommendation(
      id: 3,
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
    Recommendation(
      id: 4,
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
    Recommendation(
      id: 5,
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
    Recommendation(
      id: 6,
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
    Recommendation(
      id: 7,
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
    Recommendation(
      id: 8,
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
    await addRecord(recommendation, db);
  }
}