import { Router } from "express";
import {
  adminSignin,
  adminSignup,
} from "../controllers/auth-controllers/admin.auth.controller";
import { authMiddleware } from "../middlerware/auth.middleware";
import {
  deleteIssueByAdmin,
  getAdminProfile,
  getAdminDepartment,
  getDepartments,
  getHandledIssuesByAdmin,
  updateAdminProfile,
  updateIssueStatus,
  getHeadAdminIssues,
  assignIssuePriority,
  getIssuePriorityHistory,
} from "../controllers/admin.controller";
import { getIssues } from "../controllers/issues.controllers";

const router = Router();

router.post("/admin/signup", adminSignup);

router.post("/admin/signin", adminSignin);

router.get("/admin/departments", getDepartments);

router.get("/admin/department", authMiddleware, getAdminDepartment);

router.get("/admin/profile/:id", authMiddleware, getAdminProfile);

router.get("/admin/issues", authMiddleware, getIssues);

router.get("/admin/handled-issues", authMiddleware, getHandledIssuesByAdmin);

router.put("/admin/:id", authMiddleware, updateAdminProfile);

router.put("/admin/issue/:id/status", authMiddleware, updateIssueStatus);

router.delete("/issue/admin/:issueid", authMiddleware, deleteIssueByAdmin);

// Head Admin Routes
router.get("/admin/head-admin-issues", authMiddleware, getHeadAdminIssues);

router.get("/admin/head/all-issues", authMiddleware, getHeadAdminIssues);

router.post("/admin/head/assign-priority", authMiddleware, assignIssuePriority);

router.get(
  "/admin/head/priority-history/:issueId",
  authMiddleware,
  getIssuePriorityHistory
);

export default router;
