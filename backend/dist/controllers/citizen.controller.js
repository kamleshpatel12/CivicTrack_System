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
exports.deleteIssue = exports.getIssuesByCitizen = exports.updateCitizenProfile = exports.getCitizenProfile = void 0;
const db_1 = require("../utils/db");
const getCitizenProfile = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const loggedInCitizenId = req.citizenId;
        // SQL: Get citizen profile (without password)
        const citizen = yield (0, db_1.queryOne)("SELECT id, full_name, email, phone_number FROM citizens WHERE id = ?", [loggedInCitizenId]);
        if (!citizen) {
            res.status(404).json({ message: "Citizen not found" });
            return;
        }
        res.json(citizen);
    }
    catch (error) {
        console.error("Error fetching citizen profile:", error);
        res.status(500).json({ message: "Internal Server Error" });
    }
});
exports.getCitizenProfile = getCitizenProfile;
const updateCitizenProfile = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        const loggedInCitizenId = req.citizenId;
        if (id !== loggedInCitizenId) {
            res.status(403).json({ message: "Unauthorised Citizen access" });
            return;
        }
        const { fullName, email, phonenumber } = req.body;
        if (!fullName || !email || !phonenumber) {
            res.status(400).json({ message: "All fields are required" });
            return;
        }
        // SQL: Update citizen profile
        yield (0, db_1.query)("UPDATE citizens SET full_name = ?, email = ?, phone_number = ? WHERE id = ?", [fullName, email, phonenumber, id]);
        res.json({
            message: "Profile updated successfully",
        });
    }
    catch (error) {
        console.error("Error updating citizen profile:", error);
        res.status(500).json({ message: "Internal Server Error" });
    }
});
exports.updateCitizenProfile = updateCitizenProfile;
const getIssuesByCitizen = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const authReq = req;
    try {
        const citizenId = authReq.citizenId;
        if (!citizenId) {
            res.status(401).json({ message: "Unauthorized" });
            return;
        }
        // SQL: Get all issues reported by this citizen with issue type details
        const issues = (yield (0, db_1.queryAll)(`SELECT 
        i.id, i.title, i.description, i.issue_type_id, 
        it.type_name, i.address, i.status, i.created_at
      FROM issues i
      LEFT JOIN issue_types it ON i.issue_type_id = it.id
      WHERE i.citizen_id = ?
      ORDER BY i.created_at DESC`, [citizenId]));
        res.json({ issues });
    }
    catch (error) {
        console.error("Error fetching issues:", error);
        res.status(500).json({ message: "Internal Server Error" });
    }
});
exports.getIssuesByCitizen = getIssuesByCitizen;
const deleteIssue = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { issueId } = req.body;
        const citizenId = req.citizenId;
        // SQL: Check if issue exists and is owned by this citizen
        const issue = yield (0, db_1.queryOne)("SELECT id, citizen_id FROM issues WHERE id = ? AND citizen_id = ?", [issueId, citizenId]);
        if (!issue) {
            res.status(404).json({ message: "Issue not found or unauthorized" });
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
        res.status(500).json({ message: "Internal Server Error" });
    }
});
exports.deleteIssue = deleteIssue;
