-- ============================================================================
-- CIVICTRACK - CIVIL ISSUE REPORTING SYSTEM
-- DBMS Project: Complete Database Schema with DDL, DML, Views, SP, Functions, Triggers
-- ============================================================================

USE civic_issue_db;

-- ============================================================================
-- 1. DDL - CREATE TABLES WITH CONSTRAINTS
-- ============================================================================

-- Citizens Table
CREATE TABLE IF NOT EXISTS citizens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_phone_length CHECK (LENGTH(phone) >= 10),
    INDEX idx_city (city),
    INDEX idx_email (email)
);

-- Admins Table
CREATE TABLE IF NOT EXISTS admins (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    department VARCHAR(100),
    designation VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_admin_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_admin_phone CHECK (LENGTH(phone) >= 10),
    INDEX idx_department (department),
    INDEX idx_is_active (is_active)
);

-- Issues Table
CREATE TABLE IF NOT EXISTS issues (
    id INT PRIMARY KEY AUTO_INCREMENT,
    citizen_id INT NOT NULL,
    issue_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    address VARCHAR(500),
    status ENUM('Reported', 'In Progress', 'Resolved', 'Rejected', 'Pending') DEFAULT 'Reported',
    assigned_admin INT,
    priority ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_date TIMESTAMP NULL,
    estimated_resolution_date DATE,
    CONSTRAINT fk_citizen FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
    CONSTRAINT fk_admin FOREIGN KEY (assigned_admin) REFERENCES admins(id) ON DELETE SET NULL,
    CONSTRAINT chk_priority_default CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
    CONSTRAINT chk_status_enum CHECK (status IN ('Reported', 'In Progress', 'Resolved', 'Rejected', 'Pending')),
    INDEX idx_status (status),
    INDEX idx_citizen_id (citizen_id),
    INDEX idx_assigned_admin (assigned_admin),
    INDEX idx_created_at (created_at),
    INDEX idx_priority (priority)
);

-- Multimedia Table
CREATE TABLE IF NOT EXISTS multimedia (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_id INT NOT NULL,
    file_type ENUM('image', 'video', 'document') NOT NULL,
    url VARCHAR(500) NOT NULL,
    filename VARCHAR(255),
    file_size INT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_issue_media FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    INDEX idx_issue_id (issue_id),
    INDEX idx_file_type (file_type)
);

-- Issue Status History Table
CREATE TABLE IF NOT EXISTS issue_status_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_id INT NOT NULL,
    old_status ENUM('Reported', 'In Progress', 'Resolved', 'Rejected', 'Pending'),
    new_status ENUM('Reported', 'In Progress', 'Resolved', 'Rejected', 'Pending') NOT NULL,
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    remarks TEXT,
    CONSTRAINT fk_issue_history FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_changed_by FOREIGN KEY (changed_by) REFERENCES admins(id) ON DELETE SET NULL,
    INDEX idx_issue_id_history (issue_id),
    INDEX idx_changed_at (changed_at)
);

-- ============================================================================
-- 2. DML - INSERT SAMPLE DATA
-- ============================================================================

-- Citizens Data
INSERT INTO citizens (full_name, email, phone, password_hash, address, city, state, pincode) VALUES
('Ramesh Kumar', 'ramesh.kumar@email.com', '9876543210', 'hash1', '42 MG Road', 'Bangalore', 'Karnataka', '560001'),
('Priya Sharma', 'priya.sharma@email.com', '9876543211', 'hash2', '78 Koramangala', 'Bangalore', 'Karnataka', '560034'),
('John Smith', 'john.smith@email.com', '9876543212', 'hash3', '123 Church Street', 'Pune', 'Maharashtra', '411001'),
('Anjali Verma', 'anjali.verma@email.com', '9876543213', 'hash4', '56 Sector Road', 'Delhi', 'Delhi', '110001'),
('Vikram Patel', 'vikram.patel@email.com', '9876543214', 'hash5', '89 Indiranagar', 'Bangalore', 'Karnataka', '560038');

-- Admins Data
INSERT INTO admins (full_name, email, phone, password_hash, department, designation, is_active) VALUES
('Mr. Rajesh Singh', 'rajesh.admin@email.com', '9111111111', 'hash1', 'Public Works', 'Senior Officer', TRUE),
('Mrs. Sneha Walia', 'sneha.admin@email.com', '9111111112', 'hash2', 'Sanitation', 'Manager', TRUE),
('Dr. Amit Desai', 'amit.admin@email.com', '9111111113', 'hash3', 'Public Safety', 'Officer', TRUE),
('Ms. Kavya Nair', 'kavya.admin@email.com', '9111111114', 'hash4', 'Infrastructure', 'Supervisor', TRUE),
('Mr. Arjun Menon', 'arjun.admin@email.com', '9111111115', 'hash5', 'Utilities', 'Technical Lead', FALSE);

-- Issues Data
INSERT INTO issues (citizen_id, issue_type, title, description, latitude, longitude, address, status, assigned_admin, priority, estimated_resolution_date) VALUES
(1, 'Road Infrastructure', 'Pothole on MG Road', 'Large pothole causing traffic issues', 12.9716, 77.5946, '42 MG Road, Bangalore', 'In Progress', 1, 'High', DATE_ADD(CURDATE(), INTERVAL 7 DAY)),
(2, 'Waste Management', 'Garbage Accumulation', 'Garbage not collected for 5 days', 12.9352, 77.6245, '78 Koramangala, Bangalore', 'Reported', 2, 'Medium', DATE_ADD(CURDATE(), INTERVAL 3 DAY)),
(3, 'Public Safety', 'Street Light Failure', 'Multiple lights not working', 18.5204, 73.8567, '123 Church Street, Pune', 'Pending', 3, 'Medium', DATE_ADD(CURDATE(), INTERVAL 5 DAY)),
(4, 'Water Supply', 'Pipe Leakage', 'Water leakage from main pipe', 28.7041, 77.1025, '56 Sector Road, Delhi', 'Resolved', 4, 'High', CURDATE()),
(5, 'Road Infrastructure', 'Broken Sidewalk', 'Sidewalk damaged affecting pedestrians', 12.9716, 77.5946, '89 Indiranagar, Bangalore', 'In Progress', 1, 'Critical', DATE_ADD(CURDATE(), INTERVAL 10 DAY)),
(1, 'Public Safety', 'Traffic Signal Malfunction', 'Signal not working at intersection', 12.9789, 77.5901, '42 MG Road, Bangalore', 'Reported', NULL, 'High', DATE_ADD(CURDATE(), INTERVAL 2 DAY)),
(2, 'Sanitation', 'Drain Blockage', 'Street drain completely blocked', 12.9352, 77.6245, '78 Koramangala, Bangalore', 'In Progress', 2, 'Critical', DATE_ADD(CURDATE(), INTERVAL 1 DAY)),
(3, 'Utilities', 'Electricity Pole Down', 'Electricity pole fallen on road', 18.5204, 73.8567, '123 Church Street, Pune', 'Reported', NULL, 'Critical', DATE_ADD(CURDATE(), INTERVAL 1 DAY)),
(4, 'Road Infrastructure', 'Road Marking Faded', 'Road markings completely faded', 28.7041, 77.1025, '56 Sector Road, Delhi', 'Resolved', 4, 'Low', CURDATE()),
(5, 'Public Safety', 'Safety Barrier Damaged', 'Safety railing damaged near park', 12.9716, 77.5946, '89 Indiranagar, Bangalore', 'Rejected', 3, 'Medium', CURDATE());

-- Multimedia Data
INSERT INTO multimedia (issue_id, file_type, url, filename, file_size) VALUES
(1, 'image', 'https://example.com/pothole1.jpg', 'pothole1.jpg', 2048576),
(2, 'image', 'https://example.com/garbage1.jpg', 'garbage1.jpg', 1536000),
(3, 'image', 'https://example.com/light_failure.jpg', 'light_failure.jpg', 1024000),
(4, 'image', 'https://example.com/pipe_leak.jpg', 'pipe_leak.jpg', 2560000),
(5, 'video', 'https://example.com/sidewalk_damage.mp4', 'sidewalk_damage.mp4', 15360000),
(6, 'image', 'https://example.com/signal.jpg', 'signal.jpg', 1800000),
(7, 'image', 'https://example.com/drain.jpg', 'drain.jpg', 1900000),
(8, 'image', 'https://example.com/pole_down.jpg', 'pole_down.jpg', 2200000);

-- Issue Status History Data
INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_by, remarks) VALUES
(1, 'Reported', 'In Progress', 1, 'Work started on fixing the pothole'),
(4, 'Reported', 'Pending', 4, 'Waiting for parts approval'),
(4, 'Pending', 'In Progress', 4, 'Parts received, work started'),
(4, 'In Progress', 'Resolved', 4, 'Pipe replaced successfully'),
(9, 'Reported', 'In Progress', 4, 'Road marking work started'),
(9, 'In Progress', 'Resolved', 4, 'Road markings completed'),
(10, 'Reported', 'Rejected', 3, 'Not a valid safety barrier issue'),
(3, 'Reported', 'Pending', NULL, 'Assigned for verification');

-- ============================================================================
-- 3. VIEWS
-- ============================================================================

-- View 1: Active Issues (Not Resolved)
CREATE OR REPLACE VIEW v_active_issues AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    c.city,
    i.issue_type,
    i.priority,
    i.status,
    i.assigned_admin,
    COALESCE(a.full_name, 'Unassigned') AS assigned_to,
    DATEDIFF(i.estimated_resolution_date, CURDATE()) AS days_until_deadline,
    i.created_at
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
LEFT JOIN admins a ON i.assigned_admin = a.id
WHERE i.status NOT IN ('Resolved', 'Rejected')
ORDER BY i.priority DESC, i.created_at ASC;

-- View 2: Resolved Issues with Resolution Time
CREATE OR REPLACE VIEW v_resolved_issues_report AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    c.city,
    i.issue_type,
    a.full_name AS resolved_by,
    a.department,
    i.created_at,
    i.resolved_date,
    DATEDIFF(i.resolved_date, i.created_at) AS days_to_resolve
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
LEFT JOIN admins a ON i.assigned_admin = a.id
WHERE i.status = 'Resolved'
ORDER BY i.resolved_date DESC;

-- View 3: User Activity Report
CREATE OR REPLACE VIEW v_user_activity_report AS
SELECT 
    c.id,
    c.full_name,
    c.email,
    c.city,
    COUNT(i.id) AS total_issues_reported,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_issues,
    SUM(CASE WHEN i.status IN ('Reported', 'Pending') THEN 1 ELSE 0 END) AS pending_issues,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) AS inprogress_issues,
    MAX(i.created_at) AS last_issue_reported
FROM citizens c
LEFT JOIN issues i ON c.id = i.citizen_id
GROUP BY c.id, c.full_name, c.email, c.city;

-- View 4: Issues Overdue for Resolution
CREATE OR REPLACE VIEW v_overdue_issues AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    i.priority,
    i.status,
    a.full_name AS assigned_to,
    i.estimated_resolution_date,
    DATEDIFF(CURDATE(), i.estimated_resolution_date) AS days_overdue,
    i.created_at
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
LEFT JOIN admins a ON i.assigned_admin = a.id
WHERE i.status NOT IN ('Resolved', 'Rejected')
  AND i.estimated_resolution_date < CURDATE()
ORDER BY days_overdue DESC;

-- View 5: Department Performance
CREATE OR REPLACE VIEW v_department_performance AS
SELECT 
    a.department,
    COUNT(i.id) AS total_issues_handled,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress,
    SUM(CASE WHEN i.status IN ('Reported', 'Pending') THEN 1 ELSE 0 END) AS pending,
    ROUND(SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(i.id) * 100, 2) AS completion_percentage
FROM admins a
LEFT JOIN issues i ON a.id = i.assigned_admin
WHERE a.is_active = TRUE
GROUP BY a.department;

-- ============================================================================
-- 4. STORED PROCEDURES
-- ============================================================================

-- Stored Procedure 1: Report New Issue
DELIMITER $$

CREATE PROCEDURE sp_report_issue(
    IN p_citizen_id INT,
    IN p_issue_type VARCHAR(100),
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_latitude DECIMAL(10, 8),
    IN p_longitude DECIMAL(11, 8),
    IN p_address VARCHAR(500),
    IN p_priority ENUM('Low', 'Medium', 'High', 'Critical'),
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
        INSERT INTO issues (citizen_id, issue_type, title, description, latitude, longitude, address, priority, estimated_resolution_date, status)
        VALUES (p_citizen_id, p_issue_type, p_title, p_description, p_latitude, p_longitude, p_address, p_priority, DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'Reported');
        
        SET p_issue_id = LAST_INSERT_ID();
        SET p_message = CONCAT('Issue reported successfully with ID: ', p_issue_id);
    END IF;
END$$

DELIMITER ;

-- Stored Procedure 2: Assign Issue to Admin
DELIMITER $$

CREATE PROCEDURE sp_assign_issue_to_admin(
    IN p_issue_id INT,
    IN p_admin_id INT,
    IN p_priority ENUM('Low', 'Medium', 'High', 'Critical'),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_issue_exists INT;
    DECLARE v_admin_exists INT;
    DECLARE v_current_admin INT;
    DECLARE v_old_status VARCHAR(20);
    
    -- Check if issue exists
    SELECT COUNT(*) INTO v_issue_exists FROM issues WHERE id = p_issue_id;
    
    -- Check if admin exists
    SELECT COUNT(*) INTO v_admin_exists FROM admins WHERE id = p_admin_id AND is_active = TRUE;
    
    IF v_issue_exists = 0 THEN
        SET p_message = 'Issue not found';
    ELSEIF v_admin_exists = 0 THEN
        SET p_message = 'Admin not found or inactive';
    ELSE
        -- Get current status and admin
        SELECT status, assigned_admin INTO v_old_status, v_current_admin FROM issues WHERE id = p_issue_id;
        
        -- Update issue assignment
        UPDATE issues 
        SET assigned_admin = p_admin_id, priority = p_priority, status = 'In Progress', updated_at = CURRENT_TIMESTAMP
        WHERE id = p_issue_id;
        
        -- Log status change
        INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_by, remarks)
        VALUES (p_issue_id, v_old_status, 'In Progress', p_admin_id, 'Issue assigned to admin');
        
        SET p_message = 'Issue assigned successfully';
    END IF;
END$$

DELIMITER ;

-- Stored Procedure 3: Resolve Issue
DELIMITER $$

CREATE PROCEDURE sp_resolve_issue(
    IN p_issue_id INT,
    IN p_admin_id INT,
    IN p_remarks TEXT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_issue_exists INT;
    DECLARE v_admin_exists INT;
    DECLARE v_old_status VARCHAR(20);
    
    -- Check if issue exists
    SELECT COUNT(*) INTO v_issue_exists FROM issues WHERE id = p_issue_id;
    
    -- Check if admin exists
    SELECT COUNT(*) INTO v_admin_exists FROM admins WHERE id = p_admin_id;
    
    IF v_issue_exists = 0 THEN
        SET p_message = 'Issue not found';
    ELSEIF v_admin_exists = 0 THEN
        SET p_message = 'Admin not found';
    ELSE
        -- Get current status
        SELECT status INTO v_old_status FROM issues WHERE id = p_issue_id;
        
        -- Update issue as resolved
        UPDATE issues 
        SET status = 'Resolved', resolved_date = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
        WHERE id = p_issue_id;
        
        -- Log status change
        INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_by, remarks)
        VALUES (p_issue_id, v_old_status, 'Resolved', p_admin_id, p_remarks);
        
        SET p_message = 'Issue resolved successfully';
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- 5. FUNCTIONS
-- ============================================================================

-- Function 1: Get Total Issues by Citizen
DELIMITER $$

CREATE FUNCTION fn_get_total_issues_by_citizen(p_citizen_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COUNT(*) INTO v_total FROM issues WHERE citizen_id = p_citizen_id;
    RETURN v_total;
END$$

DELIMITER ;

-- Function 2: Get Average Resolution Time (in days)
DELIMITER $$

CREATE FUNCTION fn_get_avg_resolution_time(p_admin_id INT)
RETURNS DECIMAL(5, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_avg_time DECIMAL(5, 2);
    SELECT ROUND(AVG(DATEDIFF(resolved_date, created_at)), 2) INTO v_avg_time
    FROM issues
    WHERE assigned_admin = p_admin_id AND status = 'Resolved' AND resolved_date IS NOT NULL;
    RETURN COALESCE(v_avg_time, 0);
END$$

DELIMITER ;

-- Function 3: Get Issue Status Count
DELIMITER $$

CREATE FUNCTION fn_get_issue_count_by_status(p_status VARCHAR(20))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM issues WHERE status = p_status;
    RETURN v_count;
END$$

DELIMITER ;

-- ============================================================================
-- 6. TRIGGERS
-- ============================================================================

-- Trigger 1: Auto Update Timestamp on Issue Update
DELIMITER $$

CREATE TRIGGER trg_update_issue_timestamp
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END$$

DELIMITER ;

-- Trigger 2: Log Status Change in History
DELIMITER $$

CREATE TRIGGER trg_log_issue_status_change
AFTER UPDATE ON issues
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_by, remarks)
        VALUES (NEW.id, OLD.status, NEW.status, NEW.assigned_admin, 'Status changed via system update');
    END IF;
END$$

DELIMITER ;

-- Trigger 3: Auto Escalate Issue if Unresolved for 7 Days
DELIMITER $$

CREATE TRIGGER trg_escalate_old_issues
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    DECLARE v_days_pending INT;
    
    -- Calculate days since creation
    SET v_days_pending = DATEDIFF(CURDATE(), DATE(NEW.created_at));
    
    -- Auto escalate to Critical if pending for more than 7 days
    IF v_days_pending > 7 AND NEW.status NOT IN ('Resolved', 'Rejected') AND NEW.priority != 'Critical' THEN
        SET NEW.priority = 'Critical';
    END IF;
END$$

DELIMITER ;

-- Trigger 4: Set Resolved Date when Status Becomes Resolved
DELIMITER $$

CREATE TRIGGER trg_set_resolved_date
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    IF OLD.status != 'Resolved' AND NEW.status = 'Resolved' THEN
        SET NEW.resolved_date = CURRENT_TIMESTAMP;
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- 7. INDEXES
-- ============================================================================

-- Indexes are created in table definitions (see DDL above)
-- Additional optimized indexes for complex queries:

CREATE INDEX idx_issues_status_priority ON issues(status, priority);
CREATE INDEX idx_issues_citizen_status ON issues(citizen_id, status);
CREATE INDEX idx_issues_admin_status ON issues(assigned_admin, status);
CREATE INDEX idx_issue_history_issue_date ON issue_status_history(issue_id, changed_at);
CREATE INDEX idx_multimedia_issue_type ON multimedia(issue_id, file_type);
CREATE INDEX idx_citizens_city_state ON citizens(city, state);
CREATE INDEX idx_admins_dept_active ON admins(department, is_active);

