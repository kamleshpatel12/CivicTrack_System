

SET FOREIGN_KEY_CHECKS = 0;

-- Core 10 tables (drop to recreate)
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS priority_assignments;
DROP TABLE IF EXISTS issue_history;
DROP TABLE IF EXISTS issues;
DROP TABLE IF EXISTS head_admin;
DROP TABLE IF EXISTS status;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS citizens;
DROP TABLE IF EXISTS civic_categories;
DROP TABLE IF EXISTS location;
DROP TABLE IF EXISTS department;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;



-- Table 1: DEPARTMENT
CREATE TABLE department (
    id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    budget DECIMAL(15, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_department_name (department_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 2: CIVIC_CATEGORIES
CREATE TABLE civic_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    department_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_civic_category_dept FOREIGN KEY (department_id) REFERENCES department(id) ON DELETE SET NULL,
    INDEX idx_type_name (type_name),
    INDEX idx_department_id (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 3: LOCATION
CREATE TABLE location (
    id INT PRIMARY KEY AUTO_INCREMENT,
    city VARCHAR(100) NOT NULL,
    area_name VARCHAR(100) NOT NULL,
    locality VARCHAR(100),
    zip_code VARCHAR(6),
    state VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(city, area_name),
    INDEX idx_city (city),
    INDEX idx_area_name (area_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- CORE ENTITY TABLES
-- ================================================================================

-- Table 4: CITIZENS
CREATE TABLE citizens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_phone_number (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 5: ADMINS
CREATE TABLE admins(
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    department_id INT,
    employee_id VARCHAR(50) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_admin_dept FOREIGN KEY (department_id) REFERENCES department(id) ON DELETE SET NULL,
    INDEX idx_department_id (department_id),
    INDEX idx_is_active (is_active),
    INDEX idx_employee_id (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- TABLE 6: STATUS (Status Definitions)
-- ================================================================================
-- Master table defining all possible issue statuses
CREATE TABLE status (
    id INT PRIMARY KEY AUTO_INCREMENT,
    status_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    color VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_status_name (status_name),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- TABLE 7: HEAD_ADMIN (Separate Table for Head Administrators)
-- ================================================================================
-- Designates which admins have head admin privileges
CREATE TABLE head_admin (
    id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_head_admin FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
    INDEX idx_admin_id (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- TABLE 8: ISSUES (Transaction Table - Core)
-- ================================================================================
-- Citizens report issues here
-- Each issue can be tracked and updated by admins
CREATE TABLE issues (
    id INT PRIMARY KEY AUTO_INCREMENT,
    citizen_id INT NOT NULL,
    issue_type_id INT NOT NULL,
    location_id INT,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    address VARCHAR(255),
    status VARCHAR(20) DEFAULT 'Reported',
    assigned_admin INT,
    priority VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_date TIMESTAMP NULL,
    
    CONSTRAINT chk_issues_status CHECK (status IN ('Reported','Pending','In Progress','Resolved','Rejected','Closed')),
    CONSTRAINT fk_issue_citizen FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
    CONSTRAINT fk_issue_category FOREIGN KEY (issue_type_id) REFERENCES civic_categories(id) ON DELETE RESTRICT,
    CONSTRAINT fk_issue_location FOREIGN KEY (location_id) REFERENCES location(id) ON DELETE SET NULL,
    CONSTRAINT fk_issue_admin FOREIGN KEY (assigned_admin) REFERENCES admins(id) ON DELETE SET NULL,
    
    INDEX idx_status (status),
    INDEX idx_citizen_id (citizen_id),
    INDEX idx_assigned_admin (assigned_admin),
    INDEX idx_created_at (created_at),
    INDEX idx_location_id (location_id),
    INDEX idx_issue_type_id (issue_type_id),
    INDEX idx_priority (priority)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- TABLE 9: ISSUE_HISTORY (Audit Trail Table)
-- ================================================================================
-- Tracks every status change of an issue
-- Provides complete audit trail for compliance and analysis
CREATE TABLE issue_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_id INT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_by_admin_id INT,
    remarks TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_issue_history_old_status CHECK (old_status IS NULL OR old_status IN ('Reported','Pending','In Progress','Resolved','Rejected','Closed')),
    CONSTRAINT chk_issue_history_new_status CHECK (new_status IN ('Reported','Pending','In Progress','Resolved','Rejected','Closed')),
    CONSTRAINT fk_history_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_history_admin FOREIGN KEY (changed_by_admin_id) REFERENCES admins(id) ON DELETE SET NULL,
    
    INDEX idx_issue_id (issue_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_new_status (new_status),
    INDEX idx_changed_by_admin_id (changed_by_admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- TABLE 10: PRIORITY_ASSIGNMENTS (Audit Trail Table)
-- ================================================================================
-- Tracks priority assignments made by head admins
-- Complete audit trail for priority decision history
CREATE TABLE priority_assignments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    issue_id INT NOT NULL,
    priority VARCHAR(20),
    assigned_by_admin_id INT NOT NULL,
    remarks TEXT,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_priority_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_priority_admin FOREIGN KEY (assigned_by_admin_id) REFERENCES admins(id) ON DELETE RESTRICT,
    
    INDEX idx_issue_id (issue_id),
    INDEX idx_assigned_at (assigned_at),
    INDEX idx_priority (priority),
    INDEX idx_assigned_by_admin_id (assigned_by_admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- TABLE 11: AUDIT_LOGS (System Activity Tracking)
-- ================================================================================
-- Tracks all important actions in the system for compliance and audit purposes
CREATE TABLE audit_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    action_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT,
    performed_by_admin_id INT,
    performed_by_citizen_id INT,
    old_value TEXT,
    new_value TEXT,
    details VARCHAR(500),
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_audit_admin FOREIGN KEY (performed_by_admin_id) REFERENCES admins(id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_citizen FOREIGN KEY (performed_by_citizen_id) REFERENCES citizens(id) ON DELETE SET NULL,
    CONSTRAINT chk_audit_logs_action_type CHECK (action_type IN ('Login', 'Logout', 'StatusChange', 'AssignmentChange', 'PriorityChange', 'DataEdit', 'Deletion', 'IssueCreated')),
    CONSTRAINT chk_audit_logs_entity_type CHECK (entity_type IN ('Issue', 'Admin', 'Citizen', 'Department', 'Profile')),
    
    INDEX idx_action_type (action_type),
    INDEX idx_entity_type (entity_type),
    INDEX idx_performed_by_admin (performed_by_admin_id),
    INDEX idx_performed_by_citizen (performed_by_citizen_id),
    INDEX idx_created_at (created_at),
    INDEX idx_entity_id (entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- TRIGGERS

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
        INSERT INTO issue_history 
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
-- INSERT DEFAULT STATUS TYPES
-- ================================================================================
INSERT INTO status (status_name, description, color, is_active) VALUES
('Reported', 'Issue has been reported by citizen', '#FF6B6B', TRUE),
('Pending', 'Issue received and awaiting action', '#FFA500', TRUE),
('In Progress', 'Issue is being actively worked on', '#4ECDC4', TRUE),
('Resolved', 'Issue has been fixed and resolved', '#95E1D3', TRUE),
('Rejected', 'Issue was rejected or invalid', '#D3D3D3', TRUE),
('Closed', 'Issue has been closed and archived', '#808080', TRUE);


