from fastapi import FastAPI
from pydantic import BaseModel
import numpy as np
import pickle
import tensorflow 
from tensorflow.keras.models import load_model

app = FastAPI()

# Загрузка модели и вспомогательных объектов при старте приложения
model = load_model('model/model.h5')
if model != None:
    print("OK")

with open('model/scaler.pkl', 'rb') as f:
    scaler = pickle.load(f)

with open('model/label_encoders.pkl', 'rb') as f:
    le_dict = pickle.load(f)

# Определение Pydantic-класса для валидации входных данных
class InputData(BaseModel):
    Temperature: float
    Wind_Speed: float
    Precipitation: float
    Sex: str
    Age: int


@app.post("/predict")
def predict(data: InputData):
    # Извлечение данных
    temperature = data.Temperature
    wind_speed = data.Wind_Speed
    precipitation = data.Precipitation
    sex = data.Sex
    age = data.Age

    # Преобразование пола
    sex_mapping = {'male': 0, 'female': 1}
    sex_numeric = sex_mapping[sex]

    # Формирование входного массива
    input_array = np.array([[temperature, wind_speed, precipitation, sex_numeric, age]], dtype=float)

    # Масштабирование входных данных
    input_scaled = scaler.transform(input_array)

    # Предсказание модели
    predictions = model.predict(input_scaled)

    # Предполагается, что модель возвращает список предсказаний по категориям одежды,
    # например: predictions = [pred_head, pred_arms, pred_neck, pred_body, pred_legs, pred_shoes]
    # где каждый пред_* - это массив вероятностей для соответствующей категории
    head_pred = np.argmax(predictions[0], axis=1)
    arms_pred = np.argmax(predictions[1], axis=1)
    neck_pred = np.argmax(predictions[2], axis=1)
    body_pred = np.argmax(predictions[3], axis=1)
    legs_pred = np.argmax(predictions[4], axis=1)
    shoes_pred = np.argmax(predictions[5], axis=1)

    head_recommend = le_dict['head'].inverse_transform(head_pred)
    arms_recommend = le_dict['arms'].inverse_transform(arms_pred)
    neck_recommend = le_dict['neck'].inverse_transform(neck_pred)
    body_recommend = le_dict['body'].inverse_transform(body_pred)
    legs_recommend = le_dict['legs'].inverse_transform(legs_pred)
    shoes_recommend = le_dict['shoes'].inverse_transform(shoes_pred)

    # Формирование итогового комплекта
    complete_outfit = [
        head_recommend[0],
        arms_recommend[0],
        neck_recommend[0],
        body_recommend[0],
        legs_recommend[0],
        shoes_recommend[0]
    ]

    # Удаление пустых элементов, если есть
    complete_outfit = [item for item in complete_outfit if item and item.strip()]

    # Возврат итоговой рекомендации строкой или списком
    # Если нужен именно строковый вывод, например через запятую:
    result_str = ", ".join(complete_outfit)

    return {"recommendation": result_str}
