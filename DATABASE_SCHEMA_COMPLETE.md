# CIVIC TRACK DATABASE - COMPLETE SCHEMA DOCUMENTATION


---

## TABLE 1: DEPARTMENT (Strong Entity)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| department_name | VARCHAR(100) | NOT NULL, UNIQUE | Department name |
| budget | DECIMAL(15,2) | NULL | Budget allocation |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

**Indexes:** idx_department_name  
**Cardinality:** 1:M with ADMINS, 1:M with CIVIC_CATEGORIES  
**Purpose:** Master list of all departments in the system

---

## TABLE 2: CIVIC_CATEGORIES (Strong Entity)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| type_name | VARCHAR(100) | NOT NULL, UNIQUE | Category/issue type name |
| description | TEXT | NULL | Category description |
| department_id | INT | FK → DEPARTMENT(id) | Parent department |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

**Foreign Keys:**  
- `fk_civic_category_dept` → DEPARTMENT(id) ON DELETE SET NULL

**Indexes:** idx_type_name, idx_department_id  
**Cardinality:** M:1 with DEPARTMENT, 1:M with ISSUES  
**Relationship Type:** Many categories belong to one department  
**Purpose:** Issue types/categories linked to specific departments (e.g., Potholes → Roads & Infrastructure)

---

## TABLE 3: LOCATION (Strong Entity)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| city | VARCHAR(100) | NOT NULL | City name |
| area_name | VARCHAR(100) | NOT NULL | Area/neighborhood name |
| locality | VARCHAR(100) | NULL | Locality/sub-area |
| zip_code | VARCHAR(6) | NULL | Postal code |
| state | VARCHAR(50) | NULL | State/province |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

**Unique Constraint:** (city, area_name) - composite key  
**Indexes:** idx_city, idx_area_name  
**Cardinality:** 1:M with ISSUES  
**Purpose:** Geographic locations where issues can be reported

---

## TABLE 4: CITIZENS (Strong Entity)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| full_name | VARCHAR(255) | NOT NULL | Citizen's full name |
| email | VARCHAR(255) | NOT NULL, UNIQUE | Email address |
| phone_number | VARCHAR(20) | NOT NULL, UNIQUE | Phone number |
| password | VARCHAR(255) | NOT NULL | Hashed password |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Registration timestamp |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

**Indexes:** idx_email, idx_phone_number  
**Cardinality:** 1:M with ISSUES, 1:M with AUDIT_LOGS  
**Purpose:** Citizen user accounts for reporting issues

---

## TABLE 5: ADMINS (Strong Entity)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| full_name | VARCHAR(255) | NOT NULL | Admin's full name |
| email | VARCHAR(255) | NOT NULL, UNIQUE | Email address |
| phone_number | VARCHAR(20) | NOT NULL, UNIQUE | Phone number |
| password | VARCHAR(255) | NOT NULL | Hashed password |
| department_id | INT | FK → DEPARTMENT(id) | Assigned department |
| employee_id | VARCHAR(50) | UNIQUE | Employee ID |
| is_active | BOOLEAN | DEFAULT TRUE | Active status |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Registration timestamp |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

**Foreign Keys:**  
- `fk_admin_dept` → DEPARTMENT(id) ON DELETE SET NULL

**Indexes:** idx_department_id, idx_is_active, idx_employee_id  
**Cardinality:** M:1 with DEPARTMENT, 1:M with ISSUES, 1:M with ISSUE_HISTORY, 1:M with PRIORITY_ASSIGNMENTS, 1:M with AUDIT_LOGS, 1:1 with HEAD_ADMIN  
**Purpose:** Department administrators who manage issues and assign priorities

---

## TABLE 6: STATUS (Reference Entity - Lookup Table)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| status_name | VARCHAR(50) | NOT NULL, UNIQUE | Status name (Reported, Pending, etc.) |
| description | TEXT | NULL | Detailed description |
| color | VARCHAR(20) | NULL | Hex color for UI display |
| is_active | BOOLEAN | DEFAULT TRUE | Active/inactive status |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

**Indexes:** idx_status_name, idx_is_active  
**Pre-populated Data:**
- Reported (#FF6B6B) - Issue has been reported by citizen
- Pending (#FFA500) - Issue received and awaiting action
- In Progress (#4ECDC4) - Issue is being actively worked on
- Resolved (#95E1D3) - Issue has been fixed and resolved
- Rejected (#D3D3D3) - Issue was rejected or invalid
- Closed (#808080) - Issue has been closed and archived

**Purpose:** Master reference table defining all possible issue statuses

---

## TABLE 7: HEAD_ADMIN (Strong Entity - Associative Table)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| admin_id | INT | FK → ADMINS(id), UNIQUE | Reference to admin |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

**Foreign Keys:**  
- `fk_head_admin` → ADMINS(id) ON DELETE CASCADE

**Indexes:** idx_admin_id  
**Cardinality:** 1:1 with ADMINS  
**Entity Type:** Independent associative/mapping table  
**Purpose:** Designates which admins have head admin privileges (role/privilege assignment table)  
**Feature:** One-to-one relationship with ADMINS (each admin has at most one head_admin designation)

---

## TABLE 8: ISSUES (Strong Entity - Core Transaction Table)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| citizen_id | INT | FK → CITIZENS(id), NOT NULL | Issue reporter |
| issue_type_id | INT | FK → CIVIC_CATEGORIES(id), NOT NULL | Category of issue |
| location_id | INT | FK → LOCATION(id), NULL | Optional geographic location (reference only) |
| title | VARCHAR(255) | NOT NULL | Issue title |
| description | TEXT | NOT NULL | Detailed description |
| address | VARCHAR(255) | NOT NULL | **PRIMARY** - Complete physical address where issue occurred |
| status | VARCHAR(20) | DEFAULT 'Reported' | Current status |
| assigned_admin | INT | FK → ADMINS(id) | Assigned administrator |
| priority | VARCHAR(20) | NULL | Priority level |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Report timestamp |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | Last update |
| resolved_date | TIMESTAMP | NULL | Resolution date |

**Check Constraint:**  
- `chk_issues_status`: status IN ('Reported','Pending','In Progress','Resolved','Rejected','Closed')

**Foreign Keys:**
- `fk_issue_citizen` → CITIZENS(id) ON DELETE CASCADE
- `fk_issue_category` → CIVIC_CATEGORIES(id) ON DELETE RESTRICT
- `fk_issue_location` → LOCATION(id) ON DELETE SET NULL
- `fk_issue_admin` → ADMINS(id) ON DELETE SET NULL

**Indexes:** idx_status, idx_citizen_id, idx_assigned_admin, idx_created_at, idx_location_id, idx_issue_type_id, idx_priority  
**Cardinality:**
- M:1 with CITIZENS (many issues per citizen)
- M:1 with CIVIC_CATEGORIES (many issues per category)
- M:1 with LOCATION (many issues per location)
- M:1 with ADMINS (many issues per admin)
- 1:M with ISSUE_HISTORY (one issue has many status changes)
- 1:M with PRIORITY_ASSIGNMENTS (one issue has many priority changes)

**Purpose:** Core transaction table storing all reported civic issues

**Location Design Pattern:** 
- `address` field is PRIMARY location storage (free-text, flexible, any location accepted)
- `location_id` is OPTIONAL reference to pre-defined areas (for analytics/filtering only)
- Citizens can report from any location by entering address - no pre-registration required
- Address field accepts: "Indira Vihar, Pune", "123 Main St, New York", etc.

---

## TABLE 9: ISSUE_HISTORY (Weak Entity ⚠️ - Audit Trail)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| issue_id | INT | FK → ISSUES(id), NOT NULL | Parent issue |
| old_status | VARCHAR(20) | NULL | Previous status |
| new_status | VARCHAR(20) | NOT NULL | Current status |
| changed_by_admin_id | INT | FK → ADMINS(id) | Admin who changed status |
| remarks | TEXT | NULL | Comments about change |
| changed_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Change timestamp |

**Check Constraints:**
- `chk_issue_history_old_status`: old_status IS NULL OR in valid statuses
- `chk_issue_history_new_status`: new_status IN valid statuses

**Foreign Keys:**
- `fk_history_issue` → ISSUES(id) ON DELETE CASCADE
- `fk_history_admin` → ADMINS(id) ON DELETE SET NULL

**Indexes:** idx_issue_id, idx_changed_at, idx_new_status, idx_changed_by_admin_id  
**Cardinality:** M:1 with ISSUES, M:1 with ADMINS  
**Weak Entity:** Existence depends on ISSUES table (CASCADE Delete)  
**Purpose:** Audit trail for status changes  
**Auto-populated by:** Trigger `trg_log_issue_status_change`

---

## TABLE 10: PRIORITY_ASSIGNMENTS (Weak Entity ⚠️ - Audit Trail)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| issue_id | INT | FK → ISSUES(id), NOT NULL | Reference issue |
| priority | VARCHAR(20) | NULL | Assigned priority level |
| assigned_by_admin_id | INT | FK → ADMINS(id), NOT NULL | Head admin who assigned |
| remarks | TEXT | NULL | Notes about assignment |
| assigned_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Assignment timestamp |

**Foreign Keys:**
- `fk_priority_issue` → ISSUES(id) ON DELETE CASCADE
- `fk_priority_admin` → ADMINS(id) ON DELETE RESTRICT

**Indexes:** idx_issue_id, idx_assigned_at, idx_priority, idx_assigned_by_admin_id  
**Cardinality:** M:1 with ISSUES, M:1 with ADMINS  
**Weak Entity:** Existence depends on ISSUES table (CASCADE Delete)  
**Purpose:** Track priority assignment history  
**Feature:** ON DELETE RESTRICT on admin (prevents deletion of admins with pending assignments)

---

## TABLE 11: AUDIT_LOGS (Weak Entity ⚠️ - System Activity)

| Column | Data Type | Constraints | Notes |
|--------|-----------|-------------|-------|
| id | INT | PK, AUTO_INCREMENT | Unique identifier |
| action_type | VARCHAR(50) | NOT NULL | Type of action |
| entity_type | VARCHAR(50) | NOT NULL | Entity affected |
| entity_id | INT | NULL | ID of affected entity |
| performed_by_admin_id | INT | FK → ADMINS(id) | Admin who performed action |
| performed_by_citizen_id | INT | FK → CITIZENS(id) | Citizen who performed action |
| old_value | TEXT | NULL | Previous value |
| new_value | TEXT | NULL | New value |
| details | VARCHAR(500) | NULL | Additional details |
| ip_address | VARCHAR(45) | NULL | IP address of action |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Action timestamp |

**Check Constraints:**
- `chk_audit_logs_action_type`: IN ('Login', 'Logout', 'StatusChange', 'AssignmentChange', 'PriorityChange', 'DataEdit', 'Deletion', 'IssueCreated')
- `chk_audit_logs_entity_type`: IN ('Issue', 'Admin', 'Citizen', 'Department', 'Profile')

**Foreign Keys:**
- `fk_audit_admin` → ADMINS(id) ON DELETE SET NULL
- `fk_audit_citizen` → CITIZENS(id) ON DELETE SET NULL

**Indexes:** idx_action_type, idx_entity_type, idx_performed_by_admin, idx_performed_by_citizen, idx_created_at, idx_entity_id  
**Cardinality:** M:1 with ADMINS, M:1 with CITIZENS  
**Weak Entity:** Depends on either ADMINS or CITIZENS  
**Purpose:** System-wide activity logging for compliance and audit

---

## COMPLETE RELATIONSHIP SUMMARY

| Relationship | Type | Cardinality | Delete Rule | Description |
|--------------|------|-------------|-------------|-------------|
| DEPARTMENT ↔ CIVIC_CATEGORIES | 1:M | One-to-Many | SET NULL | One department has many issue categories |
| DEPARTMENT ↔ ADMINS | 1:M | One-to-Many | SET NULL | One department has many admins |
| CITIZENS ↔ ISSUES | 1:M | One-to-Many | CASCADE | One citizen can report many issues |
| CIVIC_CATEGORIES ↔ ISSUES | 1:M | One-to-Many | RESTRICT | One category has many issues |
| LOCATION ↔ ISSUES | 1:M | One-to-Many | SET NULL | One location has many reported issues |
| ADMINS ↔ ISSUES | 1:M | One-to-Many | SET NULL | One admin can handle many issues |
| ADMINS ↔ HEAD_ADMIN | 1:1 | One-to-One | CASCADE | One admin can be designated as head admin |
| ISSUES ↔ ISSUE_HISTORY | 1:M | One-to-Many | CASCADE | One issue has many status changes |
| ADMINS ↔ ISSUE_HISTORY | M:1 | Many-to-One | SET NULL | Many admins can change statuses |
| ISSUES ↔ PRIORITY_ASSIGNMENTS | 1:M | One-to-Many | CASCADE | One issue can have many priority assignments |
| ADMINS ↔ PRIORITY_ASSIGNMENTS | M:1 | Many-to-One | RESTRICT | Many priority assignments by admins |
| ADMINS ↔ AUDIT_LOGS | M:1 | Many-to-One | SET NULL | Admin activities logged |
| CITIZENS ↔ AUDIT_LOGS | M:1 | Many-to-One | SET NULL | Citizen activities logged |

---

## WEAK ENTITIES (Dependent on Parent Tables)

1. **ISSUE_HISTORY** - Depends on ISSUES (CASCADE Delete)
   - Audit trail records cannot exist without parent issue
   - When issue is deleted, all status change history is deleted

2. **PRIORITY_ASSIGNMENTS** - Depends on ISSUES (CASCADE Delete)
   - Priority change records cannot exist without parent issue
   - When issue is deleted, all priority history is deleted

3. **AUDIT_LOGS** - Depends on ADMINS or CITIZENS (SET NULL)
   - Activity records remain but lose reference if user is deleted
   - Allows historical tracking even if user account is removed

---

## STRONG ENTITIES (Independent)

1. **DEPARTMENT** - Can exist independently
2. **CIVIC_CATEGORIES** - Can exist independently (though linked to departments)
3. **LOCATION** - Can exist independently
4. **CITIZENS** - Can exist independently
5. **ADMINS** - Can exist independently (though linked to departments)
6. **STATUS** - Reference table (can exist independently)
7. **HEAD_ADMIN** - Associative/mapping table (designates admin privileges, independent entity)
8. **ISSUES** - Core transaction table (independent despite FKs)

---

## KEY DATA TYPE PATTERNS

**Primary Keys:** All INT AUTO_INCREMENT  
**Unique Identifiers:**
- EMAIL (CITIZENS, ADMINS)
- PHONE_NUMBER (CITIZENS, ADMINS)
- DEPARTMENT_NAME (DEPARTMENT)
- TYPE_NAME (CIVIC_CATEGORIES)
- STATUS_NAME (STATUS)
- EMPLOYEE_ID (ADMINS)
- ADMIN_ID (HEAD_ADMIN - one-to-one)

**Composite Keys:**
- (city, area_name) in LOCATION

**Timestamps:**
- created_at: DEFAULT CURRENT_TIMESTAMP (immutable)
- updated_at: ON UPDATE CURRENT_TIMESTAMP (auto-updates)
- changed_at/assigned_at: DEFAULT CURRENT_TIMESTAMP (specific event timestamps)

**Enums (Check Constraints):**
- status: 'Reported', 'Pending', 'In Progress', 'Resolved', 'Rejected', 'Closed'
- action_type: 'Login', 'Logout', 'StatusChange', 'AssignmentChange', 'PriorityChange', 'DataEdit', 'Deletion', 'IssueCreated'
- entity_type: 'Issue', 'Admin', 'Citizen', 'Department', 'Profile'

---

## TRIGGERS (Automated Actions)

1. **trg_update_issue_timestamp**
   - Event: BEFORE UPDATE on ISSUES
   - Action: Auto-updates `updated_at` timestamp
   - Purpose: Track when issue record was last modified

2. **trg_log_issue_status_change**
   - Event: AFTER UPDATE on ISSUES
   - Condition: Only fires if `status` field changes
   - Action: Inserts record into ISSUE_HISTORY
   - Purpose: Automatic audit trail of status changes

3. **trg_prevent_delete_resolved**
   - Event: BEFORE DELETE on ISSUES
   - Condition: Only fires if status is 'Resolved'
   - Action: Raises error "Cannot delete resolved issues..."
   - Purpose: Enforce compliance/audit requirements

4. **trg_validate_admin_assignment**
   - Event: BEFORE UPDATE on ISSUES
   - Condition: If assigned_admin is being set
   - Action: Validates admin exists and is active
   - Purpose: Prevent invalid admin assignments

---

## DATABASE CHARACTERISTICS

✅ **Engine:** InnoDB (supports transactions, foreign keys)  
✅ **Charset:** utf8mb4 (supports full Unicode including emojis)  
✅ **Collation:** utf8mb4_unicode_ci (case-insensitive Unicode)  
✅ **Foreign Key Checks:** Enabled (referential integrity enforced)  
✅ **Cascade Deletes:** Used for dependent records (ISSUE_HISTORY, PRIORITY_ASSIGNMENTS, HEAD_ADMIN)  
✅ **Restrict Deletes:** Used for critical relationships (CIVIC_CATEGORIES, PRIORITY_ASSIGNMENTS)  
✅ **Set Null Deletes:** Used for optional assignments (DEPARTMENT, LOCATION, ADMINS in audit)

---

## INDEX STRATEGY

**High-cardinality indexes (fast lookups):**
- idx_email (CITIZENS, ADMINS)
- idx_phone_number (CITIZENS, ADMINS)
- idx_created_at (ISSUES, ISSUE_HISTORY, AUDIT_LOGS)
- idx_changed_at (ISSUE_HISTORY)

**Foreign key indexes:**
- idx_department_id
- idx_citizen_id
- idx_assigned_admin
- idx_issue_id
- idx_changed_by_admin_id

**Reference indexes:**
- idx_status
- idx_priority
- idx_action_type
- idx_entity_type

---

## SAMPLE DATA PRESET

**Pre-populated Tables:**
- STATUS: 6 predefined statuses with color codes
- DEPARTMENT: 5 departments (Water Supply, Roads & Infrastructure, Sanitation, Parks & Recreation, Public Safety)
- CIVIC_CATEGORIES: 5 issue types linked to departments
- LOCATION: Optional reference areas (not required for issue creation - address field is flexible)
- CITIZENS: Sample citizen (ID: 1, John Doe)

**Note:** LOCATION table is optional. Citizens can report from ANY location via the address field without needing pre-registration.

---

## USAGE EXAMPLES

### Issue Lifecycle
1. Citizen reports issue:
   - Enters: title, description, **address** (any location, no validation)
   - Optional: location_id (if from pre-defined area)
   - Result: ISSUES.status = 'Reported', AUDIT_LOGS = IssueCreated
2. Admin views issue → AUDIT_LOGS = DataEdit
3. Admin assigns to self → ISSUES.assigned_admin updated, AUDIT_LOGS = AssignmentChange
4. Admin works on it → ISSUES.status = 'In Progress' (triggers ISSUE_HISTORY)
5. Admin resolves → ISSUES.status = 'Resolved' (triggers ISSUE_HISTORY + blocks deletion)
6. Head admin assigns priority → PRIORITY_ASSIGNMENTS row inserted, AUDIT_LOGS = PriorityChange
7. Admin closes → ISSUES.status = 'Closed' (triggers ISSUE_HISTORY)

### Audit Trail Access
- View all status changes for issue: SELECT * FROM issue_history WHERE issue_id = X
- View who changed what: SELECT * FROM audit_logs WHERE entity_id = X
- View admin activity: SELECT * FROM audit_logs WHERE performed_by_admin_id = Y
- View all changes by date: ORDER BY changed_at DESC

---

## FOR ER DIAGRAM CREATION

**Essential Elements:**
- ✅ All 11 tables with all columns
- ✅ Primary keys (underlined/bold)
- ✅ Foreign keys (with cardinality symbols)
- ✅ Unique constraints (marked with U)
- ✅ Check constraints (documented)
- ✅ 1:M relationships (crow's foot notation)
- ✅ 1:1 relationships (one-to-one line)
- ✅ Weak entities (double rectangle)
- ✅ Strong entities (single rectangle)
- ✅ Identifying relationships (double line for weak entities)

**Cardinality Symbols:**
- One side: | (one)
- Many side: > (many)
- Example: DEPARTMENT -< ADMINS (one-to-many)

---

**Document Version:** 1.0  
**Last Updated:** April 5, 2026  
**Status:** Complete and Ready for ER Diagram
