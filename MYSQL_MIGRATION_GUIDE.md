# MongoDB → MySQL Migration Guide
**For: Civic Issue Reporter Application**

---

## 📋 Prerequisites

✅ MySQL already downloaded on your PC
- Verify: Open Command Prompt
  ```bash
  mysql --version
  ```

---

## **STEP 1: Create MySQL Database & Tables (5 minutes)**

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

Copy and run this SQL script in MySQL:

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

-- Issue Status History Table (for audit trail)
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

✅ **Verify tables were created:**
```sql
SHOW TABLES;
```

---

## **STEP 2: Install MySQL Driver & ORM (3 minutes)**

Navigate to backend folder:
```bash
cd C:\DBS_Project\backend
```

### Choose ONE ORM (I recommend Prisma - fastest)

#### **Option A: Prisma (RECOMMENDED)**
```bash
npm install @prisma/client prisma mysql2
npx prisma init
```

#### **Option B: Sequelize**
```bash
npm install mysql2 sequelize
```

#### **Option C: TypeORM**
```bash
npm install mysql2 typeorm reflect-metadata
```

---

## **STEP 3: Update Environment Variables (2 minutes)**

Create/Update `.env` file in `backend` folder:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=civic_issue_db

# Other existing configs
PORT=3000
CORS_ORIGIN=http://localhost:5173
JWT_PASSWORD=your_jwt_secret_key
CLOUDINARY_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

---

## **STEP 4: Update Database Connection (5 minutes)**

### **Using Prisma (RECOMMENDED)**

#### 4.1 Update `prisma/schema.prisma`:
```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

model Citizen {
  id        Int     @id @default(autoincrement())
  fullName  String
  email     String  @unique
  phoneNumber String
  password  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  issues    Issue[]

  @@map("citizens")
}

model Admin {
  id              Int     @id @default(autoincrement())
  fullName        String
  email           String  @unique
  phoneNumber     String
  password        String
  department      String
  adminAccessCode Int     @unique
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
  handledIssues   Issue[]
  statusHistory   IssueStatusHistory[]

  @@map("admins")
}

model Issue {
  id          Int     @id @default(autoincrement())
  citizenId   Int
  issueType   String  @default("Road Infrastructure")
  title       String  @unique
  description String  @db.LongText
  latitude    Decimal? @db.Decimal(10, 8)
  longitude   Decimal? @db.Decimal(11, 8)
  address     String?
  status      String  @default("Reported")
  handledBy   Int?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  citizen     Citizen @relation(fields: [citizenId], references: [id], onDelete: Cascade)
  admin       Admin?  @relation(fields: [handledBy], references: [id], onDelete: SetNull)
  multimedia  Multimedia[]
  statusHistory IssueStatusHistory[]

  @@index([citizenId])
  @@index([status])
  @@index([createdAt])
  @@index([handledBy])
  @@map("issues")
}

model Multimedia {
  id        Int     @id @default(autoincrement())
  issueId   Int
  fileType  String  // "image" or "video"
  url       String
  filename  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  issue     Issue @relation(fields: [issueId], references: [id], onDelete: Cascade)

  @@index([issueId])
  @@map("multimedia")
}

model IssueStatusHistory {
  id        Int     @id @default(autoincrement())
  issueId   Int
  oldStatus String?
  newStatus String
  changedBy Int?
  changedAt DateTime @default(now())

  issue     Issue @relation(fields: [issueId], references: [id], onDelete: Cascade)
  admin     Admin? @relation(fields: [changedBy], references: [id], onDelete: SetNull)

  @@index([issueId])
  @@index([changedAt])
  @@map("issue_status_history")
}
```

#### 4.2 Update `.env` for Prisma:
```env
DATABASE_URL="mysql://root:your_password@localhost:3306/civic_issue_db"
```

#### 4.3 Push schema to database:
```bash
npx prisma migrate dev --name init
```

---

### **Using Sequelize (ALTERNATIVE)**

Replace `src/config/database.ts`:

```typescript
import { Sequelize } from 'sequelize';
import 'dotenv/config';

const sequelize = new Sequelize(
  process.env.DB_NAME || 'civic_issue_db',
  process.env.DB_USER || 'root',
  process.env.DB_PASSWORD || '',
  {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306'),
    dialect: 'mysql',
    logging: false,
    pool: {
      max: 10,
      min: 0,
      idle: 10000,
    },
  }
);

export const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connected to MySQL Database!');
  } catch (error) {
    console.error('Unable to connect to the database:', error);
    process.exit(1);
  }
};

export default sequelize;
```

---

## **STEP 5: Rewrite Models (30 minutes)**

Delete MongoDB models, create new MySQL models.

### **Using Prisma (Just use schema.prisma above)**

### **Using Sequelize:**

#### Create `src/models/citizen.model.ts`:
```typescript
import { DataTypes, Model } from 'sequelize';
import sequelize from '../config/database';

export class Citizen extends Model {
  public id!: number;
  public fullName!: string;
  public email!: string;
  public phoneNumber!: string;
  public password!: string;
  readonly createdAt!: Date;
  readonly updatedAt!: Date;
}

Citizen.init(
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    fullName: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true,
      },
    },
    phoneNumber: {
      type: DataTypes.STRING(10),
      allowNull: false,
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false,
    },
  },
  {
    sequelize,
    tableName: 'citizens',
    timestamps: true,
  }
);

export default Citizen;
```

#### Create `src/models/issue.model.ts`:
```typescript
import { DataTypes, Model } from 'sequelize';
import sequelize from '../config/database';
import Citizen from './citizen.model';
import Admin from './admin.model';

export class Issue extends Model {
  public id!: number;
  public citizenId!: number;
  public issueType!: string;
  public title!: string;
  public description!: string;
  public latitude?: number;
  public longitude?: number;
  public address?: string;
  public status!: string;
  public handledBy?: number;
  readonly createdAt!: Date;
  readonly updatedAt!: Date;
}

Issue.init(
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    citizenId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Citizen,
        key: 'id',
      },
    },
    issueType: {
      type: DataTypes.ENUM('Road Infrastructure', 'Waste Management', 'Environmental Issues', 'Utilities & Infrastructure', 'Public Safety', 'Other'),
      defaultValue: 'Road Infrastructure',
      allowNull: false,
    },
    title: {
      type: DataTypes.STRING(100),
      allowNull: false,
      unique: true,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    latitude: {
      type: DataTypes.DECIMAL(10, 8),
    },
    longitude: {
      type: DataTypes.DECIMAL(11, 8),
    },
    address: {
      type: DataTypes.STRING(500),
    },
    status: {
      type: DataTypes.ENUM('Reported', 'In Progress', 'Resolved', 'Rejected', 'Pending'),
      defaultValue: 'Reported',
    },
    handledBy: {
      type: DataTypes.INTEGER,
      references: {
        model: Admin,
        key: 'id',
      },
      onDelete: 'SET NULL',
    },
  },
  {
    sequelize,
    tableName: 'issues',
    timestamps: true,
  }
);

// Relationships
Issue.belongsTo(Citizen, { foreignKey: 'citizenId' });
Citizen.hasMany(Issue, { foreignKey: 'citizenId' });

Issue.belongsTo(Admin, { foreignKey: 'handledBy' });
Admin.hasMany(Issue, { foreignKey: 'handledBy' });

export default Issue;
```

#### Create `src/models/multimedia.model.ts`:
```typescript
import { DataTypes, Model } from 'sequelize';
import sequelize from '../config/database';
import Issue from './issue.model';

export class Multimedia extends Model {
  public id!: number;
  public issueId!: number;
  public fileType!: string;
  public url!: string;
  public filename!: string;
  readonly createdAt!: Date;
  readonly updatedAt!: Date;
}

Multimedia.init(
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    issueId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Issue,
        key: 'id',
      },
    },
    fileType: {
      type: DataTypes.ENUM('image', 'video'),
      allowNull: false,
    },
    url: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    filename: {
      type: DataTypes.STRING,
      allowNull: false,
    },
  },
  {
    sequelize,
    tableName: 'multimedia',
    timestamps: true,
  }
);

Multimedia.belongsTo(Issue, { foreignKey: 'issueId' });
Issue.hasMany(Multimedia, { foreignKey: 'issueId' });

export default Multimedia;
```

---

## **STEP 6: Update Controllers (1 hour)**

### **For Sequelize:**

#### Update `src/controllers/auth-controllers/citizen.auth.controller.ts`:

**Old (MongoDB):**
```typescript
const existingCitizen = await CitizenModel.findOne({ email });
await CitizenModel.create({...});
```

**New (MySQL with Sequelize):**
```typescript
import Citizen from '../../models/citizen.model';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export const citizenSignup = async (req: Request, res: Response) => {
  try {
    const { fullName, email, password, phonenumber } = req.body;

    // Check if citizen exists
    const existingCitizen = await Citizen.findOne({ where: { email } });
    if (existingCitizen) {
      res.status(400).json({ message: 'Citizen already exists' });
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create citizen
    const citizen = await Citizen.create({
      fullName,
      email,
      phoneNumber: phonenumber,
      password: hashedPassword,
    });

    res.status(201).json({ message: 'Citizen Signed up!' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const citizenSignin = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    // Find citizen
    const citizen = await Citizen.findOne({ where: { email } });
    if (!citizen) {
      res.status(400).json({ message: 'Invalid email or password' });
      return;
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, citizen.password);
    if (!isPasswordValid) {
      res.status(400).json({ message: 'Invalid email or password' });
      return;
    }

    // Generate JWT
    const token = jwt.sign(
      { id: citizen.id, role: 'citizen' },
      process.env.JWT_PASSWORD!,
      { expiresIn: '1d' }
    );

    res.json({
      token,
      user: {
        id: citizen.id,
        fullName: citizen.fullName,
        email: citizen.email,
        phonenumber: citizen.phoneNumber,
        role: 'citizen',
      },
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
```

#### Update `src/controllers/issues.controllers.ts`:

**Old (MongoDB):**
```typescript
const issue = await IssueModel.create({...});
const issues = await IssueModel.find({}).populate("citizenId");
```

**New (MySQL with Sequelize):**
```typescript
import Issue from '../models/issue.model';
import Multimedia from '../models/multimedia.model';
import Citizen from '../models/citizen.model';

export const createIssue = async (req: Request, res: Response) => {
  try {
    const files = (req.files as Express.Multer.File[]) || [];
    const { title, description, location, issueType } = req.body;

    let parsedLocation = location;
    if (typeof location === 'string') {
      parsedLocation = JSON.parse(location);
    }

    // Create issue
    const issue = await Issue.create({
      citizenId: (req as any).citizenId,
      issueType,
      title,
      description,
      latitude: parsedLocation.latitude,
      longitude: parsedLocation.longitude,
      address: parsedLocation.address,
      status: 'Reported',
    });

    // Create multimedia records
    const mediaDocs = await Promise.all(
      files.map((file) =>
        Multimedia.create({
          issueId: issue.id,
          fileType: file.mimetype.startsWith('video') ? 'video' : 'image',
          url: file.path,
          filename: file.originalname,
        })
      )
    );

    res.status(200).json({ message: 'Issue created', issue, media: mediaDocs });
  } catch (error) {
    console.error('Error creating issue:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getIssues = async (req: Request, res: Response) => {
  try {
    const issues = await Issue.findAll({
      include: [
        { model: Citizen, attributes: ['fullName'] },
      ],
    });

    const issuesWithMedia = await Promise.all(
      issues.map(async (issue) => {
        const media = await Multimedia.findAll({
          where: { issueId: issue.id },
        });

        return {
          _id: issue.id,
          title: issue.title,
          description: issue.description,
          type: issue.issueType,
          location: {
            latitude: issue.latitude,
            longitude: issue.longitude,
            address: issue.address,
          },
          reportedBy: issue.Citizen?.fullName || 'Anonymous',
          reportedAt: issue.createdAt,
          image: media.length > 0 ? media[0].url : null,
          status: issue.status,
        };
      })
    );

    res.json({ issues: issuesWithMedia });
  } catch (error) {
    console.error('Error fetching issues:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
```

---

## **STEP 7: Update App Initialization (2 minutes)**

Update `src/index.ts`:

**Old:**
```typescript
import { connectDB } from "./config/database";

connectDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server running on port: ${PORT}`);
    });
  })
  .catch((error) => {
    console.log("MongoDB connection failed!", error);
    process.exit(1);
  });
```

**New (Sequelize):**
```typescript
import { connectDB } from "./config/database";

connectDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server running on port: ${PORT}`);
    });
  })
  .catch((error) => {
    console.log("MySQL connection failed!", error);
    process.exit(1);
  });
```

---

## **STEP 8: Test Everything (15 minutes)**

### 8.1 Start the backend server:
```bash
cd C:\DBS_Project\backend
npm install  # (Install new dependencies)
npm start
```

### 8.2 Test API endpoints using Postman or curl:

**Test Signup:**
```bash
POST http://localhost:3000/api/v1/citizen/signup
Content-Type: application/json

{
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "phonenumber": "9876543210"
}
```

**Test Signin:**
```bash
POST http://localhost:3000/api/v1/citizen/signin
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Test Create Issue:**
```bash
POST http://localhost:3000/api/v1/citizen/create-issue
Content-Type: multipart/form-data
Authorization: Bearer {token_from_signin}

Body:
- title: "Pothole on Main Street"
- description: "Large pothole"
- issueType: "Road Infrastructure"
- location: {"latitude": 28.7041, "longitude": 77.1025, "address": "Delhi"}
- files: [image.jpg]
```

**Test Get Issues:**
```bash
GET http://localhost:3000/api/v1/all-issues
Authorization: Bearer {token_from_signin}
```

---

## **STEP 9: Verify in MySQL (Optional)**

Check if data is being saved:
```bash
mysql -u root -p civic_issue_db
```

```sql
SELECT * FROM citizens;
SELECT * FROM issues;
SELECT * FROM multimedia;
```

---

## **Summary Checklist**

- [ ] MySQL database created
- [ ] Tables created with SQL script
- [ ] MySQL driver installed (mysql2)
- [ ] ORM installed (Sequelize/Prisma/TypeORM)
- [ ] `.env` file updated with MySQL credentials
- [ ] `database.ts` updated for MySQL
- [ ] Models rewritten for MySQL
- [ ] Controllers updated to use new models
- [ ] `index.ts` updated
- [ ] Backend tested with Postman/curl
- [ ] Data verified in MySQL database
- [ ] Frontend still works (no changes needed)

---

## **Rollback Plan (If needed)**

Keep `.env.mongodb` backup to switch back:
```bash
# To go back to MongoDB
SET DATABASE_TYPE=mongodb
npm install mongoose
# Use old config/database.ts
```

---

## **Common Errors & Solutions**

### Error: `Access denied for user 'root'@'localhost'`
```bash
# Reset MySQL password
mysql -u root
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

### Error: `Table doesn't exist`
```bash
# Run the SQL table creation script again
mysql -u root -p civic_issue_db < schema.sql
```

### Error: `Foreign key constraint fails`
```sql
-- Check constraints
SHOW CREATE TABLE issues\G
-- Drop and recreate if needed
ALTER TABLE issues DROP FOREIGN KEY issues_ibfk_1;
```

---

You're ready to migrate! Follow these steps in order. 🚀
