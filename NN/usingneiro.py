import numpy as np
import pickle
from tensorflow.keras.models import load_model

# Загрузка модели
model = load_model('clothing_recommendation_model.h5')

# Загрузка скейлера
with open('scaler.pkl', 'rb') as f:
    scaler = pickle.load(f)

# Загрузка энкодеров
with open('label_encoders.pkl', 'rb') as f:
    le_dict = pickle.load(f)

def predict_clothing_recommendation_from_data(inputData):
    """
    Извлекает данные о погоде из inputData (dict) и предсказывает полный комплект одежды.
    
    Ожидается следующая структура:
    {
      "settings": { "age": ..., "sex": ... },
      "coord": { "lon": ..., "lat": ... },
      "weather": [...],
      "main": { "temp": ..., ... },
      "wind": { "speed": ... },
      "clouds": { "all": ... },
      ... 
    }
    
    Параметры для модели:
    - Температура: main["temp"]
    - Скорость ветра: wind["speed"]
    - Осадки: rain["1h"], если есть, иначе 0
    """
    # Извлечение температуры
    temperature = inputData['main']['temp']

    # Извлечение скорости ветра
    wind_speed = inputData['wind']['speed']

    # Извлечение осадков
    precipitation = 0.0
    if 'rain' in inputData and '1h' in inputData['rain']:
        precipitation = inputData['rain']['1h']

    # Создание входного массива
    input_data = np.array([[temperature, wind_speed, precipitation]])

    # Масштабирование входных данных
    input_data_scaled = scaler.transform(input_data)

    # Предсказание модели
    predictions = model.predict(input_data_scaled)

    # Получаем индексы наиболее вероятных классов для каждой категории одежды
    head_pred = np.argmax(predictions[0], axis=1)
    arms_pred = np.argmax(predictions[1], axis=1)
    neck_pred = np.argmax(predictions[2], axis=1)
    body_pred = np.argmax(predictions[3], axis=1)
    legs_pred = np.argmax(predictions[4], axis=1)
    shoes_pred = np.argmax(predictions[5], axis=1)

    # Декодирование индексов в названия одежды
    head_recommend = le_dict['head'].inverse_transform(head_pred)
    arms_recommend = le_dict['arms'].inverse_transform(arms_pred)
    neck_recommend = le_dict['neck'].inverse_transform(neck_pred)
    body_recommend = le_dict['body'].inverse_transform(body_pred)
    legs_recommend = le_dict['legs'].inverse_transform(legs_pred)
    shoes_recommend = le_dict['shoes'].inverse_transform(shoes_pred)

    # Формируем итоговый комплект одежды
    complete_outfit = [
        head_recommend[0],
        arms_recommend[0],
        neck_recommend[0],
        body_recommend[0],
        legs_recommend[0],
        shoes_recommend[0]
    ]

    # Удаляем пустые строки, если они есть
    complete_outfit = [item for item in complete_outfit if item and item.strip()]

    return complete_outfit

# Пример использования
if __name__ == "__main__":
    # Предполагается, что inputData уже получен из другого файла или источника
    inputData = {
        "settings": {"age":18,"sex":"male"},
        "coord": {"lon":21.1669,"lat":42.6727},
        "weather":[{"id":803,"main":"Clouds","description":"broken clouds","icon":"04n"}],
        "base":"stations",
        "main":{"temp":2.77,"feels_like":1.35,"temp_min":2.01,"temp_max":3.43,"pressure":1014,"humidity":84,"sea_level":1014,"grnd_level":937},
        "visibility":10000,
        "wind":{"speed":1.54,"deg":160},
        "clouds":{"all":75},
        "dt":1733594662,
        "sys":{"type":2,"id":2001690,"country":"XK","sunrise":1733550737,"sunset":1733583712},
        "timezone":3600,
        "id":786714,
        "name":"Pristina",
        "cod":200
    }

    recommendation = predict_clothing_recommendation_from_data(inputData)
    print("Рекомендованный комплект одежды:")
    print(", ".join(recommendation))