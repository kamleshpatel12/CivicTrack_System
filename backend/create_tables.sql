-- Create Database
CREATE DATABASE IF NOT EXISTS civic_issue_db;
USE civic_issue_db;

-- Citizens Table
CREATE TABLE citizens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone_number VARCHAR(10) NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
);

-- Admins Table
CREATE TABLE admins (
  id INT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone_number VARCHAR(10) NOT NULL,
  password VARCHAR(255) NOT NULL,
  department VARCHAR(100) NOT NULL,
  admin_access_code INT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
);

-- Issues Table
CREATE TABLE issues (
  id INT PRIMARY KEY AUTO_INCREMENT,
  citizen_id INT NOT NULL,
  issue_type ENUM('Road Infrastructure', 'Waste Management', 'Environmental Issues', 'Utilities & Infrastructure', 'Public Safety', 'Other') DEFAULT 'Road Infrastructure',
  title VARCHAR(100) UNIQUE NOT NULL,
  description LONGTEXT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  address VARCHAR(500),
  status ENUM('Reported', 'In Progress', 'Resolved', 'Rejected', 'Pending') DEFAULT 'Reported',
  handled_by INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
  FOREIGN KEY (handled_by) REFERENCES admins(id) ON DELETE SET NULL,
  INDEX idx_citizen_id (citizen_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at),
  INDEX idx_handled_by (handled_by)
);

-- Multimedia Table
CREATE TABLE multimedia (
  id INT PRIMARY KEY AUTO_INCREMENT,
  issue_id INT NOT NULL,
  file_type ENUM('image', 'video') NOT NULL,
  url VARCHAR(500) NOT NULL,
  filename VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
  INDEX idx_issue_id (issue_id)
);

-- Issue Status History Table (Audit Trail)
CREATE TABLE issue_status_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  issue_id INT NOT NULL,
  old_status VARCHAR(50),
  new_status VARCHAR(50) NOT NULL,
  changed_by INT,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES admins(id) ON DELETE SET NULL,
  INDEX idx_issue_id (issue_id),
  INDEX idx_changed_at (changed_at)
);

-- Verify tables were created
SHOW TABLES;
