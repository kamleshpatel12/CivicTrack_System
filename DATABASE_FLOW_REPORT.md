# Database Flow Report - Civic Issue Reporter Application
**Current Database:** MongoDB | **Backend Framework:** Express.js + TypeScript | **Frontend Framework:** React + TypeScript

---

## Executive Summary
Your application uses **MongoDB** with **Mongoose ODM** for data persistence. The system handles civic issue reporting with user authentication, real-time data synchronization between frontend and backend, and media uploads via Cloudinary.

---

## 1. Database Schema & Models

### 1.1 Core Collections

#### **Citizen Collection**
```typescript
{
  _id: ObjectId (auto-generated)
  fullName: String (required)
  email: String (unique, required, lowercase)
  phonenumber: String (required, 10 digits)
  password: String (hashed with bcryptjs, min 8 chars)
  createdAt: Timestamp
  updatedAt: Timestamp
}
```
**Purpose:** Store citizen/user accounts who can report issues

---

#### **Issue Collection**
```typescript
{
  _id: ObjectId (auto-generated)
  citizenId: ObjectId (reference to Citizen, required)
  issueType: String (enum: "Road Infrastructure", "Waste Management", 
                     "Environmental Issues", "Utilities & Infrastructure", 
                     "Public Safety", "Other")
  title: String (unique, required, 5-100 chars)
  description: String (required)
  location: {
    latitude: Number (-90 to 90, required)
    longitude: Number (-180 to 180, required)
    address: String
  }
  status: String (enum: "Reported", "In Progress", "Resolved", "Rejected", "Pending")
  media: ObjectId (reference to Multimedia)
  handledBy: ObjectId (reference to Admin - optional)
  createdAt: Timestamp
  updatedAt: Timestamp
}
```
**Purpose:** Store civic issues reported by citizens with location and metadata

---

#### **Multimedia Collection**
```typescript
{
  _id: ObjectId (auto-generated)
  issueID: ObjectId (reference to Issue, required)
  fileType: String (enum: "image", "video")
  url: String (Cloudinary URL, required)
  filename: String (original filename)
  createdAt: Timestamp
  updatedAt: Timestamp
}
```
**Purpose:** Store images/videos associated with reported issues (hosted on Cloudinary)

---

#### **Admin Collection**
```typescript
{
  _id: ObjectId (auto-generated)
  fullName: String (required)
  email: String (lowercase, required)
  phonenumber: String (required)
  password: String (hashed, min 8 chars)
  department: String (required)
  adminAccessCode: Number (unique, required)
  createdAt: Timestamp
  updatedAt: Timestamp
}
```
**Purpose:** Store admin accounts who handle/resolve issues

---

## 2. Data Flow Architecture

### 2.1 Authentication Flow

```
Frontend (SignUp/SignIn Page)
    ↓
User Input (email, password)
    ↓
POST /api/v1/citizen/signup or /api/v1/citizen/signin
    ↓
Backend (citizen.auth.controller.ts)
    ├─ Validate with Zod schema
    ├─ Hash password with bcryptjs
    ├─ Query MongoDB for existing user
    ├─ Create new document OR verify password
    └─ Generate JWT token (expires in 1 day)
    ↓
Response with Token + User Data
    ↓
Frontend (AuthContext)
    ├─ Store token in localStorage
    ├─ Store user data in state
    └─ Redirect to Home/Dashboard
```

**Key Security:**
- Passwords: hashed with bcryptjs (10 rounds)
- JWT Token: signed with `process.env.JWT_PASSWORD`
- Token Location: Browser localStorage
- Token Header: `Authorization: Bearer {token}`

---

### 2.2 Issue Reporting Flow

```
Frontend (ReportIssue Page)
    ↓
User Input:
├─ title: string
├─ description: string
├─ issueType: enum
├─ location: {latitude, longitude, address}
└─ files: image/video (up to 10)
    ↓
FormData Creation + File Append
    ↓
POST /api/v1/citizen/create-issue
Headers: { Authorization: "Bearer {token}" }
    ↓
Backend (issue.controller.ts)
    ├─ Validate JWT token (authMiddleware)
    ├─ Extract citizenId from decoded JWT
    ├─ File Upload Middleware (multer → Cloudinary)
    ├─ Parse and validate location JSON
    ├─ Create Issue document in MongoDB
    │  └─ Fields: citizenId, issueType, title, description, location, status="Reported"
    ├─ For each uploaded file:
    │  └─ Create Multimedia document in MongoDB
    │     └─ Fields: issueID, fileType, url (Cloudinary), filename
    └─ Return: issue + media array
    ↓
Frontend (ReportIssue.tsx)
    ├─ Show success toast notification
    ├─ Clear form
    └─ Redirect to home/dashboard
```

**Database Operations:**
- 1 Insert to `Issues` collection
- N Inserts to `Multimedia` collection (N = number of files)
- File storage: Cloudinary (external), URL stored in MongoDB

---

### 2.3 Issue Browsing/Viewing Flow

```
Frontend (CitizenHome Page)
    ↓
useEffect Hook on Component Mount
    ↓
GET /api/v1/all-issues
Headers: { Authorization: "Bearer {token}" }
    ↓
Backend (issue.controller.ts → getIssues)
    ├─ Validate JWT token (authMiddleware)
    ├─ Query Issues collection:
    │  └─ .find({})
    │  └─ .populate("citizenId", "fullName")
    │  └─ .lean() [returns plain JS objects, not Mongoose docs]
    ├─ For each issue:
    │  ├─ Query Multimedia collection by issueID
    │  └─ Transform to response format:
    │     {
    │       _id, title, description, type, location,
    │       reportedBy (populated from citizen),
    │       reportedAt, image (first media URL or null), status
    │     }
    └─ Return: { issues: [...] }
    ↓
Frontend (CitizenHome State)
    ├─ setState(issues)
    ├─ Support search filtering by location.address
    ├─ Display with:
    │  ├─ Card layout per issue
    │  ├─ Status badge (color-coded)
    │  ├─ Reporter name
    │  ├─ Location marker
    │  ├─ Report date/time
    │  └─ Issue image thumbnail
    └─ Render list
```

**Database Operations:**
- 1 Find query to `Issues` collection (with population)
- N Find queries to `Multimedia` collection (N = number of issues)

---

### 2.4 Complete Data Relationship Diagram

```
CITIZEN (User)
    │
    ├─── reports ──→ ISSUE
    │                 │
    │                 ├─── references ──→ ISSUE STATUS HISTORY
    │                 │
    │                 ├─── has media ──→ MULTIMEDIA (images/videos)
    │                 │
    │                 └─── handled by ──→ ADMIN
    │
    └─── updates ──→ CITIZEN PROFILE

ADMIN (Staff)
    │
    ├─── handles ──→ ISSUE
    │
    └─── updates ──→ ISSUE STATUS
```

---

## 3. Current MongoDB Configuration

### 3.1 Connection Setup

**File:** `backend/src/config/database.ts`

```typescript
const DATABASE_URL = process.env.DATABASE_URL || "";

export const connectDB = async () => {
  try {
    await mongoose.connect(DATABASE_URL);
    console.log("Connected to DB !");
  } catch (err) {
    console.error("DB connection error:", err);
  }
};
```

**Connection Source:** Environment variable `DATABASE_URL`
- Example: `mongodb+srv://user:password@cluster.mongodb.net/database_name`

**Dependencies:**
- `mongoose: ^8.15.1` (ODM)
- `mongodb` (bundled with mongoose)

---

### 3.2 Middleware & Middleware Stack

**Order in Express App:**
```typescript
1. CORS middleware (cross-origin requests to frontend)
2. express.json() (parse JSON bodies)
3. express.urlencoded() (parse form data)
4. express.static() (serve static files)
5. cookieParser() (parse cookies)
6. Routes:
   - /api/v1/citizen/* → Citizen routes
   - /api/v1/admin/* → Admin routes
   - /api/v1/citizen/* → Issue routes
7. Auth Middleware (JWT verification) - applied per route
8. File Upload Middleware (multer + Cloudinary) - applied per route
```

---

## 4. API Endpoints & Database Operations

### 4.1 Authentication Endpoints

| Method | Endpoint | Data Flow | DB Operations |
|--------|----------|-----------|----------------|
| POST | `/citizen/signup` | Email, Password, Name, Phone → Create JWT | INSERT into Citizen collection |
| POST | `/citizen/signin` | Email, Password → Validate & Return JWT | SELECT from Citizen collection |
| POST | `/admin/signup` | Email, Password, Dept, Access Code → Create JWT | INSERT into Admin collection |
| POST | `/admin/signin` | Email, Password → Validate & Return JWT | SELECT from Admin collection |

---

### 4.2 Issue Management Endpoints

| Method | Endpoint | Data Flow | DB Operations |
|--------|----------|-----------|----------------|
| POST | `/citizen/create-issue` | Form + Files → Create Issue | INSERT Issue + N INSERT Multimedia |
| GET | `/all-issues` | JWT Auth → Get all issues | SELECT Issues + SELECT Multimedia (N times) |
| GET | `/my-issues` | JWT Auth → Get citizen's issues | SELECT Issues (filtered by citizenId) |
| PUT | `/issue/:id/status` | Issue ID + New Status → Update | UPDATE Issue |
| GET | `/issue/:id` | Issue ID → Get issue details | SELECT Issue + SELECT Multimedia |

---

## 5. Performance Analysis

### ✅ Strengths
1. **Document-oriented:** Natural fit for flexible civic issue data
2. **Relationships:** ObjectId references maintain referential integrity
3. **Timestamps:** Built-in `createdAt/updatedAt` tracking
4. **Indexing:** Implicit indexes on `_id`, `email`, `title`
5. **Scalability:** MongoDB handles growing document collections well

### ⚠️ Current Issues

**Issue #1: N+1 Query Problem**
```typescript
// Current inefficient code in getIssues:
const issues = await IssueModel.find({}).populate("citizenId", "fullName").lean();

const issuesWithMedia = await Promise.all(
  issues.map(async (issue) => {
    const media = await MultimediaModel.find({ issueID: issue._id }); // ❌ N queries
    return { ...issue, media };
  })
);
```
**Impact:** If 100 issues exist, backend makes 101 queries (1 for issues + 100 for media)

**Solution (Optimized):**
```typescript
const media = await MultimediaModel.find({}).lean();
const mediaByIssueId = new Map();
media.forEach(m => {
  if (!mediaByIssueId.has(m.issueID)) mediaByIssueId.set(m.issueID, []);
  mediaByIssueId.get(m.issueID).push(m);
});

const issuesWithMedia = issues.map(issue => ({
  ...issue,
  media: mediaByIssueId.get(issue._id) || []
}));
```
**Result:** 2 queries instead of N+1

---

**Issue #2: Missing Indexes**
```
No indexes on:
- Issue.citizenId (foreign key - used for filtering)
- Issue.status (used for filtering by status)
- Multimedia.issueID (foreign key - frequently queried)
- Issue.createdAt (sorting by date)
```

**Recommended Indexes:**
```javascript
db.issues.createIndex({ citizenId: 1 });
db.issues.createIndex({ status: 1 });
db.issues.createIndex({ createdAt: -1 });
db.multimedia.createIndex({ issueID: 1 });
```

---

**Issue #3: No Pagination**
```typescript
// Current: Gets ALL issues every time
const issues = await IssueModel.find({}).populate("citizenId", "fullName").lean();

// Recommended: Add pagination
const limit = 10;
const page = req.query.page ? parseInt(req.query.page) : 1;
const issues = await IssueModel
  .find({})
  .populate("citizenId", "fullName")
  .limit(limit)
  .skip((page - 1) * limit)
  .sort({ createdAt: -1 })
  .lean();
```

---

**Issue #4: No Aggregation Pipeline Usage**
MongoDB aggregation pipelines are more efficient for complex queries. Current approach fetches data then processes in JavaScript.

---

## 6. Frontend-Backend Communication

### 6.1 Request Format

**Login Request:**
```javascript
POST https://civic-issue-reporter-application.onrender.com/api/v1/citizen/signin
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Report Issue Request:**
```javascript
POST https://civic-issue-reporter-application.onrender.com/api/v1/citizen/create-issue
Content-Type: multipart/form-data
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

FormData:
├─ title: "Pothole on Main Street"
├─ description: "Large pothole affecting traffic"
├─ issueType: "Road Infrastructure"
├─ location: {"latitude": 28.7041, "longitude": 77.1025, "address": "Delhi"}
├─ files: [File, File, ...]
```

---

### 6.2 Response Format

**Successful Login:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "fullName": "John Doe",
    "email": "john@example.com",
    "phonenumber": "9876543210",
    "role": "citizen"
  }
}
```

**Get All Issues:**
```json
{
  "issues": [
    {
      "_id": "507f1f77bcf86cd799439012",
      "title": "Pothole on Main Street",
      "description": "Large pothole affecting traffic",
      "type": "Road Infrastructure",
      "location": {
        "latitude": 28.7041,
        "longitude": 77.1025,
        "address": "Delhi, India"
      },
      "reportedBy": "John Doe",
      "reportedAt": "2024-03-15T10:30:00Z",
      "image": "https://res.cloudinary.com/...",
      "status": "Reported"
    }
  ]
}
```

---

## 7. Migration Path: MongoDB → MySQL

### 7.1 Schema Mapping

| MongoDB Collection | MySQL Table | Notes |
|-------------------|-------------|-------|
| Citizen | citizens | Direct 1:1 mapping |
| Admin | admins | Direct 1:1 mapping |
| Issue | issues | Embed location as JSON or separate table |
| Multimedia | multimedia | Direct 1:1 mapping with foreign key |
| IssueStatusHistory | issue_status_history | New table for audit trail |

---

### 7.2 MySQL Schema (Recommended)

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

-- Locations Table (Optional - denormalized in Issues)
CREATE TABLE locations (
  id INT PRIMARY KEY AUTO_INCREMENT,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  address VARCHAR(500)
);

-- Issues Table
CREATE TABLE issues (
  id INT PRIMARY KEY AUTO_INCREMENT,
  citizen_id INT NOT NULL,
  issue_type ENUM('Road Infrastructure', 'Waste Management', 'Environmental Issues', 
                   'Utilities & Infrastructure', 'Public Safety', 'Other') DEFAULT 'Road Infrastructure',
  title VARCHAR(100) UNIQUE NOT NULL,
  description TEXT NOT NULL,
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

---

### 7.3 Code Changes Required for MySQL

**1. Update Dependencies:**
```diff
- "mongoose": "^8.15.1"
+ "mysql2": "^3.6.0"
+ "sequelize": "^6.35.0"  // OR TypeORM/Prisma
```

**2. Update Database Connection:**
```typescript
// Before (MongoDB)
import mongoose from "mongoose";
await mongoose.connect(DATABASE_URL);

// After (MySQL with Sequelize)
import { Sequelize } from 'sequelize';
const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    dialect: 'mysql',
    pool: { max: 10, min: 0, idle: 10000 }
  }
);
await sequelize.authenticate();
```

**3. Update Models:**
```typescript
// Before (MongoDB/Mongoose)
const CitizenSchema = new Schema({
  fullName: { type: String, required: true },
  email: { type: String, unique: true, required: true }
});

// After (MySQL/Sequelize)
const Citizen = sequelize.define('Citizen', {
  fullName: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING, unique: true, allowNull: false }
});
```

**4. Update Queries:**
```typescript
// Before (MongoDB)
const issue = await IssueModel.findOne({ _id: issueId }).populate("citizenId");

// After (MySQL)
const issue = await Issue.findByPk(issueId, {
  include: [{ model: Citizen, as: 'citizen' }]
});
```

---

### 7.4 Migration Checklist

- [ ] Install MySQL 8.0+ on server
- [ ] Create MySQL user with appropriate permissions
- [ ] Design and create MySQL schema (as above)
- [ ] Update `backend/package.json` dependencies
- [ ] Rewrite `src/config/database.ts` for MySQL
- [ ] Rewrite all model definitions (Mongoose → Sequelize/TypeORM)
- [ ] Update all controllers to use new ORM syntax
- [ ] Test all CRUD operations
- [ ] Update environment variables (`.env`)
- [ ] Migrate existing MongoDB data to MySQL
- [ ] Update tests
- [ ] Deploy and monitor

---

## 8. Current Technology Stack Summary

| Layer | Technology | Version |
|-------|-----------|---------|
| **Frontend** | React + TypeScript | Latest |
| **Backend** | Express.js + TypeScript | 5.1.0 |
| **Database** | MongoDB | v8.15.1 (Mongoose) |
| **Authentication** | JWT | 9.0.2 |
| **Password Hashing** | bcryptjs | 3.0.2 |
| **File Storage** | Cloudinary | 1.41.3 |
| **File Upload** | Multer | 2.0.1 |
| **Validation** | Zod | 3.25.76 |
| **Hosting** | Rendered.com (Backend) | - |

---

## 9. Recommended Optimizations (Before MySQL Migration)

1. **Add Pagination** to issue listing
2. **Create Indexes** on foreign keys and frequently filtered fields
3. **Fix N+1 Query Problem** using aggregation pipelines or batch processing
4. **Add Query Caching** for frequently accessed data (Redis)
5. **Implement Rate Limiting** on authentication endpoints
6. **Add Request Validation** at route level (express-validator)
7. **Implement Soft Deletes** for data retention/audit trails

---

## 10. Questions to Consider Before Migration

1. **Why migrate?** (Performance, licensing, existing infrastructure?)
2. **Downtime tolerance?** (Need zero-downtime migration?)
3. **Data size?** (Small migration vs. multi-GB data?)
4. **Team expertise?** (MySQL DBA available vs. learning curve?)
5. **Scaling plans?** (Horizontal? Vertical? Read replicas?)

---

## Summary

Your application currently works well with MongoDB. The data flow is straightforward: **Frontend** → **JWT Auth** → **Express Backend** → **MongoDB** → **Response to Frontend**. Before migrating to MySQL, optimize the current MongoDB setup and ensure the team is comfortable with relational schema design.

**Next Steps:**
- [ ] Review and implement the optimization suggestions above
- [ ] Test with larger datasets (thousands of issues)
- [ ] Profile API response times
- [ ] Then decide if MySQL migration is needed
