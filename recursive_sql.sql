--https://dba.stackexchange.com/questions/175774/finding-the-first-parent-manager-of-an-employee-that-makes-twice-as-much-in-a
WITH RECURSIVE hieararchy AS
(
	SELECT 
		1 AS lvl
		, TITLE 
		, EMPLOYEE_ID 
		, manager_id
		, '' AS reporting_line 
		, salary
	FROM SANDBOX.SSATUNIN.EMPLOYEES
	WHERE EMPLOYEE_ID = 1
	UNION ALL 
	SELECT 
		lvl + 1 AS lvl
		, e.TITLE 
		, e.EMPLOYEE_ID 
		, e.MANAGER_ID 
		, to_char(e.MANAGER_ID)  || ',' || h.reporting_line 
		, e.salary
	FROM SANDBOX.SSATUNIN.EMPLOYEES e
		 INNER JOIN HIEARARCHY h ON (e.manager_id = h.employee_id)
)
SELECT 
		all_emp.lvl
		, all_emp.TITLE 
		, all_emp.EMPLOYEE_ID 
		, all_emp.manager_id
		, all_emp.salary
		, all_emp.reporting_line
		, managers.employee_id AS first_manager_in_hierarchy_with_2x_salary
		, managers.salary AS managers_salary
		, row_number() over(PARTITION BY all_emp.employee_id ORDER BY managers.lvl desc)
FROM hieararchy all_emp
	 INNER JOIN hieararchy managers ON array_contains(to_char(managers.employee_id)::variant, split(all_emp.reporting_line, ','))
WHERE managers.salary >= all_emp.salary * 2
QUALIFY row_number() over(PARTITION BY all_emp.employee_id ORDER BY managers.lvl desc) = 1