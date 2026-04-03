"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const issues_controllers_1 = require("../controllers/issues.controllers");
const auth_middleware_1 = require("../middlerware/auth.middleware");
const router = (0, express_1.Router)();
router.post("/citizen/create-issue", auth_middleware_1.authMiddleware, issues_controllers_1.createIssue);
router.get("/all-issues", auth_middleware_1.authMiddleware, issues_controllers_1.getIssues);
exports.default = router;
