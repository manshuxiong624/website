-- One row per family, built from person-level longitudinal income records.
-- CASE expressions select age windows; AVG aggregates annual log income.
WITH parent_measures AS (
    SELECT
        fm.family_id,
        fm.person_id AS parent_person_id,
        AVG(CASE WHEN i.age = 25 THEN LOG(i.annual_income) END) AS parent_log_income_age25,
        AVG(CASE WHEN i.age = 30 THEN LOG(i.annual_income) END) AS parent_log_income_age30,
        AVG(CASE WHEN i.age = 35 THEN LOG(i.annual_income) END) AS parent_log_income_age35,
        AVG(CASE WHEN i.age BETWEEN 35 AND 39 THEN LOG(i.annual_income) END) AS parent_avg_log_income_35_39
    FROM family_members AS fm
    JOIN income AS i ON i.person_id = fm.person_id
    WHERE fm.role = 'parent'
    GROUP BY fm.family_id, fm.person_id
),
child_measures AS (
    SELECT
        fm.family_id,
        fm.person_id AS child_person_id,
        AVG(CASE WHEN i.age = 25 THEN LOG(i.annual_income) END) AS child_log_income_age25,
        AVG(CASE WHEN i.age = 30 THEN LOG(i.annual_income) END) AS child_log_income_age30,
        AVG(CASE WHEN i.age = 35 THEN LOG(i.annual_income) END) AS child_log_income_age35,
        AVG(CASE WHEN i.age BETWEEN 35 AND 39 THEN LOG(i.annual_income) END) AS child_avg_log_income_35_39
    FROM family_members AS fm
    JOIN income AS i ON i.person_id = fm.person_id
    WHERE fm.role = 'child'
    GROUP BY fm.family_id, fm.person_id
)
SELECT
    p.family_id,
    p.parent_person_id,
    c.child_person_id,
    EXP(p.parent_log_income_age25) AS parent_age25_income,
    EXP(p.parent_log_income_age30) AS parent_age30_income,
    EXP(p.parent_log_income_age35) AS parent_age35_income,
    EXP(p.parent_avg_log_income_35_39) AS parent_avg_35_39_income,
    EXP(c.child_log_income_age25) AS child_age25_income,
    EXP(c.child_log_income_age30) AS child_age30_income,
    EXP(c.child_log_income_age35) AS child_age35_income,
    EXP(c.child_avg_log_income_35_39) AS child_avg_35_39_income
FROM parent_measures AS p
JOIN child_measures AS c ON c.family_id = p.family_id
ORDER BY p.family_id;
