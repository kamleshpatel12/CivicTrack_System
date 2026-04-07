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
exports.updateIssueStatus = exports.getIssueById = exports.getIssues = exports.createIssue = void 0;
const db_1 = require("../utils/db");
const cloudinary_1 = require("../config/cloudinary");
const createIssue = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { title, description, issueType, address, image } = req.body;
        const citizenId = req.citizenId;
        console.log("=".repeat(60));
        console.log("📋 NEW ISSUE REPORTED");
        console.log("=".repeat(60));
        console.log(`👤 Citizen ID: ${citizenId}`);
        console.log(`📌 Issue Type: ${issueType}`);
        console.log(`📍 Location: ${address}`);
        // Validate required fields
        if (!title || !description || !issueType || !address) {
            res.status(400).json({ message: "Please fill all required fields" });
            return;
        }
        // SQL: Lookup issue_type_id and department from civic_categories table
        const issueTypeRecord = yield (0, db_1.queryOne)(`SELECT it.id, it.type_name, it.department_id, d.department_name 
       FROM civic_categories it
       LEFT JOIN department d ON it.department_id = d.id
       WHERE it.type_name = ?`, [issueType]);
        if (!issueTypeRecord) {
            console.log(`❌ Issue type '${issueType}' not found in database`);
            res.status(400).json({ message: `Issue type '${issueType}' not found` });
            return;
        }
        const issueTypeId = issueTypeRecord.id;
        const departmentName = issueTypeRecord.department_name || "Unknown";
        const departmentId = issueTypeRecord.department_id;
        console.log(`🏢 Department: ${departmentName} (ID: ${departmentId})`);
        let imageUrl = null;
        // Upload image if provided
        if (image) {
            try {
                console.log("📸 Uploading image to Cloudinary...");
                const uploadResponse = yield cloudinary_1.cloudinary.uploader.upload(image, {
                    folder: "civic_issues",
                    resource_type: "auto",
                });
                imageUrl = uploadResponse.secure_url;
                console.log("✅ Image uploaded successfully");
            }
            catch (imageError) {
                console.error("⚠️  Image upload failed:", imageError);
                // Continue without image rather than failing the entire issue creation
            }
        }
        // SQL: Insert issue
        const issueId = yield (0, db_1.insert)(`INSERT INTO issues 
       (citizen_id, issue_type_id, title, description, address, status, image_url) 
       VALUES (?, ?, ?, ?, ?, ?, ?)`, [
            citizenId,
            issueTypeId,
            title,
            description,
            address,
            "Reported",
            imageUrl,
        ]);
        console.log(`✅ Issue Created Successfully`);
        console.log(`📌 Issue ID: ${issueId}`);
        console.log(`👨‍💼 Assigned to Department: ${departmentName} (ID: ${departmentId})`);
        console.log("=".repeat(60));
        res.status(200).json({
            message: "Issue created successfully",
            issue: {
                id: issueId,
                citizenId,
                issueType,
                title,
                description,
                address,
                status: "Reported",
                departmentId,
                departmentName,
                image: imageUrl,
            },
        });
    }
    catch (error) {
        console.error("❌ Error creating issue:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.createIssue = createIssue;
const getIssues = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const loggedInAdminId = req.adminId;
        console.log("\n" + "=".repeat(60));
        console.log("👨‍💼 ADMIN FETCHING ISSUES");
        console.log("=".repeat(60));
        console.log(`Admin ID: ${loggedInAdminId}`);
        // SQL: Get admin's department
        const admin = yield (0, db_1.queryOne)(`SELECT a.department_id, d.department_name 
       FROM admins a
       LEFT JOIN department d ON a.department_id = d.id
       WHERE a.id = ?`, [loggedInAdminId]);
        if (!admin) {
            res.status(404).json({ message: "Admin not found" });
            return;
        }
        const adminDepartmentId = admin.department_id;
        const departmentName = admin.department_name || "Unknown";
        console.log(`🏢 Department: ${departmentName} (ID: ${adminDepartmentId})`);
        // SQL: Get issues only for this admin's department
        const issues = (yield (0, db_1.queryAll)(`SELECT 
        i.id,
        i.citizen_id,
        i.issue_type_id,
        i.title,
        i.description,
        i.address,
        i.status,
        i.priority,
        i.created_at,
        i.updated_at,
        c.full_name,
        it.type_name,
        d.department_name
      FROM issues i
      LEFT JOIN citizens c ON i.citizen_id = c.id
      LEFT JOIN civic_categories it ON i.issue_type_id = it.id
      LEFT JOIN department d ON it.department_id = d.id
      WHERE d.id = ?
      ORDER BY i.created_at DESC`, [adminDepartmentId]));
        console.log(`📊 Found ${issues.length} issue(s) for this department`);
        if (issues.length > 0) {
            issues.forEach((issue, index) => {
                console.log(`   ${index + 1}. [${issue.type_name}] ${issue.title} - Status: ${issue.status}`);
            });
        }
        console.log("=".repeat(60) + "\n");
        res.json({
            issues,
            departmentId: adminDepartmentId,
        });
    }
    catch (error) {
        console.error("Error fetching issues:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.getIssues = getIssues;
// Get single issue by ID
const getIssueById = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        // SQL: Get issue by ID
        const issue = yield (0, db_1.queryOne)(`SELECT 
        i.id,
        i.citizen_id,
        i.issue_type,
        i.title,
        i.description,
        i.latitude,
        i.longitude,
        i.address,
        i.status,
        i.created_at,
        c.full_name
      FROM issues i
      LEFT JOIN citizens c ON i.citizen_id = c.id
      WHERE i.id = ?`, [id]);
        if (!issue) {
            res.status(404).json({ message: "Issue not found" });
            return;
        }
        res.json({
            issue,
        });
    }
    catch (error) {
        console.error("Error fetching issue:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.getIssueById = getIssueById;
// Update issue status
const updateIssueStatus = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const adminId = req.adminId;
        // Valid statuses
        const validStatuses = [
            "Reported",
            "In Progress",
            "Resolved",
            "Rejected",
            "Pending",
        ];
        if (!validStatuses.includes(status)) {
            res.status(400).json({ message: "Invalid status" });
            return;
        }
        // SQL: Get old status
        const issue = yield (0, db_1.queryOne)("SELECT status FROM issues WHERE id = ?", [
            id,
        ]);
        if (!issue) {
            res.status(404).json({ message: "Issue not found" });
            return;
        }
        // SQL: Update issue status
        yield (0, db_1.query)("UPDATE issues SET status = ? WHERE id = ?", [status, id]);
        // SQL: Insert into status history for audit trail
        yield (0, db_1.insert)(`INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_by) 
       VALUES (?, ?, ?, ?)`, [id, issue.status, status, adminId]);
        res.json({ message: "Issue status updated", newStatus: status });
    }
    catch (error) {
        console.error("Error updating issue status:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.updateIssueStatus = updateIssueStatus;
