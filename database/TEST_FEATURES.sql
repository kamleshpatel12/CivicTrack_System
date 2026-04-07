-- =====================================================
-- CIVIC ISSUE DATABASE - FEATURE TEST SCRIPT
-- =====================================================
-- Run this script to verify all advanced features work
-- Copy each section and paste into MySQL client
-- =====================================================

-- 1. VERIFY PROCEDURES EXIST
-- ======================
SHOW PROCEDURE STATUS WHERE db = 'civic_issue_db';

-- 2. VERIFY VIEWS EXIST
-- ===================
SHOW TABLES IN civic_issue_db LIKE 'vw_%';

-- 3. TEST PROCEDURE 1: Department Performance
-- ====================================
CALL sp_department_performance_report();

-- Expected Output:
-- Columns: id, department_name, total_issues, resolved_issues, resolution_rate_percent
-- Shows all departments with their metrics


-- 4. TEST NESTED QUERY 1: Department Performance (Standalone)
-- ==================================================
SELECT 
    d.id,
    d.department_name,
    (SELECT COUNT(*) FROM issues i 
     JOIN admins a ON i.assigned_to = a.email 
     WHERE a.department_id = d.id) AS total_issues,
    (SELECT COUNT(*) FROM issues i 
     JOIN admins a ON i.assigned_to = a.email 
     WHERE a.department_id = d.id AND i.status = 'Resolved') AS resolved_issues
FROM department d
ORDER BY total_issues DESC;

-- Expected Output:
-- Water Management: 45 total, 38 resolved
-- Sanitation: 32 total, 28 resolved
-- etc.


-- 5. TEST VIEW 1: Unresolved High Priority Issues
-- ============================================
SELECT * FROM vw_unresolved_high_priority;

-- Expected Output:
-- Shows unresolved medium/high priority issues with citizen count


-- 6. TEST PROCEDURE 2: Get High Priority Issues (with parameter)
-- =============================================
-- First, get a valid department ID
SELECT id FROM department LIMIT 1;

-- Replace 1 with actual dept_id if different
CALL sp_get_high_priority_issues(1);

-- Expected Output:
-- Urgent unresolved issues from that department


-- 7. TEST CURSOR: Bulk Update Status
-- ==============================
-- Check how many issues exist first
SELECT COUNT(*) FROM issues;

-- Then run the procedure (updates up to 5 issues)
CALL sp_bulk_update_status('Pending', 5);

-- Verify changes in issue_history table
SELECT * FROM issue_history ORDER BY created_at DESC LIMIT 5;

-- Expected: 5 rows showing status changes


-- 8. TEST NESTED QUERY 2: Citizen Activity
-- ==================================
SELECT 
    c.full_name,
    c.email,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) AS total_reports,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id AND status = 'Resolved') AS resolved,
    (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id AND status = 'In Progress') AS in_progress
FROM citizens c
WHERE (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) > 0
ORDER BY total_reports DESC
LIMIT 5;

-- Expected Output:
-- Citizens with most reports and their status breakdown


-- 9. TEST VIEW 2: Department Dashboard
-- ================================
SELECT * FROM vw_department_dashboard;

-- Expected Output:
-- Department stats: name, total, resolved, in_progress, pending, rejected, resolution_rate


-- 10. TEST PROCEDURE: Auto-prioritize Issues
-- ==============================
CALL sp_auto_assign_priority();

-- Check results
SELECT id, priority, created_at, DATEDIFF(CURDATE(), created_at) as days_old
FROM issues
WHERE status != 'Resolved'
ORDER BY DATEDIFF(CURDATE(), created_at) DESC
LIMIT 10;

-- Expected: Issues 30+ days old should be High priority
--           Issues 15-30 days old should be Medium priority
--           Issues <15 days old should be Low priority


-- 11. TEST NESTED QUERY 3: Problem Areas
-- ============================
SELECT 
    address,
    COUNT(*) as total_issues,
    (SELECT COUNT(*) FROM issues WHERE address = i.address AND status = 'Resolved') as resolved,
    (SELECT COUNT(*) FROM issues WHERE address = i.address AND status = 'In Progress') as in_progress
FROM issues i
GROUP BY address
HAVING COUNT(*) > 2
ORDER BY total_issues DESC;

-- Expected Output:
-- Addresses with 3+ issues (problem areas)


-- 12. TEST PROCEDURE: Admin Workload
-- ==========================
CALL sp_admin_workload_distribution();

-- Expected Output:
-- Admin names with: total assigned, resolved, in_progress, pending, resolution_rate


-- 13. TEST NESTED QUERY 4: Admin Rankings
-- =========================
SELECT 
    a.full_name,
    a.email,
    (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email) AS assigned,
    (SELECT COUNT(*) FROM issues WHERE assigned_to = a.email AND status = 'Resolved') AS resolved,
    ROUND((SELECT COUNT(*) FROM issues WHERE assigned_to = a.email AND status = 'Resolved') * 100.0 / 
          NULLIF((SELECT COUNT(*) FROM issues WHERE assigned_to = a.email), 0), 2) AS resolution_rate
FROM admins a
WHERE a.is_active = TRUE
ORDER BY resolution_rate DESC;

-- Expected Output:
-- Admins ranked by resolution rate %


-- 14. TEST PROCEDURE: Get Issues by Location
-- =====================================
-- Get a valid city first
SELECT DISTINCT city FROM location LIMIT 1;

-- Replace 'Manipal' with actual city if different
CALL sp_get_issues_by_location('Manipal');

-- Expected Output:
-- Issues in that city with monthly stats


-- 15. TEST NESTED QUERY 5: Overdue Issues Analysis
-- =========================================
SELECT 
    status,
    COUNT(*) as count,
    AVG(DATEDIFF(CURDATE(), created_at)) as avg_days_open,
    MIN(DATEDIFF(CURDATE(), created_at)) as min_days,
    MAX(DATEDIFF(CURDATE(), created_at)) as max_days
FROM issues
WHERE status IN ('Reported', 'Pending', 'In Progress')
GROUP BY status;

-- Expected Output:
-- Average days each status has been open


-- 16. TEST VIEW 3: Citizen Issues Summary
-- ==================================
SELECT * FROM vw_citizen_issues_summary;

-- Expected Output:
-- Citizen summaries: name, total reports, resolved, ongoing, last report date


-- 17. TEST PROCEDURE: Problem Areas
-- ==========================
CALL sp_identify_problem_areas();

-- Expected Output:
-- Cities with 3+ issues (problem areas identification)


-- 18. TEST PROCEDURE: Archive Resolved Issues
-- ====================================
-- Note: This archives issues resolved 90+ days ago
-- Check how many would be archived first
SELECT COUNT(*) as would_be_archived
FROM issues
WHERE status = 'Resolved' AND DATEDIFF(CURDATE(), updated_at) > 90;

-- Then run (only run if you want to archive)
-- CALL sp_archive_resolved_issues();


-- 19. TEST PROCEDURE: Monthly Statistics
-- ==========================
-- Get stats for current month
CALL sp_monthly_issue_statistics(YEAR(CURDATE()), MONTH(CURDATE()));

-- Expected Output:
-- reported, resolved, in_progress, rejected, rejected_reason counts


-- =====================================================
-- SUMMARY OF TESTS
-- =====================================================
-- If all above tests return data without errors:
--
-- ✅ 10 Stored Procedures - WORKING
-- ✅ 3 Views - WORKING  
-- ✅ 2 Cursors - WORKING (can see in issue_history)
-- ✅ 5 Nested Queries - WORKING
--
-- Your database is ready for API integration!
-- =====================================================
