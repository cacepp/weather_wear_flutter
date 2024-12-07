import csv
import random

def get_weather_category(temperature, precipitation):
    categories = [
        (40, float('inf'), 1, 2),
        (35, 40, 3, 4),
        (30, 35, 5, 6),
        (25, 30, 7, 8),
        (20, 25, 9, 10),
        (15, 20, 11, 12),
        (10, 15, 13, 14),
        (5, 10, 15, 16),
        (2, 5, 17, 18),
        (0, 2, 19, 20),
        (-5, 0, 21, 22),
        (-10, -5, 23, 24),
        (-15, -10, 25, 26),
        (-20, -15, 27, 28),
        (-30, -20, 29, 30),
        (-35, -30, 31, 32),
        (-40, -35, 33, 34)
    ]
    
    for lower, upper, cat_no_precip, cat_with_precip in categories:
        if lower <= temperature < upper:
            return cat_with_precip if precipitation else cat_no_precip
    if temperature >= 40:
        return 2 if precipitation else 1
    if temperature < -40:
        return 34
    return None

def load_clothing(filename):
    clothing_dict = {}
    with open(filename, encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        headers = next(reader)
        for row in reader:
            if len(row) < 5:
                continue
            clothing = row[0].strip()
            gender = row[1].strip()
            age = row[2].strip()
            body_part = row[3].strip()
            categories = []
            for cat in row[4:]:
                cat = cat.strip().rstrip(',')
                if cat.isdigit():
                    categories.append(int(cat))
            if body_part not in clothing_dict:
                clothing_dict[body_part] = {}
            for category in categories:
                if category not in clothing_dict[body_part]:
                    clothing_dict[body_part][category] = []
                clothing_dict[body_part][category].append(clothing)
    return clothing_dict

def select_clothing(clothing_dict, category, body_part):
    if body_part not in clothing_dict:
        return ''
    if category not in clothing_dict[body_part]:
        return ''
    return random.choice(clothing_dict[body_part][category])

def generate_random_weather():
    temperature = round(random.uniform(-40, 40), 1)
    wind_speed = round(random.uniform(0, 30), 1)
    precipitation = random.choices([0, 1], weights=[70, 30])[0]
    return temperature, wind_speed, precipitation

def main():
    random.seed(42)

    clothing_filename = 'file.csv'
    clothing_dict = load_clothing(clothing_filename)

    required_parts = ['Голова', 'Тело', 'Ноги', 'Обувь']
    optional_parts = ['Руки', 'Шея']

    missing_required = [part for part in required_parts if part not in clothing_dict]
    if missing_required:
        print(f"Внимание: В файле '{clothing_filename}' отсутствуют предметы для частей тела: {', '.join(missing_required)}.")
        print("Пожалуйста, добавьте соответствующие записи в 'file.csv'.")
        return

    output_filename = 'res.csv'
    headers = [
        'Temperature', 'Wind_Speed', 'Precipitation', 'Category', 
        'Head_Clothing', 'Body_Clothing', 'Legs_Clothing', 'Shoes_Clothing',
        'Arms_Clothing', 'Neck_Clothing'
    ]
    
    with open(output_filename, 'w', newline='', encoding='utf-8') as outfile:
        writer = csv.writer(outfile)
        writer.writerow(headers)
        
        records_generated = 0
        attempts = 0
        max_attempts = 10000
        
        while records_generated < 10000 and attempts < max_attempts:
            attempts += 1
            temperature, wind_speed, precipitation = generate_random_weather()
            category = get_weather_category(temperature, bool(precipitation))
            
            if category is None:
                continue
            
            head = select_clothing(clothing_dict, category, 'Голова')
            body = select_clothing(clothing_dict, category, 'Тело')
            legs = select_clothing(clothing_dict, category, 'Ноги')
            shoes = select_clothing(clothing_dict, category, 'Обувь')
            
            if not all([head, body, legs, shoes]):
                continue
            
            arms = select_clothing(clothing_dict, category, 'Руки') if 'Руки' in clothing_dict else ''
            neck = select_clothing(clothing_dict, category, 'Шея') if 'Шея' in clothing_dict else ''
            
            writer.writerow([
                temperature,
                wind_speed,
                precipitation,
                category,
                head,
                body,
                legs,
                shoes,
                arms,
                neck
            ])
            records_generated += 1
    
    if records_generated < 100:
        print(f"Успешно создано {records_generated} записей из запрошенных 100. Возможно, недостаточно данных в 'file.csv'.")
    else:
        print(f"Файл '{output_filename}' успешно создан с 100 записями.")

if __name__ == "__main__":
    main()
