import express from "express";
import {
  getDepartmentPerformance,
  getMonthlyStatistics,
  getHighPriorityIssues,
  getIssuesByLocation,
  identifyProblemAreas,
  getAdminWorkload,
  getCitizenActivityReport,
  autoPrioritizeIssues,
  bulkUpdateStatus,
  archiveResolvedIssues,
  getUnresolvedHighPriorityView,
  getDepartmentDashboard,
  getCitizenIssuesSummary,
} from "../controllers/analytics.controller";

const router = express.Router();

// Analytics Endpoints

// Department Performance Report
router.get("/analytics/department-performance", getDepartmentPerformance);

// Monthly Statistics
router.get("/analytics/monthly-stats", getMonthlyStatistics);

// High Priority Issues by Department
router.get("/analytics/high-priority/:deptId", getHighPriorityIssues);

// Issues by Location
router.get("/analytics/location/:city", getIssuesByLocation);

// Problem Areas (Hotspots)
router.get("/analytics/problem-areas", identifyProblemAreas);

// Admin Workload Distribution
router.get("/analytics/admin-workload", getAdminWorkload);

// Citizen Activity Report
router.get("/analytics/citizen/:email", getCitizenActivityReport);

// Auto Prioritize Issues (POST - modifies data)
router.post("/analytics/auto-prioritize", autoPrioritizeIssues);

// Bulk Update Status (POST - modifies data)
router.post("/analytics/bulk-update", bulkUpdateStatus);

// Archive Resolved Issues (POST - modifies data)
router.post("/analytics/archive", archiveResolvedIssues);

// View: Unresolved High Priority
router.get("/analytics/view/high-priority", getUnresolvedHighPriorityView);

// View: Department Dashboard
router.get("/analytics/view/dashboard", getDepartmentDashboard);

// View: Citizen Issues Summary
router.get("/analytics/view/citizen-summary", getCitizenIssuesSummary);

export default router;
