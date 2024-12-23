import requests
import json
import logging

# Настройка логгера
logging.basicConfig(filename="api_test_log.log", level=logging.INFO, format="%(asctime)s - %(message)s")
logger = logging.getLogger()

# Адрес вашего API
API_URL = "http://195.133.13.249:8000/predict"

# Тестовые данные
test_cases = [
    {
        "name": "Valid input male user",
        "payload": {"Temperature": 10.0, "Wind_Speed": 3.5, "Precipitation": 0.0, "Sex": "male", "Age": 25},
        "expected_status": 200
    },
    {
        "name": "Valid input female user",
        "payload": {"Temperature": -5.0, "Wind_Speed": 10.0, "Precipitation": 1.0, "Sex": "female", "Age": 30},
        "expected_status": 200
    },
    {
        "name": "Invalid sex field",
        "payload": {"Temperature": 15.0, "Wind_Speed": 5.0, "Precipitation": 0.0, "Sex": "other", "Age": 20},
        "expected_status": 422 
        # выдал 500
    },
    {
        "name": "Missing Temperature field",
        "payload": {"Wind_Speed": 3.0, "Precipitation": 0.0, "Sex": "male", "Age": 22},
        "expected_status": 422
    },
    {
        "name": "Negative Age input",
        "payload": {"Temperature": 12.0, "Wind_Speed": 4.0, "Precipitation": 0.5, "Sex": "female", "Age": -10},
        "expected_status": 422
    },
    {
        "name": "Empty payload",
        "payload": {},
        "expected_status": 422
    },
    {
        "name": "Zero temperature input",
        "payload": {"Temperature": 0.0, "Wind_Speed": 3.0, "Precipitation": 0.0, "Sex": "male", "Age": 25},
        "expected_status": 200
    },
    {
        "name": "High precipitation value",
        "payload": {"Temperature": 5.0, "Wind_Speed": 6.0, "Precipitation": 100.0, "Sex": "male", "Age": 40},
        "expected_status": 200
    },
    {
        "name": "High wind speed value",
        "payload": {"Temperature": 8.0, "Wind_Speed": 50.0, "Precipitation": 2.0, "Sex": "female", "Age": 33},
        "expected_status": 200
    },
    {
        "name": "Large age input",
        "payload": {"Temperature": 15.0, "Wind_Speed": 5.0, "Precipitation": 0.0, "Sex": "male", "Age": 150},
        "expected_status": 200
    }
]

# Функция для тестирования API
def test_api():
    total_tests = len(test_cases)
    passed_tests = 0

    for test in test_cases:
        try:
            # Отправка запроса
            response = requests.post(API_URL, json=test["payload"])
            status_code = response.status_code

            # Логирование результата
            if status_code == test["expected_status"]:
                logger.info(f"TEST PASSED: {test['name']}")
                passed_tests += 1
            else:
                logger.error(f"TEST FAILED: {test['name']} | Expected: {test['expected_status']}, Got: {status_code}")

        except Exception as e:
            logger.error(f"TEST ERROR: {test['name']} | Error: {str(e)}")

    # Итоговый лог
    logger.info(f"TOTAL TESTS: {total_tests}, PASSED: {passed_tests}, FAILED: {total_tests - passed_tests}")
    print(f"TOTAL TESTS: {total_tests}, PASSED: {passed_tests}, FAILED: {total_tests - passed_tests}")

# Запуск тестов
if __name__ == "__main__":
    test_api()
