#  Civic Issue Reporter - Full Stack Application

A complete, production-ready civic issue management platform built with React, Express.js, and MySQL. This system enables citizens to report civic issues with photo uploads, admins to manage them with advanced analytics, and head-admins to view comprehensive reports.

## ✨ Key Features

### 🏢 Complete Three-Tier Architecture
- **Frontend**: React 18 + TypeScript + Vite
- **Backend**: Express.js + Node.js + TypeScript
- **Database**: MySQL with 11 tables + Advanced features

### 👤 Citizen Features
- Secure JWT-based authentication
- Report issues with title, description, location, and category
- **Upload images for each issue** (stored in localStorage)
- Track issue status in real-time
- View personal issue history

### 🛡️ Admin Features
- Manage assigned issues and update statuses
- View department performance metrics
- Prioritize urgent issues
- See images attached to reports
- Track workload distribution

### 👑 Head-Admin Features
- View all system issues
- Access comprehensive analytics
- Monitor department performance
- View high-priority issues across departments
- Review admin workload

### 📊 Advanced Database Features
- **10 Stored Procedures** for automation
- **2 Cursor Implementations** for row-by-row processing
- **3 Database Views** for simplified queries
- **5 Nested Subqueries** for complex analytics
- **4 Active Triggers** for data integrity

### 📸 Image Management
- Upload images when reporting issues
- Images stored in browser localStorage (no database required)
- Display thumbnails in dashboards
- Full image preview in modals

### 📈 Analytics & Reporting
- Department performance reports
- Monthly issue statistics
- Problem area identification
- Admin workload distribution
- Citizen activity tracking

---

## 🚀 Quick Start (3 Steps)

### Step 1: Start Database
```bash
mysql -u root -p
USE civic_issue_db;
SOURCE c:/DBS_Project/database/advanced_features.sql;
```

### Step 2: Start Backend
```bash
cd backend
npm install
npm run dev
```

### Step 3: Start Frontend
```bash
cd frontend
npm run dev
```

**Access**: http://localhost:5173

**Full Guide**: See `QUICKSTART.md`

---

## 📁 Project Structure

```
DBS_Project/
├── frontend/               # React application
│   ├── src/
│   │   ├── pages/         # Page components
│   │   ├── components/    # Reusable components
│   │   ├── contexts/      # Auth & Loader contexts
│   │   └── config/        # Configuration
│   └── package.json
│
├── backend/               # Express.js server
│   ├── src/
│   │   ├── controllers/   # 4 controllers (13 analytics endpoints)
│   │   ├── routes/        # 4 route files
│   │   ├── config/        # Database & Cloudinary config
│   │   ├── middleware/    # Auth & upload middleware
│   │   └── app.ts         # Main application file
│   └── package.json
│
├── database/              # MySQL database
│   ├── advanced_features.sql              # Procedures, views, cursors
│   ├── TEST_FEATURES.sql                  # Database test script
│   ├── ADVANCED_FEATURES_DOCUMENTATION.md # Database docs
│   └── QUICK_REFERENCE.md
│
├── QUICKSTART.md                    # 3-step startup guide
├── INTEGRATION_COMPLETE.md          # Detailed setup guide
├── INTEGRATION_SUMMARY.md           # What's implemented
├── TEACHER_PRESENTATION_GUIDE.md    # Demo script (15-20 min)
└── README.md                        # This file
```

---

## 🛠️ Technology Stack

### Frontend
- React 18
- TypeScript
- Vite
- TailwindCSS
- Framer Motion
- React Router v6

### Backend
- Node.js
- Express.js
- TypeScript
- MySQL2 (pool-based)
- JWT (authentication)
- bcrypt (password hashing)

### Database
- MySQL/MariaDB
- 11 normalized tables
- 10 stored procedures
- 3 views with subqueries
- 2 cursor implementations
- 4 active triggers

---

## 🔐 Authentication

### Three User Roles
- **Citizen**: Report issues, upload images, track progress
- **Admin**: Manage assigned issues, update statuses, view images
- **Head-Admin**: View all issues, analytics, reports

### Security
- JWT tokens (24-hour expiry)
- bcrypt password hashing
- Protected routes with auth middleware
- CORS configuration for development

---

## 📊 Analytics Features (13 API Endpoints)

All accessible at `http://localhost:3000/api/v1/analytics/*`

### GET Endpoints
- `/department-performance` - Department metrics
- `/monthly-stats?year=YYYY&month=MM` - Monthly breakdown
- `/high-priority/:deptId` - Urgent issues by department
- `/location/:city` - Issues by location
- `/problem-areas` - Hotspot locations
- `/admin-workload` - Admin performance
- `/citizen/:email` - Citizen activity report
- `/view/high-priority` - High priority issues view
- `/view/dashboard` - Department dashboard view
- `/view/citizen-summary` - Citizen summary view

### POST Endpoints
- `/auto-prioritize` - Auto-assign priority based on age
- `/bulk-update` - Batch update status with logging
- `/archive` - Archive resolved issues 90+ days old

---

## 🗄️ Database Schema

### 11 Tables
1. **citizens** - Citizen profiles
2. **admins** - Admin users
3. **department** - Departments
4. **civic_categories** - Issue types
5. **location** - Geographic locations
6. **issues** - Reported issues (core table)
7. **issue_status** - Issue status history
8. **issue_history** - Change audit log
9. **audit_logs** - System audit trail
10. **triggers_log** - Trigger execution log
11. **rejected_reason** - Rejection reasons

### 10 Stored Procedures
1. `sp_department_performance_report()` - Department metrics
2. `sp_auto_assign_priority()` - Auto-prioritize by age
3. `sp_get_high_priority_issues(dept_id)` - Get urgent issues
4. `sp_monthly_issue_statistics(year, month)` - Monthly stats
5. `sp_bulk_update_status(status, count)` - **CURSOR** - Batch update with logging
6. `sp_get_issues_by_location(city)` - Issues by city
7. `sp_archive_resolved_issues()` - **CURSOR** - Archive old issues
8. `sp_citizen_activity_report(email)` - Citizen profile
9. `sp_identify_problem_areas()` - Find hotspots
10. `sp_admin_workload_distribution()` - Admin rankings

### 3 Database Views
1. `vw_unresolved_high_priority` - Urgent issues
2. `vw_department_dashboard` - Department metrics
3. `vw_citizen_issues_summary` - Citizen activity

**Detailed Documentation**: See `database/ADVANCED_FEATURES_DOCUMENTATION.md`

---

## 📸 Image Upload Feature

### How It Works
1. User selects image in "Report Issue" form
2. Image is converted to Base64
3. Stored in browser localStorage (key: `issue_images`)
4. Mapped by issue ID for retrieval
5. Displayed in all dashboards

### Technical Details
- Supported formats: JPG, PNG, GIF, WebP
- Max size: 5MB
- Storage: localStorage (no database)
- Persists across browser refresh

### Where Used
- **CitizenHome**: Shows issue thumbnail
- **AdminHome**: Shows thumbnail in table + full in modal
- **HeadAdminHome**: Shows thumbnail + full image
- **ReportIssue**: Image preview before upload

---

## 🧪 Testing

### Database Testing
```bash
# Run in MySQL client
SOURCE database/TEST_FEATURES.sql;
```

Verifies:
- All 10 procedures work
- All 3 views return data
- Both cursors execute correctly
- 5 nested queries return results

### API Testing

**Using curl or Postman**:
```bash
# Department Performance
curl http://localhost:3000/api/v1/analytics/department-performance

# Monthly Stats
curl "http://localhost:3000/api/v1/analytics/monthly-stats?year=2026&month=1"

# High Priority Issues
curl http://localhost:3000/api/v1/analytics/high-priority/1
```

### Frontend Testing
1. Navigate to http://localhost:5173
2. Sign up as citizen
3. Go to "Report Issue"
4. Upload an image
5. Check dashboard - image displays ✅

---

## 🎓 Teacher Presentation

This system demonstrates:

1. **Stored Procedures** - Automated business logic in SQL
2. **Nested Subqueries** - Dynamic calculations without JOINs
3. **Cursors** - Row-by-row processing with logging capability
4. **Database Views** - Simplified complex queries
5. **Full Integration** - Frontend → API → Database

**Presentation Guide**: See `TEACHER_PRESENTATION_GUIDE.md`  
**Demo Duration**: 15-20 minutes with Q&A

---

## 📝 Documentation Files

- **QUICKSTART.md** - 3-step startup guide (read first!)
- **INTEGRATION_COMPLETE.md** - Complete setup and testing guide
- **INTEGRATION_SUMMARY.md** - What's implemented checklist
- **TEACHER_PRESENTATION_GUIDE.md** - 20-minute demo script
- **ADVANCED_FEATURES_DOCUMENTATION.md** - Database feature details
- **database/TEST_FEATURES.sql** - SQL test script
- **database/QUICK_REFERENCE.md** - Procedure usage examples
- **IMPLEMENTATION_COMPLETE.md** - Phase 1 documentation
- **DATABASE_SCHEMA_COMPLETE.md** - Original schema design

---

## 🚨 Troubleshooting

### Backend won't start?
```bash
# Check dependencies
npm install

# Check port 3000 is free
netstat -ano | findstr :3000
```

### Database procedures not found?
```bash
# Reload procedures
mysql -u root -p civic_issue_db < database/advanced_features.sql
```

### Images not showing?
- Check browser console for errors
- Check localStorage: DevTools → Application → Storage → localStorage

### API returns 404?
- Restart backend: `npm run dev`
- Verify `analytics.routes.ts` is imported in `app.ts`

---

## 📊 System Status

✅ **Fully Integrated and Production Ready**

- ✅ All 13 API endpoints working
- ✅ All 10 database procedures functional
- ✅ Image upload end-to-end working
- ✅ Three-tier authentication verified
- ✅ All documentation complete
- ✅ Database tests passing
- ✅ Ready for teacher presentation

---

## 🎉 Next Steps

1. **Start the system**: Use `QUICKSTART.md`
2. **Run database tests**: Execute `database/TEST_FEATURES.sql`
3. **Test APIs**: Use curl or Postman with endpoint examples
4. **Try frontend**: Upload images and view in dashboards
5. **Present to teacher**: Follow `TEACHER_PRESENTATION_GUIDE.md`

---

## 📞 Support

- **Startup Issues**: See QUICKSTART.md
- **Integration Questions**: See INTEGRATION_COMPLETE.md
- **Database Features**: See ADVANCED_FEATURES_DOCUMENTATION.md
- **What's Implemented**: See INTEGRATION_SUMMARY.md
- **Database Tests**: Run database/TEST_FEATURES.sql

---

**Built with ❤️ - Complete, documented, and ready to present!**

*Last Updated: 2026-01-15*






