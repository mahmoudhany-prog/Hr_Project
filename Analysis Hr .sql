1-- لتاكيد من الريلايشن
SELECT 
    f.EmployeeID,
    d.Department,
    r.JobRole,
    f.MonthlyIncome,
    s.JobSatisfaction
FROM [fact_HR] f
JOIN [dim_Department] d ON f.DepartmentID = d.DepartmentID
JOIN [dim_JobRole] r ON f.RoleID = r.RoleID
JOIN [dim_Satisfaction] s ON f.Satisfaction_ID = s.Satisfaction_ID;
-----------------------------------------------------------------------------------------------
2--  معدل ترك العمل في كل قسم
SELECT 
    d.Department,
    COUNT(*) AS TotalEmployees,
    SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS AttritionCount,
    ROUND(CAST(SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100, 2) AS AttritionRate
FROM [fact_HR] f
JOIN [dim_Department] d ON f.DepartmentID = d.DepartmentID
GROUP BY d.Department
ORDER BY AttritionRate DESC;
------------------------------------------------------------------------------------------------
3--تحليل الرواتب والرضا الوظيفي"MonthlyIncome & JobSatisfaction"
SELECT 
    r.JobRole,
    AVG(f.MonthlyIncome) AS AvgMonthlyIncome,
    AVG(CAST(s.JobSatisfaction AS FLOAT)) AS AvgSatisfaction
FROM [fact_HR] f
JOIN [dim_JobRole] r ON f.RoleID = r.RoleID
JOIN [dim_Satisfaction] s ON f.Satisfaction_ID = s.Satisfaction_ID
GROUP BY r.JobRole
ORDER BY AvgMonthlyIncome DESC;
------------------------------------------------------------------------------------------------------
4-- تأثير "العمل الإضافي" على "التوازن بين العمل والحياة""WorkLifeBalance & OverTime"
SELECT 
    f.OverTime,
    AVG(CAST(s.WorkLifeBalance AS FLOAT)) AS AvgWorkLifeBalance,
    COUNT(*) AS EmployeeCount
FROM [fact_HR] f
JOIN [dim_Satisfaction] s ON f.Satisfaction_ID = s.Satisfaction_ID
GROUP BY f.OverTime;
------------------------------------------------------------------------------------------------------
5--"All Data"انشاء جدول وههمي للحصول علي الداتا مجمعة
CREATE VIEW v_HR_Master_Report AS
SELECT 
    f.*, 
    d.Department, d.Department_Group,
    r.JobRole, r.BusinessTravel, r.JobLevel,
    s.JobSatisfaction, s.EnvironmentSatisfaction, s.WorkLifeBalance
FROM [fact_HR] f
JOIN [dim_Department] d ON f.DepartmentID = d.DepartmentID
JOIN [dim_JobRole] r ON f.RoleID = r.RoleID
JOIN [dim_Satisfaction] s ON f.Satisfaction_ID = s.Satisfaction_ID;
SELECT * FROM v_HR_Master_Report 
------------------------------------------------------------------------------------------------------
6-- تحليل "عدالة الرواتب" (Salary Fairness Analysis)
SELECT 
    f.EmployeeID,
    d.Department,
    r.JobRole,
    f.MonthlyIncome,
    -- حساب متوسط راتب القسم لكل موظف في سطر واحد
    AVG(f.MonthlyIncome) OVER(PARTITION BY d.Department) AS DeptAvgSalary,
    -- حساب الفرق بين راتب الموظف ومتوسط قسمه
    f.MonthlyIncome - AVG(f.MonthlyIncome) OVER(PARTITION BY d.Department) AS SalaryDiff
FROM [fact_HR] f
JOIN [dim_Department] d ON f.DepartmentID = d.DepartmentID
JOIN [dim_JobRole] r ON f.RoleID = r.RoleID
ORDER BY SalaryDiff ASC;
---------------------------------------------------------------------------------------------------
7--تحليل "الارتباط" بين المسافة والاحتراق الوظيفي"DistanceFromHome & AttritionRate "
SELECT 
    CASE 
        WHEN DistanceFromHome <= 5 THEN 'Near (0-5km)'
        WHEN DistanceFromHome <= 15 THEN 'Moderate (6-15km)'
        ELSE 'Far (15km+)'
    END AS DistanceCategory,
    COUNT(*) AS TotalEmployees,
    ROUND(CAST(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100, 2) AS AttritionRate
FROM [fact_HR]
GROUP BY 
    CASE 
        WHEN DistanceFromHome <= 5 THEN 'Near (0-5km)'
        WHEN DistanceFromHome <= 15 THEN 'Moderate (6-15km)'
        ELSE 'Far (15km+)'
    END
ORDER BY AttritionRate DESC;
-------------------------------------------------------------------------------------------
8--تحليل "جمود الترقيات" "Stagnation in promotions"
SELECT 
    f.EmployeeID,
    d.Department,
    d.Department_Group, 
    f.YearsAtCompany,
    f.YearsSinceLastPromotion,
    s.PerformanceRating,
-- نسبة الركود الوظيفي
    ROUND(CAST(f.YearsSinceLastPromotion AS FLOAT) / NULLIF(f.YearsAtCompany, 0) * 100, 2) AS StagnationIndex
FROM [fact_HR] f
JOIN [dim_Satisfaction] s ON f.Satisfaction_ID = s.Satisfaction_ID
JOIN [dim_Department] d ON f.DepartmentID = d.DepartmentID
WHERE f.YearsSinceLastPromotion > 5 
AND s.PerformanceRating >= 3
ORDER BY StagnationIndex DESC;
--------------------------------------------------------------------------------------------------------------------
9--تحليل "الأجيال" "Generations analysis"
SELECT 
    CASE 
        WHEN Age < 30 THEN 'Gen Z (Under 30)'
        WHEN Age BETWEEN 30 AND 45 THEN 'Millennials (30-45)'
        ELSE 'Gen X+ (Over 45)'
    END AS AgeGroup,
    COUNT(*) AS EmployeeCount,
    ROUND(AVG(MonthlyIncome), 0) AS AvgIncome,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS AttritionRate
FROM [fact_HR] f
JOIN [dim_employee] e ON f.EmployeeID = e.EmployeeID
GROUP BY 
    CASE 
        WHEN Age < 30 THEN 'Gen Z (Under 30)'
        WHEN Age BETWEEN 30 AND 45 THEN 'Millennials (30-45)'
        ELSE 'Gen X+ (Over 45)'
    END
---------------------------------------------------------------------------------------
10--تحليل "الولاء مقابل الراتب""Tenure Level"
SELECT 
    CASE 
        WHEN TotalWorkingYears <= 2 THEN 'Junior (0-2y)'
        WHEN TotalWorkingYears <= 7 THEN 'Intermediate (3-7y)'
        ELSE 'Senior (7y+)'
    END AS TenureLevel,
    OverTime,
    COUNT(*) AS TotalEmployees,
    ROUND(AVG(MonthlyIncome), 0) AS AvgSalary,
    -- نسبة الناس اللي مشيت
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS AttritionRate
FROM [fact_HR]
GROUP BY 
    CASE 
        WHEN TotalWorkingYears <= 2 THEN 'Junior (0-2y)'
        WHEN TotalWorkingYears <= 7 THEN 'Intermediate (3-7y)'
        ELSE 'Senior (7y+)'
    END,
    OverTime
ORDER BY TenureLevel, OverTime;
-----------------------------------------------------------------------
11--تحليل "ساعات العمل الإضافية والاحتراق""Job burnout & OverTime,"
SELECT 
    OverTime,
    COUNT(*) AS EmpCount,
    ROUND(AVG(CAST(s.WorkLifeBalance AS FLOAT)), 2) AS AvgWorkLifeBalance,
    ROUND(AVG(CAST(s.EnvironmentSatisfaction AS FLOAT)), 2) AS AvgEnvSatisfaction,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS AttritionRate
FROM [fact_HR] f
JOIN [dim_Satisfaction] s ON f.Satisfaction_ID = s.Satisfaction_ID
GROUP BY OverTime;
-------------------------------------------------------------------------------------------------
12--مؤشر "التوازن" (Work-Life Balance):/مؤشر "المسافة" (Distance Factor):/الرضا عن البيئة
SELECT 
    CASE 
        WHEN TotalWorkingYears <= 2 THEN 'Junior (0-2y)'
        WHEN TotalWorkingYears <= 7 THEN 'Intermediate (3-7y)'
        ELSE 'Senior (7y+)'
    END AS TenureLevel,
    f.OverTime,
    -- تحليل بيئة العمل والرضا (نفسي)
    ROUND(AVG(CAST(s.EnvironmentSatisfaction AS FLOAT)), 2) AS AvgEnvSatisfaction,
    ROUND(AVG(CAST(s.WorkLifeBalance AS FLOAT)), 2) AS AvgWorkLifeBalance,
    -- تحليل المسافة (جسدي)
    ROUND(AVG(f.DistanceFromHome), 1) AS AvgDistance,
    -- تحليل مادي (الراتب مقابل الجهد)
    ROUND(AVG(f.MonthlyIncome), 0) AS AvgIncome,
    -- النتيجة النهائية (الاستقالات)
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS AttritionRate
FROM [fact_HR] f
JOIN [dim_Satisfaction] s ON f.Satisfaction_ID = s.Satisfaction_ID
GROUP BY 
    CASE 
        WHEN TotalWorkingYears <= 2 THEN 'Junior (0-2y)'
        WHEN TotalWorkingYears <= 7 THEN 'Intermediate (3-7y)'
        ELSE 'Senior (7y+)'
    END,
    f.OverTime
ORDER BY AttritionRate DESC;
--------------------------------------------------------------------------------------------------------
13--تحليل إضافي (Bonus): تحليل التخصصات "الهشة""“Fragile” specialties & Bonus"
SELECT 
    e.EducationField,
    COUNT(*) AS TotalCount,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS AttritionRate,
    AVG(MonthlyIncome) AS AvgSalary
FROM [fact_HR] f
JOIN [dim_Education] e ON f.EducationID = e.EducationID
GROUP BY e.EducationField
ORDER BY AttritionRate DESC;
----------------------------------------------------------------------------------------------------------
14--تحليل "المسافة والاحتراق" (Distance & Burnout)
SELECT 
    f.OverTime,
    CASE 
        WHEN f.DistanceFromHome <= 5 THEN 'Near'
        WHEN f.DistanceFromHome BETWEEN 6 AND 15 THEN 'Moderate'
        ELSE 'Far'
    END AS DistanceCategory,
    COUNT(*) AS JuniorCount,
    ROUND(SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS AttritionRate
FROM [fact_HR] f
WHERE f.TotalWorkingYears <= 2 -- تركيزنا على الـ Juniors
GROUP BY f.OverTime, 
    CASE 
        WHEN f.DistanceFromHome <= 5 THEN 'Near'
        WHEN f.DistanceFromHome BETWEEN 6 AND 15 THEN 'Moderate'
        ELSE 'Far'
    END
ORDER BY AttritionRate DESC;
-----------------------------------------------------------------------------------------------
15--تحليل "العلاقة مع المدير" (Management vs. Attrition)
SELECT 
    f.YearsWithCurrManager,
    COUNT(*) AS TotalEmployees,
    ROUND(AVG(CAST(s.JobSatisfaction AS FLOAT)), 2) AS AvgSatisfaction,
    ROUND(SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS AttritionRate
FROM [fact_HR] f
JOIN [dim_Satisfaction] s ON f.Satisfaction_ID = s.Satisfaction_ID
GROUP BY f.YearsWithCurrManager
ORDER BY f.YearsWithCurrManager;
--------------------------------------------------------------------------------
16--تحليل الأقسام (الأكثر فقداً للموظفين في السنة الأولى)"NewHires & AttritionRate"
SELECT 
    d.Department,
    d.Department_Group,
    COUNT(f.EmployeeID) AS NewHiresCount,
    SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS LeaversInYearZero,
    ROUND(SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.EmployeeID), 2) AS AttritionRate_Year0
FROM [fact_HR] f
JOIN [dim_Department] d ON f.DepartmentID = d.DepartmentID
WHERE f.YearsWithCurrManager = 0 -- التركيز على السنة الأولى فقط
GROUP BY d.Department, d.Department_Group
ORDER BY AttritionRate_Year0 DESC;
--------------------------------------------------------------------------------------------------------------------------
17--تحليل المسميات الوظيفية (هل المشكلة في طبيعة الدور؟)"JobRole & AttritionRate"
SELECT 
    r.JobRole,
    COUNT(f.EmployeeID) AS TotalInRole,
    ROUND(SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.EmployeeID), 2) AS AttritionRate_Year0
FROM [fact_HR] f
JOIN [dim_JobRole] r ON f.RoleID = r.RoleID
WHERE f.YearsWithCurrManager = 0
GROUP BY r.JobRole
HAVING COUNT(f.EmployeeID) > 5 -- فلتر لاستبعاد الأعداد الصغيرة جداً
ORDER BY AttritionRate_Year0 DESC;
-----------------------------------------------------------------------------------------------------------------------------
18--الاستعلام اللي هيربط الدور الوظيفي بالـ Overtime والـ Attrition للموظفين اللي في سنتهم الأولى (Year 0) فقط
SELECT 
    r.JobRole,
    f.OverTime,
    COUNT(f.EmployeeID) AS TotalInRole,
    SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS Leavers,
    ROUND(SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.EmployeeID), 2) AS AttritionRate_Year0
FROM [fact_HR] f
JOIN [dim_JobRole] r ON f.RoleID = r.RoleID
WHERE f.YearsWithCurrManager = 0
GROUP BY r.JobRole, f.OverTime
ORDER BY r.JobRole, f.OverTime;
-------------------------------------------------------------------------------------------------------------------------------
--إليكِ الاستعلام الذي يحسب مجموع الرواتب الشهرية المفقودة (Monthly Income Loss) لكل دور وظيفي تضرر من الاستقالات في السنة الأولى:
SELECT 
    r.JobRole,
    COUNT(f.EmployeeID) AS LeaversCount,
    -- إجمالي الرواتب المفقودة شهرياً
    SUM(f.MonthlyIncome) AS MonthlySalaryLoss,
    -- إجمالي الخسارة السنوية المتوقعة (راتب 12 شهر)
    SUM(f.MonthlyIncome) * 12 AS AnnualSalaryLoss,
    ROUND(AVG(f.MonthlyIncome), 0) AS AvgSalaryOfLeaver
FROM [fact_HR] f
JOIN [dim_JobRole] r ON f.RoleID = r.RoleID
WHERE f.YearsWithCurrManager = 0 
AND f.Attrition = 'Yes'
GROUP BY r.JobRole
ORDER BY AnnualSalaryLoss DESC;

----------------------------------------------------------------------------------------------------------------
20-SELECT 
    e.[Gender], 
    e.[MaritalStatus],
    COUNT(e.[EmployeeID]) AS TotalEmployees,
    SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS TotalResigned,
    -- حساب نسبة الاستقالة لكل فئة
    CAST(SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(e.[EmployeeID]) AS DECIMAL(10,2)) AS AttritionRate
FROM 
    [dw_HR].[dbo].[dim_employee] AS e
LEFT JOIN 
    [dbo].[fact_HR] AS f -- افتراض اسم جدول الحقائق الخاص بك
    ON e.[EmployeeID] = f.[EmployeeID]
GROUP BY 
    e.[Gender], e.[MaritalStatus]
ORDER BY 
    AttritionRate DESC
    ------------------------
    21-
    SELECT 
    dim_JobRole.BusinessTravel, 
    COUNT(fact_HR.EmployeeID) AS Total_Employees,
    SUM(CASE WHEN fact_HR.Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    -- حساب معدل الاستقالات كنسبة مئوية
    CAST(SUM(CASE WHEN fact_HR.Attrition = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / 
    NULLIF(COUNT(fact_HR.EmployeeID), 0) * 100 AS AttritionRate
FROM fact_HR
JOIN dim_JobRole ON fact_HR.RoleID = dim_JobRole.RoleID
GROUP BY dim_JobRole.BusinessTravel