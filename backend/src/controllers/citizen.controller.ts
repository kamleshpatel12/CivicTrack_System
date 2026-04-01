import { Request, Response } from "express";
import { queryOne, query, queryAll } from "../utils/db";

interface AuthRequest extends Request {
  citizenId?: string;
}

export const getCitizenProfile = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const loggedInCitizenId = req.citizenId;

    // SQL: Get citizen profile (without password)
    const citizen = await queryOne(
      "SELECT id, full_name, email, phone_number FROM citizens WHERE id = ?",
      [loggedInCitizenId]
    );

    if (!citizen) {
      res.status(404).json({ message: "Citizen not found" });
      return;
    }

    res.json(citizen);
  } catch (error) {
    console.error("Error fetching citizen profile:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

export const updateCitizenProfile = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
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
    await query(
      "UPDATE citizens SET full_name = ?, email = ?, phone_number = ? WHERE id = ?",
      [fullName, email, phonenumber, id]
    );

    res.json({
      message: "Profile updated successfully",
    });
  } catch (error) {
    console.error("Error updating citizen profile:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

export const getIssuesByCitizen = async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;

  try {
    const citizenId = authReq.citizenId;
    if (!citizenId) {
      res.status(401).json({ message: "Unauthorized" });
      return;
    }

    // SQL: Get all issues reported by this citizen
    const issues = (await queryAll(
      `SELECT 
        i.id, i.title, i.description, i.issue_type, 
        i.latitude, i.longitude, i.address, i.status, i.created_at
      FROM issues i
      WHERE i.citizen_id = ?
      ORDER BY i.created_at DESC`,
      [citizenId]
    )) as any[];

    res.json({ issues });
  } catch (error) {
    console.error("Error fetching issues:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

export const deleteIssue = async (req: AuthRequest, res: Response) => {
  try {
    const { issueId } = req.body;
    const citizenId = req.citizenId;

    // SQL: Check if issue exists and is owned by this citizen
    const issue = await queryOne(
      "SELECT id, citizen_id FROM issues WHERE id = ? AND citizen_id = ?",
      [issueId, citizenId]
    );

    if (!issue) {
      res.status(404).json({ message: "Issue not found or unauthorized" });
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
    res.status(500).json({ message: "Internal Server Error" });
  }
};
