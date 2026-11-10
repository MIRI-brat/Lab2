-- ============================================================================
-- ЧАСТЬ 1. ИСХОДНЫЕ ЗАПРОСЫ (Сохранены без изменений)
-- ============================================================================

-- 1. Выбрать факультеты, основанные более 10 лет назад, деятельность которых связана с исследованиями в области физики
SELECT *
FROM faculties
WHERE foundation_date < CURRENT_DATE - INTERVAL '10 years'
  AND activity_type ILIKE '%физик%';

-- 2. Выбрать все кафедры, входящие в состав математического факультета, у которых есть веб-сайт
SELECT *
FROM departments
WHERE faculty_code IN (
    SELECT faculty_code 
    FROM faculties 
    WHERE faculty_name ILIKE '%математич%'
)
AND website IS NOT NULL 
AND website <> '';

-- 3. Создать таблицу, содержащую данные 2 запроса с указанием, является ли кафедра выпускающей и номера телефона
DROP TABLE IF EXISTS new_table;

SELECT department_code, faculty_code, department_name, head_of_department, website, is_graduating, phone
INTO new_table
FROM departments
WHERE faculty_code IN (
    SELECT faculty_code 
    FROM faculties 
    WHERE faculty_name ILIKE '%математич%'
)
AND website IS NOT NULL 
AND website <> '';

-- 4. Добавить в созданную таблицу кафедры, в название которых входит слово «информатика»
INSERT INTO new_table (department_code, faculty_code, department_name, head_of_department, website, is_graduating, phone)
SELECT department_code, faculty_code, department_name, head_of_department, website, is_graduating, phone
FROM departments
WHERE department_name ILIKE '%информатик%';

-- 5. В созданной таблице для всех кафедр с четными номерами убрать отметку выпускающей кафедры
UPDATE new_table
SET is_graduating = 'Нет'
WHERE department_code % 2 = 0;

-- 6. Удалить из созданной таблицы все записи для кафедр, у которых отсутствует номер телефона
DELETE FROM new_table
WHERE phone IS NULL OR phone = '';

-- 7. Посчитать сколько выпускающих кафедр находится на каждом факультете
SELECT faculty_code, COUNT(*) AS graduating_departments_count
FROM departments
WHERE is_graduating ILIKE ANY (ARRAY['да', 'true', 'выпускающая', '+', '1', 'yes'])
GROUP BY faculty_code;

SELECT * FROM new_table;


-- ============================================================================
-- ЧАСТЬ 2. РАБОТА СО ССЫЛОЧНОЙ ЦЕЛОСТНОСТЬЮ И ВНЕШНИМИ СОЕДИНЕНИЯМИ (JOIN)
-- ============================================================================

-- КРИТЕРИЙ 1: Ссылочная целостность данных нарушена
-- Примечание: если в базе жестко задан внешний ключ (FOREIGN KEY), временно отключаем его или удаляем для демонстрации нарушения.
-- (Раскомментируйте строку ниже, если СУБД запрещает вставку несуществующего faculty_code; укажите актуальное имя ограничения):
-- ALTER TABLE departments DROP CONSTRAINT IF EXISTS departments_faculty_code_fkey;

-- Добавляем кафедру со ссылкой на несуществующий код факультета (например, 9999)
INSERT INTO departments (department_code, faculty_code, department_name, head_of_department, website, is_graduating, phone)
VALUES (999, 9999, 'Кафедра искусственного интеллекта (тестовая)', 'Иванов И.И.', 'ai.university.ru', 'Да', '+7-999-000-00-00');

-- Также добавим факультет, у которого пока нет ни одной кафедры (например, код 8888), чтобы наглядно показать разницу между LEFT и RIGHT JOIN
INSERT INTO faculties (faculty_code, faculty_name, foundation_date, activity_type)
VALUES (8888, 'Факультет робототехники (без кафедр)', '2020-01-01', 'Робототехника');


-- КРИТЕРИЙ 2: Создан запрос с левосторонним соединением (LEFT JOIN)
-- Выводит ВСЕ факультеты (левая таблица), даже если у них нет кафедр (для факультета 8888 поля кафедры будут NULL).
-- Кафедра-сирота (код 999) сюда НЕ попадёт, так как её faculty_code = 9999 отсутствует в таблице faculties.
SELECT 
    f.faculty_code AS код_факультета,
    f.faculty_name AS название_факультета,
    d.department_code AS код_кафедры,
    d.department_name AS название_кафедры
FROM faculties f
LEFT JOIN departments d ON f.faculty_code = d.faculty_code
ORDER BY f.faculty_code;


-- КРИТЕРИЙ 3: Создан запрос с правосторонним соединением (RIGHT JOIN)
-- Выводит ВСЕ кафедры (правая таблица), даже если их факультет не существует.
-- Здесь мы увидим «потерянную» кафедру (код 999) с NULL в полях факультета, а вот пустой факультет (8888) сюда НЕ попадёт.
SELECT 
    f.faculty_code AS код_факультета,
    f.faculty_name AS название_факультета,
    d.department_code AS код_кафедры,
    d.department_name AS название_кафедры
FROM faculties f
RIGHT JOIN departments d ON f.faculty_code = d.faculty_code
ORDER BY d.department_code;


-- КРИТЕРИЙ 4: Сравнение с симметричным (внутренним) соединением (INNER JOIN)
-- Выводит ТОЛЬКО те записи, где есть строгое совпадение в обеих таблицах.
-- Ни пустой факультет (8888), ни кафедра без факультета (999) в результат НЕ попадают.
SELECT 
    f.faculty_code AS код_факультета,
    f.faculty_name AS название_факультета,
    d.department_code AS код_кафедры,
    d.department_name AS название_кафедры
FROM faculties f
INNER JOIN departments d ON f.faculty_code = d.faculty_code
ORDER BY f.faculty_code;


-- КРИТЕРИЙ 5: Определен запрос, выявляющий нарушение ссылочной целостности данных
-- Ищем в дочерней таблице (departments) записи, у которых нет родительской записи в таблице faculties.
SELECT 
    d.department_code,
    d.department_name,
    d.faculty_code AS несуществующий_код_факультета
FROM departments d
LEFT JOIN faculties f ON d.faculty_code = f.faculty_code
WHERE f.faculty_code IS NULL;


-- КРИТЕРИЙ 6: Ссылочная целостность данных восстановлена
-- Вариант А: Удаляем некорректные («осиротевшие») записи и тестовый пустой факультет
DELETE FROM departments
WHERE faculty_code NOT IN (SELECT faculty_code FROM faculties);

DELETE FROM faculties
WHERE faculty_code = 8888;

-- (Опционально) Возвращаем ограничение внешнего ключа, чтобы база впредь сама защищала целостность:
-- ALTER TABLE departments ADD CONSTRAINT departments_faculty_code_fkey FOREIGN KEY (faculty_code) REFERENCES faculties (faculty_code);

-- Контрольная проверка (запрос должен вернуть 0 строк, что подтверждает восстановление целостности):
SELECT d.*
FROM departments d
LEFT JOIN faculties f ON d.faculty_code = f.faculty_code
WHERE f.faculty_code IS NULL;


