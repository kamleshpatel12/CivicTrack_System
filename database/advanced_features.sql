-- ================================================================================
-- CIVIC ISSUE TRACKING SYSTEM - ADVANCED FEATURES
-- Subqueries, Cursors, and Stored Procedures (Simplified)
-- ================================================================================

USE civic_issue_db;

-- ================================================================================
-- STORED PROCEDURES
-- ================================================================================

-- PROCEDURE 1: Get Department Performance Report (Nested Subqueries)
DELIMITER $$
CREATE PROCEDURE sp_department_performance_report()
BEGIN
    SELECT 
        d.id,
        d.department_name,
        (SELECT COUNT(*) FROM issues i 
         JOIN admins a ON i.assigned_to = a.email 
         WHERE a.department_id = d.id) AS total_issues,
        (SELECT COUNT(*) FROM issues i 
         JOIN admins a ON i.assigned_to = a.email 
         WHERE a.department_id = d.id AND i.status = 'Resolved') AS resolved_issues,
        ROUND(
            (SELECT COUNT(*) FROM issues i 
             JOIN admins a ON i.assigned_to = a.email 
             WHERE a.department_id = d.id AND i.status = 'Resolved') * 100.0 /
            NULLIF((SELECT COUNT(*) FROM issues i 
             JOIN admins a ON i.assigned_to = a.email 
             WHERE a.department_id = d.id), 0), 2
        ) AS resolution_rate_percent
    FROM department d
    ORDER BY resolved_issues DESC;
END$$
DELIMITER ;

-- PROCEDURE 2: Assign Priority Based on Issue Age
DELIMITER $$
CREATE PROCEDURE sp_auto_assign_priority()
BEGIN
    DECLARE priority_high_id INT;
    DECLARE priority_medium_id INT;
    DECLARE priority_low_id INT;
    
    SET priority_high_id = (SELECT id FROM priority_level WHERE priority_name = 'High' LIMIT 1);
    SET priority_medium_id = (SELECT id FROM priority_level WHERE priority_name = 'Medium' LIMIT 1);
    SET priority_low_id = (SELECT id FROM priority_level WHERE priority_name = 'Low' LIMIT 1);
    
    UPDATE issues 
    SET priority_level_id = priority_high_id
    WHERE priority_level_id IS NULL 
    AND DATEDIFF(CURDATE(), created_at) > 30
    AND status != 'Resolved';
    
    UPDATE issues 
    SET priority_level_id = priority_medium_id
    WHERE priority_level_id IS NULL 
    AND DATEDIFF(CURDATE(), created_at) BETWEEN 15 AND 30
    AND status != 'Resolved';
    
    UPDATE issues 
    SET priority_level_id = priority_low_id
    WHERE priority_level_id IS NULL 
    AND DATEDIFF(CURDATE(), created_at) < 15
    AND status != 'Resolved';
    
    SELECT 'Priority assignment completed' AS result;
END$$
DELIMITER ;

-- PROCEDURE 3: Get High Priority Issues for Admin (Nested Subquery)
DELIMITER $$
CREATE PROCEDURE sp_get_high_priority_issues(IN dept_id INT)
BEGIN
    SELECT 
        i.id,
        i.title,
        i.description,
        i.address,
        i.issue_type,
        i.status,
        c.full_name as citizen_name,
        pl.priority_name,
        DATEDIFF(CURDATE(), i.created_at) as days_open,
        (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id AND status != 'Resolved') as citizen_open_issues
    FROM issues i
    JOIN citizens c ON i.citizen_id = c.id
    JOIN priority_level pl ON i.priority_level_id = pl.id
    JOIN admins a ON i.assigned_to = a.email
    WHERE a.department_id = dept_id
    AND pl.priority_name = 'High'
    AND i.status != 'Resolved'
    ORDER BY i.created_at ASC;
END$$
DELIMITER ;

-- PROCEDURE 4: Generate Monthly Issue Statistics (Nested Subqueries)
DELIMITER $$
CREATE PROCEDURE sp_monthly_issue_statistics(IN report_year INT, IN report_month INT)
BEGIN
    SELECT 
        DATE_FORMAT(CURDATE(), '%Y-%m') AS month,
        (SELECT COUNT(*) FROM issues 
         WHERE YEAR(created_at) = report_year AND MONTH(created_at) = report_month) AS total_reported,
        (SELECT COUNT(*) FROM issues 
         WHERE YEAR(created_at) = report_year AND MONTH(created_at) = report_month 
         AND status = 'Resolved') AS total_resolved,
        (SELECT COUNT(*) FROM issues 
         WHERE YEAR(created_at) = report_year AND MONTH(created_at) = report_month 
         AND status = 'In Progress') AS in_progress,
        (SELECT COUNT(*) FROM issues 
         WHERE YEAR(created_at) = report_year AND MONTH(created_at) = report_month 
         AND status = 'Rejected') AS rejected;
END$$
DELIMITER ;

-- PROCEDURE 5: Bulk Update Issue Status (Uses Cursor)
DELIMITER $$
CREATE PROCEDURE sp_bulk_update_status(IN new_status VARCHAR(50), IN issue_count INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE issue_id_var INT;
    DECLARE old_status_var VARCHAR(50);
    DECLARE cursor_issues CURSOR FOR 
        SELECT id, status FROM issues 
        WHERE status != new_status AND status != 'Resolved' 
        LIMIT issue_count;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cursor_issues;
    
    read_loop: LOOP
        FETCH cursor_issues INTO issue_id_var, old_status_var;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        UPDATE issues SET status = new_status WHERE id = issue_id_var;
        INSERT INTO issue_history (issue_id, status, changed_by, change_reason)
        VALUES (issue_id_var, new_status, 'SYSTEM', CONCAT('Bulk update from ', old_status_var));
        
    END LOOP;
    
    CLOSE cursor_issues;
    
    SELECT CONCAT('Updated ', issue_count, ' issues to status: ', new_status) AS result;
END$$
DELIMITER ;

-- PROCEDURE 6: Get Issues by Location (Correlated Subquery)
DELIMITER $$
CREATE PROCEDURE sp_get_issues_by_location(IN city_name VARCHAR(100))
BEGIN
    SELECT 
        i.id,
        i.title,
        i.description,
        i.address,
        i.issue_type,
        i.status,
        c.full_name as reported_by,
        (SELECT COUNT(*) FROM issues 
         WHERE YEAR(created_at) = YEAR(i.created_at) 
         AND MONTH(created_at) = MONTH(i.created_at)
         AND address LIKE CONCAT('%', city_name, '%')) AS issues_this_month_in_city
    FROM issues i
    JOIN citizens c ON i.citizen_id = c.id
    WHERE i.address LIKE CONCAT('%', city_name, '%')
    ORDER BY i.created_at DESC;
END$$
DELIMITER ;

-- PROCEDURE 7: Close Resolved Issues and Archive (Uses Cursor)
DELIMITER $$
CREATE PROCEDURE sp_archive_resolved_issues()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE issue_id_var INT;
    DECLARE cursor_resolved CURSOR FOR 
        SELECT id FROM issues 
        WHERE status = 'Resolved' 
        AND DATEDIFF(CURDATE(), updated_at) > 90;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cursor_resolved;
    
    archive_loop: LOOP
        FETCH cursor_resolved INTO issue_id_var;
        IF done THEN
            LEAVE archive_loop;
        END IF;
        
        INSERT INTO audit_logs (admin_email, action, details)
        VALUES ('SYSTEM', 'ARCHIVE', CONCAT('Issue ', issue_id_var, ' archived after 90 days resolved'));
        
    END LOOP;
    
    CLOSE cursor_resolved;
    
    SELECT 'Archival process completed' AS result;
END$$
DELIMITER ;

-- PROCEDURE 8: Get Citizen Activity Report (Nested Subqueries)
DELIMITER $$
CREATE PROCEDURE sp_citizen_activity_report(IN citizen_email VARCHAR(255))
BEGIN
    SELECT 
        c.full_name,
        c.email,
        c.phone_number,
        c.created_at as member_since,
        (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) AS total_reports,
        (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id AND status = 'Resolved') AS resolved_reports,
        (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id AND status = 'In Progress') AS ongoing_reports,
        (SELECT MAX(created_at) FROM issues WHERE citizen_id = c.id) AS last_report_date
    FROM citizens c
    WHERE c.email = citizen_email;
END$$
DELIMITER ;

-- PROCEDURE 9: Identify Problem Areas (Group + Subquery)
DELIMITER $$
CREATE PROCEDURE sp_identify_problem_areas()
BEGIN
    SELECT 
        COALESCE(i.address, 'Unknown') as location,
        COUNT(i.id) as issue_count,
        GROUP_CONCAT(DISTINCT i.issue_type SEPARATOR ', ') as issue_types,
        MIN(i.created_at) as first_report_date,
        MAX(i.created_at) as last_report_date
    FROM issues i
    GROUP BY i.address
    HAVING issue_count > 2
    ORDER BY issue_count DESC;
END$$
DELIMITER ;

-- PROCEDURE 10: Admin Workload Distribution (Nested Subqueries)
DELIMITER $$
CREATE PROCEDURE sp_admin_workload_distribution()
BEGIN
    SELECT 
        a.id,
        a.full_name,
        a.email,
        d.department_name,
        (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email) AS assigned_issues,
        (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email AND status = 'Resolved') AS resolved,
        (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email AND status = 'In Progress') AS in_progress,
        ROUND(
            (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email AND status = 'Resolved') * 100.0 / 
            NULLIF((SELECT COUNT(*) FROM issues WHERE assigned_to = a.email), 0), 2
        ) AS resolution_rate_percent
    FROM admins a
    LEFT JOIN department d ON a.department_id = d.id
    WHERE a.is_active = TRUE
    ORDER BY assigned_issues DESC;
END$$
DELIMITER ;

-- ================================================================================
-- VIEWS WITH NESTED SUBQUERIES
-- ================================================================================

DROP VIEW IF EXISTS vw_unresolved_high_priority;
CREATE VIEW vw_unresolved_high_priority AS
SELECT 
    i.id,
    i.title,
    i.description,
    i.address,
    c.full_name as citizen_name,
    pl.priority_name,
    DATEDIFF(CURDATE(), i.created_at) as days_open,
    (SELECT COUNT(*) FROM issues 
     WHERE citizen_id = c.id AND status != 'Resolved') AS citizen_open_issues
FROM issues i
JOIN citizens c ON i.citizen_id = c.id
JOIN priority_level pl ON i.priority_level_id = pl.id
WHERE i.status != 'Resolved'
AND pl.priority_name IN ('High', 'Medium')
ORDER BY pl.priority_name DESC, i.created_at ASC;

DROP VIEW IF EXISTS vw_department_dashboard;
CREATE VIEW vw_department_dashboard AS
SELECT 
    d.id,
    d.department_name,
    COUNT(i.id) as total_issues,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) as resolved,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) as in_progress,
    SUM(CASE WHEN i.status = 'Pending' THEN 1 ELSE 0 END) as pending,
    ROUND(SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) * 100.0 / 
    NULLIF(COUNT(i.id), 0), 2) as resolution_rate
FROM department d
LEFT JOIN admins a ON a.department_id = d.id
LEFT JOIN issues i ON i.assigned_to = a.email
GROUP BY d.id, d.department_name;

DROP VIEW IF EXISTS vw_citizen_issues_summary;
CREATE VIEW vw_citizen_issues_summary AS
SELECT 
    c.id,
    c.full_name,
    c.email,
    COUNT(i.id) as total_reports,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) as resolved_reports,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) as ongoing_reports,
    MAX(i.created_at) as last_report_date
FROM citizens c
LEFT JOIN issues i ON i.citizen_id = c.id
GROUP BY c.id, c.full_name, c.email;

-- ================================================================================
-- VIEW 4: Admin Performance Metrics (Response Time & Metrics)
-- ================================================================================
DROP VIEW IF EXISTS vw_admin_performance_metrics;
CREATE VIEW vw_admin_performance_metrics AS
SELECT 
    a.id,
    a.full_name,
    a.email,
    d.department_name,
    COUNT(i.id) as total_assigned,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) as resolved_count,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) as in_progress_count,
    SUM(CASE WHEN i.status = 'Pending' THEN 1 ELSE 0 END) as pending_count,
    ROUND(AVG(DATEDIFF(i.updated_at, i.created_at)), 1) as avg_resolution_days,
    ROUND(
        SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(i.id), 0), 2
    ) as resolution_percentage
FROM admins a
LEFT JOIN department d ON a.department_id = d.id
LEFT JOIN issues i ON i.assigned_to = a.email
WHERE a.is_active = TRUE
GROUP BY a.id, a.full_name, a.email, d.department_name
ORDER BY resolution_percentage DESC;

-- ================================================================================
-- PROCEDURE 11: Notify Citizens of Overdue Issues (Uses CURSOR)
-- ================================================================================
DELIMITER $$
CREATE PROCEDURE sp_notify_overdue_issues()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE issue_id_var INT;
    DECLARE citizen_id_var INT;
    DECLARE citizen_email_var VARCHAR(255);
    DECLARE days_open_var INT;
    DECLARE cursor_overdue CURSOR FOR 
        SELECT i.id, i.citizen_id, c.email, DATEDIFF(CURDATE(), i.created_at)
        FROM issues i
        JOIN citizens c ON i.citizen_id = c.id
        WHERE i.status IN ('Reported', 'Pending')
        AND DATEDIFF(CURDATE(), i.created_at) > 30;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cursor_overdue;
    
    notify_loop: LOOP
        FETCH cursor_overdue INTO issue_id_var, citizen_id_var, citizen_email_var, days_open_var;
        IF done THEN
            LEAVE notify_loop;
        END IF;
        
        -- Log notification in audit_logs (simulating email notification)
        INSERT INTO audit_logs (admin_email, action, details)
        VALUES ('SYSTEM', 'NOTIFY', CONCAT('Citizen ', citizen_email_var, ' notified - Issue ', issue_id_var, ' is ', days_open_var, ' days old'));
        
        -- Mark issue with a notification flag
        UPDATE issues SET status = 'Pending' WHERE id = issue_id_var AND status = 'Reported';
        
    END LOOP;
    
    CLOSE cursor_overdue;
    
    SELECT 'Notification process completed' AS result;
END$$
DELIMITER ;

-- ================================================================================
-- PROCEDURE 12: Generate Monthly Report by Department (Uses CURSOR)
-- ================================================================================
DELIMITER $$
CREATE PROCEDURE sp_generate_monthly_reports()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE dept_id_var INT;
    DECLARE dept_name_var VARCHAR(100);
    DECLARE total_issues_var INT;
    DECLARE resolved_issues_var INT;
    DECLARE cursor_departments CURSOR FOR 
        SELECT DISTINCT d.id, d.department_name 
        FROM department d
        WHERE EXISTS (SELECT 1 FROM admins WHERE department_id = d.id);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cursor_departments;
    
    report_loop: LOOP
        FETCH cursor_departments INTO dept_id_var, dept_name_var;
        IF done THEN
            LEAVE report_loop;
        END IF;
        
        -- Calculate totals for this department
        SELECT COUNT(*) INTO total_issues_var
        FROM issues i
        JOIN admins a ON i.assigned_to = a.email
        WHERE a.department_id = dept_id_var
        AND MONTH(i.created_at) = MONTH(CURDATE())
        AND YEAR(i.created_at) = YEAR(CURDATE());
        
        SELECT COUNT(*) INTO resolved_issues_var
        FROM issues i
        JOIN admins a ON i.assigned_to = a.email
        WHERE a.department_id = dept_id_var
        AND i.status = 'Resolved'
        AND MONTH(i.created_at) = MONTH(CURDATE())
        AND YEAR(i.created_at) = YEAR(CURDATE());
        
        -- Log the report generation
        INSERT INTO audit_logs (admin_email, action, details)
        VALUES ('SYSTEM', 'REPORT', CONCAT('Monthly Report: ', dept_name_var, ' - Total: ', total_issues_var, ', Resolved: ', resolved_issues_var));
        
    END LOOP;
    
    CLOSE cursor_departments;
    
    SELECT 'Monthly reports generated for all departments' AS result;
END$$
DELIMITER ;

-- ================================================================================
-- 4-5 KEY NESTED QUERY EXAMPLES (For Teacher Demonstration)
-- ================================================================================

-- NESTED QUERY 1: Department Performance with Multiple Levels
-- Shows total issues per department with resolution rate
SELECT 
    d.id,
    d.department_name,
    (SELECT COUNT(*) FROM issues i 
     JOIN admins a ON i.assigned_to = a.email 
     WHERE a.department_id = d.id) AS total_issues,
    (SELECT COUNT(*) FROM issues i 
     JOIN admins a ON i.assigned_to = a.email 
     WHERE a.department_id = d.id AND i.status = 'Resolved') AS resolved_issues,
    ROUND(
        (SELECT COUNT(*) FROM issues i 
         JOIN admins a ON i.assigned_to = a.email 
         WHERE a.department_id = d.id AND i.status = 'Resolved') * 100.0 / 
        NULLIF((SELECT COUNT(*) FROM issues i 
         JOIN admins a ON i.assigned_to = a.email 
         WHERE a.department_id = d.id), 0), 2
    ) AS resolution_rate
FROM department d
WHERE d.id IN (SELECT DISTINCT department_id FROM admins)
ORDER BY total_issues DESC;

-- NESTED QUERY 2: Citizen with Most Issues and Their Status Breakdown
-- Shows which citizen reported most issues and current status distribution
SELECT 
    c.id,
    c.full_name,
    c.email,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) AS total_issues,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id AND status = 'Resolved') AS resolved,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id AND status = 'In Progress') AS in_progress,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id AND status = 'Pending') AS pending
FROM citizens c
WHERE (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) > 0
ORDER BY (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) DESC
LIMIT 10;

-- NESTED QUERY 3: Issues in Hotspot Areas
-- Finds areas with recurring issues (3+ issues) with current status
SELECT 
    i.address,
    COUNT(i.id) as total_issues,
    (SELECT COUNT(*) FROM issues WHERE address = i.address AND status = 'Resolved') as resolved,
    (SELECT COUNT(*) FROM issues WHERE address = i.address AND status = 'In Progress') as in_progress,
    (SELECT MAX(created_at) FROM issues WHERE address = i.address) as latest_report
FROM issues i
GROUP BY i.address
HAVING total_issues > 2
ORDER BY total_issues DESC;

-- NESTED QUERY 4: Admin Performance Ranking
-- Shows admin names with their resolution stats and department
SELECT 
    a.full_name,
    d.department_name,
    (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email) as total_assigned,
    (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email AND status = 'Resolved') as resolved,
    ROUND(
        (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email AND status = 'Resolved') * 100.0 / 
        NULLIF((SELECT COUNT(*) FROM issues WHERE assigned_to = a.email), 0), 2
    ) as resolution_rate_percent
FROM admins a
LEFT JOIN department d ON a.department_id = d.id
WHERE a.is_active = TRUE
ORDER BY resolution_rate_percent DESC;

-- NESTED QUERY 5: Issues Not Yet Resolved and Days Open
-- Shows unresolved issues with days in system, grouped by status
SELECT 
    status,
    COUNT(*) as count,
    AVG(DATEDIFF(CURDATE(), created_at)) as avg_days_open,
    MIN(DATEDIFF(CURDATE(), created_at)) as min_days,
    MAX(DATEDIFF(CURDATE(), created_at)) as max_days,
    (SELECT COUNT(*) FROM issues WHERE status IN ('Reported', 'Pending') 
     AND DATEDIFF(CURDATE(), created_at) > 30) as overdue_count
FROM issues
WHERE status IN ('Reported', 'Pending', 'In Progress')
GROUP BY status;

-- To execute procedures, uncomment and run:
-- CALL sp_department_performance_report();
-- CALL sp_auto_assign_priority();
-- CALL sp_get_high_priority_issues(1);
-- CALL sp_monthly_issue_statistics(2026, 4);
-- CALL sp_bulk_update_status('In Progress', 5);
-- CALL sp_get_issues_by_location('Manipal');
-- CALL sp_archive_resolved_issues();
-- CALL sp_citizen_activity_report('citizen@example.com');
-- CALL sp_identify_problem_areas();
-- CALL sp_admin_workload_distribution();
-- CALL sp_notify_overdue_issues();
-- CALL sp_generate_monthly_reports();

-- Select from views:
-- SELECT * FROM vw_unresolved_high_priority;
-- SELECT * FROM vw_department_dashboard;
-- SELECT * FROM vw_citizen_issues_summary;
-- SELECT * FROM vw_admin_performance_metrics;

-- ================================================================================
-- OPTIMIZATION INDEXES FOR PERFORMANCE (7-8 Key Indexes)
-- ================================================================================

-- Composite indexes for common query patterns
ALTER TABLE issues ADD INDEX idx_citizen_status (citizen_id, status);
ALTER TABLE issues ADD INDEX idx_assigned_status (assigned_to, status);
ALTER TABLE issues ADD INDEX idx_status_created (status, created_at);

-- Indexes for issue_history table
ALTER TABLE issue_history ADD INDEX idx_issue_created (issue_id, changed_at);

-- Indexes for audit_logs table
ALTER TABLE audit_logs ADD INDEX idx_action_date (action_type, created_at);

-- Indexes for citizens table
ALTER TABLE citizens ADD INDEX idx_email_created (email, created_at);

-- Indexes for admins table
ALTER TABLE admins ADD INDEX idx_dept_active (department_id, is_active);

-- Indexes for location table
ALTER TABLE location ADD INDEX idx_city_area (city, area_name);

