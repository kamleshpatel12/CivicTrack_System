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
} from "../components/ui/card";
import { Label } from "../components/ui/label";
import { Input } from "../components/ui/input";
import { Button } from "../components/ui/button";
import { useAuth } from "../contexts/AuthContext";
import { useLoader } from "../contexts/LoaderContext";

const SignIn = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [citizenForm, setCitizenForm] = useState({ email: "", password: "" });
  const [adminForm, setAdminForm] = useState({
    email: "",
    password: "",
    employeeId: "",
  });
  const [activeTab, setActiveTab] = useState<"citizen" | "admin">("citizen");

  const navigate = useNavigate();
  const { login } = useAuth();
  const { showLoader, hideLoader } = useLoader();

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    showLoader();

    const minLoaderDuration = new Promise((resolve) =>
      setTimeout(resolve, 2000)
    );

    try {
      let result: boolean;
      if (activeTab === "citizen") {
        result = await Promise.all([
          login(citizenForm.email, citizenForm.password, "citizen"),
          minLoaderDuration,
        ]).then(([res]) => res);
      } else {
        result = await Promise.all([
          login(
            adminForm.email,
            adminForm.password,
            "admin",
            adminForm.employeeId
          ),
          minLoaderDuration,
        ]).then(([res]) => res);
      }

      if (result === true) {
        toast.success("Sign In Successful!", {
          description:
            activeTab === "citizen"
              ? "Welcome back!"
              : "Welcome back, Administrator!",
        });
        navigate(activeTab === "citizen" ? "/citizen" : "/admin", {
          replace: true,
        });
      } else {
        toast.error("Sign In Failed!", {
          description: "Invalid credentials",
        });
        hideLoader();
      }
    } catch (error) {
      console.error(error);
      toast.error("Sign In Failed!", {
        description: "Something went wrong",
      });
      hideLoader();
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
              <center>Sign In</center>
            </CardTitle>
            <CardDescription>
              Access your account to report issues or manage community reports
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="border-b border-gray-200 mb-6">
              <div className="flex space-x-2">
                <button
                  onClick={() => setActiveTab("citizen")}
                  className={`px-4 py-2 font-medium transition-colors ${
                    activeTab === "citizen"
                      ? "text-black border-b-2 border-black"
                      : "text-gray-600 border-b-2 border-transparent"
                  }`}
                >
                  Citizen
                </button>
                <button
                  onClick={() => setActiveTab("admin")}
                  className={`px-4 py-2 font-medium transition-colors ${
                    activeTab === "admin"
                      ? "text-black border-b-2 border-black"
                      : "text-gray-600 border-b-2 border-transparent"
                  }`}
                >
                  Administrator
                </button>
              </div>
            </div>

            {activeTab === "citizen" && (
              <form onSubmit={handleSignIn} className="space-y-4">
                <div>
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
                </div>
                <div>
                  <Label htmlFor="citizen-password">Password</Label>
                  <div className="relative">
                    <Input
                      id="citizen-password"
                      type={showPassword ? "text" : "password"}
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
                      className="absolute right-0 top-0 h-full px-3 py-2"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </Button>
                  </div>
                </div>
                <Button type="submit" className="w-full">
                  Sign In as Citizen
                </Button>
              </form>
            )}

            {activeTab === "admin" && (
              <form onSubmit={handleSignIn} className="space-y-4">
                <div>
                  <Label htmlFor="admin-email">Email</Label>
                  <Input
                    id="admin-email"
                    type="email"
                    value={adminForm.email}
                    onChange={(e) =>
                      setAdminForm({
                        ...adminForm,
                        email: e.target.value,
                      })
                    }
                    required
                  />
                </div>
                <div>
                  <Label htmlFor="admin-password">Password</Label>
                  <div className="relative">
                    <Input
                      id="admin-password"
                      type={showPassword ? "text" : "password"}
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
                      className="absolute right-0 top-0 h-full px-3 py-2"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </Button>
                  </div>
                </div>
                <div>
                  <Label htmlFor="admin-code">Employee ID</Label>
                  <Input
                    id="admin-code"
                    value={adminForm.employeeId}
                    onChange={(e) =>
                      setAdminForm({
                        ...adminForm,
                        employeeId: e.target.value,
                      })
                    }
                    required
                  />
                </div>
                <Button type="submit" className="w-full">
                  Sign In as Administrator
                </Button>
              </form>
            )}

            <div className="mt-6 text-center">
              <p className="text-sm text-muted-foreground">
                Don{"'"}t have an account?{" "}
                <Link to="/signup" className="text-primary hover:underline">
                  Sign up here
                </Link>
              </p>
              <Link
                to="/"
                className="text-sm text-muted-foreground hover:text-primary"
              >
                ← Back to Home
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SignIn;
