import React, { useState } from "react";
import { Eye, EyeOff } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "sonner";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "../components/ui/card.tsx";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "../components/ui/tabs.tsx";
import { Label } from "../components/ui/label.tsx";
import { Input } from "../components/ui/input.tsx";
import { Button } from "../components/ui/button.tsx";
import { Checkbox } from "../components/ui/checkbox.tsx";
import { motion, AnimatePresence } from "framer-motion";
import { VITE_BACKEND_URL } from "../config/config.tsx";

const SignUp = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [citizenForm, setCitizenForm] = useState({
    fullName: "",
    email: "",
    phonenumber: "",
    password: "",
    confirmPassword: "",
    agreeToTerms: false,
  });
  const [adminForm, setAdminForm] = useState({
    fullName: "",
    email: "",
    phonenumber: "",
    department: "",
    employeeId: "",
    password: "",
    confirmPassword: "",
    agreeToTerms: false,
  });
  const [headAdminForm, setHeadAdminForm] = useState({
    fullName: "",
    email: "",
    phonenumber: "",
    employeeId: "",
    password: "",
    confirmPassword: "",
    agreeToTerms: false,
  });

  const [citizenErrors, setCitizenErrors] = useState<Record<string, string>>(
    {}
  );
  const [adminErrors, setAdminErrors] = useState<Record<string, string>>({});
  const [headAdminErrors, setHeadAdminErrors] = useState<Record<string, string>>({});

  const [activeTab, setActiveTab] = useState("citizen");
  const navigate = useNavigate();

  // Password validation: min 4 chars
  const validatePassword = (password: string) => {
    return password.length >= 4;
  };

  // Citizen signup handler
  const handleCitizenSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setCitizenErrors({});

    if (!validatePassword(citizenForm.password)) {
      toast.error(
        "Password must be at least 4 characters."
      );
      return;
    }
    if (citizenForm.password !== citizenForm.confirmPassword) {
      toast.error("Passwords do not match.");
      return;
    }
    if (!citizenForm.agreeToTerms) {
      toast.error("Please agree to the terms and conditions.");
      return;
    }
    if (
      citizenForm.phonenumber.trim().length !== 10 ||
      !/^\d{10}$/.test(citizenForm.phonenumber.trim())
    ) {
      toast.error("Phone number must be exactly 10 digits.");
      return;
    }

    try {
      const response = await fetch(
        `${VITE_BACKEND_URL}/api/v1/citizen/signup`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            fullName: citizenForm.fullName,
            email: citizenForm.email,
            password: citizenForm.password,
            phonenumber: citizenForm.phonenumber,
          }),
        }
      );

      const data = await response.json();

      if (response.ok) {
        toast.success("Registration Successful! You can now sign in.");
        navigate("/signin");
      } else if (data.errors && Array.isArray(data.errors)) {
        const errs: Record<string, string> = {};
        data.errors.forEach((err: any) => {
          if (err.path && err.path.length > 0) {
            errs[err.path[0]] = err.message;
          }
        });
        setCitizenErrors(errs);
      } else {
        toast.error(data.message || "Something went wrong! Please try again.");
      }
    } catch (error) {
      toast.error("Something went wrong! Please try again.");
      console.error(error);
    }
  };

  // Admin signup handler
  const handleAdminSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setAdminErrors({});

    if (!validatePassword(adminForm.password)) {
      toast.error(
        "Password must be at least 4 characters."
      );
      return;
    }
    if (adminForm.password !== adminForm.confirmPassword) {
      toast.error("Passwords do not match.");
      return;
    }
    if (!adminForm.agreeToTerms) {
      toast.error("Please agree to the terms and conditions.");
      return;
    }
    if (
      !adminForm.fullName.trim() ||
      !adminForm.email.trim() ||
      !adminForm.phonenumber.trim() ||
      !adminForm.department.trim() ||
      !adminForm.employeeId.trim()
    ) {
      toast.error("Please fill all required fields.");
      return;
    }
    if (
      adminForm.phonenumber.trim().length !== 10 ||
      !/^\d{10}$/.test(adminForm.phonenumber.trim())
    ) {
      toast.error("Phone number must be exactly 10 digits.");
      return;
    }
    if (adminForm.employeeId.trim().length < 3) {
      toast.error("Employee ID must be at least 3 characters.");
      return;
    }

    try {
      const response = await fetch(`${VITE_BACKEND_URL}/api/v1/admin/signup`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          fullName: adminForm.fullName,
          email: adminForm.email,
          password: adminForm.password,
          phonenumber: adminForm.phonenumber,
          department: adminForm.department,
          employeeId: adminForm.employeeId.trim(),
        }),
      });

      const data = await response.json();

      if (response.ok) {
        toast.success("Admin Registration Successful! Pending approval.");
        navigate("/signin");
      } else if (data.errors && Array.isArray(data.errors)) {
        const errs: Record<string, string> = {};
        data.errors.forEach((err: any) => {
          if (err.path && err.path.length > 0) {
            errs[err.path[0]] = err.message;
          }
        });
        setAdminErrors(errs);
      } else {
        toast.error(data.message || "Signup failed");
      }
    } catch (error) {
      toast.error("Something went wrong! Please try again.");
      console.error(error);
    }
  };

  // Head Admin signup handler
  const handleHeadAdminSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setHeadAdminErrors({});

    if (!validatePassword(headAdminForm.password)) {
      toast.error(
        "Password must be at least 4 characters."
      );
      return;
    }
    if (headAdminForm.password !== headAdminForm.confirmPassword) {
      toast.error("Passwords do not match.");
      return;
    }
    if (!headAdminForm.agreeToTerms) {
      toast.error("Please agree to the terms and conditions.");
      return;
    }
    if (
      !headAdminForm.fullName.trim() ||
      !headAdminForm.email.trim() ||
      !headAdminForm.phonenumber.trim() ||
      !headAdminForm.employeeId.trim()
    ) {
      toast.error("Please fill all required fields.");
      return;
    }
    if (
      headAdminForm.phonenumber.trim().length !== 10 ||
      !/^\d{10}$/.test(headAdminForm.phonenumber.trim())
    ) {
      toast.error("Phone number must be exactly 10 digits.");
      return;
    }
    if (headAdminForm.employeeId.trim().length < 3) {
      toast.error("Employee ID must be at least 3 characters.");
      return;
    }

    try {
      const response = await fetch(`${VITE_BACKEND_URL}/api/v1/admin/signup`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          fullName: headAdminForm.fullName,
          email: headAdminForm.email,
          password: headAdminForm.password,
          phonenumber: headAdminForm.phonenumber,
          employeeId: headAdminForm.employeeId.trim(),
          isHeadAdmin: true,
        }),
      });

      const data = await response.json();

      if (response.ok) {
        toast.success("Head Admin Registration Successful! Pending approval.");
        navigate("/signin?role=head-admin");
      } else if (data.errors && Array.isArray(data.errors)) {
        const errs: Record<string, string> = {};
        data.errors.forEach((err: any) => {
          if (err.path && err.path.length > 0) {
            errs[err.path[0]] = err.message;
          }
        });
        setHeadAdminErrors(errs);
      } else {
        toast.error(data.message || "Signup failed");
      }
    } catch (error) {
      toast.error("Something went wrong! Please try again.");
      console.error(error);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden">
      <div className="pointer-events-none fixed inset-0 -z-10 bg-[#f0f7f5]" />

      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Link to="/" className="inline-flex items-center space-x-2 mb-4 justify-center">
            <div>
              <h1 className="text-4xl font-extrabold text-foreground">
                CivicReport
              </h1>
            </div>
          </Link>
        </div>

        <Card className="rounded-2xl shadow-2xl bg-white border-0">
          <CardHeader>
            <CardTitle>
              <center>Create Account</center>
            </CardTitle>
            <CardDescription>
              Join our community to report issues and help build better cities
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Tabs value={activeTab} onValueChange={setActiveTab}>
              <TabsList className="grid w-full grid-cols-3 rounded-full bg-gray-100 p-1">
                <TabsTrigger
                  value="citizen"
                  className="rounded-full"
                >
                  Citizen
                </TabsTrigger>
                <TabsTrigger
                  value="admin"
                  className="rounded-full"
                >
                  Administrator
                </TabsTrigger>
                <TabsTrigger
                  value="head-admin"
                  className="rounded-full"
                >
                  Head Admin
                </TabsTrigger>
              </TabsList>

              {/* Citizen Tab Content */}
              <TabsContent value="citizen">
                <AnimatePresence mode="wait">
                  {activeTab === "citizen" && (
                    <motion.div
                      key="citizen-motion"
                      initial={{ opacity: 0, x: 32 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -32 }}
                      transition={{ duration: 0.33, ease: "easeOut" }}
                      className="mt-6"
                    >
                      <form
                        onSubmit={handleCitizenSignUp}
                        className="space-y-4"
                      >
                        <div className="space-y-2">
                          <Label htmlFor="citizen-fullName">Full Name</Label>
                          <Input
                            id="citizen-fullName"
                            value={citizenForm.fullName}
                            onChange={(e) =>
                              setCitizenForm({
                                ...citizenForm,
                                fullName: e.target.value,
                              })
                            }
                            required
                          />
                          {citizenErrors.fullName && (
                            <p className="text-red-600 text-sm">
                              {citizenErrors.fullName}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="citizen-email">Email</Label>
                          <Input
                            id="citizen-email"
                            type="email"
                            value={citizenForm.email}
                            onChange={(e) =>
                              setCitizenForm({
                                ...citizenForm,
                                email: e.target.value,
                              })
                            }
                            required
                          />
                          {citizenErrors.email && (
                            <p className="text-red-600 text-sm">
                              {citizenErrors.email}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="citizen-phone">Phone Number</Label>
                          <Input
                            id="citizen-phone"
                            type="tel"
                            value={citizenForm.phonenumber}
                            onChange={(e) =>
                              setCitizenForm({
                                ...citizenForm,
                                phonenumber: e.target.value,
                              })
                            }
                            required
                          />
                          {citizenErrors.phonenumber && (
                            <p className="text-red-600 text-sm">
                              {citizenErrors.phonenumber}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="citizen-password">Password</Label>
                          <div className="relative">
                            <Input
                              id="citizen-password"
                              type={showPassword ? "text" : "password"}
                              placeholder="Create a strong password"
                              value={citizenForm.password}
                              onChange={(e) =>
                                setCitizenForm({
                                  ...citizenForm,
                                  password: e.target.value,
                                })
                              }
                              required
                            />
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                              onClick={() => setShowPassword(!showPassword)}
                            >
                              {showPassword ? (
                                <EyeOff className="h-4 w-4" />
                              ) : (
                                <Eye className="h-4 w-4" />
                              )}
                            </Button>
                          </div>
                          {citizenErrors.password && (
                            <p className="text-red-600 text-sm">
                              {citizenErrors.password}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="citizen-confirmPassword">
                            Confirm Password
                          </Label>
                          <div className="relative">
                            <Input
                              id="citizen-confirmPassword"
                              type={showConfirmPassword ? "text" : "password"}
                              placeholder="Confirm your password"
                              value={citizenForm.confirmPassword}
                              onChange={(e) =>
                                setCitizenForm({
                                  ...citizenForm,
                                  confirmPassword: e.target.value,
                                })
                              }
                              required
                            />
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                              onClick={() =>
                                setShowConfirmPassword(!showConfirmPassword)
                              }
                            >
                              {showConfirmPassword ? (
                                <EyeOff className="h-4 w-4" />
                              ) : (
                                <Eye className="h-4 w-4" />
                              )}
                            </Button>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Checkbox
                            id="citizen-terms"
                            checked={citizenForm.agreeToTerms}
                            onCheckedChange={(checked) =>
                              setCitizenForm({
                                ...citizenForm,
                                agreeToTerms: checked as boolean,
                              })
                            }
                          />
                          <Label htmlFor="citizen-terms" className="text-sm">
                            I agree to the Terms and Conditions
                          </Label>
                          {citizenErrors.agreeToTerms && (
                            <p className="text-red-600 text-sm">
                              {citizenErrors.agreeToTerms}
                            </p>
                          )}
                        </div>
                        <Button
                          type="submit"
                          className="w-full"
                        >
                          Create Citizen Account
                        </Button>
                      </form>
                    </motion.div>
                  )}
                </AnimatePresence>
              </TabsContent>

              {/* Admin Tab Content */}

              <TabsContent value="admin">
                <AnimatePresence mode="wait">
                  {activeTab === "admin" && (
                    <motion.div
                      key="admin-motion"
                      initial={{ opacity: 0, x: 32 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -32 }}
                      transition={{ duration: 0.33, ease: "easeOut" }}
                      className="mt-6"
                    >
                      <form onSubmit={handleAdminSignUp} className="space-y-4">
                        <div className="space-y-2">
                          <Label htmlFor="admin-fullName">Full Name</Label>
                          <Input
                            id="admin-fullName"
                            value={adminForm.fullName}
                            onChange={(e) =>
                              setAdminForm({
                                ...adminForm,
                                fullName: e.target.value,
                              })
                            }
                            required
                          />
                          {adminErrors.fullName && (
                            <p className="text-red-600 text-sm">
                              {adminErrors.fullName}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="admin-email">Official Email</Label>
                          <Input
                            id="admin-email"
                            type="email"
                            placeholder="admin@city.gov"
                            value={adminForm.email}
                            onChange={(e) =>
                              setAdminForm({
                                ...adminForm,
                                email: e.target.value,
                              })
                            }
                            required
                          />
                          {adminErrors.email && (
                            <p className="text-red-600 text-sm">
                              {adminErrors.email}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="admin-phone">Phone Number</Label>
                          <Input
                            id="admin-phone"
                            type="tel"
                            value={adminForm.phonenumber}
                            onChange={(e) =>
                              setAdminForm({
                                ...adminForm,
                                phonenumber: e.target.value,
                              })
                            }
                            required
                          />
                          {adminErrors.phonenumber && (
                            <p className="text-red-600 text-sm">
                              {adminErrors.phonenumber}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="admin-department">Department</Label>
                          <select
                            id="admin-department"
                            value={adminForm.department}
                            onChange={(e) =>
                              setAdminForm({
                                ...adminForm,
                                department: e.target.value,
                              })
                            }
                            required
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                          >
                            <option value="">Select Department</option>
                            <option value="Roads & Infrastructure">Roads & Infrastructure</option>
                            <option value="Water Supply">Water Supply</option>
                            <option value="Sanitation">Sanitation</option>
                            <option value="Public Lighting">Public Lighting</option>
                            <option value="Others">Others</option>
                          </select>
                          {adminErrors.department && (
                            <p className="text-red-600 text-sm">
                              {adminErrors.department}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="employee-id">Employee ID</Label>
                          <Input
                            id="employee-id"
                            type="text"
                            placeholder="Enter your Employee ID"
                            value={adminForm.employeeId}
                            onChange={(e) =>
                              setAdminForm({
                                ...adminForm,
                                employeeId: e.target.value,
                              })
                            }
                            required
                          />
                          {adminErrors.employeeId && (
                            <p className="text-red-600 text-sm">
                              {adminErrors.employeeId}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="admin-password">Password</Label>
                          <div className="relative">
                            <Input
                              id="admin-password"
                              type={showPassword ? "text" : "password"}
                              placeholder="Create a strong password"
                              value={adminForm.password}
                              onChange={(e) =>
                                setAdminForm({
                                  ...adminForm,
                                  password: e.target.value,
                                })
                              }
                              required
                            />
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                              onClick={() => setShowPassword(!showPassword)}
                            >
                              {showPassword ? (
                                <EyeOff className="h-4 w-4" />
                              ) : (
                                <Eye className="h-4 w-4" />
                              )}
                            </Button>
                          </div>
                          {adminErrors.password && (
                            <p className="text-red-600 text-sm">
                              {adminErrors.password}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="admin-confirmPassword">
                            Confirm Password
                          </Label>
                          <div className="relative">
                            <Input
                              id="admin-confirmPassword"
                              type={showConfirmPassword ? "text" : "password"}
                              placeholder="Confirm your password"
                              value={adminForm.confirmPassword}
                              onChange={(e) =>
                                setAdminForm({
                                  ...adminForm,
                                  confirmPassword: e.target.value,
                                })
                              }
                              required
                            />
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                              onClick={() =>
                                setShowConfirmPassword(!showConfirmPassword)
                              }
                            >
                              {showConfirmPassword ? (
                                <EyeOff className="h-4 w-4" />
                              ) : (
                                <Eye className="h-4 w-4" />
                              )}
                            </Button>
                          </div>
                          {adminErrors.confirmPassword && (
                            <p className="text-red-600 text-sm">
                              {adminErrors.confirmPassword}
                            </p>
                          )}
                        </div>
                        <div className="flex items-center space-x-2">
                          <Checkbox
                            id="admin-terms"
                            checked={adminForm.agreeToTerms}
                            onCheckedChange={(checked) =>
                              setAdminForm({
                                ...adminForm,
                                agreeToTerms: checked as boolean,
                              })
                            }
                          />
                          <Label htmlFor="admin-terms" className="text-sm">
                            I agree to the Terms and Conditions
                          </Label>
                          {adminErrors.agreeToTerms && (
                            <p className="text-red-600 text-sm">
                              {adminErrors.agreeToTerms}
                            </p>
                          )}
                        </div>
                        <Button
                          type="submit"
                          className="w-full"
                        >
                          Create Admin Account
                        </Button>
                      </form>
                    </motion.div>
                  )}
                </AnimatePresence>
              </TabsContent>

              <div className="mt-6 text-center">
                <p className="text-sm text-muted-foreground">
                  Already have an account?{" "}
                  <Link to="/signin" className="text-primary hover:underline">
                    Sign in here
                  </Link>
                </p>
                <Link
                  to="/"
                  className="text-sm text-muted-foreground hover:text-primary"
                >
                  ← Back to Home
                </Link>
              </div>

              {/* Head Admin Tab Content */}
              <TabsContent value="head-admin">
                <AnimatePresence mode="wait">
                  {activeTab === "head-admin" && (
                    <motion.div
                      key="head-admin-motion"
                      initial={{ opacity: 0, x: 32 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -32 }}
                      transition={{ duration: 0.33, ease: "easeOut" }}
                      className="mt-6"
                    >
                      <form
                        onSubmit={handleHeadAdminSignUp}
                        className="space-y-4"
                      >
                        <div className="space-y-2">
                          <Label htmlFor="head-admin-fullName">Full Name</Label>
                          <Input
                            id="head-admin-fullName"
                            value={headAdminForm.fullName}
                            onChange={(e) =>
                              setHeadAdminForm({
                                ...headAdminForm,
                                fullName: e.target.value,
                              })
                            }
                            required
                          />
                          {headAdminErrors.fullName && (
                            <p className="text-red-600 text-sm">
                              {headAdminErrors.fullName}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="head-admin-email">Email</Label>
                          <Input
                            id="head-admin-email"
                            type="email"
                            value={headAdminForm.email}
                            onChange={(e) =>
                              setHeadAdminForm({
                                ...headAdminForm,
                                email: e.target.value,
                              })
                            }
                            required
                          />
                          {headAdminErrors.email && (
                            <p className="text-red-600 text-sm">
                              {headAdminErrors.email}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="head-admin-phone">Phone Number</Label>
                          <Input
                            id="head-admin-phone"
                            value={headAdminForm.phonenumber}
                            onChange={(e) =>
                              setHeadAdminForm({
                                ...headAdminForm,
                                phonenumber: e.target.value,
                              })
                            }
                            required
                          />
                          {headAdminErrors.phonenumber && (
                            <p className="text-red-600 text-sm">
                              {headAdminErrors.phonenumber}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="head-admin-employeeId">Officer ID</Label>
                          <Input
                            id="head-admin-employeeId"
                            value={headAdminForm.employeeId}
                            onChange={(e) =>
                              setHeadAdminForm({
                                ...headAdminForm,
                                employeeId: e.target.value,
                              })
                            }
                            required
                          />
                          {headAdminErrors.employeeId && (
                            <p className="text-red-600 text-sm">
                              {headAdminErrors.employeeId}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="head-admin-password">Password</Label>
                          <div className="relative">
                            <Input
                              id="head-admin-password"
                              type={showPassword ? "text" : "password"}
                              value={headAdminForm.password}
                              onChange={(e) =>
                                setHeadAdminForm({
                                  ...headAdminForm,
                                  password: e.target.value,
                                })
                              }
                              required
                            />
                            <button
                              type="button"
                              onClick={() => setShowPassword(!showPassword)}
                              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500"
                            >
                              {showPassword ? (
                                <EyeOff className="w-4 h-4" />
                              ) : (
                                <Eye className="w-4 h-4" />
                              )}
                            </button>
                          </div>
                          {headAdminErrors.password && (
                            <p className="text-red-600 text-sm">
                              {headAdminErrors.password}
                            </p>
                          )}
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="head-admin-confirm-password">
                            Confirm Password
                          </Label>
                          <div className="relative">
                            <Input
                              id="head-admin-confirm-password"
                              type={showConfirmPassword ? "text" : "password"}
                              value={headAdminForm.confirmPassword}
                              onChange={(e) =>
                                setHeadAdminForm({
                                  ...headAdminForm,
                                  confirmPassword: e.target.value,
                                })
                              }
                              required
                            />
                            <button
                              type="button"
                              onClick={() =>
                                setShowConfirmPassword(!showConfirmPassword)
                              }
                              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500"
                            >
                              {showConfirmPassword ? (
                                <EyeOff className="w-4 h-4" />
                              ) : (
                                <Eye className="w-4 h-4" />
                              )}
                            </button>
                          </div>
                          {headAdminErrors.confirmPassword && (
                            <p className="text-red-600 text-sm">
                              {headAdminErrors.confirmPassword}
                            </p>
                          )}
                        </div>
                        <div className="flex items-center space-x-2">
                          <Checkbox
                            id="head-admin-terms"
                            checked={headAdminForm.agreeToTerms}
                            onCheckedChange={(checked) =>
                              setHeadAdminForm({
                                ...headAdminForm,
                                agreeToTerms: checked as boolean,
                              })
                            }
                          />
                          <label
                            htmlFor="head-admin-terms"
                            className="text-sm text-gray-600 cursor-pointer"
                          >
                            I agree to the{" "}
                            <a href="#" className="text-primary font-semibold">
                              Terms and Conditions
                            </a>
                          </label>
                        </div>
                        <Button
                          type="submit"
                          className="w-full bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800"
                        >
                          Register as Head Admin
                        </Button>
                      </form>
                      <p className="text-center text-sm text-gray-600 mt-4">
                        Already have an account?{" "}
                        <Link
                          to="/signin"
                          className="text-primary font-semibold hover:underline"
                        >
                          Sign in
                        </Link>
                      </p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SignUp;
