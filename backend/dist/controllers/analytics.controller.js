"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCitizenIssuesSummary = exports.getDepartmentDashboard = exports.getUnresolvedHighPriorityView = exports.archiveResolvedIssues = exports.bulkUpdateStatus = exports.autoPrioritizeIssues = exports.getCitizenActivityReport = exports.getAdminWorkload = exports.identifyProblemAreas = exports.getIssuesByLocation = exports.getHighPriorityIssues = exports.getMonthlyStatistics = exports.getDepartmentPerformance = void 0;
const database_1 = __importDefault(require("../config/database"));
// ================================
// ANALYTICS CONTROLLERS
// ================================
/**
 * Get Department Performance Report
 * Shows metrics: total issues, resolved, resolution rate, avg resolution days
 */
const getDepartmentPerformance = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const results = yield database_1.default.query('CALL sp_department_performance_report()');
        const data = results[0];
        res.status(200).json({
            success: true,
            message: 'Department performance report generated',
            data: data,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error getting department performance:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to generate performance report',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.getDepartmentPerformance = getDepartmentPerformance;
/**
 * Get Monthly Issue Statistics
 * Shows: reported, resolved, in progress, rejected, most common type
 */
const getMonthlyStatistics = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { year, month } = req.query;
        if (!year || !month) {
            res.status(400).json({
                success: false,
                message: 'Year and month parameters required',
            });
            return;
        }
        const results = yield database_1.default.query('CALL sp_monthly_issue_statistics(?, ?)', [parseInt(year), parseInt(month)]);
        res.status(200).json({
            success: true,
            message: `Statistics for ${year}-${String(month).padStart(2, '0')}`,
            data: results[0],
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error getting monthly statistics:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get monthly statistics',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.getMonthlyStatistics = getMonthlyStatistics;
/**
 * Get High Priority Issues for Department
 * Shows unresolved high-priority issues
 */
const getHighPriorityIssues = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { deptId } = req.params;
        if (!deptId) {
            res.status(400).json({
                success: false,
                message: 'Department ID required',
            });
            return;
        }
        const results = yield database_1.default.query('CALL sp_get_high_priority_issues(?)', [parseInt(deptId)]);
        const data = Array.isArray(results[0]) ? results[0] : [];
        res.status(200).json({
            success: true,
            message: `High priority issues for Department ${deptId}`,
            count: data.length,
            data: data,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error getting high priority issues:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get high priority issues',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.getHighPriorityIssues = getHighPriorityIssues;
/**
 * Get Issues by Location
 * Shows all issues in a specific city with analytics
 */
const getIssuesByLocation = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { city } = req.params;
        if (!city) {
            res.status(400).json({
                success: false,
                message: 'City name required',
            });
            return;
        }
        const results = yield database_1.default.query('CALL sp_get_issues_by_location(?)', [city]);
        const data = Array.isArray(results[0]) ? results[0] : [];
        res.status(200).json({
            success: true,
            message: `Issues in ${city}`,
            count: data.length,
            data: data,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error getting issues by location:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get issues by location',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.getIssuesByLocation = getIssuesByLocation;
/**
 * Identify Problem Areas
 * Finds locations with recurring issues (3+ issues)
 */
const identifyProblemAreas = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const results = yield database_1.default.query('CALL sp_identify_problem_areas()');
        const data = Array.isArray(results[0]) ? results[0] : [];
        res.status(200).json({
            success: true,
            message: 'Problem areas identified',
            count: data.length,
            data: data,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error identifying problem areas:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to identify problem areas',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.identifyProblemAreas = identifyProblemAreas;
/**
 * Get Admin Workload Distribution
 * Shows issues assigned to each admin with metrics
 */
const getAdminWorkload = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const results = yield database_1.default.query('CALL sp_admin_workload_distribution()');
        res.status(200).json({
            success: true,
            message: 'Admin workload distribution',
            data: results[0],
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error getting admin workload:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get admin workload',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.getAdminWorkload = getAdminWorkload;
/**
 * Get Citizen Activity Report
 * Shows comprehensive citizen profile with statistics
 */
const getCitizenActivityReport = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { email } = req.params;
        if (!email) {
            res.status(400).json({
                success: false,
                message: 'Citizen email required',
            });
            return;
        }
        const results = yield database_1.default.query('CALL sp_citizen_activity_report(?)', [email]);
        const data = Array.isArray(results[0]) ? results[0] : [];
        if (data.length === 0) {
            res.status(404).json({
                success: false,
                message: 'Citizen not found',
            });
            return;
        }
        res.status(200).json({
            success: true,
            message: `Activity report for ${email}`,
            data: data[0],
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error getting citizen activity:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get citizen activity report',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.getCitizenActivityReport = getCitizenActivityReport;
// ================================
// MAINTENANCE & AUTOMATION
// ================================
/**
 * Auto-Assign Priorities
 * Automatically assigns priority to unassigned issues based on age
 */
const autoPrioritizeIssues = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const results = yield database_1.default.query('CALL sp_auto_assign_priority()');
        res.status(200).json({
            success: true,
            message: 'Issues auto-prioritized based on age',
            data: results[0],
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error auto-prioritizing issues:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to auto-prioritize issues',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.autoPrioritizeIssues = autoPrioritizeIssues;
/**
 * Bulk Update Issue Status
 * Updates status for multiple issues and logs changes
 */
const bulkUpdateStatus = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { status, count } = req.body;
        if (!status || !count) {
            res.status(400).json({
                success: false,
                message: 'Status and count required',
            });
            return;
        }
        const results = yield database_1.default.query('CALL sp_bulk_update_status(?, ?)', [status, parseInt(count)]);
        res.status(200).json({
            success: true,
            message: `Bulk status update completed`,
            data: results[0],
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error bulk updating status:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to bulk update status',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.bulkUpdateStatus = bulkUpdateStatus;
/**
 * Archive Resolved Issues
 * Archives issues resolved over 90 days ago
 */
const archiveResolvedIssues = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const results = yield database_1.default.query('CALL sp_archive_resolved_issues()');
        res.status(200).json({
            success: true,
            message: 'Resolved issues archived',
            data: results[0],
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error archiving resolved issues:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to archive issues',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.archiveResolvedIssues = archiveResolvedIssues;
// ================================
// VIEW QUERIES
// ================================
/**
 * Get Unresolved High Priority Issues
 * Uses view with subqueries
 */
const getUnresolvedHighPriorityView = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const results = yield database_1.default.query('SELECT * FROM vw_unresolved_high_priority');
        const data = Array.isArray(results) ? results : [];
        res.status(200).json({
            success: true,
            message: 'Unresolved high priority issues',
            count: data.length,
            data: data,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error getting unresolved high priority view:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get high priority view',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.getUnresolvedHighPriorityView = getUnresolvedHighPriorityView;
/**
 * Get Department Dashboard
 * Uses view with aggregation and subqueries
 */
const getDepartmentDashboard = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const results = yield database_1.default.query('SELECT * FROM vw_department_dashboard');
        res.status(200).json({
            success: true,
            message: 'Department dashboard',
            data: results,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error getting department dashboard:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get department dashboard',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.getDepartmentDashboard = getDepartmentDashboard;
/**
 * Get Citizen Issues Summary
 * Uses view for quick citizen overview
 */
const getCitizenIssuesSummary = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const results = yield database_1.default.query('SELECT * FROM vw_citizen_issues_summary');
        const data = Array.isArray(results) ? results : [];
        res.status(200).json({
            success: true,
            message: 'Citizen issues summary',
            count: data.length,
            data: data,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        console.error('Error getting citizen issues summary:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get citizen issues summary',
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
exports.getCitizenIssuesSummary = getCitizenIssuesSummary;
