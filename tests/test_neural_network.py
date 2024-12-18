import pytest
import numpy as np
import pickle
import logging
from tensorflow.keras.models import load_model
from usingneiro import predict_clothing_recommendation_from_data

# Настройка логирования с кодировкой UTF-8
logger = logging.getLogger("test_logger")
logger.setLevel(logging.INFO)
file_handler = logging.FileHandler("recommendation_logs.log", mode='w', encoding="utf-8")  # Указываем кодировку
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
logger.addHandler(file_handler)

@pytest.fixture(scope="module")
def setup_model_and_scaler():
    """
    Загружает модель, scaler и энкодеры для тестирования.
    """
    model = load_model('clothing_recommendation_model.h5')
    with open('scaler.pkl', 'rb') as f:
        scaler = pickle.load(f)
    with open('label_encoders.pkl', 'rb') as f:
        le_dict = pickle.load(f)
    return model, scaler, le_dict


@pytest.mark.parametrize("inputData", [
    {"Temperature": 15, "Wind_Speed": 10, "Precipitation": 0, "Sex": "female", "Age": 25},
    {"Temperature": -5, "Wind_Speed": 20, "Precipitation": 1, "Sex": "male", "Age": 30},
    {"Temperature": 30, "Wind_Speed": 5, "Precipitation": 0, "Sex": "female", "Age": 40},
    {"Temperature": 5, "Wind_Speed": 15, "Precipitation": 1, "Sex": "male", "Age": 20},
    {"Temperature": 10, "Wind_Speed": 0, "Precipitation": 0, "Sex": "female", "Age": 50},
    {"Temperature": 25, "Wind_Speed": 10, "Precipitation": 1, "Sex": "male", "Age": 35},
    {"Temperature": -400, "Wind_Speed": 30, "Precipitation": 1, "Sex": "female", "Age": 18},
    {"Temperature": -10, "Wind_Speed": 25, "Precipitation": 7, "Sex": "male", "Age": 45},
    {"Temperature": 20, "Wind_Speed": 5, "Precipitation": 0, "Sex": "other", "Age": 60},
    {"Temperature": -20, "Wind_Speed": 15, "Precipitation": 1, "Sex": "male", "Age": -10},
])
def test_complete_pipeline(inputData, setup_model_and_scaler):
    """
    Проверяет весь процесс от ввода данных до получения рекомендаций для разных условий.
    """
    recommendations = predict_clothing_recommendation_from_data(inputData)

    # Проверка и логирование пустых предсказаний
    if not recommendations or any(item.strip() == "" for item in recommendations):
        logger.warning(f"Пустые или некорректные предсказания: {recommendations} для входных данных {inputData}")
    else:
        logger.info(f"Полный пайплайн: входные данные: {inputData}, рекомендации: {recommendations}")

    # Проверка структуры и содержимого рекомендаций
    assert isinstance(recommendations, list), "Рекомендации должны быть списком."
    assert 4 <= len(recommendations) <= 6, f"Длина рекомендаций должна быть от 4 до 6, но получено {len(recommendations)}."
    for item in recommendations:
        assert isinstance(item, str), "Каждая рекомендация должна быть строкой."
        assert item.strip() != "", "Рекомендация не должна быть пустой строкой."


def test_model_prediction(setup_model_and_scaler):
    """
    Проверяет, что модель возвращает предсказания в правильной форме и диапазоне.
    """
    model, scaler, le_dict = setup_model_and_scaler
    input_array = np.array([[20, 5, 0, 0, 25]])  # Пример нормализованных данных
    input_scaled = scaler.transform(input_array)
    predictions = model.predict(input_scaled)

    # Логирование предсказаний
    logger.info(f"Модель предсказала: {[pred.tolist() for pred in predictions]}")

    assert len(predictions) == 6, "Ожидается 6 категорий предсказаний."
    for prediction in predictions:
        assert prediction.shape[1] > 0, "Каждая категория должна иметь хотя бы один класс."
        assert np.all(prediction >= 0) and np.all(prediction <= 1), "Вероятности должны быть в диапазоне [0, 1]."


def test_label_decoding(setup_model_and_scaler):
    """
    Проверяет декодирование предсказанных меток в категории одежды.
    """
    _, _, le_dict = setup_model_and_scaler
    fake_predictions = [
        np.array([[0.1, 0.9]]),  # Головной убор
        np.array([[0.3, 0.7]]),  # Руки
        np.array([[0.6, 0.4]]),  # Шея
        np.array([[0.2, 0.8]]),  # Тело
        np.array([[0.5, 0.5]]),  # Ноги
        np.array([[0.9, 0.1]]),  # Обувь
    ]

    decoded_labels = [
        le.inverse_transform([np.argmax(pred)])
        for le, pred in zip(
            [le_dict['head'], le_dict['arms'], le_dict['neck'], le_dict['body'], le_dict['legs'], le_dict['shoes']],
            fake_predictions
        )
    ]

    # Логирование декодированных меток
    logger.info(f"Декодированные предсказания: {decoded_labels}")

    assert len(decoded_labels) == 6, "Декодированные метки должны содержать 6 элементов."
    for label in decoded_labels:
        assert isinstance(label, np.ndarray), "Каждая декодированная метка должна быть массивом."
        assert len(label) == 1, "Каждая декодированная метка должна содержать ровно одну категорию."
