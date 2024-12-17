import numpy as np
import pickle
from tensorflow.keras.models import load_model
import random
import pandas as pd
from inputData import input_data

def read_input_data():
    """
    Обрабатывает данные из переменной input_data (JSON-объект) и возвращает их в виде списка словарей.
    
    Returns:
        list: Список словарей с данными.
    """
    # Проверка, является ли input_data списком словарей
    if isinstance(input_data, list):
        input_data_list = input_data  # Если это уже список, просто присваиваем

    # Если это словарь, то нормализуем данные в список словарей
    elif isinstance(input_data, dict):
        input_data_list = pd.json_normalize(input_data).to_dict(orient='records')
    
    else:
        # Если формат данных неизвестен, выбрасываем ошибку
        raise ValueError("Неизвестный формат данных в input_data")
    
    return input_data_list

def predict_clothing_recommendation_from_data(inputData):
    """
    Извлекает данные из inputData, предобрабатывает их и предсказывает комплект одежды.
    
    Args:
        inputData (dict): Содержит Temperature, Wind_Speed, Precipitation, Sex, Age.
    
    Returns:
        list: Рекомендованный комплект одежды.
    """
    # Извлечение признаков из inputData
    temperature = inputData.get('Temperature')
    wind_speed = inputData.get('Wind_Speed')
    precipitation = inputData.get('Precipitation')
    sex = inputData.get('Sex')
    age = inputData.get('Age')
    
    # Проверка наличия всех необходимых признаков
    if temperature is None or wind_speed is None or precipitation is None or sex is None or age is None:
        raise ValueError("Input data must contain Temperature, Wind_Speed, Precipitation, Sex, and Age.")
    
    # Преобразование пола в числовой формат: 'male' -> 0, 'female' -> 1
    sex_mapping = {'male': 0, 'female': 1}
    sex_numeric = sex_mapping.get(sex.lower())
    if sex_numeric is None:
        raise ValueError("Sex must be either 'male' or 'female'.")
    
    # Создание массива входных данных в нужном формате
    # Порядок признаков: [Temperature, Wind_Speed, Precipitation, Sex, Age]
    input_array = np.array([[temperature, wind_speed, precipitation, sex_numeric, age]])
    
    # Загрузка скейлера
    with open('scaler.pkl', 'rb') as f:
        scaler = pickle.load(f)
    
    # Масштабирование входных данных
    try:
        input_scaled = scaler.transform(input_array)
    except ValueError as e:
        raise ValueError(f"Ошибка при масштабировании данных: {e}")
    
    # Загрузка модели
    model = load_model('clothing_recommendation_model.h5')
    
    # Загрузка энкодеров
    with open('label_encoders.pkl', 'rb') as f:
        le_dict = pickle.load(f)
    
    # Предсказание модели
    predictions = model.predict(input_scaled)
    
    # Извлечение предсказаний для каждой категории одежды
    head_pred = np.argmax(predictions[0], axis=1)
    arms_pred = np.argmax(predictions[1], axis=1)
    neck_pred = np.argmax(predictions[2], axis=1)
    body_pred = np.argmax(predictions[3], axis=1)
    legs_pred = np.argmax(predictions[4], axis=1)
    shoes_pred = np.argmax(predictions[5], axis=1)
    
    # Декодирование предсказаний обратно в наименования одежды
    head_recommend = le_dict['head'].inverse_transform(head_pred)
    arms_recommend = le_dict['arms'].inverse_transform(arms_pred)
    neck_recommend = le_dict['neck'].inverse_transform(neck_pred)
    body_recommend = le_dict['body'].inverse_transform(body_pred)
    legs_recommend = le_dict['legs'].inverse_transform(legs_pred)
    shoes_recommend = le_dict['shoes'].inverse_transform(shoes_pred)
    
    # Формирование итогового комплекта одежды
    complete_outfit = [
        head_recommend[0],
        arms_recommend[0],
        neck_recommend[0],
        body_recommend[0],
        legs_recommend[0],
        shoes_recommend[0]
    ]
    
    # Удаление пустых рекомендаций, если они есть
    complete_outfit = [item for item in complete_outfit if item and item.strip()]
    
    return complete_outfit

if __name__ == "__main__":
    # Чтение данных из файла
    file_path = 'input_data.csv'  # Путь к файлу с данными
    input_data_list = read_input_data(file_path)
    
    # Предсказания для каждого набора данных
    for i, input_data in enumerate(input_data_list):
        print(f"\nТест {i+1}: {input_data}")
        try:
            # Получение рекомендации по одежде
            recommendation = predict_clothing_recommendation_from_data(input_data)
            print("Рекомендованный комплект одежды:")
            print(", ".join(recommendation))
        except Exception as e:
            print(f"Произошла ошибка при предсказании: {e}")
