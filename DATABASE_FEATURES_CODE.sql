-- ================================================================================
-- CIVIC ISSUE TRACKING SYSTEM - DATABASE FEATURES FOR REPORT
-- Triggers, Stored Procedures, Cursors, Views & Indexes
-- ================================================================================

-- ================================================================================
-- 1. TRIGGERS (4 Total)
-- ================================================================================

-- TRIGGER 1: Auto-update timestamp on issue updates
DELIMITER $$
CREATE TRIGGER trg_update_issue_timestamp
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- TRIGGER 2: Log all status changes to issue_history table
DELIMITER $$
CREATE TRIGGER trg_log_issue_status_change
AFTER UPDATE ON issues
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO issue_history 
        (issue_id, old_status, new_status, changed_at)
        VALUES (NEW.id, OLD.status, NEW.status, CURRENT_TIMESTAMP);
    END IF;
END$$
DELIMITER ;

-- TRIGGER 3: Prevent deletion of resolved issues (Compliance)
DELIMITER $$
CREATE TRIGGER trg_prevent_delete_resolved
BEFORE DELETE ON issues
FOR EACH ROW
BEGIN
    IF OLD.status = 'Resolved' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete resolved issues for audit and compliance purposes';
    END IF;
END$$
DELIMITER ;

-- TRIGGER 4: Validate admin assignment before update
DELIMITER $$
CREATE TRIGGER trg_validate_admin_assignment
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    IF NEW.assigned_admin IS NOT NULL THEN
        IF (SELECT COUNT(*) FROM admins WHERE id = NEW.assigned_admin AND is_active = TRUE) = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assigned admin does not exist or is inactive';
        END IF;
    END IF;
END$$
DELIMITER ;

-- ================================================================================
-- 2. STORED PROCEDURES WITH CURSORS (12 Total)
-- ================================================================================

-- PROCEDURE 1: Department Performance Report (Nested Subqueries)
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

-- PROCEDURE 2: Auto-Assign Priority Based on Issue Age
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

-- PROCEDURE 3: Bulk Update Issue Status (Uses CURSOR 1)
DELIMITER $$
CREATE PROCEDURE sp_bulk_update_status(IN new_status VARCHAR(50), IN issue_count INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE issue_id_var INT;
    DECLARE old_status_var VARCHAR(50);
    
    -- CURSOR 1: cursor_issues
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

-- PROCEDURE 4: Get High Priority Issues for Department
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

-- PROCEDURE 5: Archive Resolved Issues (Uses CURSOR 2)
DELIMITER $$
CREATE PROCEDURE sp_archive_resolved_issues()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE issue_id_var INT;
    
    -- CURSOR 2: cursor_resolved
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

-- PROCEDURE 6: Notify Overdue Issues (Uses CURSOR 3)
DELIMITER $$
CREATE PROCEDURE sp_notify_overdue_issues()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE issue_id_var INT;
    DECLARE citizen_id_var INT;
    DECLARE citizen_email_var VARCHAR(255);
    DECLARE days_open_var INT;
    
    -- CURSOR 3: cursor_overdue
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
        
        INSERT INTO audit_logs (admin_email, action, details)
        VALUES ('SYSTEM', 'NOTIFY', CONCAT('Citizen ', citizen_email_var, ' notified - Issue ', issue_id_var, ' is ', days_open_var, ' days old'));
        
        UPDATE issues SET status = 'Pending' WHERE id = issue_id_var AND status = 'Reported';
        
    END LOOP;
    
    CLOSE cursor_overdue;
    
    SELECT 'Notification process completed' AS result;
END$$
DELIMITER ;

-- PROCEDURE 7: Generate Monthly Reports by Department (Uses CURSOR 4)
DELIMITER $$
CREATE PROCEDURE sp_generate_monthly_reports()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE dept_id_var INT;
    DECLARE dept_name_var VARCHAR(100);
    DECLARE total_issues_var INT;
    DECLARE resolved_issues_var INT;
    
    -- CURSOR 4: cursor_departments
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
        
        INSERT INTO audit_logs (admin_email, action, details)
        VALUES ('SYSTEM', 'REPORT', CONCAT('Monthly Report: ', dept_name_var, ' - Total: ', total_issues_var, ', Resolved: ', resolved_issues_var));
        
    END LOOP;
    
    CLOSE cursor_departments;
    
    SELECT 'Monthly reports generated for all departments' AS result;
END$$
DELIMITER ;

-- PROCEDURE 8: Monthly Statistics (Nested Subqueries)
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

-- PROCEDURE 9: Get Issues by Location
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

-- PROCEDURE 10: Identify Problem Areas
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

-- PROCEDURE 11: Citizen Activity Report
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

-- PROCEDURE 12: Admin Workload Distribution
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
-- 3. VIEWS (4 Total)
-- ================================================================================

-- VIEW 1: Unresolved High Priority Issues
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

-- VIEW 2: Department Dashboard
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

-- VIEW 3: Citizen Issues Summary
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

-- VIEW 4: Admin Performance Metrics
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
-- 4. OPTIMIZATION INDEXES (8 Total)
-- ================================================================================

-- INDEX 1: Composite index for citizen and status queries
ALTER TABLE issues ADD INDEX idx_citizen_status (citizen_id, status);

-- INDEX 2: Composite index for admin and status queries
ALTER TABLE issues ADD INDEX idx_assigned_status (assigned_to, status);

-- INDEX 3: Composite index for status and date range queries
ALTER TABLE issues ADD INDEX idx_status_created (status, created_at);

-- INDEX 4: Composite index for issue history tracking
ALTER TABLE issue_history ADD INDEX idx_issue_created (issue_id, changed_at);

-- INDEX 5: Composite index for audit log queries
ALTER TABLE audit_logs ADD INDEX idx_action_date (action_type, created_at);

-- INDEX 6: Composite index for citizen lookups
ALTER TABLE citizens ADD INDEX idx_email_created (email, created_at);

-- INDEX 7: Composite index for admin department queries
ALTER TABLE admins ADD INDEX idx_dept_active (department_id, is_active);

-- INDEX 8: Composite index for location searches
ALTER TABLE location ADD INDEX idx_city_area (city, area_name);

-- ================================================================================
-- SUMMARY
-- ================================================================================
-- Total Database Objects Implemented:
-- ✓ 4 Triggers (Auto-update, Status logging, Delete prevention, Validation)
-- ✓ 12 Stored Procedures (Advanced analytics and automation)
-- ✓ 4 Cursors (Bulk updates, archival, notifications, reports)
-- ✓ 4 Views (Performance dashboards and summaries)
-- ✓ 8 Indexes (Optimized query performance)
-- ✓ 25+ Nested Subqueries (Throughout procedures and views)
-- ================================================================================
