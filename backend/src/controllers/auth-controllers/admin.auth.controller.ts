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
  department: z.string().trim(),
  employeeId: z.string().min(3, { message: "Employee ID is required" }).trim(),
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

    // SQL: Get department ID (default to 1 if not found)
    const depResult = await queryOne(
      "SELECT id FROM departments WHERE department_name = ? LIMIT 1",
      [department]
    );
    const departmentId = depResult?.id || 1;

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // SQL: Create new admin
    const adminId = await insert(
      "INSERT INTO admins (full_name, email, phone_number, password, department_id, employee_id, is_active) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [fullName, email, phonenumber, hashedPassword, departmentId, employeeId, true]
    );

    console.log("Admin created with ID:", adminId);
    res.status(200).json({ 
      message: "Admin Signed up!",
      adminId: adminId
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

    // SQL: Find admin by email and employee_id with department info
    const existingUser = await queryOne(
      `SELECT 
        a.id, 
        a.full_name, 
        a.email, 
        a.phone_number, 
        a.password, 
        a.department_id,
        a.employee_id,
        d.department_name as department
      FROM admins a
      LEFT JOIN departments d ON a.department_id = d.id
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
        role: "admin",
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
        department: existingUser.department || "Unknown",
        phonenumber: existingUser.phone_number,
        role: "admin",
      },
    });
  } catch (error) {
    console.error("Error during admin signin:", error);
    res.status(500).json({
      message: "Internal Server Error",
    });
  }
};
