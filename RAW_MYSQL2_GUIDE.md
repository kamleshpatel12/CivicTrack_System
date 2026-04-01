# MySQL Migration Guide - Raw SQL with mysql2
**For: Civic Issue Reporter Application (DBMS Project)**

---

## Why Raw mysql2?
✅ Write actual SQL queries (SELECT, JOIN, INSERT, UPDATE, DELETE)  
✅ Professor sees real database operations  
✅ No ORM abstraction—pure SQL  
✅ Smaller bundle size  
✅ Full control over queries  
✅ Easy to debug and explain  

---

## **STEP 1: Create MySQL Database & Tables**

### 1.1 Connect to MySQL
```bash
mysql -u root -p
# Enter your MySQL root password
```

### 1.2 Create Database
```sql
CREATE DATABASE civic_issue_db;
USE civic_issue_db;
```

### 1.3 Create All Tables

Copy and run this complete SQL script:

```sql
-- Citizens Table
CREATE TABLE citizens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone_number VARCHAR(10) NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
);

-- Admins Table
CREATE TABLE admins (
  id INT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone_number VARCHAR(10) NOT NULL,
  password VARCHAR(255) NOT NULL,
  department VARCHAR(100) NOT NULL,
  admin_access_code INT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
);

-- Issues Table
CREATE TABLE issues (
  id INT PRIMARY KEY AUTO_INCREMENT,
  citizen_id INT NOT NULL,
  issue_type ENUM('Road Infrastructure', 'Waste Management', 'Environmental Issues', 'Utilities & Infrastructure', 'Public Safety', 'Other') DEFAULT 'Road Infrastructure',
  title VARCHAR(100) UNIQUE NOT NULL,
  description LONGTEXT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  address VARCHAR(500),
  status ENUM('Reported', 'In Progress', 'Resolved', 'Rejected', 'Pending') DEFAULT 'Reported',
  handled_by INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
  FOREIGN KEY (handled_by) REFERENCES admins(id) ON DELETE SET NULL,
  INDEX idx_citizen_id (citizen_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at),
  INDEX idx_handled_by (handled_by)
);

-- Multimedia Table
CREATE TABLE multimedia (
  id INT PRIMARY KEY AUTO_INCREMENT,
  issue_id INT NOT NULL,
  file_type ENUM('image', 'video') NOT NULL,
  url VARCHAR(500) NOT NULL,
  filename VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
  INDEX idx_issue_id (issue_id)
);

-- Issue Status History (Audit Trail)
CREATE TABLE issue_status_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  issue_id INT NOT NULL,
  old_status VARCHAR(50),
  new_status VARCHAR(50) NOT NULL,
  changed_by INT,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES admins(id) ON DELETE SET NULL,
  INDEX idx_issue_id (issue_id),
  INDEX idx_changed_at (changed_at)
);
```

✅ **Verify tables:**
```sql
SHOW TABLES;
DESC citizens;
DESC issues;
DESC multimedia;
```

---

## **STEP 2: Install mysql2 Package**

```bash
cd C:\DBS_Project\backend
npm install mysql2
```

---

## **STEP 3: Update `.env` File**

Create/update `.env` in `backend` folder:

```env
# MySQL Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=civic_issue_db

# Other configs
PORT=3000
CORS_ORIGIN=http://localhost:5173
JWT_PASSWORD=your_jwt_secret_key
CLOUDINARY_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

---

## **STEP 4: Create Database Connection File**

Create `src/config/database.ts`:

```typescript
import mysql from "mysql2/promise";
import "dotenv/config";

// Create connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "3306"),
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "civic_issue_db",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

export const connectDB = async () => {
  try {
    const connection = await pool.getConnection();
    console.log("Connected to MySQL Database!");
    connection.release();
  } catch (error) {
    console.error("Database connection failed:", error);
    process.exit(1);
  }
};

export default pool;
```

---

## **STEP 5: Create Database Utility Functions**

Create `src/utils/db.ts` for reusable query functions:

```typescript
import pool from "../config/database";

// Execute query and get results
export const query = async (sql: string, values?: any[]) => {
  try {
    const connection = await pool.getConnection();
    const [results] = await connection.execute(sql, values || []);
    connection.release();
    return results;
  } catch (error) {
    console.error("Database query error:", error);
    throw error;
  }
};

// Execute query with connection (for transactions)
export const queryWithConnection = async (
  connection: any,
  sql: string,
  values?: any[]
) => {
  return await connection.execute(sql, values || []);
};

// Get single row
export const queryOne = async (sql: string, values?: any[]) => {
  const results = await query(sql, values);
  return (results as any)[0] || null;
};

// Get all rows
export const queryAll = async (sql: string, values?: any[]) => {
  return await query(sql, values);
};

// Insert and get ID
export const insert = async (sql: string, values?: any[]) => {
  const results = await query(sql, values) as any;
  return results.insertId;
};
```

---

## **STEP 6: Rewrite Controllers with Raw SQL**

### **6.1 Citizen Auth Controller**

Create/Update `src/controllers/auth-controllers/citizen.auth.controller.ts`:

```typescript
import { Request, Response } from "express";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import { query, queryOne, insert } from "../../utils/db";
import { z } from "zod";

const signupSchema = z.object({
  fullName: z.string().min(1, { message: "Full name is required" }).trim(),
  password: z
    .string()
    .min(8, { message: "Password must be at least 8 characters" })
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
      {
        message:
          "Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character",
      }
    )
    .trim(),
  email: z.string().email({ message: "Invalid email format" }).trim(),
  phonenumber: z
    .string()
    .length(10, { message: "Phone number must be exactly 10 digits" }),
});

export const citizenSignup = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const parsedData = signupSchema.parse(req.body);
    const { fullName, password, email, phonenumber } = parsedData;

    // SQL: Check if citizen exists
    const existingCitizen = await queryOne(
      "SELECT id FROM citizens WHERE email = ?",
      [email]
    );

    if (existingCitizen) {
      res.status(400).json({ message: "Citizen already exists" });
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // SQL: Insert new citizen
    await insert(
      "INSERT INTO citizens (full_name, email, phone_number, password) VALUES (?, ?, ?, ?)",
      [fullName, email, phonenumber, hashedPassword]
    );

    console.log("Citizen created!");
    res.status(201).json({ message: "Citizen Signed up!" });
  } catch (err: any) {
    if (err.name === "ZodError") {
      res.status(400).json({
        message: "Validation failed",
        errors: err.errors,
      });
      return;
    }

    console.error("Error creating citizen:", err);
    res.status(411).json({ message: "Citizen already exists or another error occurred" });
  }
};

export const citizenSignin = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { email, password } = req.body;

    // SQL: Find citizen by email
    const citizen = await queryOne(
      "SELECT id, full_name, email, phone_number, password FROM citizens WHERE email = ?",
      [email]
    );

    if (!citizen) {
      res.status(400).json({ message: "Invalid email or password" });
      return;
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, citizen.password);
    if (!isPasswordValid) {
      res.status(400).json({ message: "Invalid email or password" });
      return;
    }

    // Generate JWT
    const token = jwt.sign(
      {
        id: citizen.id,
        role: "citizen",
      },
      process.env.JWT_PASSWORD!,
      { expiresIn: "1d" }
    );

    res.json({
      token,
      user: {
        id: citizen.id,
        fullName: citizen.full_name,
        email: citizen.email,
        phonenumber: citizen.phone_number,
        role: "citizen",
      },
    });
    console.log("Citizen signed in!");
  } catch (error) {
    console.error("Error during citizen signin:", error);
    res.status(500).json({
      message: "Internal Server Error",
    });
  }
};
```

---

### **6.2 Issues Controller**

Create/Update `src/controllers/issues.controllers.ts`:

```typescript
import { Request, Response } from "express";
import { query, queryOne, queryAll, insert } from "../utils/db";
import { MultimediaModel } from "../models/multimedia.model";

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
      res.status(400).json({ message: "Please fill all the required fields" });
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

// New: Get single issue by ID
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
```

---

## **STEP 7: Real SQL Query Examples**

Here are the actual SQL queries being executed:

### **Authentication Queries:**

```sql
-- Check if email exists (Signup)
SELECT id FROM citizens WHERE email = ?;

-- Insert new citizen (Signup)
INSERT INTO citizens (full_name, email, phone_number, password) 
VALUES (?, ?, ?, ?);

-- Get citizen for login (Signin)
SELECT id, full_name, email, phone_number, password 
FROM citizens 
WHERE email = ?;
```

### **Issue Queries:**

```sql
-- Check if title exists
SELECT id FROM issues WHERE title = ?;

-- Create issue
INSERT INTO issues 
(citizen_id, issue_type, title, description, latitude, longitude, address, status) 
VALUES (?, ?, ?, ?, ?, ?, ?, ?);

-- Insert multimedia
INSERT INTO multimedia (issue_id, file_type, url, filename) 
VALUES (?, ?, ?, ?);

-- Get all issues with citizen names (JOIN)
SELECT 
  i.id, i.citizen_id, i.issue_type, i.title, i.description,
  i.latitude, i.longitude, i.address, i.status, i.created_at,
  c.full_name
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
ORDER BY i.created_at DESC;

-- Get multimedia for issues
SELECT id, issue_id, file_type, url, filename 
FROM multimedia;

-- Get single issue with citizen
SELECT 
  i.id, i.citizen_id, i.issue_type, i.title, i.description,
  i.latitude, i.longitude, i.address, i.status, i.created_at,
  c.full_name
FROM issues i
LEFT JOIN citizens c ON i.citizen_id = c.id
WHERE i.id = ?;

-- Update issue status
UPDATE issues SET status = ? WHERE id = ?;

-- Log status change (Audit trail)
INSERT INTO issue_status_history (issue_id, old_status, new_status, changed_by) 
VALUES (?, ?, ?, ?);
```

---

## **STEP 8: Update App Initialization**

Update `src/index.ts`:

```typescript
import dotenv from "dotenv";
import { connectDB } from "./config/database";
import app from "./app";

dotenv.config({ path: "./.env" });

const PORT = process.env.PORT || 3000;

connectDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server is running on port : ${PORT}`);
    });
  })
  .catch((error) => {
    console.log("MySQL connection failed!\n", error);
    process.exit(1);
  });
```

---

## **STEP 9: Complete File Structure**

```
backend/
├── src/
│   ├── config/
│   │   └── database.ts          ✅ Raw mysql2 pool
│   ├── utils/
│   │   └── db.ts                ✅ Query helper functions
│   ├── controllers/
│   │   ├── auth-controllers/
│   │   │   └── citizen.auth.controller.ts    ✅ Raw SQL queries
│   │   └── issues.controllers.ts             ✅ Raw SQL with JOINs
│   ├── middlerware/
│   │   └── auth.middleware.ts    (no changes)
│   ├── routes/
│   │   └── issue.routes.ts       (no changes)
│   ├── app.ts                   (no changes)
│   └── index.ts                 (updated)
├── .env                          ✅ Updated with MySQL config
└── package.json                  ✅ Added mysql2
```

---

## **STEP 10: Installation & Testing**

### 10.1 Install mysql2
```bash
cd C:\DBS_Project\backend
npm install mysql2
```

### 10.2 Update package.json

Ensure your `package.json` has:
```json
{
  "dependencies": {
    "mysql2": "^3.6.0",
    "express": "^5.1.0",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^3.0.2",
    "cloudinary": "^1.41.3",
    "multer": "^2.0.1"
  }
}
```

### 10.3 Test with Postman

**Signup:**
```
POST http://localhost:3000/api/v1/citizen/signup
Content-Type: application/json

{
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "phonenumber": "9876543210"
}
```

**Check MySQL:**
```sql
SELECT * FROM citizens;
```

---

## **STEP 11: Verify All Queries in MySQL**

Check the database directly:

```bash
mysql -u root -p civic_issue_db
```

```sql
-- See all citizens
SELECT * FROM citizens;

-- See all issues with citizen names
SELECT i.title, i.description, c.full_name, i.status 
FROM issues i 
JOIN citizens c ON i.citizen_id = c.id;

-- See multimedia count per issue
SELECT issue_id, COUNT(*) as media_count 
FROM multimedia 
GROUP BY issue_id;

-- See status change history
SELECT * FROM issue_status_history;
```

---

## **Key Advantages of Raw SQL**

✅ **Professor sees actual database operations**
```typescript
// Instead of: Issue.create({...})
// You write: INSERT INTO issues (citizen_id, title, ...) VALUES (?, ?, ...)
```

✅ **Easy to explain in presentation**
- "Here's the SQL: INSERT INTO citizens..."
- "Here's the JOIN: SELECT FROM issues LEFT JOIN citizens..."

✅ **Performance visible**
- You see exactly which queries run
- N+1 problem becomes obvious: "1 query for issues + 1 query for all media = 2 total"

✅ **No black box**
- No ORM magic
- Every SQL statement is explicit

✅ **Learn actual database concepts**
- JOINs, indexes, foreign keys
- Prepared statements for SQL injection prevention

---

## **Common Queries Reference**

```sql
-- SELECT with WHERE
SELECT * FROM citizens WHERE email = 'john@example.com';

-- JOIN two tables
SELECT c.full_name, i.title 
FROM issues i 
JOIN citizens c ON i.citizen_id = c.id;

-- INSERT with RETURNING (or use insertId)
INSERT INTO issues (citizen_id, title) VALUES (1, 'Pothole');

-- UPDATE
UPDATE issues SET status = 'Resolved' WHERE id = 1;

-- DELETE
DELETE FROM issues WHERE id = 1;

-- COUNT and GROUP BY
SELECT status, COUNT(*) FROM issues GROUP BY status;

-- ORDER BY and LIMIT
SELECT * FROM issues ORDER BY created_at DESC LIMIT 10;

-- AGGREGATE with JOIN
SELECT c.full_name, COUNT(i.id) as issue_count 
FROM citizens c 
LEFT JOIN issues i ON c.id = i.citizen_id 
GROUP BY c.id;
```

---

## **Done! 🎉**

You now have:
- ✅ Raw MySQL with mysql2
- ✅ Real SQL queries visible in code
- ✅ Professor can see actual SQL statements
- ✅ JOINs, indexes, foreign keys demonstrated
- ✅ No ORM abstraction

Your project showcases real DBMS concepts!
