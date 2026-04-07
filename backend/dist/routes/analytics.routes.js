"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const analytics_controller_1 = require("../controllers/analytics.controller");
const router = express_1.default.Router();
// Analytics Endpoints
// Department Performance Report
router.get("/analytics/department-performance", analytics_controller_1.getDepartmentPerformance);
// Monthly Statistics
router.get("/analytics/monthly-stats", analytics_controller_1.getMonthlyStatistics);
// High Priority Issues by Department
router.get("/analytics/high-priority/:deptId", analytics_controller_1.getHighPriorityIssues);
// Issues by Location
router.get("/analytics/location/:city", analytics_controller_1.getIssuesByLocation);
// Problem Areas (Hotspots)
router.get("/analytics/problem-areas", analytics_controller_1.identifyProblemAreas);
// Admin Workload Distribution
router.get("/analytics/admin-workload", analytics_controller_1.getAdminWorkload);
// Citizen Activity Report
router.get("/analytics/citizen/:email", analytics_controller_1.getCitizenActivityReport);
// Auto Prioritize Issues (POST - modifies data)
router.post("/analytics/auto-prioritize", analytics_controller_1.autoPrioritizeIssues);
// Bulk Update Status (POST - modifies data)
router.post("/analytics/bulk-update", analytics_controller_1.bulkUpdateStatus);
// Archive Resolved Issues (POST - modifies data)
router.post("/analytics/archive", analytics_controller_1.archiveResolvedIssues);
// View: Unresolved High Priority
router.get("/analytics/view/high-priority", analytics_controller_1.getUnresolvedHighPriorityView);
// View: Department Dashboard
router.get("/analytics/view/dashboard", analytics_controller_1.getDepartmentDashboard);
// View: Citizen Issues Summary
router.get("/analytics/view/citizen-summary", analytics_controller_1.getCitizenIssuesSummary);
exports.default = router;
