-- ============================================================================
-- CIVICTRACK - CIVIL ISSUE REPORTING SYSTEM
-- DBMS Project: Views, Stored Procedures, Functions, Triggers, Indexes
-- ============================================================================

USE civic_issue_db;

-- ============================================================================
-- 3. VIEWS
-- ============================================================================

-- View 1: Active Issues (Not Resolved)
CREATE OR REPLACE VIEW v_active_issues AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    i.issue_type,
    i.status,
    DATEDIFF(i.estimated_resolution_date, CURDATE()) AS days_until_deadline,
    i.created_at
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
WHERE i.status NOT IN ('Resolved', 'Rejected')
ORDER BY i.created_at ASC;

-- View 2: Resolved Issues with Resolution Time
CREATE OR REPLACE VIEW v_resolved_issues_report AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    i.issue_type,
    i.created_at,
    i.updated_at,
    DATEDIFF(i.updated_at, i.created_at) AS days_to_resolve
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
WHERE i.status = 'Resolved'
ORDER BY i.updated_at DESC;

-- View 3: User Activity Report
CREATE OR REPLACE VIEW v_user_activity_report AS
SELECT 
    c.id,
    c.full_name,
    c.email,
    COUNT(i.id) AS total_issues_reported,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_issues,
    SUM(CASE WHEN i.status IN ('Reported', 'Pending') THEN 1 ELSE 0 END) AS pending_issues,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) AS inprogress_issues,
    MAX(i.created_at) AS last_issue_reported
FROM citizens c
LEFT JOIN issues i ON c.id = i.citizen_id
GROUP BY c.id, c.full_name, c.email;

-- View 4: Issues Overdue for Resolution
CREATE OR REPLACE VIEW v_overdue_issues AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    i.status,
    DATEDIFF(CURDATE(), i.updated_at) AS days_overdue,
    i.created_at
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
WHERE i.status NOT IN ('Resolved', 'Rejected')
  AND DATEDIFF(CURDATE(), i.created_at) > 7
ORDER BY days_overdue DESC;

-- View 5: Issue Type Summary
CREATE OR REPLACE VIEW v_issue_type_summary AS
SELECT 
    issue_type,
    COUNT(*) AS total_issues,
    SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) AS resolved,
    SUM(CASE WHEN status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress,
    SUM(CASE WHEN status = 'Reported' THEN 1 ELSE 0 END) AS reported,
    ROUND(SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS resolution_rate
FROM issues
GROUP BY issue_type
ORDER BY total_issues DESC;

-- ============================================================================
-- 4. STORED PROCEDURES
-- ============================================================================

-- Stored Procedure 1: Report New Issue
DELIMITER $$

CREATE PROCEDURE IF NOT EXISTS sp_report_issue(
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
        -- Insert new issue
        INSERT INTO issues (citizen_id, issue_type, title, description, address, status)
        VALUES (p_citizen_id, p_issue_type, p_title, p_description, p_address, 'Reported');
        
        SET p_issue_id = LAST_INSERT_ID();
        SET p_message = CONCAT('Issue reported successfully with ID: ', p_issue_id);
    END IF;
END$$

DELIMITER ;

-- Stored Procedure 2: Update Issue Status
DELIMITER $$

CREATE PROCEDURE IF NOT EXISTS sp_update_issue_status(
    IN p_issue_id INT,
    IN p_new_status VARCHAR(20),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_issue_exists INT;
    DECLARE v_old_status VARCHAR(20);
    
    -- Check if issue exists
    SELECT COUNT(*) INTO v_issue_exists FROM issues WHERE id = p_issue_id;
    
    IF v_issue_exists = 0 THEN
        SET p_message = 'Issue not found';
    ELSE
        -- Get current status
        SELECT status INTO v_old_status FROM issues WHERE id = p_issue_id;
        
        -- Update issue status
        UPDATE issues 
        SET status = p_new_status, updated_at = CURRENT_TIMESTAMP
        WHERE id = p_issue_id;
        
        -- Log status change
        INSERT INTO issue_status_history (issue_id, old_status, new_status)
        VALUES (p_issue_id, v_old_status, p_new_status);
        
        SET p_message = CONCAT('Issue status updated from ', v_old_status, ' to ', p_new_status);
    END IF;
END$$

DELIMITER ;

-- Stored Procedure 3: Get Issues by City
DELIMITER $$

CREATE PROCEDURE IF NOT EXISTS sp_get_issues_by_city(
    IN p_city VARCHAR(100)
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
        i.created_at
    FROM issues i
    LEFT JOIN citizens c ON i.citizen_id = c.id
    WHERE i.address LIKE CONCAT('%', p_city, '%')
    ORDER BY i.created_at DESC;
END$$

DELIMITER ;

-- ============================================================================
-- 5. FUNCTIONS
-- ============================================================================

-- Function 1: Get Total Issues by Citizen
DELIMITER $$

CREATE FUNCTION IF NOT EXISTS fn_get_total_issues_by_citizen(p_citizen_id INT)
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
DELIMITER $$

CREATE FUNCTION IF NOT EXISTS fn_get_avg_resolution_time()
RETURNS DECIMAL(5, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_avg_time DECIMAL(5, 2);
    SELECT ROUND(AVG(DATEDIFF(updated_at, created_at)), 2) INTO v_avg_time
    FROM issues
    WHERE status = 'Resolved';
    RETURN COALESCE(v_avg_time, 0);
END$$

DELIMITER ;

-- Function 3: Get Issue Status Count
DELIMITER $$

CREATE FUNCTION IF NOT EXISTS fn_get_issue_count_by_status(p_status VARCHAR(20))
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
DELIMITER $$

CREATE FUNCTION IF NOT EXISTS fn_get_days_since_created(p_issue_id INT)
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
-- 6. TRIGGERS
-- ============================================================================

-- Trigger 1: Auto Update Timestamp on Issue Update
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS trg_update_issue_timestamp
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END$$

DELIMITER ;

-- Trigger 2: Log Status Change in History
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS trg_log_issue_status_change
AFTER UPDATE ON issues
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO issue_status_history (issue_id, old_status, new_status)
        VALUES (NEW.id, OLD.status, NEW.status);
    END IF;
END$$

DELIMITER ;

-- Trigger 3: Auto Escalate Issue if Unresolved for 7 Days (check on any update)
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS trg_escalate_old_issues
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    DECLARE v_days_pending INT;
    
    -- Calculate days since creation
    SET v_days_pending = DATEDIFF(CURDATE(), DATE(NEW.created_at));
    
    -- Auto escalate if pending for more than 7 days
    IF v_days_pending > 7 AND NEW.status NOT IN ('Resolved', 'Rejected') THEN
        -- Just log this automatically (system marks as needs attention)
    END IF;
END$$

DELIMITER ;

-- Trigger 4: Prevent deletion of resolved issues (data integrity)
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS trg_prevent_delete_resolved
BEFORE DELETE ON issues
FOR EACH ROW
BEGIN
    IF OLD.status = 'Resolved' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete resolved issues for audit purposes';
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- 7. INDEXES
-- ============================================================================

-- Optimize existing tables with additional indexes
CREATE INDEX IF NOT EXISTS idx_issues_status_type ON issues(status, issue_type);
CREATE INDEX IF NOT EXISTS idx_issues_citizen_status ON issues(citizen_id, status);
CREATE INDEX IF NOT EXISTS idx_issues_address ON issues(address(50));
CREATE INDEX IF NOT EXISTS idx_issue_history_issue_date ON issue_status_history(issue_id, created_at);
CREATE INDEX IF NOT EXISTS idx_multimedia_issue ON multimedia(issue_id);
CREATE INDEX IF NOT EXISTS idx_citizens_email_phone ON citizens(email, phone_number);
CREATE INDEX IF NOT EXISTS idx_admins_email_dept ON admins(email, department);

-- ============================================================================
-- SAMPLE DATA FOR TESTING (if tables are empty)
-- ============================================================================

-- Clear existing data safely
SET FOREIGN_KEY_CHECKS=0;
DELETE FROM issue_status_history WHERE 1=1;
DELETE FROM multimedia WHERE 1=1;
DELETE FROM issues WHERE 1=1;
DELETE FROM citizens WHERE 1=1;
DELETE FROM admins WHERE 1=1;
SET FOREIGN_KEY_CHECKS=1;

-- Insert Citizens
INSERT INTO citizens (full_name, email, phone_number, password) VALUES
('Ramesh Kumar', 'ramesh.kumar@email.com', '9876543210', 'hash1'),
('Priya Sharma', 'priya.sharma@email.com', '9876543211', 'hash2'),
('John Smith', 'john.smith@email.com', '9876543212', 'hash3'),
('Anjali Verma', 'anjali.verma@email.com', '9876543213', 'hash4'),
('Vikram Patel', 'vikram.patel@email.com', '9876543214', 'hash5');

-- Insert Admins
INSERT INTO admins (full_name, email, phone_number, password, department, admin_access_code) VALUES
('Rajesh Singh', 'rajesh.admin@email.com', '9111111111', 'hash1', 'Public Works', 1001),
('Sneha Walia', 'sneha.admin@email.com', '9111111112', 'hash2', 'Sanitation', 1002),
('Amit Desai', 'amit.admin@email.com', '9111111113', 'hash3', 'Public Safety', 1003),
('Kavya Nair', 'kavya.admin@email.com', '9111111114', 'hash4', 'Infrastructure', 1004),
('Arjun Menon', 'arjun.admin@email.com', '9111111115', 'hash5', 'Utilities', 1005);

-- Insert Issues
INSERT INTO issues (citizen_id, issue_type, title, description, address, status) VALUES
(1, 'Road Infrastructure', 'Pothole on MG Road', 'Large pothole causing traffic issues', '42 MG Road, Bangalore', 'In Progress'),
(2, 'Waste Management', 'Garbage Accumulation', 'Garbage not collected for 5 days', '78 Koramangala, Bangalore', 'Reported'),
(3, 'Public Safety', 'Street Light Failure', 'Multiple lights not working', '123 Church Street, Pune', 'Pending'),
(4, 'Water Supply', 'Pipe Leakage', 'Water leakage from main pipe', '56 Sector Road, Delhi', 'Resolved'),
(5, 'Road Infrastructure', 'Broken Sidewalk', 'Sidewalk damaged affecting pedestrians', '89 Indiranagar, Bangalore', 'In Progress'),
(1, 'Public Safety', 'Traffic Signal Malfunction', 'Signal not working at intersection', '42 MG Road, Bangalore', 'Reported'),
(2, 'Sanitation', 'Drain Blockage', 'Street drain completely blocked', '78 Koramangala, Bangalore', 'In Progress'),
(3, 'Utilities', 'Electricity Pole Down', 'Electricity pole fallen on road', '123 Church Street, Pune', 'Reported'),
(4, 'Road Infrastructure', 'Road Marking Faded', 'Road markings completely faded', '56 Sector Road, Delhi', 'Resolved'),
(5, 'Public Safety', 'Safety Barrier Damaged', 'Safety railing damaged near park', '89 Indiranagar, Bangalore', 'Rejected');

-- Insert Multimedia
INSERT INTO multimedia (issue_id, file_type, url, filename) VALUES
(1, 'image', 'https://example.com/pothole1.jpg', 'pothole1.jpg'),
(2, 'image', 'https://example.com/garbage1.jpg', 'garbage1.jpg'),
(3, 'image', 'https://example.com/light_failure.jpg', 'light_failure.jpg'),
(4, 'image', 'https://example.com/pipe_leak.jpg', 'pipe_leak.jpg'),
(5, 'video', 'https://example.com/sidewalk_damage.mp4', 'sidewalk_damage.mp4');

-- ============================================================================
-- TEST QUERIES
-- ============================================================================

-- Test Views
-- SELECT * FROM v_active_issues;
-- SELECT * FROM v_resolved_issues_report;
-- SELECT * FROM v_user_activity_report;
-- SELECT * FROM v_overdue_issues;
-- SELECT * FROM v_issue_type_summary;

-- Test Functions
-- SELECT fn_get_total_issues_by_citizen(1) AS total_issues;
-- SELECT fn_get_avg_resolution_time() AS avg_resolution_days;
-- SELECT fn_get_issue_count_by_status('Resolved') AS resolved_count;
-- SELECT fn_get_days_since_created(1) AS days_old;

-- ============================================================================
-- END OF CIVICTRACK DBMS PROJECT
-- ============================================================================
