import { Request, Response } from "express";
import { query, queryOne, queryAll, insert } from "../utils/db";

export const createIssue = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { title, description, issueType, address } = req.body;
    const citizenId = (req as any).citizenId;

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
    const issueTypeRecord = await queryOne(
      `SELECT it.id, it.type_name, it.department_id, d.department_name 
       FROM civic_categories it
       LEFT JOIN department d ON it.department_id = d.id
       WHERE it.type_name = ?`,
      [issueType]
    );

    if (!issueTypeRecord) {
      console.log(`❌ Issue type '${issueType}' not found in database`);
      res.status(400).json({ message: `Issue type '${issueType}' not found` });
      return;
    }

    const issueTypeId = (issueTypeRecord as any).id;
    const departmentName = (issueTypeRecord as any).department_name || "Unknown";
    const departmentId = (issueTypeRecord as any).department_id;

    console.log(`🏢 Department: ${departmentName} (ID: ${departmentId})`);

    // SQL: Check if issue with same title exists
    const existingIssue = await queryOne(
      "SELECT id FROM issues WHERE title = ?",
      [title]
    );

    if (existingIssue) {
      console.log(`⚠️  Issue with title '${title}' already exists`);
      res
        .status(400)
        .json({ message: "Issue with this title already exists" });
      return;
    }

    // SQL: Insert issue
    const issueId = await insert(
      `INSERT INTO issues 
       (citizen_id, issue_type_id, title, description, address, status) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        citizenId,
        issueTypeId,
        title,
        description,
        address,
        "Reported",
      ]
    );

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
      },
    });
  } catch (error) {
    console.error("❌ Error creating issue:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getIssues = async (req: Request, res: Response) => {
  try {
    const loggedInAdminId = (req as any).adminId;

    console.log("\n" + "=".repeat(60));
    console.log("👨‍💼 ADMIN FETCHING ISSUES");
    console.log("=".repeat(60));
    console.log(`Admin ID: ${loggedInAdminId}`);

    // SQL: Get admin's department
    const admin = await queryOne(
      `SELECT a.department_id, d.department_name 
       FROM admins a
       LEFT JOIN department d ON a.department_id = d.id
       WHERE a.id = ?`,
      [loggedInAdminId]
    );

    if (!admin) {
      res.status(404).json({ message: "Admin not found" });
      return;
    }

    const adminDepartmentId = (admin as any).department_id;
    const departmentName = (admin as any).department_name || "Unknown";

    console.log(`🏢 Department: ${departmentName} (ID: ${adminDepartmentId})`);

    // SQL: Get issues only for this admin's department
    const issues = (await queryAll(
      `SELECT 
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
      ORDER BY i.created_at DESC`,
      [adminDepartmentId]
    )) as any[];

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
  } catch (error) {
    console.error("Error fetching issues:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

// Get single issue by ID
export const getIssueById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // SQL: Get issue by ID
    const issue = await queryOne(
      `SELECT 
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
      WHERE i.id = ?`,
      [id]
    );

    if (!issue) {
      res.status(404).json({ message: "Issue not found" });
      return;
    }

    res.json({
      issue,
    });
  } catch (error) {
    console.error("Error fetching issue:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

// Update issue status
export const updateIssueStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const adminId = (req as any).adminId;

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
    const issue = await queryOne("SELECT status FROM issues WHERE id = ?", [
      id,
    ]);
    if (!issue) {
      res.status(404).json({ message: "Issue not found" });
      return;
    }

    // SQL: Update issue status
    await query("UPDATE issues SET status = ? WHERE id = ?", [status, id]);

    // SQL: Insert into status history for audit trail
    await insert(
      `INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_by) 
       VALUES (?, ?, ?, ?)`,
      [id, issue.status, status, adminId]
    );

    res.json({ message: "Issue status updated", newStatus: status });
  } catch (error) {
    console.error("Error updating issue status:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};
