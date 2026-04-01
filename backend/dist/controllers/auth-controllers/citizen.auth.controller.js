"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.citizenSignin = exports.citizenSignup = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const db_1 = require("../../utils/db");
const zod_1 = require("zod");
const signupSchema = zod_1.z.object({
    fullName: zod_1.z.string().min(1, { message: "Full name is required" }).trim(),
    password: zod_1.z
        .string()
        .min(8, { message: "Password must be at least 8 characters" })
        .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/, {
        message: "Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character",
    })
        .trim(),
    email: zod_1.z.string().email({ message: "Invalid email format" }).trim(),
    phonenumber: zod_1.z
        .string()
        .length(10, { message: "Phone number must be exactly 10 digits" }),
});
const citizenSignup = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const parsedData = signupSchema.parse(req.body);
        const { fullName, password, email, phonenumber } = parsedData;
        // SQL: Check if citizen exists
        const existingCitizen = yield (0, db_1.queryOne)("SELECT id FROM citizens WHERE email = ?", [email]);
        if (existingCitizen) {
            res.status(400).json({ message: "Citizen already exists" });
            return;
        }
        // Hash password
        const hashedPassword = yield bcryptjs_1.default.hash(password, 10);
        // SQL: Insert new citizen
        yield (0, db_1.insert)("INSERT INTO citizens (full_name, email, phone_number, password) VALUES (?, ?, ?, ?)", [fullName, email, phonenumber, hashedPassword]);
        console.log("Citizen created!");
        res.status(201).json({ message: "Citizen Signed up!" });
    }
    catch (err) {
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
});
exports.citizenSignup = citizenSignup;
const citizenSignin = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { email, password } = req.body;
        // SQL: Find citizen by email
        const citizen = yield (0, db_1.queryOne)("SELECT id, full_name, email, phone_number, password FROM citizens WHERE email = ?", [email]);
        if (!citizen) {
            res.status(400).json({ message: "Invalid email or password" });
            return;
        }
        // Verify password
        const isPasswordValid = yield bcryptjs_1.default.compare(password, citizen.password);
        if (!isPasswordValid) {
            res.status(400).json({ message: "Invalid email or password" });
            return;
        }
        // Generate JWT
        const token = jsonwebtoken_1.default.sign({
            id: citizen.id,
            role: "citizen",
        }, process.env.JWT_PASSWORD, { expiresIn: "1d" });
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
    }
    catch (error) {
        console.error("Error during citizen signin:", error);
        res.status(500).json({
            message: "Internal Server Error",
        });
    }
});
exports.citizenSignin = citizenSignin;
