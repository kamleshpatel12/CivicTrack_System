import { Request, Response } from "express";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import { queryOne, insert } from "../../utils/db";
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
    res
      .status(411)
      .json({ message: "Citizen already exists or another error occurred" });
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
