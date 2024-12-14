import tensorflow as tf

# Загрузка модели
model = tf.keras.models.load_model('best.h5')

# Конвертация в TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Сохранение модели
with open('model.tflite', 'wb') as f:
    f.write(tflite_model)