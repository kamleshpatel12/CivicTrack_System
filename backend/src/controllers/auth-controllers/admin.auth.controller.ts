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
  adminAccessCode: z
    .number()
    .int()
    .min(1000, { message: "Admin access code must be at least 4 digits" }),
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
      adminAccessCode,
    } = parsedData;

    // SQL: Check if the admin already exists
    const existingUser = await queryOne(
      "SELECT id FROM admins WHERE email = ? OR admin_access_code = ?",
      [email, adminAccessCode]
    );
    if (existingUser) {
      res.status(400).json({ message: "User already exists" });
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // SQL: Create new admin
    await insert(
      "INSERT INTO admins (full_name, email, phone_number, password, department, admin_access_code) VALUES (?, ?, ?, ?, ?, ?)",
      [fullName, email, phonenumber, hashedPassword, department, adminAccessCode]
    );

    console.log("Admin created!");
    res.status(200).json({ message: "Admin Signed up!" });
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
      .status(411)
      .json({ message: "Admin already exists or another error occurred" });
  }
};

export const adminSignin = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { email, password, adminAccessCode } = req.body;

    // SQL: Find admin by email and access code
    const existingUser = await queryOne(
      "SELECT id, full_name, email, phone_number, password, department, admin_access_code FROM admins WHERE email = ? AND admin_access_code = ?",
      [email, adminAccessCode]
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
        adminAccessCode: existingUser.admin_access_code,
        department: existingUser.department,
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
