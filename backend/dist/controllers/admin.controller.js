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
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteIssueByAdmin = exports.getHandledIssuesByAdmin = exports.updateIssueStatus = exports.updateAdminProfile = exports.getAdminProfile = exports.getAdminDepartment = exports.getDepartments = void 0;
const db_1 = require("../utils/db");
const getDepartments = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // SQL: Get all departments
        const departments = (yield (0, db_1.queryAll)("SELECT id, department_name FROM departments ORDER BY department_name ASC"));
        res.json({
            departments: departments.map((dept) => ({
                id: dept.id,
                name: dept.department_name,
            })),
        });
    }
    catch (error) {
        console.error("Error fetching departments:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.getDepartments = getDepartments;
const getAdminDepartment = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const loggedInAdminId = req.adminId;
        // SQL: Get admin's department info
        const admin = yield (0, db_1.queryOne)(`SELECT 
        a.id,
        a.full_name,
        a.email,
        a.department_id,
        d.department_name,
        d.budget
      FROM admins a
      LEFT JOIN departments d ON a.department_id = d.id
      WHERE a.id = ?`, [loggedInAdminId]);
        if (!admin) {
            res.status(404).json({ message: "Admin not found" });
            return;
        }
        res.json({
            id: admin.id,
            fullName: admin.full_name,
            email: admin.email,
            departmentId: admin.department_id,
            departmentName: admin.department_name || "Unknown",
            budget: admin.budget,
        });
    }
    catch (error) {
        console.error("Error fetching admin department:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.getAdminDepartment = getAdminDepartment;
const getAdminProfile = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        const loggedInAdminId = req.adminId;
        if (id !== loggedInAdminId) {
            res.status(403).json({ message: "Unauthorised access" });
            return;
        }
        // SQL: Get admin by id (without password)
        const admin = yield (0, db_1.queryOne)("SELECT id, full_name, email, phone_number, department, admin_access_code FROM admins WHERE id = ?", [id]);
        if (!admin) {
            res.status(404).json({ message: "Admin not found" });
            return;
        }
        res.json(admin);
    }
    catch (error) {
        console.error("Error fetching admin profile:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.getAdminProfile = getAdminProfile;
const updateAdminProfile = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        const loggedInAdminId = req.adminId;
        const { fullName, email, phonenumber, department } = req.body;
        if (id !== loggedInAdminId) {
            res.status(403).json({ message: "Unauthorised access" });
            return;
        }
        // SQL: Check if email already exists for another admin
        const existingAdmin = yield (0, db_1.queryOne)("SELECT id FROM admins WHERE email = ? AND id != ?", [email, id]);
        if (existingAdmin) {
            res.status(400).json({ message: "Email already in use" });
            return;
        }
        // SQL: Update admin profile
        yield (0, db_1.query)("UPDATE admins SET full_name = ?, email = ?, phone_number = ?, department = ? WHERE id = ?", [fullName, email, phonenumber, department, id]);
        res.json({ message: "Profile updated successfully" });
    }
    catch (error) {
        console.error("Error updating admin profile:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.updateAdminProfile = updateAdminProfile;
const updateIssueStatus = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const loggedInAdminId = req.adminId;
        const validStatuses = [
            "Reported",
            "Pending",
            "In Progress",
            "Resolved",
            "Rejected",
            "Closed",
        ];
        if (!validStatuses.includes(status)) {
            res.status(400).json({ message: "Invalid status" });
            return;
        }
        // SQL: Get old status
        const issue = yield (0, db_1.queryOne)("SELECT status FROM issues WHERE id = ?", [id]);
        if (!issue) {
            res.status(404).json({ message: "Issue not found" });
            return;
        }
        // SQL: Update issue status and assigned admin
        yield (0, db_1.query)("UPDATE issues SET status = ?, assigned_admin = ? WHERE id = ?", [
            status,
            loggedInAdminId,
            id,
        ]);
        // SQL: Insert into status history
        yield (0, db_1.insert)("INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_by_admin) VALUES (?, ?, ?, ?)", [id, issue.status, status, loggedInAdminId]);
        res.json({ message: "Issue status updated successfully" });
    }
    catch (error) {
        console.error("Error updating issue status:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.updateIssueStatus = updateIssueStatus;
const getHandledIssuesByAdmin = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const loggedInAdminId = req.adminId;
        // SQL: Get all issues assigned to this admin
        const issues = (yield (0, db_1.queryAll)(`SELECT 
        i.id, i.title, i.description, i.issue_type_id, 
        i.address, i.status, 
        i.created_at, c.full_name
      FROM issues i
      LEFT JOIN citizens c ON i.citizen_id = c.id
      WHERE i.assigned_admin = ?
      ORDER BY i.updated_at DESC`, [loggedInAdminId]));
        res.json({ issues });
    }
    catch (error) {
        console.error("Error fetching handled issues:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.getHandledIssuesByAdmin = getHandledIssuesByAdmin;
const deleteIssueByAdmin = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { issueId } = req.params;
        const loggedInAdminId = req.adminId;
        // SQL: Check if issue exists and is handled by this admin
        const issue = yield (0, db_1.queryOne)("SELECT id, handled_by FROM issues WHERE id = ?", [issueId]);
        if (!issue) {
            res.status(404).json({ message: "Issue not found" });
            return;
        }
        if (issue.handled_by !== loggedInAdminId) {
            res
                .status(403)
                .json({ message: "You can only delete issues you have handled" });
            return;
        }
        // SQL: Delete issue status history
        yield (0, db_1.query)("DELETE FROM issue_status_history WHERE issue_id = ?", [
            issueId,
        ]);
        // SQL: Delete issue
        yield (0, db_1.query)("DELETE FROM issues WHERE id = ?", [issueId]);
        res.json({ message: "Issue deleted successfully" });
    }
    catch (error) {
        console.error("Error deleting issue:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.deleteIssueByAdmin = deleteIssueByAdmin;
