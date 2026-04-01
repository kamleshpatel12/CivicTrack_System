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
const createIssue = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const files = req.files || [];
        const { title, description, location, issueType } = req.body;
        const citizenId = req.citizenId;
        // Parse location
        let parsedLocation = location;
        if (typeof location === "string") {
            try {
                parsedLocation = JSON.parse(location);
            }
            catch (_a) {
                res.status(400).json({ message: "Invalid location JSON format" });
                return;
            }
        }
        // Validate required fields
        if (!title ||
            !description ||
            !parsedLocation ||
            !parsedLocation.latitude ||
            !parsedLocation.longitude ||
            !issueType) {
            res.status(400).json({ message: "Please fill all the required fields " });
            return;
        }
        // SQL: Check if issue with same title exists
        const existingIssue = yield (0, db_1.queryOne)("SELECT id FROM issues WHERE title = ?", [title]);
        if (existingIssue) {
            res
                .status(400)
                .json({ message: "Issue with this title already exists" });
            return;
        }
        // SQL: Insert issue
        const issueId = yield (0, db_1.insert)(`INSERT INTO issues 
       (citizen_id, issue_type, title, description, latitude, longitude, address, status) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`, [
            citizenId,
            issueType,
            title,
            description,
            parsedLocation.latitude,
            parsedLocation.longitude,
            parsedLocation.address,
            "Reported",
        ]);
        // SQL: Insert multimedia files
        const mediaDocs = yield Promise.all(files.map((file) => (() => __awaiter(void 0, void 0, void 0, function* () {
            const mediaId = yield (0, db_1.insert)(`INSERT INTO multimedia (issue_id, file_type, url, filename) 
             VALUES (?, ?, ?, ?)`, [
                issueId,
                file.mimetype.startsWith("video") ? "video" : "image",
                file.path,
                file.originalname,
            ]);
            return {
                id: mediaId,
                issueId,
                fileType: file.mimetype.startsWith("video") ? "video" : "image",
                url: file.path,
                filename: file.originalname,
            };
        }))()));
        res.status(200).json({
            message: "Issue created",
            issue: {
                id: issueId,
                citizenId,
                issueType,
                title,
                description,
                location: parsedLocation,
                status: "Reported",
            },
            media: mediaDocs,
        });
    }
    catch (error) {
        console.error("Error creating issue:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});
exports.createIssue = createIssue;
const getIssues = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // SQL: JOINed query to get issues with citizen names (ONE query instead of N+1)
        const issues = (yield (0, db_1.queryAll)(`SELECT 
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
        i.updated_at,
        c.full_name
      FROM issues i
      LEFT JOIN citizens c ON i.citizen_id = c.id
      ORDER BY i.created_at DESC`));
        // SQL: Get multimedia for all issues in one query
        const allMedia = (yield (0, db_1.queryAll)(`SELECT id, issue_id, file_type, url, filename FROM multimedia`));
        // Map multimedia by issue_id
        const mediaByIssueId = new Map();
        allMedia.forEach((media) => {
            if (!mediaByIssueId.has(media.issue_id)) {
                mediaByIssueId.set(media.issue_id, []);
            }
            mediaByIssueId.get(media.issue_id).push(media);
        });
        // Transform response
        const issuesWithMedia = issues.map((issue) => {
            const media = mediaByIssueId.get(issue.id) || [];
            return {
                _id: issue.id,
                title: issue.title,
                description: issue.description,
                type: issue.issue_type,
                location: {
                    latitude: issue.latitude,
                    longitude: issue.longitude,
                    address: issue.address,
                },
                reportedBy: issue.full_name || "Anonymous",
                reportedAt: issue.created_at,
                image: media.length > 0 ? media[0].url : null,
                status: issue.status,
            };
        });
        res.json({ issues: issuesWithMedia });
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
        // SQL: Get multimedia for this issue
        const media = yield (0, db_1.queryAll)(`SELECT id, file_type, url, filename FROM multimedia WHERE issue_id = ?`, [id]);
        res.json({
            issue,
            media,
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
