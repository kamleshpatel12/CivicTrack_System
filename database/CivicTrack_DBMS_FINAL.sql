-- ============================================================================
-- CIVICTRACK - CIVIL ISSUE REPORTING SYSTEM
-- DBMS Project: Views, Stored Procedures, Functions, Triggers, Indexes
-- ============================================================================

USE civic_issue_db;

-- ============================================================================
-- 1. VIEWS (Updated to match existing schema)
-- ============================================================================

-- View 1: Active Issues (Not Resolved)
DROP VIEW IF EXISTS v_active_issues;
CREATE VIEW v_active_issues AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    i.issue_type,
    i.status,
    a.full_name AS handled_by,
    DATEDIFF(CURDATE(), i.created_at) AS days_pending,
    i.created_at
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
LEFT JOIN admins a ON i.handled_by = a.id
WHERE i.status NOT IN ('Resolved', 'Rejected')
ORDER BY i.created_at ASC;

-- View 2: Resolved Issues with Resolution Time
DROP VIEW IF EXISTS v_resolved_issues_report;
CREATE VIEW v_resolved_issues_report AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    i.issue_type,
    a.full_name AS resolved_by,
    a.department,
    i.created_at,
    i.updated_at,
    DATEDIFF(i.updated_at, i.created_at) AS days_to_resolve
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
LEFT JOIN admins a ON i.handled_by = a.id
WHERE i.status = 'Resolved'
ORDER BY i.updated_at DESC;

-- View 3: User Activity Report
DROP VIEW IF EXISTS v_user_activity_report;
CREATE VIEW v_user_activity_report AS
SELECT 
    c.id,
    c.full_name,
    c.email,
    COUNT(i.id) AS total_issues_reported,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_issues,
    SUM(CASE WHEN i.status IN ('Reported', 'Pending') THEN 1 ELSE 0 END) AS pending_issues,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) AS inprogress_issues,
    SUM(CASE WHEN i.status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_issues,
    MAX(i.created_at) AS last_issue_reported
FROM citizens c
LEFT JOIN issues i ON c.id = i.citizen_id
GROUP BY c.id, c.full_name, c.email;

-- View 4: Issues Overdue for Resolution
DROP VIEW IF EXISTS v_overdue_issues;
CREATE VIEW v_overdue_issues AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    i.issue_type,
    i.status,
    a.full_name AS assigned_to,
    DATEDIFF(CURDATE(), i.created_at) AS days_pending,
    i.created_at
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
LEFT JOIN admins a ON i.handled_by = a.id
WHERE i.status NOT IN ('Resolved', 'Rejected')
  AND DATEDIFF(CURDATE(), i.created_at) > 7
ORDER BY days_pending DESC;

-- View 5: Issue Type Summary
DROP VIEW IF EXISTS v_issue_type_summary;
CREATE VIEW v_issue_type_summary AS
SELECT 
    issue_type,
    COUNT(*) AS total_issues,
    SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) AS resolved,
    SUM(CASE WHEN status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress,
    SUM(CASE WHEN status = 'Reported' THEN 1 ELSE 0 END) AS reported,
    SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending,
    ROUND(SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS resolution_rate
FROM issues
GROUP BY issue_type
ORDER BY total_issues DESC;

-- View 6: Admin Performance Report
DROP VIEW IF EXISTS v_admin_performance;
CREATE VIEW v_admin_performance AS
SELECT 
    a.id,
    a.full_name,
    a.email,
    a.department,
    COUNT(i.id) AS total_issues_handled,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_issues,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress_issues,
    ROUND(SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(i.id) * 100, 2) AS resolution_percentage
FROM admins a
LEFT JOIN issues i ON a.id = i.handled_by
WHERE a.department IS NOT NULL
GROUP BY a.id, a.full_name, a.email, a.department;

-- ============================================================================
-- 2. STORED PROCEDURES
-- ============================================================================

-- Stored Procedure 1: Report New Issue
DROP PROCEDURE IF EXISTS sp_report_issue;
DELIMITER $$

CREATE PROCEDURE sp_report_issue(
    IN p_citizen_id INT,
    IN p_issue_type VARCHAR(100),
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_address VARCHAR(500),
    OUT p_issue_id INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_citizen_exists INT;
    
    -- Check if citizen exists
    SELECT COUNT(*) INTO v_citizen_exists FROM citizens WHERE id = p_citizen_id;
    
    IF v_citizen_exists = 0 THEN
        SET p_message = 'Citizen not found';
        SET p_issue_id = NULL;
    ELSE
        BEGIN
            DECLARE EXIT HANDLER FOR SQLEXCEPTION
            BEGIN
                SET p_message = 'Error: Issue title already exists or invalid data';
                SET p_issue_id = NULL;
            END;
            
            -- Insert new issue
            INSERT INTO issues (citizen_id, issue_type, title, description, address, status, created_at, updated_at)
            VALUES (p_citizen_id, p_issue_type, p_title, p_description, p_address, 'Reported', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
            
            SET p_issue_id = LAST_INSERT_ID();
            SET p_message = CONCAT('Issue reported successfully with ID: ', p_issue_id);
        END;
    END IF;
END$$

DELIMITER ;

-- Stored Procedure 2: Update Issue Status and Assign to Admin
DROP PROCEDURE IF EXISTS sp_update_issue_status;
DELIMITER $$

CREATE PROCEDURE sp_update_issue_status(
    IN p_issue_id INT,
    IN p_new_status VARCHAR(20),
    IN p_admin_id INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_issue_exists INT;
    DECLARE v_admin_exists INT;
    DECLARE v_old_status VARCHAR(20);
    
    -- Check if issue exists
    SELECT COUNT(*) INTO v_issue_exists FROM issues WHERE id = p_issue_id;
    
    IF v_issue_exists = 0 THEN
        SET p_message = 'Issue not found';
    ELSE
        -- Check if admin exists and is valid
        IF p_admin_id IS NOT NULL THEN
            SELECT COUNT(*) INTO v_admin_exists FROM admins WHERE id = p_admin_id;
            IF v_admin_exists = 0 THEN
                SET p_message = 'Invalid admin ID';
                SET p_admin_id = NULL;
            END IF;
        END IF;
        
        -- Get current status
        SELECT status INTO v_old_status FROM issues WHERE id = p_issue_id;
        
        -- Update issue status and admin
        UPDATE issues 
        SET status = p_new_status, 
            handled_by = COALESCE(p_admin_id, handled_by),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_issue_id;
        
        -- Log status change
        INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_at)
        VALUES (p_issue_id, v_old_status, p_new_status, CURRENT_TIMESTAMP);
        
        SET p_message = CONCAT('Issue status updated from ', v_old_status, ' to ', p_new_status);
    END IF;
END$$

DELIMITER ;

-- Stored Procedure 3: Get Issues by City
DROP PROCEDURE IF EXISTS sp_get_issues_by_city;
DELIMITER $$

CREATE PROCEDURE sp_get_issues_by_city(
    IN p_city_address VARCHAR(100)
)
BEGIN
    SELECT 
        i.id,
        i.title,
        i.description,
        i.issue_type,
        i.status,
        i.address,
        c.full_name AS reported_by,
        a.full_name AS handled_by,
        DATEDIFF(CURDATE(), i.created_at) AS age_in_days,
        i.created_at
    FROM issues i
    LEFT JOIN citizens c ON i.citizen_id = c.id
    LEFT JOIN admins a ON i.handled_by = a.id
    WHERE i.address LIKE CONCAT('%', p_city_address, '%')
    ORDER BY i.created_at DESC;
END$$

DELIMITER ;

-- ============================================================================
-- 3. FUNCTIONS
-- ============================================================================

-- Function 1: Get Total Issues by Citizen
DROP FUNCTION IF EXISTS fn_get_total_issues_by_citizen;
DELIMITER $$

CREATE FUNCTION fn_get_total_issues_by_citizen(p_citizen_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COUNT(*) INTO v_total FROM issues WHERE citizen_id = p_citizen_id;
    RETURN COALESCE(v_total, 0);
END$$

DELIMITER ;

-- Function 2: Get Average Resolution Time (in days)
DROP FUNCTION IF EXISTS fn_get_avg_resolution_time;
DELIMITER $$

CREATE FUNCTION fn_get_avg_resolution_time()
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_avg_time DECIMAL(10, 2);
    SELECT ROUND(AVG(DATEDIFF(updated_at, created_at)), 2) INTO v_avg_time
    FROM issues
    WHERE status = 'Resolved';
    RETURN COALESCE(v_avg_time, 0);
END$$

DELIMITER ;

-- Function 3: Get Issue Status Count
DROP FUNCTION IF EXISTS fn_get_issue_count_by_status;
DELIMITER $$

CREATE FUNCTION fn_get_issue_count_by_status(p_status VARCHAR(20))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM issues WHERE status = p_status;
    RETURN COALESCE(v_count, 0);
END$$

DELIMITER ;

-- Function 4: Get Days Since Issue Created
DROP FUNCTION IF EXISTS fn_get_days_since_created;
DELIMITER $$

CREATE FUNCTION fn_get_days_since_created(p_issue_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_days INT;
    SELECT DATEDIFF(CURDATE(), DATE(created_at)) INTO v_days FROM issues WHERE id = p_issue_id;
    RETURN COALESCE(v_days, 0);
END$$

DELIMITER ;

-- ============================================================================
-- 4. TRIGGERS
-- ============================================================================

-- Trigger 1: Auto Update Timestamp on Issue Update
DROP TRIGGER IF EXISTS trg_update_issue_timestamp;
DELIMITER $$

CREATE TRIGGER trg_update_issue_timestamp
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END$$

DELIMITER ;

-- Trigger 2: Log Status Change in History
DROP TRIGGER IF EXISTS trg_log_issue_status_change;
DELIMITER $$

CREATE TRIGGER trg_log_issue_status_change
AFTER UPDATE ON issues
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_at)
        VALUES (NEW.id, OLD.status, NEW.status, CURRENT_TIMESTAMP);
    END IF;
END$$

DELIMITER ;

-- Trigger 3: Prevent Deletion of Resolved Issues (Audit Trail)
DROP TRIGGER IF EXISTS trg_prevent_delete_resolved;
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

-- Trigger 4: Validate Admin Assignment
DROP TRIGGER IF EXISTS trg_validate_admin_assignment;
DELIMITER $$

CREATE TRIGGER trg_validate_admin_assignment
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    IF NEW.handled_by IS NOT NULL THEN
        IF (SELECT COUNT(*) FROM admins WHERE id = NEW.handled_by) = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assigned admin does not exist';
        END IF;
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- 5. INDEXES (Commented out - can be created manually if needed)
-- ============================================================================

-- Note: Indexes can be created manually later without conflicts
-- ALTER TABLE issues DROP INDEX IF EXISTS idx_issues_status_type;
-- CREATE INDEX idx_issues_status_type ON issues(status, issue_type);
-- CREATE INDEX idx_issues_citizen_status ON issues(citizen_id, status);
-- CREATE INDEX idx_issues_address ON issues(address(50));
-- CREATE INDEX idx_issues_handled_by ON issues(handled_by);
-- CREATE INDEX idx_issue_history_issue_date ON issue_status_history(issue_id, changed_at);
-- CREATE INDEX idx_multimedia_issue ON multimedia(issue_id);
-- CREATE INDEX idx_citizens_email ON citizens(email);
-- CREATE INDEX idx_admins_email ON admins(email);
-- CREATE INDEX idx_admins_dept ON admins(department);

-- ============================================================================
-- SAMPLE DATA (Optional - for testing views/procedures)
-- ============================================================================
-- Note: Sample data insertion commented out to avoid conflicts
-- Uncomment the lines below if you want to populate test data


-- Safely clear data
-- SET FOREIGN_KEY_CHECKS=0;
-- TRUNCATE TABLE issue_status_history;
-- TRUNCATE TABLE multimedia;
-- TRUNCATE TABLE issues;
-- DELETE FROM citizens WHERE id > 0;
-- DELETE FROM admins WHERE id > 0;
-- SET FOREIGN_KEY_CHECKS=1;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- View all created views
-- SHOW FULL TABLES IN civic_issue_db WHERE TABLE_TYPE = 'VIEW';

-- Show all procedures
-- SHOW PROCEDURE STATUS WHERE db = 'civic_issue_db';

-- Show all functions
-- SHOW FUNCTION STATUS WHERE db = 'civic_issue_db';

-- Show all triggers
-- SHOW TRIGGERS FROM civic_issue_db;

-- ============================================================================
-- END OF CIVICTRACK DBMS PROJECT
-- ============================================================================
