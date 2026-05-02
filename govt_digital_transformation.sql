-- ================
-- Database Create
-- ================

CREATE DATABASE govt_digital_transformation;

-- ============
-- Database Use
-- ============

USE govt_digital_transformation;

-- ============
-- Tables Create
-- =============

CREATE TABLE Departments2 (
dept_id INT PRIMARY KEY,
dept_name VARCHAR(100),
ministry VARCHAR(100),
head_city VARCHAR(50)
);

CREATE TABLE Contractors (
contractor_id INT PRIMARY KEY,
company_name VARCHAR(120),
expertise VARCHAR(100),
hq_city VARCHAR(50)
);

CREATE TABLE Projects (
project_id INT PRIMARY KEY,
project_name VARCHAR(150),
dept_id INT,
state VARCHAR(50),
budget_crore DECIMAL(10,2),
status VARCHAR(50)
);

CREATE TABLE Project_Assignments (
assignment_id INT PRIMARY KEY,
project_id INT,
contractor_id INT,
contract_value_crore DECIMAL(10,2)
);

CREATE TABLE Project_KPI (
kpi_id INT PRIMARY KEY,
project_id INT,
year INT,
quarter VARCHAR(10),
progress_percent INT,
budget_utilization_percent INT,
citizen_satisfaction DECIMAL(4,2)
);

-- ===============
-- CSV Data Import
-- ===============

-- ===========
-- Departments
-- ===========

COPY Departments2
(dept_id, dept_name, ministry, head_city)
FROM 'D:\sql project\departments.csv'
DELIMITER ','
CSV HEADER;

-- ===========
-- Contractors
-- ===========

COPY Contractors
(contractor_id, company_name, expertise, hq_city)
FROM 'D:\sql project\contractors.csv'
DELIMITER ','
CSV HEADER;

-- ========
-- Projects
-- ========

COPY Projects
(project_id, project_name, dept_id, state, budget_crore, status)
FROM 'D:\sql project\projects.csv'
DELIMITER ','
CSV HEADER;

-- ===================
-- Project Assignments
-- ===================

COPY Project_Assignments
(assignment_id, project_id, contractor_id, contract_value_crore)
FROM 'D:\sql project\project_assignments.csv'
DELIMITER ','
CSV HEADER;

-- ===========
-- Project KPI
-- ===========
COPY Project_KPI
(kpi_id, project_id, year, quarter, progress_percent, budget_utilization_percent, citizen_satisfaction)
FROM 'D:\sql project\project_kpi_175k_rows.csv'
DELIMITER ','
CSV HEADER;

-- ===========
-- Data Verify
-- ===========
SELECT * FROM Departments2;
SELECT * FROM Contractors;
SELECT * FROM Projects;
SELECT * FROM Project_Assignments;
SELECT * FROM Project_KPI;

-- ===================
-- Total Records Check
-- ===================
SELECT COUNT(*) FROM Project_KPI;

-- ==============================
-- 1️.Department wise Total Budget
-- ==============================

SELECT d.dept_name,
SUM(p.budget_crore) AS total_budget
FROM Projects p
JOIN Departments2 d ON p.dept_id = d.dept_id
GROUP BY d.dept_name
ORDER BY total_budget DESC;
-- ===============================
-- 2️.State wise Number of Projects
-- ===============================

SELECT state,
COUNT(*) AS total_projects
FROM Projects
GROUP BY state
ORDER BY total_projects DESC;
-- ===============================
-- 3️.Top 5 Highest Budget Projects
-- ===============================

SELECT project_name, budget_crore
FROM Projects
ORDER BY budget_crore DESC
LIMIT 5;

-- ===============================
-- 4️.Contractor with Most Projects
-- ===============================

SELECT c.company_name,
COUNT(pa.project_id) AS total_projects
FROM Contractors c
JOIN Project_Assignments pa 
ON c.contractor_id = pa.contractor_id
GROUP BY c.company_name
ORDER BY total_projects DESC;

-- =======================================
-- 5️.Average Citizen Satisfaction by State
-- =======================================

SELECT p.state,
AVG(k.citizen_satisfaction) AS avg_satisfaction
FROM Project_KPI k
JOIN Projects p
ON k.project_id = p.project_id
GROUP BY p.state
ORDER BY avg_satisfaction DESC;

-- =======================================
-- 6️.Projects with Budget > Average Budget
-- =======================================

SELECT project_name, budget_crore
FROM Projects
WHERE budget_crore >
(
SELECT AVG(budget_crore)
FROM Projects
);

-- =============================
-- 7️.Yearly Progress of Projects
-- =============================

SELECT year,
AVG(progress_percent) AS avg_progress
FROM Project_KPI
GROUP BY year
ORDER BY year;

-- ====================
-- 8️.Contractor Revenue
-- ====================

SELECT c.company_name,
SUM(pa.contract_value_crore) AS revenue
FROM Contractors c
JOIN Project_Assignments pa
ON c.contractor_id = pa.contractor_id
GROUP BY c.company_name
ORDER BY revenue DESC;

-- ============================================
-- 9️.Projects with Low Citizen Satisfaction (<3)
-- ============================================

SELECT DISTINCT p.project_name
FROM Projects p
JOIN Project_KPI k
ON p.project_id = k.project_id
WHERE citizen_satisfaction < 3;

-- =============================
-- 10.Average Budget by Ministry
-- =============================

SELECT d.ministry,
AVG(p.budget_crore) AS avg_budget
FROM Projects p
JOIN Departments2 d
ON p.dept_id = d.dept_id
GROUP BY d.ministry;

-- ===========================
-- 11.Running Average Progress
-- ===========================

SELECT project_id,
year,
quarter,
progress_percent,
AVG(progress_percent) OVER
(PARTITION BY project_id ORDER BY year)
AS running_avg
FROM Project_KPI;

-- ==========================
-- 12.Rank Projects by Budget
-- ==========================

SELECT project_name,
budget_crore,
RANK() OVER
(ORDER BY budget_crore DESC) AS rank_budget
FROM Projects;

-- ==============================
-- 13.Top Contractor in Each City
-- ==============================

SELECT *
FROM
(
SELECT company_name,
hq_city,
COUNT(*) AS projects,
RANK() OVER
(PARTITION BY hq_city ORDER BY COUNT(*) DESC) AS rnk
FROM Contractors c
JOIN Project_Assignments pa
ON c.contractor_id = pa.contractor_id
GROUP BY company_name, hq_city
) t
WHERE rnk = 1;

-- ===========================
-- 14.Budget Utilization Trend
-- ===========================

SELECT year,
AVG(budget_utilization_percent) AS avg_utilization
FROM Project_KPI
GROUP BY year;

-- ====================================
-- 15.Projects Delayed (Progress < 50%)
-- ====================================

SELECT DISTINCT p.project_name
FROM Projects p
JOIN Project_KPI k
ON p.project_id = k.project_id
WHERE progress_percent < 50;

-- ============================
-- 16.State with Highest Budget
-- ============================

SELECT state,
SUM(budget_crore) AS total_budget
FROM Projects
GROUP BY state
ORDER BY total_budget DESC
LIMIT 1;

-- =============================
-- 17.Project Count per Ministry
-- =============================

SELECT d.ministry,
COUNT(p.project_id) AS total_projects
FROM Projects p
JOIN Departments2 d
ON p.dept_id = d.dept_id
GROUP BY d.ministry;

-- ========================================
-- 18.Citizen Satisfaction Trend by Quarter
-- ========================================

SELECT quarter,
AVG(citizen_satisfaction) AS avg_rating
FROM Project_KPI
GROUP BY quarter;

-- =========================================
-- 19.Contractors Working in Multiple States
-- =========================================

SELECT c.company_name,
COUNT(DISTINCT p.state) AS states
FROM Contractors c
JOIN Project_Assignments pa
ON c.contractor_id = pa.contractor_id
JOIN Projects p
ON pa.project_id = p.project_id
GROUP BY c.company_name
HAVING COUNT(DISTINCT p.state) > 1;

-- ============================================
-- 20.Top Performing Project (Highest Progress)
-- ============================================

SELECT project_id,
AVG(progress_percent) AS avg_progress
FROM Project_KPI
GROUP BY project_id
ORDER BY avg_progress DESC
LIMIT 1;

-- ==============================
-- 21.Budget vs Progress Analysis
-- ==============================

SELECT p.project_name,
p.budget_crore,
AVG(k.progress_percent) AS progress
FROM Projects p
JOIN Project_KPI k
ON p.project_id = k.project_id
GROUP BY p.project_name, p.budget_crore;

-- =========================
-- 22.Average KPI by Project
-- =========================

SELECT project_id,
AVG(progress_percent) AS avg_progress,
AVG(budget_utilization_percent) AS avg_budget_use
FROM Project_KPI
GROUP BY project_id;

-- ================================
-- 23.Department with Most Projects
-- ================================

SELECT d.dept_name,
COUNT(p.project_id) AS project_count
FROM Projects p
JOIN Departments2 d
ON p.dept_id = d.dept_id
GROUP BY d.dept_name
ORDER BY project_count DESC;

-- ================================
-- 24.Latest KPI Record per Project
-- ================================

SELECT *
FROM Project_KPI k
WHERE (year, quarter) =
(
SELECT MAX(year), MAX(quarter)
FROM Project_KPI
);

-- ===================================
-- 25.Percentage of Completed Projects
-- ===================================

SELECT
COUNT(CASE WHEN status='Completed' THEN 1 END)*100.0
/
COUNT(*) AS completion_rate
FROM Projects;

-- ==========================================
-- 26.State with Highest Citizen Satisfaction
-- ==========================================

SELECT p.state,
AVG(k.citizen_satisfaction) AS rating
FROM Project_KPI k
JOIN Projects p
ON k.project_id = p.project_id
GROUP BY p.state
ORDER BY rating DESC
LIMIT 1;

-- ===============================
-- 27.Contractor Performance Score
-- ===============================

SELECT c.company_name,
AVG(k.progress_percent) AS performance
FROM Contractors c
JOIN Project_Assignments pa
ON c.contractor_id = pa.contractor_id
JOIN Project_KPI k
ON pa.project_id = k.project_id
GROUP BY c.company_name
ORDER BY performance DESC;

-- ===============================
-- 28.Budget Utilization Above 80%
-- ===============================

SELECT DISTINCT project_id
FROM Project_KPI
WHERE budget_utilization_percent > 80;

-- ========================
-- 29.Ministry Budget Share
-- ========================

SELECT d.ministry,
SUM(p.budget_crore) /
(SELECT SUM(budget_crore) FROM Projects)
*100 AS budget_share
FROM Projects p
JOIN Departments2 d
ON p.dept_id = d.dept_id
GROUP BY d.ministry;

-- ===================================================
-- 30.Most Consistent Projects (Low Progress Variance)
-- ===================================================
SELECT project_id,
STDDEV(progress_percent) AS progress_variance
FROM Project_KPI
GROUP BY project_id
ORDER BY progress_variance ASC;

