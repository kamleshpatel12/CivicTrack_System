# Advanced Database Features - Civic Issue Tracking System

## Quick Overview
This database implements:
- ✅ **10 Stored Procedures** for automation
- ✅ **2 Cursor Implementations** for row-by-row processing  
- ✅ **4-5 Nested Subqueries** for complex analytics
- ✅ **3 Views** for simplified data access

---

## STORED PROCEDURES (10 Total)

### 1. `sp_department_performance_report()`
Shows department metrics: total issues, resolved, resolution rate

### 2. `sp_auto_assign_priority()`
Automatically assigns priority based on issue age
- 30+ days = High
- 15-30 days = Medium  
- <15 days = Low

### 3. `sp_get_high_priority_issues(dept_id)`
Get urgent unresolved issues for a department

### 4. `sp_monthly_issue_statistics(year, month)`
Monthly stats: reported, resolved, in progress, rejected

### 5. `sp_bulk_update_status(status, count)`
**Uses CURSOR** - Updates multiple issues and logs changes

### 6. `sp_get_issues_by_location(city_name)`
**Uses nested subquery** - Issues in a city with monthly stats

### 7. `sp_archive_resolved_issues()`
**Uses CURSOR** - Archives issues resolved 90+ days ago

### 8. `sp_citizen_activity_report(email)`
**Uses nested subqueries** - Citizen profile with statistics

### 9. `sp_identify_problem_areas()`
Finds hotspot areas with 3+ issues

### 10. `sp_admin_workload_distribution()`
**Uses nested subqueries** - Admin performance ranking

---

## CURSORS (2 Implementations)

### Cursor 1: `sp_bulk_update_status()`
```sql
DECLARE cursor_issues CURSOR FOR 
    SELECT id, status FROM issues 
    WHERE status != new_status LIMIT issue_count;

LOOP
    FETCH cursor_issues INTO issue_id_var, old_status_var;
    UPDATE issues SET status = new_status WHERE id = issue_id_var;
    INSERT INTO issue_history (...) VALUES (...);
END LOOP;
```
**Purpose**: Updates issues one-by-one and logs each change

---

### Cursor 2: `sp_archive_resolved_issues()`
```sql
DECLARE cursor_resolved CURSOR FOR 
    SELECT id FROM issues 
    WHERE status = 'Resolved' 
    AND DATEDIFF(CURDATE(), updated_at) > 90;

LOOP
    FETCH cursor_resolved INTO issue_id_var;
    INSERT INTO audit_logs (...) VALUES (...);
END LOOP;
```
**Purpose**: Archives old resolved issues with audit trail

---

## 4-5 KEY NESTED QUERIES (For Teacher Explanation)

### NESTED QUERY 1: Department Performance
Shows which department resolved most issues
```sql
SELECT 
    d.department_name,
    (SELECT COUNT(*) FROM issues i 
     WHERE dept_id = d.id) AS total_issues,
    (SELECT COUNT(*) FROM issues i 
     WHERE dept_id = d.id AND status = 'Resolved') AS resolved_issues,
    ROUND((resolved_issues * 100) / total_issues, 2) AS resolution_rate
FROM department d;
```

**Output**: Department name, total issues, resolved count, resolution %

---

### NESTED QUERY 2: Citizen Contributions
Shows citizens with most reported issues
```sql
SELECT 
    c.full_name,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) AS total_reports,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id 
     AND status = 'Resolved') AS resolved,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id 
     AND status = 'In Progress') AS in_progress
FROM citizens c
WHERE (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) > 0
ORDER BY total_reports DESC;
```

**Output**: Shows most active citizens and their issue status breakdown

---

### NESTED QUERY 3: Problem Areas
Identifies locations with recurring issues
```sql
SELECT 
    address,
    COUNT(*) as total_issues,
    (SELECT COUNT(*) FROM issues WHERE address = i.address 
     AND status = 'Resolved') as resolved,
    (SELECT COUNT(*) FROM issues WHERE address = i.address 
     AND status = 'In Progress') as in_progress
FROM issues i
GROUP BY address
HAVING COUNT(*) > 2
ORDER BY total_issues DESC;
```

**Output**: Hotspot areas with 3+ issues and current resolution status

---

### NESTED QUERY 4: Admin Rankings
Shows admin performance with resolution rates
```sql
SELECT 
    a.full_name,
    (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email) AS assigned,
    (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email 
     AND status = 'Resolved') AS resolved,
    ROUND((resolved * 100) / assigned, 2) AS resolution_rate
FROM admins a
WHERE a.is_active = TRUE
ORDER BY resolution_rate DESC;
```

**Output**: Admin names with assignment count and resolution %

---

### NESTED QUERY 5: Overdue Issues
Shows unresolved issues and how long they've been open
```sql
SELECT 
    status,
    COUNT(*) as count,
    AVG(DATEDIFF(CURDATE(), created_at)) as avg_days_open,
    (SELECT COUNT(*) FROM issues WHERE status IN ('Reported', 'Pending') 
     AND DATEDIFF(CURDATE(), created_at) > 30) as overdue_count
FROM issues
WHERE status IN ('Reported', 'Pending', 'In Progress')
GROUP BY status;
```

**Output**: Issues by status with average days open and overdue count

---

## CURSORS EXPLAINED

A cursor processes a result set row-by-row, allowing custom logic for each row.

**Why use cursors here?**
1. **Bulk Update with Logging**: Update issue + log in issue_history simultaneously
2. **Archive with Audit**: Create audit records while archiving old issues
3. **Row-by-row validation**: Could add business logic checks per row

**When NOT to use**: Simply selecting or bulk updating without custom logic

---

## VIEWS (3 Implementations)

### View 1: High Priority Issues
```sql
SELECT * FROM vw_unresolved_high_priority;
```
Shows unresolved medium/high priority issues with days open

### View 2: Department Dashboard  
```sql
SELECT * FROM vw_department_dashboard;
```
Shows department metrics: total, resolved, in progress, pending, resolution rate

### View 3: Citizen Summary
```sql
SELECT * FROM vw_citizen_issues_summary;
```
Shows citizen stats: total reports, resolved, ongoing, last report date

---

## HOW TO EXECUTE

### 1. Load the database features
```sql
SOURCE advanced_features.sql;
```

### 2. Run a procedure
```sql
CALL sp_department_performance_report();
CALL sp_auto_assign_priority();
CALL sp_get_high_priority_issues(1);  -- Dept ID 1
```

### 3. Query a view
```sql
SELECT * FROM vw_unresolved_high_priority;
SELECT * FROM vw_department_dashboard;
```

### 4. Run a nested query (standalone)
```sql
-- Execute any of the 5 nested queries directly
SELECT ...  -- Use NESTED QUERY 1, 2, 3, 4, or 5 from above
```

---

## WHAT TO TELL YOUR TEACHER

### "Here's what we implemented:"

1. **10 Stored Procedures** = Automated business logic
   - Auto-prioritize old issues
   - Get urgent issues for departments
   - Generate monthly reports
   - Bulk update with logging

2. **2 Cursor Implementations** = Row-by-row processing
   - Update issues one-by-one and log each change
   - Archive old issues with audit records

3. **4-5 Nested Subqueries** = Complex analytics without writing multiple queries
   - Department performance (total, resolved, resolution rate)
   - Which citizens report most issues
   - Hotspot areas with recurring problems
   - Admin performance rankings
   - Overdue issues analysis

4. **3 Views** = Simplified data access
   - High priority issues
   - Department dashboard
   - Citizen summary

### "Why is this important?"

- ✅ **Automation**: Procedures run automatically (no manual updates)
- ✅ **Efficiency**: Nested queries get all data in single call
- ✅ **Logging**: Cursors ensure changes are properly tracked
- ✅ **Scalability**: Can handle 1000s of issues
- ✅ **Analytics**: Built-in reporting for management decisions

### Demo Steps for Teacher:

```bash
# Step 1: Set priorities automatically
mysql> CALL sp_auto_assign_priority();

# Step 2: View urgent issues
mysql> SELECT * FROM vw_unresolved_high_priority;

# Step 3: Check department performance
mysql> CALL sp_department_performance_report();

# Step 4: Identify problem areas
mysql> CALL sp_identify_problem_areas();

# Step 5: Check admin workload
mysql> CALL sp_admin_workload_distribution();
```

---

## KEY CONCEPTS TO EXPLAIN

| Concept | What It Does | Example |
|---------|-------------|---------|
| **Nested Subquery** | Query inside a query to get dynamic values | `(SELECT COUNT(*) FROM issues WHERE dept = d.id)` |
| **Cursor** | Process result set row-by-row | Loop through issues, update each one |
| **Stored Procedure** | Pre-written SQL saved in database | `sp_department_performance_report()` |
| **View** | Virtual table from complex query | `vw_unresolved_high_priority` |

---

## PERFORMANCE NOTES

- Nested subqueries are fast for small datasets (< 10,000 rows)
- Cursors are slower but necessary for logging/auditing
- Views are cached by MySQL for quick access
- All queries use indexes on frequently searched columns (status, created_at, etc.)

---

**Total Features**: 10 Procedures + 2 Cursors + 4-5 Nested Queries + 3 Views = Production-Grade Database! 🎉

