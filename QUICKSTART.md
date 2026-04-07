# 🚀 QUICK START GUIDE - Run Your System in 3 Steps

## Step 1️⃣: Start Database (30 seconds)
```bash
# Open MySQL
mysql -u root -p

# Then type:
USE civic_issue_db;
SOURCE c:/DBS_Project/database/advanced_features.sql;
```
No output needed, just verify no errors.

---

## Step 2️⃣: Start Backend (1 minute)
```bash
# Open Command Prompt, navigate to backend
cd c:\DBS_Project\backend

# First time only - install dependencies
npm install

# Start server
npm run dev
```

You should see:
```
Server running on port 3000
Database connected
```

---

## Step 3️⃣: Start Frontend (30 seconds)
```bash
# Open NEW Command Prompt window
cd c:\DBS_Project\frontend

npm run dev
```

You should see:
```
Local: http://localhost:5173
```

---

## ✅ System is Running!

Open: **http://localhost:5173**

---

## 🎯 Quick Test

### Test 1: Upload Image (1 minute)
1. Click "Sign In" → Create new citizen account
2. Click "Report Issue"
3. Fill form + **select an image**
4. Click "Report Issue"
5. Go to dashboard → See image displayed ✅

### Test 2: Check API (1 minute)
Open in browser:
```
http://localhost:3000/api/v1/analytics/department-performance
```

Should see JSON with department data ✅

### Test 3: Check Database (1 minute)
In MySQL:
```sql
CALL sp_department_performance_report();
```

Should show department metrics ✅

---

## 🎓 For Teacher Demo

### Show These 5 Key Queries:
```sql
-- 1. Procedures
CALL sp_department_performance_report();

-- 2. Cursors (check issue_history after)
CALL sp_bulk_update_status('Pending', 5);
SELECT * FROM issue_history ORDER BY created_at DESC LIMIT 5;

-- 3. Nested Query 1
SELECT c.full_name, (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) as total_reports FROM citizens c WHERE (SELECT COUNT(*) FROM issues WHERE citizen_id = c.id) > 0;

-- 4. Views
SELECT * FROM vw_department_dashboard;

-- 5. API Response
-- Go to browser: http://localhost:3000/api/v1/analytics/department-performance
```

---

## 📊 What Each Part Shows

| Component | Language | What It Does |
|-----------|----------|--------------|
| **Database** | SQL | Stores all data + procedures + views |
| **Backend** | Express.js | Calls procedures via API |
| **Frontend** | React | Upload images + display issues |
| **Image Storage** | localStorage | Saves images in browser (no DB) |

---

## 🆘 Troubleshooting

### Backend won't start?
```bash
# Check port is free
netstat -ano | findstr :3000

# If in use, kill the process or restart
```

### Database procedures not found?
```bash
# Reload in MySQL client
SOURCE c:/DBS_Project/database/advanced_features.sql;

# Verify
SHOW PROCEDURE STATUS WHERE db = 'civic_issue_db';
```

### Images not showing?
- Check browser console (F12)
- Check localStorage: Application → Storage → localStorage → `issue_images`

### API returns 404?
- Restart backend server: Ctrl+C then `npm run dev`
- Verify analytics.routes.ts imported in app.ts

---

## 📚 Full Documentation

- **Integration**: `INTEGRATION_COMPLETE.md` (detailed setup)
- **Teacher Guide**: `TEACHER_PRESENTATION_GUIDE.md` (5-20 min presentation)
- **DB Tests**: `database/TEST_FEATURES.sql` (verify all features)
- **DB Docs**: `database/ADVANCED_FEATURES_DOCUMENTATION.md` (detailed explanations)

---

## 🎉 You're Done!

All 3 components running = System is ready for demo/presentation! 🚀

**Questions? Check the full documentation files above.**
