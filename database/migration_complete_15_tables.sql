-- ================================================================================
-- CivicTrack DBMS - Complete Database Migration Script
-- 15 Tables: Reference + Entity + Transaction + Detail + Feedback
-- ================================================================================

-- Drop existing tables (if exist) in reverse order of dependencies
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS issue_reviews;
DROP TABLE IF EXISTS issue_comments;
DROP TABLE IF EXISTS issue_assignments_history;
DROP TABLE IF EXISTS multimedia;
DROP TABLE IF EXISTS issue_status_history;
DROP TABLE IF EXISTS issues;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS citizens;
DROP TABLE IF EXISTS priority_levels;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS issue_categories;
DROP TABLE IF EXISTS issue_types;
DROP TABLE IF EXISTS designations;
DROP TABLE IF EXISTS departments;

-- ================================================================================
-- REFERENCE TABLES (Lookup/Master Data)
-- ================================================================================

-- Table 1: DEPARTMENTS
CREATE TABLE departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    budget DECIMAL(15, 2),
    head_admin_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_department_name (department_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 2: DESIGNATIONS
CREATE TABLE designations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    designation_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    salary_range_min DECIMAL(10, 2),
    salary_range_max DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_designation_name (designation_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 3: ISSUE_TYPES
CREATE TABLE issue_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    department_id INT,
    severity_level VARCHAR(20) DEFAULT 'Medium',
    avg_resolution_days INT,
    CONSTRAINT chk_severity_level CHECK (severity_level IN ('Low', 'Medium', 'High', 'Critical')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_issue_type_dept FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    INDEX idx_type_name (type_name),
    INDEX idx_department_id (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 4: ISSUE_CATEGORIES
CREATE TABLE issue_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_type_id INT NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_category_type FOREIGN KEY (issue_type_id) REFERENCES issue_types(id) ON DELETE CASCADE,
    UNIQUE(issue_type_id, category_name),
    INDEX idx_type_id (issue_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 5: LOCATIONS
CREATE TABLE locations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    city VARCHAR(100) NOT NULL,
    area_name VARCHAR(100) NOT NULL,
    locality VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    zip_code VARCHAR(6),
    state VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE(city, area_name),
    INDEX idx_city (city),
    INDEX idx_area_name (area_name),
    INDEX idx_zip_code (zip_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 6: PRIORITY_LEVELS
CREATE TABLE priority_levels (
    id INT PRIMARY KEY AUTO_INCREMENT,
    priority_name VARCHAR(50) NOT NULL UNIQUE,
    sla_hours INT,
    response_time_hours INT,
    resolution_time_days INT,
    color_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_priority_name (priority_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- CORE ENTITY TABLES
-- ================================================================================

-- Table 7: CITIZENS
CREATE TABLE citizens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    address VARCHAR(500),
    location_id INT,
    state VARCHAR(100),
    pincode VARCHAR(6),
    aadhar_number VARCHAR(12),
    date_of_birth DATE,
    gender VARCHAR(20) DEFAULT 'Male',
    profile_image_url VARCHAR(500),
    CONSTRAINT chk_gender CHECK (gender IN ('Male', 'Female', 'Other')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_citizen_location FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL,
    INDEX idx_email (email),
    INDEX idx_phone_number (phone_number),
    INDEX idx_location_id (location_id),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 8: ADMINS
CREATE TABLE admins (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    department_id INT,
    designation_id INT,
    employee_id VARCHAR(50) UNIQUE,
    date_of_joining DATE,
    is_active BOOLEAN DEFAULT TRUE,
    aadhar_number VARCHAR(12),
    profile_image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_admin_dept FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    CONSTRAINT fk_admin_desig FOREIGN KEY (designation_id) REFERENCES designations(id) ON DELETE SET NULL,
    INDEX idx_department_id (department_id),
    INDEX idx_designation_id (designation_id),
    INDEX idx_is_active (is_active),
    INDEX idx_employee_id (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Update departments to add head_admin_id constraint now that admins table exists
ALTER TABLE departments ADD CONSTRAINT fk_dept_head_admin FOREIGN KEY (head_admin_id) REFERENCES admins(id) ON DELETE SET NULL;

-- ================================================================================
-- MAIN TRANSACTION TABLE
-- ================================================================================

-- Table 9: ISSUES (Central Hub)
CREATE TABLE issues (
    id INT PRIMARY KEY AUTO_INCREMENT,
    citizen_id INT NOT NULL,
    issue_type_id INT NOT NULL,
    issue_category_id INT,
    location_id INT,
    priority_level_id INT DEFAULT 3,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    address VARCHAR(500),
    status VARCHAR(20) DEFAULT 'Reported',
    assigned_admin INT,
    CONSTRAINT chk_issue_status CHECK (status IN ('Reported','Pending','In Progress','Resolved','Rejected','Closed')),
    estimated_resolution_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_date TIMESTAMP NULL,
    
    CONSTRAINT fk_issue_citizen FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
    CONSTRAINT fk_issue_type FOREIGN KEY (issue_type_id) REFERENCES issue_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_issue_category FOREIGN KEY (issue_category_id) REFERENCES issue_categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_issue_location FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL,
    CONSTRAINT fk_issue_priority FOREIGN KEY (priority_level_id) REFERENCES priority_levels(id) ON DELETE SET DEFAULT,
    CONSTRAINT fk_issue_admin FOREIGN KEY (assigned_admin) REFERENCES admins(id) ON DELETE SET NULL,
    
    INDEX idx_status (status),
    INDEX idx_citizen_id (citizen_id),
    INDEX idx_assigned_admin (assigned_admin),
    INDEX idx_created_at (created_at),
    INDEX idx_priority_level_id (priority_level_id),
    INDEX idx_location_id (location_id),
    INDEX idx_issue_type_id (issue_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- DETAIL & HISTORY TABLES
-- ================================================================================

-- Table 10: MULTIMEDIA
CREATE TABLE multimedia (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_id INT NOT NULL,
    file_type VARCHAR(20) NOT NULL,
    url VARCHAR(500) NOT NULL,
    CONSTRAINT chk_file_type CHECK (file_type IN ('image', 'video', 'document', 'audio')),
    filename VARCHAR(255),
    file_size INT,
    mime_type VARCHAR(100),
    uploaded_by_citizen BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_media_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    INDEX idx_issue_id (issue_id),
    INDEX idx_file_type (file_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 11: ISSUE_COMMENTS
CREATE TABLE issue_comments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_id INT NOT NULL,
    user_id INT,
    admin_id INT,
    comment_text TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_comment_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_citizen FOREIGN KEY (user_id) REFERENCES citizens(id) ON DELETE SET NULL,
    CONSTRAINT fk_comment_admin FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE SET NULL,
    INDEX idx_issue_id (issue_id),
    INDEX idx_created_at (created_at),
    INDEX idx_is_internal (is_internal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 12: ISSUE_STATUS_HISTORY
CREATE TABLE issue_status_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_id INT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_by_admin INT,
    CONSTRAINT chk_old_status CHECK (old_status IS NULL OR old_status IN ('Reported','Pending','In Progress','Resolved','Rejected','Closed')),
    CONSTRAINT chk_new_status CHECK (new_status IN ('Reported','Pending','In Progress','Resolved','Rejected','Closed')),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    remarks TEXT,
    internal_notes TEXT,
    CONSTRAINT fk_status_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_status_admin FOREIGN KEY (changed_by_admin) REFERENCES admins(id) ON DELETE SET NULL,
    INDEX idx_issue_id (issue_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_new_status (new_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 13: ISSUE_ASSIGNMENTS_HISTORY
CREATE TABLE issue_assignments_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_id INT NOT NULL,
    old_admin_id INT,
    new_admin_id INT NOT NULL,
    assigned_by_admin_id INT,
    assignment_reason TEXT,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reassignment_date DATE,
    CONSTRAINT fk_assign_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_assign_old_admin FOREIGN KEY (old_admin_id) REFERENCES admins(id) ON DELETE SET NULL,
    CONSTRAINT fk_assign_new_admin FOREIGN KEY (new_admin_id) REFERENCES admins(id) ON DELETE RESTRICT,
    CONSTRAINT fk_assigned_by FOREIGN KEY (assigned_by_admin_id) REFERENCES admins(id) ON DELETE SET NULL,
    INDEX idx_issue_id (issue_id),
    INDEX idx_new_admin_id (new_admin_id),
    INDEX idx_assigned_at (assigned_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- FEEDBACK & NOTIFICATION TABLES
-- ================================================================================

-- Table 14: ISSUE_REVIEWS
CREATE TABLE issue_reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_id INT NOT NULL,
    citizen_id INT NOT NULL,
    admin_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    cleanliness_rating INT CHECK (cleanliness_rating BETWEEN 1 AND 5),
    time_taken_rating INT CHECK (time_taken_rating BETWEEN 1 AND 5),
    quality_of_work INT CHECK (quality_of_work BETWEEN 1 AND 5),
    would_recommend BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_review_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_review_citizen FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
    CONSTRAINT fk_review_admin FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE SET NULL,
    UNIQUE(issue_id, citizen_id),
    INDEX idx_issue_id (issue_id),
    INDEX idx_citizen_id (citizen_id),
    INDEX idx_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 15: NOTIFICATIONS
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    recipient_citizen_id INT,
    recipient_admin_id INT,
    issue_id INT,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    CONSTRAINT chk_notification_type CHECK (notification_type IN ('Status Update', 'Assignment', 'Review Request', 'Resolved', 'Assigned', 'Comment Added')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    sent_via VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_sent_via CHECK (sent_via IN ('Email', 'SMS', 'In-App')),
    CONSTRAINT fk_notif_citizen FOREIGN KEY (recipient_citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
    CONSTRAINT fk_notif_admin FOREIGN KEY (recipient_admin_id) REFERENCES admins(id) ON DELETE CASCADE,
    CONSTRAINT fk_notif_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    INDEX idx_recipient_citizen (recipient_citizen_id),
    INDEX idx_recipient_admin (recipient_admin_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at),
    INDEX idx_issue_id (issue_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- TRIGGERS
-- ================================================================================

-- Trigger 1: Auto-update timestamp on ISSUES update
DELIMITER $$
CREATE TRIGGER trg_update_issue_timestamp
BEFORE UPDATE ON issues
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- Trigger 2: Log issue status changes
DELIMITER $$
CREATE TRIGGER trg_log_issue_status_change
AFTER UPDATE ON issues
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO issue_status_history 
        (issue_id, old_status, new_status, changed_at)
        VALUES (NEW.id, OLD.status, NEW.status, CURRENT_TIMESTAMP);
    END IF;
END$$
DELIMITER ;

-- Trigger 3: Prevent deletion of resolved issues
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

-- Trigger 4: Validate admin assignment
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
-- VIEWS
-- ================================================================================

-- View 1: Active Issues (unresolved)
CREATE VIEW v_active_issues AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    it.type_name AS issue_type,
    pl.priority_name AS priority,
    i.status,
    i.assigned_admin,
    COALESCE(a.full_name, 'Unassigned') AS assigned_to,
    DATEDIFF(i.estimated_resolution_date, CURDATE()) AS days_until_deadline,
    i.created_at
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
LEFT JOIN issue_types it ON i.issue_type_id = it.id
LEFT JOIN priority_levels pl ON i.priority_level_id = pl.id
LEFT JOIN admins a ON i.assigned_admin = a.id
WHERE i.status NOT IN ('Resolved', 'Rejected', 'Closed')
ORDER BY pl.priority_name DESC, i.created_at ASC;

-- View 2: Resolved Issues Report
CREATE VIEW v_resolved_issues_report AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    it.type_name AS issue_type,
    a.full_name AS resolved_by,
    d.department_name,
    i.created_at,
    i.resolved_date,
    DATEDIFF(i.resolved_date, i.created_at) AS days_to_resolve
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
LEFT JOIN issue_types it ON i.issue_type_id = it.id
LEFT JOIN admins a ON i.assigned_admin = a.id
LEFT JOIN departments d ON a.department_id = d.id
WHERE i.status = 'Resolved'
ORDER BY i.resolved_date DESC;

-- View 3: User Activity Report
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

-- View 4: Overdue Issues
CREATE VIEW v_overdue_issues AS
SELECT 
    i.id,
    i.title,
    c.full_name AS reported_by,
    it.type_name AS issue_type,
    i.status,
    COALESCE(a.full_name, 'Unassigned') AS assigned_to,
    DATEDIFF(CURDATE(), i.created_at) AS days_pending,
    i.created_at
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
LEFT JOIN issue_types it ON i.issue_type_id = it.id
LEFT JOIN admins a ON i.assigned_admin = a.id
WHERE i.status NOT IN ('Resolved', 'Rejected', 'Closed')
  AND DATEDIFF(CURDATE(), i.created_at) > 7
ORDER BY days_pending DESC;

-- View 5: Issue Type Summary
CREATE VIEW v_issue_type_summary AS
SELECT 
    it.type_name,
    COUNT(i.id) AS total_issues,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) AS resolved,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress,
    SUM(CASE WHEN i.status = 'Reported' THEN 1 ELSE 0 END) AS reported,
    SUM(CASE WHEN i.status = 'Pending' THEN 1 ELSE 0 END) AS pending,
    ROUND(SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(i.id) * 100, 2) 
        AS resolution_rate
FROM issues i
LEFT JOIN issue_types it ON i.issue_type_id = it.id
GROUP BY it.type_name
ORDER BY total_issues DESC;

-- View 6: Admin Performance
CREATE VIEW v_admin_performance AS
SELECT 
    a.id,
    a.full_name,
    a.email,
    d.department_name,
    COUNT(i.id) AS total_issues_handled,
    SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_issues,
    SUM(CASE WHEN i.status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress_issues,
    ROUND(SUM(CASE WHEN i.status = 'Resolved' THEN 1 ELSE 0 END) / NULLIF(COUNT(i.id), 0) * 100, 2) 
        AS resolution_percentage
FROM admins a
LEFT JOIN issues i ON a.id = i.assigned_admin
LEFT JOIN departments d ON a.department_id = d.id
GROUP BY a.id, a.full_name, a.email, d.department_name;

-- ================================================================================
-- STORED PROCEDURES
-- ================================================================================

-- Procedure 1: Report an issue
DELIMITER $$
CREATE PROCEDURE sp_report_issue(
    IN p_citizen_id INT,
    IN p_issue_type_id INT,
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_address VARCHAR(500),
    IN p_location_id INT,
    OUT p_issue_id INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_citizen_exists INT;
    
    SELECT COUNT(*) INTO v_citizen_exists FROM citizens WHERE id = p_citizen_id AND is_active = TRUE;
    
    IF v_citizen_exists = 0 THEN
        SET p_message = 'Citizen not found or inactive';
        SET p_issue_id = NULL;
    ELSE
        INSERT INTO issues 
        (citizen_id, issue_type_id, title, description, address, location_id, status, created_at, updated_at)
        VALUES (p_citizen_id, p_issue_type_id, p_title, p_description, p_address, p_location_id, 'Reported', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        
        SET p_issue_id = LAST_INSERT_ID();
        SET p_message = CONCAT('Issue reported successfully with ID: ', p_issue_id);
    END IF;
END$$
DELIMITER ;

-- Procedure 2: Update issue status
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
    
    SELECT COUNT(*) INTO v_issue_exists FROM issues WHERE id = p_issue_id;
    
    IF v_issue_exists = 0 THEN
        SET p_message = 'Issue not found';
    ELSE
        IF p_admin_id IS NOT NULL THEN
            SELECT COUNT(*) INTO v_admin_exists FROM admins WHERE id = p_admin_id AND is_active = TRUE;
            IF v_admin_exists = 0 THEN
                SET p_message = 'Invalid or inactive admin ID';
                SET p_admin_id = NULL;
            END IF;
        END IF;
        
        SELECT status INTO v_old_status FROM issues WHERE id = p_issue_id;
        
        UPDATE issues 
        SET status = p_new_status, 
            assigned_admin = COALESCE(p_admin_id, assigned_admin),
            updated_at = CURRENT_TIMESTAMP,
            resolved_date = IF(p_new_status = 'Resolved', CURRENT_TIMESTAMP, resolved_date)
        WHERE id = p_issue_id;
        
        INSERT INTO issue_status_history 
        (issue_id, old_status, new_status, changed_by_admin, changed_at)
        VALUES (p_issue_id, v_old_status, p_new_status, p_admin_id, CURRENT_TIMESTAMP);
        
        SET p_message = CONCAT('Issue status updated from ', v_old_status, ' to ', p_new_status);
    END IF;
END$$
DELIMITER ;

-- Procedure 3: Get issues by city
DELIMITER $$
CREATE PROCEDURE sp_get_issues_by_city(
    IN p_city_name VARCHAR(100)
)
BEGIN
    SELECT 
        i.id,
        i.title,
        i.description,
        it.type_name AS issue_type,
        i.status,
        i.address,
        c.full_name AS reported_by,
        COALESCE(a.full_name, 'Unassigned') AS handled_by,
        DATEDIFF(CURDATE(), i.created_at) AS age_in_days,
        i.created_at
    FROM issues i
    LEFT JOIN citizens c ON i.citizen_id = c.id
    LEFT JOIN issue_types it ON i.issue_type_id = it.id
    LEFT JOIN admins a ON i.assigned_admin = a.id
    LEFT JOIN locations l ON i.location_id = l.id
    WHERE l.city = p_city_name
    ORDER BY i.created_at DESC;
END$$
DELIMITER ;

-- ================================================================================
-- FUNCTIONS
-- ================================================================================

-- Function 1: Get total issues by citizen
DELIMITER $$
CREATE FUNCTION fn_get_total_issues_by_citizen(p_citizen_id INT) RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COUNT(*) INTO v_total FROM issues WHERE citizen_id = p_citizen_id;
    RETURN COALESCE(v_total, 0);
END$$
DELIMITER ;

-- Function 2: Get average resolution time
DELIMITER $$
CREATE FUNCTION fn_get_avg_resolution_time() RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_avg_time DECIMAL(10, 2);
    SELECT ROUND(AVG(DATEDIFF(resolved_date, created_at)), 2) INTO v_avg_time
    FROM issues
    WHERE status = 'Resolved' AND resolved_date IS NOT NULL;
    RETURN COALESCE(v_avg_time, 0);
END$$
DELIMITER ;

-- Function 3: Get issue count by status
DELIMITER $$
CREATE FUNCTION fn_get_issue_count_by_status(p_status VARCHAR(20)) RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM issues WHERE status = p_status;
    RETURN COALESCE(v_count, 0);
END$$
DELIMITER ;

-- Function 4: Get days since issue created
DELIMITER $$
CREATE FUNCTION fn_get_days_since_created(p_issue_id INT) RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_days INT;
    SELECT DATEDIFF(CURDATE(), DATE(created_at)) INTO v_days 
    FROM issues 
    WHERE id = p_issue_id;
    RETURN COALESCE(v_days, 0);
END$$
DELIMITER ;

-- ================================================================================
-- INSERT REFERENCE DATA
-- ================================================================================

-- Insert Designations
INSERT INTO designations (designation_name, description, salary_range_min, salary_range_max) VALUES
('Senior Officer', 'Senior administrative officer', 50000, 70000),
('Junior Officer', 'Junior administrative officer', 30000, 45000),
('Supervisor', 'Field supervisor for issue resolution', 40000, 55000),
('Coordinator', 'Issue coordination and tracking', 25000, 35000);

-- Insert Departments
INSERT INTO departments (department_name, description, budget) VALUES
('Public Works', 'Roads, highways, and infrastructure', 5000000),
('Sanitation', 'Garbage collection and waste management', 3000000),
('Water Supply', 'Water pipelines and distribution', 4000000),
('Public Safety', 'Street lights, safety measures', 2000000),
('Health & Hygiene', 'Public health and cleanliness', 1500000);

-- Insert Priority Levels
INSERT INTO priority_levels (priority_name, sla_hours, response_time_hours, resolution_time_days, color_code) VALUES
('Critical', 4, 1, 1, '#FF0000'),
('High', 24, 4, 3, '#FF8800'),
('Medium', 72, 8, 7, '#FFFF00'),
('Low', 168, 24, 14, '#00FF00');

-- Insert Locations
INSERT INTO locations (city, area_name, locality, zip_code, state) VALUES
('Bangalore', 'Whitefield', 'Tech Park', '560066', 'Karnataka'),
('Bangalore', 'Koramangala', 'SoHo', '560034', 'Karnataka'),
('Bangalore', 'Indiranagar', 'IT Hub', '560038', 'Karnataka'),
('Bangalore', '100 Feet Road', 'East Bangalore', '560100', 'Karnataka'),
('Bangalore', 'Marathahalli', 'Tech Zone', '560037', 'Karnataka');

-- Insert Issue Types
INSERT INTO issue_types (type_name, description, department_id, severity_level, avg_resolution_days) VALUES
('Pothole', 'Road surface damage', 1, 'High', 3),
('Water Leakage', 'Water supply pipeline issues', 3, 'High', 2),
('Garbage Accumulation', 'Waste management issues', 2, 'Medium', 1),
('Street Light Malfunction', 'Non-functional street lights', 4, 'Medium', 2),
('Drainage Blockage', 'Clogged drainage systems', 1, 'High', 2);

-- Insert Issue Categories
INSERT INTO issue_categories (issue_type_id, category_name, description) VALUES
(1, 'Small Pothole (1-2 ft)', 'Small surface damage'),
(1, 'Large Pothole (3+ ft)', 'Major road damage'),
(2, 'Pipe Burst', 'Major water leakage'),
(2, 'Joint Leak', 'Minor water seepage'),
(3, 'Overflowing Bins', 'Full waste containers'),
(3, 'Scattered Garbage', 'Waste on streets'),
(4, 'Bulb Failure', 'Single light out'),
(4, 'Complete Panel Down', 'Multiple lights down');

-- ================================================================================
-- INSERT SAMPLE DATA
-- ================================================================================

-- Insert Sample Admins (with hashed passwords)
INSERT INTO admins (full_name, email, phone_number, password, department_id, designation_id, employee_id, date_of_joining, is_active) VALUES
('Rajesh Singh', 'rajesh@gov.in', '9876543210', '$2b$10$qSvxStg5eJMqWvKp7QLhO.I5L5.jF0Z0T0T0T0T0T0', 1, 1, 'EMP001', '2023-01-15', TRUE),
('Priya Sharma', 'priya@gov.in', '9876543211', '$2b$10$qSvxStg5eJMqWvKp7QLhO.I5L5.jF0Z0T0T0T0T0T0', 2, 2, 'EMP002', '2023-02-20', TRUE),
('Amit Patel', 'amit@gov.in', '9876543212', '$2b$10$qSvxStg5eJMqWvKp7QLhO.I5L5.jF0Z0T0T0T0T0T0', 3, 1, 'EMP003', '2023-03-10', TRUE);

-- Insert Sample Citizens (with hashed passwords)
INSERT INTO citizens (full_name, email, phone_number, password, location_id, address, is_active) VALUES
('John Doe', 'john@email.com', '9876543220', '$2b$10$qSvxStg5eJMqWvKp7QLhO.I5L5.jF0Z0T0T0T0T0T0', 1, '42 MG Road, Whitefield', TRUE),
('Jane Smith', 'jane@email.com', '9876543221', '$2b$10$qSvxStg5eJMqWvKp7QLhO.I5L5.jF0Z0T0T0T0T0T0', 2, '100 Koramangala Street', TRUE),
('Mike Johnson', 'mike@email.com', '9876543222', '$2b$10$qSvxStg5eJMqWvKp7QLhO.I5L5.jF0Z0T0T0T0T0T0', 3, '50 Indiranagar Lane', TRUE);

-- Insert Sample Issues
INSERT INTO issues (citizen_id, issue_type_id, issue_category_id, location_id, priority_level_id, title, description, address, status, assigned_admin) VALUES
(1, 1, 1, 1, 3, 'Pothole on MG Road', 'Large pothole causing traffic hazards', '42 MG Road, Whitefield', 'Reported', NULL),
(2, 2, 3, 2, 2, 'Water Pipe Burst', 'Water leaking from underground pipe', '100 Koramangala Street', 'In Progress', 3),
(3, 3, 5, 3, 3, 'Overflowing Garbage Bins', 'Waste containers not emptied', '50 Indiranagar Lane', 'Pending', NULL);

-- ================================================================================
-- VERIFICATION QUERIES
-- ================================================================================

SHOW TABLES;
SHOW TRIGGERS;
SHOW VIEWS;

-- Display table counts
SELECT 'citizens' as table_name, COUNT(*) as row_count FROM citizens
UNION ALL SELECT 'admins', COUNT(*) FROM admins
UNION ALL SELECT 'issues', COUNT(*) FROM issues
UNION ALL SELECT 'departments', COUNT(*) FROM departments
UNION ALL SELECT 'locations', COUNT(*) FROM locations
UNION ALL SELECT 'issue_types', COUNT(*) FROM issue_types;

-- ================================================================================
-- COMPLETION MESSAGE
-- ================================================================================
SELECT '✓ Database Migration Complete! 15 Tables Created Successfully' as Message;
