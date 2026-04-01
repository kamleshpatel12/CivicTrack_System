import { Request, Response } from "express";
import { queryOne, query, queryAll, insert } from "../utils/db";

interface AuthRequest extends Request {
  adminId?: string;
}

export const getAdminProfile = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const loggedInAdminId = req.adminId;

    if (id !== loggedInAdminId) {
      res.status(403).json({ message: "Unauthorised access" });
      return;
    }

    // SQL: Get admin by id (without password)
    const admin = await queryOne(
      "SELECT id, full_name, email, phone_number, department, admin_access_code FROM admins WHERE id = ?",
      [id]
    );

    if (!admin) {
      res.status(404).json({ message: "Admin not found" });
      return;
    }

    res.json(admin);
  } catch (error) {
    console.error("Error fetching admin profile:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const updateAdminProfile = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const loggedInAdminId = req.adminId;
    const { fullName, email, phonenumber, department } = req.body;

    if (id !== loggedInAdminId) {
      res.status(403).json({ message: "Unauthorised access" });
      return;
    }

    // SQL: Check if email already exists for another admin
    const existingAdmin = await queryOne(
      "SELECT id FROM admins WHERE email = ? AND id != ?",
      [email, id]
    );

    if (existingAdmin) {
      res.status(400).json({ message: "Email already in use" });
      return;
    }

    // SQL: Update admin profile
    await query(
      "UPDATE admins SET full_name = ?, email = ?, phone_number = ?, department = ? WHERE id = ?",
      [fullName, email, phonenumber, department, id]
    );

    res.json({ message: "Profile updated successfully" });
  } catch (error) {
    console.error("Error updating admin profile:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const updateIssueStatus = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { issueId } = req.params;
    const { status } = req.body;
    const loggedInAdminId = req.adminId;

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
    const issue = await queryOne(
      "SELECT status, id FROM issues WHERE id = ?",
      [issueId]
    );

    if (!issue) {
      res.status(404).json({ message: "Issue not found" });
      return;
    }

    // SQL: Update issue status
    await query("UPDATE issues SET status = ?, handled_by = ? WHERE id = ?", [
      status,
      loggedInAdminId,
      issueId,
    ]);

    // SQL: Insert into status history
    await insert(
      "INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_by) VALUES (?, ?, ?, ?)",
      [issueId, issue.status, status, loggedInAdminId]
    );

    res.json({ message: "Issue status updated successfully" });
  } catch (error) {
    console.error("Error updating issue status:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getHandledIssuesByAdmin = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const loggedInAdminId = req.adminId;

    // SQL: Get all issues handled by this admin
    const issues = (await queryAll(
      `SELECT 
        i.id, i.title, i.description, i.issue_type, 
        i.latitude, i.longitude, i.address, i.status, 
        i.created_at, c.full_name
      FROM issues i
      LEFT JOIN citizens c ON i.citizen_id = c.id
      WHERE i.handled_by = ?
      ORDER BY i.updated_at DESC`,
      [loggedInAdminId]
    )) as any[];

    res.json({ issues });
  } catch (error) {
    console.error("Error fetching handled issues:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const deleteIssueByAdmin = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { issueId } = req.params;
    const loggedInAdminId = req.adminId;

    // SQL: Check if issue exists and is handled by this admin
    const issue = await queryOne(
      "SELECT id, handled_by FROM issues WHERE id = ?",
      [issueId]
    );

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

    // SQL: Delete multimedia first (foreign key constraint)
    await query("DELETE FROM multimedia WHERE issue_id = ?", [issueId]);

    // SQL: Delete issue status history
    await query("DELETE FROM issue_status_history WHERE issue_id = ?", [
      issueId,
    ]);

    // SQL: Delete issue
    await query("DELETE FROM issues WHERE id = ?", [issueId]);

    res.json({ message: "Issue deleted successfully" });
  } catch (error) {
    console.error("Error deleting issue:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

