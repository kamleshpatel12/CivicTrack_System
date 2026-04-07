import { Request, Response } from "express";
import jwt from "jsonwebtoken";
import { z } from "zod";
import bcrypt from "bcryptjs";
import { queryOne, insert } from "../../utils/db";

const signupSchema = z.object({
  fullName: z.string().min(1, { message: "Full name is required" }).trim(),
  password: z
    .string()
    .min(4, { message: "Password must be at least 4 characters" })
    .trim(),
  email: z.string().email({ message: "Invalid email format" }).trim(),
  phonenumber: z
    .string()
    .length(10, { message: "Phone number must be exactly 10 digits" })
    .trim(),
  department: z.string().trim().optional(),
  employeeId: z.string().min(3, { message: "Employee ID is required" }).trim(),
  isHeadAdmin: z.boolean().optional().default(false),
});

export const adminSignup = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const parsedData = signupSchema.parse(req.body);
    const {
      fullName,
      password,
      email,
      phonenumber,
      department,
      employeeId,
      isHeadAdmin,
    } = parsedData;

    // SQL: Check if the admin already exists
    const existingUser = await queryOne(
      "SELECT id FROM admins WHERE email = ? OR employee_id = ?",
      [email, employeeId]
    );
    if (existingUser) {
      res.status(400).json({ message: "User already exists" });
      return;
    }

    // SQL: Get department ID (only required for regular admins)
    let departmentId = null;
    if (!isHeadAdmin && department) {
      const depResult = await queryOne(
        "SELECT id FROM department WHERE department_name = ? LIMIT 1",
        [department]
      );
      departmentId = depResult?.id || null;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // SQL: Create new admin
    const adminId = await insert(
      "INSERT INTO admins (full_name, email, phone_number, password, department_id, employee_id, is_active) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [fullName, email, phonenumber, hashedPassword, departmentId, employeeId, true]
    );

    // If head admin, insert into head_admin table
    if (isHeadAdmin) {
      await insert(
        "INSERT INTO head_admin (admin_id) VALUES (?)",
        [adminId]
      );
    }

    console.log(`${isHeadAdmin ? 'Head Admin' : 'Admin'} created with ID:`, adminId);
    res.status(200).json({ 
      message: `${isHeadAdmin ? 'Head Admin' : 'Admin'} Signed up!`,
      adminId: adminId,
      isHeadAdmin: isHeadAdmin
    });
  } catch (err: any) {
    if (err.name === "ZodError") {
      res.status(400).json({
        message: "Validation failed",
        errors: err.errors,
      });
      return;
    }

    console.error("Error creating admin:", err);
    res
      .status(500)
      .json({ message: "Error creating admin account. Please try again." });
  }
};

export const adminSignin = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { email, password, employeeId } = req.body;

    // SQL: Find admin by email and employee_id with department info and check head admin table
    const existingUser = await queryOne(
      `SELECT 
        a.id, 
        a.full_name, 
        a.email, 
        a.phone_number, 
        a.password, 
        a.department_id,
        a.employee_id,
        CASE WHEN ha.admin_id IS NOT NULL THEN 1 ELSE 0 END as is_head_admin,
        d.department_name as department
      FROM admins a
      LEFT JOIN department d ON a.department_id = d.id
      LEFT JOIN head_admin ha ON a.id = ha.admin_id
      WHERE a.email = ? AND a.employee_id = ? AND a.is_active = TRUE`,
      [email, employeeId]
    );
    if (!existingUser) {
      res.status(404).json({ message: "Admin not found!" });
      return;
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, existingUser.password);
    if (!isPasswordValid) {
      res.status(401).json({ message: "Invalid password" });
      return;
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        id: existingUser.id,
        role: existingUser.is_head_admin ? "head-admin" : "admin",
      },
      process.env.JWT_PASSWORD!,
      { expiresIn: "1d" }
    );

    res.json({
      token,
      user: {
        id: existingUser.id,
        fullName: existingUser.full_name,
        email: existingUser.email,
        employeeId: existingUser.employee_id,
        department: existingUser.is_head_admin ? "Head Admin" : (existingUser.department || "Unknown"),
        phonenumber: existingUser.phone_number,
        role: existingUser.is_head_admin ? "head-admin" : "admin",
        isHeadAdmin: existingUser.is_head_admin,
      },
    });
  } catch (error) {
    console.error("Error during admin signin:", error);
    res.status(500).json({
      message: "Internal Server Error",
    });
  }
};
