import { Request, Response } from "express";
import { query, queryOne, queryAll, insert } from "../utils/db";

export const createIssue = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const files = (req.files as Express.Multer.File[]) || [];
    const { title, description, location, issueType } = req.body;
    const citizenId = (req as any).citizenId;

    // Parse location
    let parsedLocation = location;
    if (typeof location === "string") {
      try {
        parsedLocation = JSON.parse(location);
      } catch {
        res.status(400).json({ message: "Invalid location JSON format" });
        return;
      }
    }

    // Validate required fields
    if (
      !title ||
      !description ||
      !parsedLocation ||
      !parsedLocation.latitude ||
      !parsedLocation.longitude ||
      !issueType
    ) {
      res.status(400).json({ message: "Please fill all the required fields " });
      return;
    }

    // SQL: Check if issue with same title exists
    const existingIssue = await queryOne(
      "SELECT id FROM issues WHERE title = ?",
      [title]
    );

    if (existingIssue) {
      res
        .status(400)
        .json({ message: "Issue with this title already exists" });
      return;
    }

    // SQL: Insert issue
    const issueId = await insert(
      `INSERT INTO issues 
       (citizen_id, issue_type, title, description, latitude, longitude, address, status) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        citizenId,
        issueType,
        title,
        description,
        parsedLocation.latitude,
        parsedLocation.longitude,
        parsedLocation.address,
        "Reported",
      ]
    );

    // SQL: Insert multimedia files
    const mediaDocs = await Promise.all(
      files.map((file) =>
        (async () => {
          const mediaId = await insert(
            `INSERT INTO multimedia (issue_id, file_type, url, filename) 
             VALUES (?, ?, ?, ?)`,
            [
              issueId,
              file.mimetype.startsWith("video") ? "video" : "image",
              file.path,
              file.originalname,
            ]
          );
          return {
            id: mediaId,
            issueId,
            fileType: file.mimetype.startsWith("video") ? "video" : "image",
            url: file.path,
            filename: file.originalname,
          };
        })()
      )
    );

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
  } catch (error) {
    console.error("Error creating issue:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getIssues = async (req: Request, res: Response) => {
  try {
    // SQL: JOINed query to get issues with citizen names (ONE query instead of N+1)
    const issues = (await queryAll(
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
        i.updated_at,
        c.full_name
      FROM issues i
      LEFT JOIN citizens c ON i.citizen_id = c.id
      ORDER BY i.created_at DESC`
    )) as any[];

    // SQL: Get multimedia for all issues in one query
    const allMedia = (await queryAll(
      `SELECT id, issue_id, file_type, url, filename FROM multimedia`
    )) as any[];

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

    // SQL: Get multimedia for this issue
    const media = await queryAll(
      `SELECT id, file_type, url, filename FROM multimedia WHERE issue_id = ?`,
      [id]
    );

    res.json({
      issue,
      media,
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
