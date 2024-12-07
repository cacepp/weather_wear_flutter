import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Dense, Dropout
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping
import matplotlib.pyplot as plt
import pickle

# 1. Загрузка и предобработка данных
# Предполагается, что res.csv содержит столбцы:
# Temperature,Wind_Speed,Precipitation,Category,Head_Clothing,Arms_Clothing,Neck_Clothing,Body_Clothing,Legs_Clothing,Shoes_Clothing

# Загрузка данных
data = pd.read_csv('res.csv')

# Заполнение отсутствующих значений пустыми строками
data.fillna('', inplace=True)

# Определение входных признаков и целевых переменных
X = data[['Temperature', 'Wind_Speed', 'Precipitation']].values

# Целевые переменные: одежда по частям тела
y_head = data['Head_Clothing'].values
y_arms = data['Arms_Clothing'].values
y_neck = data['Neck_Clothing'].values
y_body = data['Body_Clothing'].values
y_legs = data['Legs_Clothing'].values
y_shoes = data['Shoes_Clothing'].values

# Кодирование целевых переменных
le_head = LabelEncoder()
le_arms = LabelEncoder()
le_neck = LabelEncoder()
le_body = LabelEncoder()
le_legs = LabelEncoder()
le_shoes = LabelEncoder()

# Проверка наличия хотя бы одного уникального значения в каждой категории
def check_unique(values, le, category_name):
    if len(set(values)) < 2:
        raise ValueError(f"Категория '{category_name}' должна содержать как минимум два уникальных значения для кодирования.")
    return le.fit_transform(values)

y_head_enc = check_unique(y_head, le_head, 'Head_Clothing')
y_arms_enc = check_unique(y_arms, le_arms, 'Arms_Clothing')
y_neck_enc = check_unique(y_neck, le_neck, 'Neck_Clothing')
y_body_enc = check_unique(y_body, le_body, 'Body_Clothing')
y_legs_enc = check_unique(y_legs, le_legs, 'Legs_Clothing')
y_shoes_enc = check_unique(y_shoes, le_shoes, 'Shoes_Clothing')

# Преобразование в категориальные переменные
num_classes_head = len(le_head.classes_)
num_classes_arms = len(le_arms.classes_)
num_classes_neck = len(le_neck.classes_)
num_classes_body = len(le_body.classes_)
num_classes_legs = len(le_legs.classes_)
num_classes_shoes = len(le_shoes.classes_)

y_head_cat = np.expand_dims(y_head_enc, axis=1)
y_arms_cat = np.expand_dims(y_arms_enc, axis=1)
y_neck_cat = np.expand_dims(y_neck_enc, axis=1)
y_body_cat = np.expand_dims(y_body_enc, axis=1)
y_legs_cat = np.expand_dims(y_legs_enc, axis=1)
y_shoes_cat = np.expand_dims(y_shoes_enc, axis=1)

# Нормализация входных данных
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Разделение на обучающую и тестовую выборки
X_train, X_test, y_head_train, y_head_test, y_arms_train, y_arms_test, \
y_neck_train, y_neck_test, y_body_train, y_body_test, \
y_legs_train, y_legs_test, y_shoes_train, y_shoes_test = train_test_split(
    X_scaled, y_head_cat, y_arms_cat, y_neck_cat, y_body_cat, y_legs_cat, y_shoes_cat,
    test_size=0.2, random_state=42
)

# 2. Построение модели
input_layer = Input(shape=(X_train.shape[1],), name='Input')

# Общие скрытые слои
dense1 = Dense(128, activation='relu', name='Dense_1')(input_layer)
drop1 = Dropout(0.5, name='Dropout_1')(dense1)
dense2 = Dense(64, activation='relu', name='Dense_2')(drop1)
drop2 = Dropout(0.5, name='Dropout_2')(dense2)

# Выходы для каждой категории одежды
output_head = Dense(num_classes_head, activation='softmax', name='head')(drop2)
output_arms = Dense(num_classes_arms, activation='softmax', name='arms')(drop2)
output_neck = Dense(num_classes_neck, activation='softmax', name='neck')(drop2)
output_body = Dense(num_classes_body, activation='softmax', name='body')(drop2)
output_legs = Dense(num_classes_legs, activation='softmax', name='legs')(drop2)
output_shoes = Dense(num_classes_shoes, activation='softmax', name='shoes')(drop2)

# Создание модели
model = Model(inputs=input_layer, outputs=[
    output_head, output_arms, output_neck, output_body, output_legs, output_shoes
])

# 3. Компиляция модели с метриками для каждого выхода
model.compile(
    optimizer=Adam(learning_rate=0.001),
    loss='sparse_categorical_crossentropy',
    metrics={
        'head': 'accuracy',
        'arms': 'accuracy',
        'neck': 'accuracy',
        'body': 'accuracy',
        'legs': 'accuracy',
        'shoes': 'accuracy'
    }
)

model.summary()

# 4. Обучение модели
early_stop = EarlyStopping(
    monitor='val_loss',
    patience=10,
    restore_best_weights=True
)

history = model.fit(
    X_train,
    {
        'head': y_head_train,
        'arms': y_arms_train,
        'neck': y_neck_train,
        'body': y_body_train,
        'legs': y_legs_train,
        'shoes': y_shoes_train
    },
    epochs=200,
    batch_size=32,
    validation_split=0.2,
    callbacks=[early_stop],
    verbose=1
)

# 5. Оценка модели
results = model.evaluate(X_test, {
    'head': y_head_test,
    'arms': y_arms_test,
    'neck': y_neck_test,
    'body': y_body_test,
    'legs': y_legs_test,
    'shoes': y_shoes_test
}, verbose=0)

print(f"Test Loss: {results[0]:.4f}")
print(f"Head Accuracy: {results[1]:.4f}")
print(f"Arms Accuracy: {results[2]:.4f}")
print(f"Neck Accuracy: {results[3]:.4f}")
print(f"Body Accuracy: {results[4]:.4f}")
print(f"Legs Accuracy: {results[5]:.4f}")
print(f"Shoes Accuracy: {results[6]:.4f}")

# 6. Визуализация обучения
plt.figure(figsize=(18, 12))

# Потери
plt.subplot(3, 2, 1)
plt.plot(history.history['head_loss'], label='Train Head Loss')
plt.plot(history.history['val_head_loss'], label='Val Head Loss')
plt.title('Потери Head')
plt.xlabel('Эпоха')
plt.ylabel('Потери')
plt.legend()

plt.subplot(3, 2, 2)
plt.plot(history.history['arms_loss'], label='Train Arms Loss')
plt.plot(history.history['val_arms_loss'], label='Val Arms Loss')
plt.title('Потери Arms')
plt.xlabel('Эпоха')
plt.ylabel('Потери')
plt.legend()

plt.subplot(3, 2, 3)
plt.plot(history.history['neck_loss'], label='Train Neck Loss')
plt.plot(history.history['val_neck_loss'], label='Val Neck Loss')
plt.title('Потери Neck')
plt.xlabel('Эпоха')
plt.ylabel('Потери')
plt.legend()

plt.subplot(3, 2, 4)
plt.plot(history.history['body_loss'], label='Train Body Loss')
plt.plot(history.history['val_body_loss'], label='Val Body Loss')
plt.title('Потери Body')
plt.xlabel('Эпоха')
plt.ylabel('Потери')
plt.legend()

plt.subplot(3, 2, 5)
plt.plot(history.history['legs_loss'], label='Train Legs Loss')
plt.plot(history.history['val_legs_loss'], label='Val Legs Loss')
plt.title('Потери Legs')
plt.xlabel('Эпоха')
plt.ylabel('Потери')
plt.legend()

plt.subplot(3, 2, 6)
plt.plot(history.history['shoes_loss'], label='Train Shoes Loss')
plt.plot(history.history['val_shoes_loss'], label='Val Shoes Loss')
plt.title('Потери Shoes')
plt.xlabel('Эпоха')
plt.ylabel('Потери')
plt.legend()

plt.tight_layout()
plt.show()

plt.figure(figsize=(18, 12))

# Точности
plt.subplot(3, 2, 1)
plt.plot(history.history['head_accuracy'], label='Train Head Accuracy')
plt.plot(history.history['val_head_accuracy'], label='Val Head Accuracy')
plt.title('Точность Head')
plt.xlabel('Эпоха')
plt.ylabel('Точность')
plt.legend()

plt.subplot(3, 2, 2)
plt.plot(history.history['arms_accuracy'], label='Train Arms Accuracy')
plt.plot(history.history['val_arms_accuracy'], label='Val Arms Accuracy')
plt.title('Точность Arms')
plt.xlabel('Эпоха')
plt.ylabel('Точность')
plt.legend()

plt.subplot(3, 2, 3)
plt.plot(history.history['neck_accuracy'], label='Train Neck Accuracy')
plt.plot(history.history['val_neck_accuracy'], label='Val Neck Accuracy')
plt.title('Точность Neck')
plt.xlabel('Эпоха')
plt.ylabel('Точность')
plt.legend()

plt.subplot(3, 2, 4)
plt.plot(history.history['body_accuracy'], label='Train Body Accuracy')
plt.plot(history.history['val_body_accuracy'], label='Val Body Accuracy')
plt.title('Точность Body')
plt.xlabel('Эпоха')
plt.ylabel('Точность')
plt.legend()

plt.subplot(3, 2, 5)
plt.plot(history.history['legs_accuracy'], label='Train Legs Accuracy')
plt.plot(history.history['val_legs_accuracy'], label='Val Legs Accuracy')
plt.title('Точность Legs')
plt.xlabel('Эпоха')
plt.ylabel('Точность')
plt.legend()

plt.subplot(3, 2, 6)
plt.plot(history.history['shoes_accuracy'], label='Train Shoes Accuracy')
plt.plot(history.history['val_shoes_accuracy'], label='Val Shoes Accuracy')
plt.title('Точность Shoes')
plt.xlabel('Эпоха')
plt.ylabel('Точность')
plt.legend()

plt.tight_layout()
plt.show()

# 7. Сохранение модели и препроцессоров
model.save('clothing_recommendation_model.h5')

with open('scaler.pkl', 'wb') as f:
    pickle.dump(scaler, f)

with open('label_encoders.pkl', 'wb') as f:
    pickle.dump({
        'head': le_head,
        'arms': le_arms,
        'neck': le_neck,
        'body': le_body,
        'legs': le_legs,
        'shoes': le_shoes
    }, f)

# 8. Функция для предсказания рекомендаций
def predict_clothing_recommendation(temperature, wind_speed, precipitation):
    # Загрузка скейлера и энкодеров
    with open('scaler.pkl', 'rb') as f:
        scaler = pickle.load(f)
    with open('label_encoders.pkl', 'rb') as f:
        le_dict = pickle.load(f)
    
    # Создание массива входных данных
    input_data = np.array([[temperature, wind_speed, precipitation]])
    input_data_scaled = scaler.transform(input_data)
    
    # Предсказание
    predictions = model.predict(input_data_scaled)
    
    # Распаковка предсказаний
    head_pred = np.argmax(predictions[0], axis=1)
    arms_pred = np.argmax(predictions[1], axis=1)
    neck_pred = np.argmax(predictions[2], axis=1)
    body_pred = np.argmax(predictions[3], axis=1)
    legs_pred = np.argmax(predictions[4], axis=1)
    shoes_pred = np.argmax(predictions[5], axis=1)
    
    # Декодирование предсказаний
    head_recommend = le_dict['head'].inverse_transform(head_pred)
    arms_recommend = le_dict['arms'].inverse_transform(arms_pred)
    neck_recommend = le_dict['neck'].inverse_transform(neck_pred)
    body_recommend = le_dict['body'].inverse_transform(body_pred)
    legs_recommend = le_dict['legs'].inverse_transform(legs_pred)
    shoes_recommend = le_dict['shoes'].inverse_transform(shoes_pred)
    
    # Формирование полного комплекта одежды
    complete_outfit = [
        head_recommend[0],
        arms_recommend[0],
        neck_recommend[0],
        body_recommend[0],
        legs_recommend[0],
        shoes_recommend[0]
    ]
    
    # Удаление пустых рекомендаций
    complete_outfit = [item for item in complete_outfit if item]
    
    return complete_outfit

# 9. Пример использования модели
new_weather = {
    'Temperature': 18.4,
    'Wind_Speed': 16.1,
    'Precipitation': 1
}

recommendation = predict_clothing_recommendation(
    new_weather['Temperature'],
    new_weather['Wind_Speed'],
    new_weather['Precipitation']
)

print("Рекомендованный комплект одежды:")
print(", ".join(recommendation))
