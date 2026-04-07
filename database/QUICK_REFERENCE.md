# Quick Reference Guide - Executing Advanced Database Features

## 📋 QUICK START

### Step 1: Load the Advanced Features
```sql
SOURCE /path/to/advanced_features.sql;
-- Or from command line:
-- mysql -u root -p civic_issue_db < advanced_features.sql
```

### Step 2: Verify Installation
```sql
-- List all procedures
SHOW PROCEDURE STATUS WHERE db = 'civic_issue_db';

-- List all views
SHOW TABLES IN civic_issue_db LIKE 'vw_%';
```

---

## 🔥 10 QUICK COMMANDS

### 1. Department Performance Report
```sql
CALL sp_department_performance_report();
```
**Shows**: Total issues, resolved issues, resolution rate per department

---

### 2. Auto-Assign Priorities
```sql
CALL sp_auto_assign_priority();
```
**Does**: Automatically prioritizes issues based on age (30 days = High, 15-30 = Medium)

---

### 3. Get High Priority Issues for Department
```sql
CALL sp_get_high_priority_issues(1);
-- Replace 1 with department ID
```
**Shows**: All unresolved high-priority issues for specific department

---

### 4. Monthly Statistics
```sql
CALL sp_monthly_issue_statistics(2026, 4);
-- 2026 = year, 4 = April
```
**Shows**: Monthly issue counts, resolutions, rejections, most common issue type

---

### 5. Bulk Update Issue Status
```sql
CALL sp_bulk_update_status('In Progress', 10);
-- 'In Progress' = new status, 10 = number of issues to update
```
**Does**: Updates status for multiple issues and logs all changes

---

### 6. Get Issues by City
```sql
CALL sp_get_issues_by_location('Manipal');
```
**Shows**: All issues in specific city with monthly statistics

---

### 7. Archive Old Resolved Issues
```sql
CALL sp_archive_resolved_issues();
```
**Does**: Archives issues resolved over 90 days ago

---

### 8. Citizen Activity Report
```sql
CALL sp_citizen_activity_report('citizen@example.com');
```
**Shows**: Total reports, resolved, ongoing, avg resolution time, last report date

---

### 9. Identify Problem Areas
```sql
CALL sp_identify_problem_areas();
```
**Shows**: Cities with 3+ issues, most common issue type, trend dates

---

### 10. Admin Workload Distribution
```sql
CALL sp_admin_workload_distribution();
```
**Shows**: Issues per admin, resolved count, resolution rate

---

## 📊 VIEW QUERIES

### View 1: Unresolved High Priority Issues
```sql
SELECT * FROM vw_unresolved_high_priority;

-- Filtered version
SELECT * FROM vw_unresolved_high_priority 
WHERE days_open > 30 
ORDER BY priority_name DESC;
```

---

### View 2: Department Dashboard
```sql
SELECT * FROM vw_department_dashboard;

-- Show only departments with low resolution rate
SELECT * FROM vw_department_dashboard 
WHERE resolution_rate < 75 
ORDER BY resolution_rate ASC;
```

---

### View 3: Citizen Issues Summary
```sql
SELECT * FROM vw_citizen_issues_summary;

-- Show citizens with unresolved issues
SELECT * FROM vw_citizen_issues_summary 
WHERE ongoing_reports > 0 
ORDER BY ongoing_reports DESC;
```

---

## 🔍 REAL-WORLD SCENARIOS

### Scenario 1: Head Admin Dashboard
```sql
-- Get all critical metrics
SELECT * FROM vw_department_dashboard;
CALL sp_identify_problem_areas();
CALL sp_admin_workload_distribution();
```

### Scenario 2: Daily Priority Assignment
```sql
-- Auto-assign priorities to old unresolved issues
CALL sp_auto_assign_priority();

-- View newly prioritized high-priority issues
SELECT * FROM vw_unresolved_high_priority 
WHERE days_open > 20;
```

### Scenario 3: Monthly Report Generation
```sql
-- Get April 2026 statistics
CALL sp_monthly_issue_statistics(2026, 4);

-- Get department performance
CALL sp_department_performance_report();

-- Identify problem areas
CALL sp_identify_problem_areas();
```

### Scenario 4: Bulk Status Update
```sql
-- Move 15 pending issues to "In Progress"
CALL sp_bulk_update_status('In Progress', 15);

-- Verify changes
SELECT * FROM issues WHERE status = 'In Progress' 
ORDER BY updated_at DESC LIMIT 15;
```

### Scenario 5: Citizen Profile Access
```sql
-- Get specific citizen details
CALL sp_citizen_activity_report('john@email.com');

-- Get all their issues
CALL sp_get_issues_by_location('Manipal');
```

---

## ⚙️ DATABASE MAINTENANCE

### Archive old resolved issues (quarterly)
```sql
CALL sp_archive_resolved_issues();
```

### Check admin workload balance (monthly)
```sql
CALL sp_admin_workload_distribution();
```

### Identify overdue issues (weekly)
```sql
SELECT * FROM vw_unresolved_high_priority 
WHERE days_open > 30;
```

---

## 🟢 STATUS GUIDE

| Status | Used For | Next Step |
|--------|----------|-----------|
| Reported | New issue just created | Assign to admin |
| Pending | Awaiting approval | Review & prioritize |
| In Progress | Being worked on | Monitor & update |
| Resolved | Issue fixed | Close after follow-up |
| Rejected | Cannot be resolved | Notify citizen |

---

## 📈 ANALYTICS QUERIES

### Top 5 Most Issues Types
```sql
SELECT issue_type, COUNT(*) as count 
FROM issues 
GROUP BY issue_type 
ORDER BY count DESC LIMIT 5;
```

### Average Resolution Time by Department
```sql
SELECT d.department_name, 
       AVG(DATEDIFF(i.updated_at, i.created_at)) as avg_days
FROM issues i
JOIN admins a ON i.assigned_to = a.email
JOIN department d ON a.department_id = d.id
WHERE i.status = 'Resolved'
GROUP BY d.department_name
ORDER BY avg_days DESC;
```

### Issues by Month (2026)
```sql
SELECT DATE_FORMAT(created_at, '%Y-%m') as month,
       COUNT(*) as count,
       SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) as resolved
FROM issues
WHERE YEAR(created_at) = 2026
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY month DESC;
```

---

## 🐛 TROUBLESHOOTING

### Procedure not found?
```sql
-- Check if procedure exists
SHOW PROCEDURE STATUS WHERE db = 'civic_issue_db';

-- Reload procedures
SOURCE advanced_features.sql;
```

### Getting NULL results?
- Check if tables have sufficient data
- Verify foreign key relationships
- Use EXPLAIN to see query plan

### Cursor issues?
- Ensure LIMIT on cursor SELECT
- Check variable initialization
- Verify HANDLER syntax

---

## 📝 COMMON PARAMETERS

| Procedure | Parameter 1 | Parameter 2 |
|-----------|-----------|-----------|
| sp_get_high_priority_issues | dept_id (1-5) | - |
| sp_monthly_issue_statistics | year (2026) | month (1-12) |
| sp_bulk_update_status | status | count |
| sp_get_issues_by_location | city name | - |
| sp_citizen_activity_report | email | - |

---

## 🎯 PERFORMANCE TIPS

1. **Use Views for repeated queries** - Faster than writing complex joins
2. **Limit cursor iterations** - Always use WHERE clause to filter
3. **Index frequently searched columns** - city, status, created_at
4. **Schedule procedures** - Use events for maintenance tasks
5. **Cache results** - Store in Redis for dashboard metrics

---

## 📞 SUPPORT

For issues:
1. Check procedure syntax: `SHOW CREATE PROCEDURE sp_name;`
2. Verify tables exist: `SHOW TABLES;`
3. Check logs: Look for trigger/constraint violations
4. Test with sample data first

---

**Last Updated**: April 7, 2026
**Version**: 1.0
**Database**: civic_issue_db
