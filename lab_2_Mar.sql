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
DROP TABLE IF EXISTS new_table; -- удаляет старую копию таблицы, если вы уже запускали этот код ранее

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

