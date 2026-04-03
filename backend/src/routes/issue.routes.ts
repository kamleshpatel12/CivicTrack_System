import { Router } from "express";
import { createIssue, getIssues } from "../controllers/issues.controllers";
import { authMiddleware } from "../middlerware/auth.middleware";

const router = Router();

router.post("/citizen/create-issue", authMiddleware, createIssue);
router.get("/all-issues", authMiddleware, getIssues);

export default router;
