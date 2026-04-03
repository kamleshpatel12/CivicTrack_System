import { useState } from "react";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Textarea } from "../components/ui/textarea";
import { Label } from "../components/ui/label";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "../components/ui/card";
import { RadioGroup, RadioGroupItem } from "../components/ui/radio-group";
import { ArrowLeft, Send } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { VITE_BACKEND_URL } from "../config/config";

const ReportIssue = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    title: "",
    issueDescription: "",
    issueCity: "",
    issueArea: "",
    issueType: "Pothole",
    location: {
      address: "",
      latitude: null as number | null,
      longitude: null as number | null,
    },
  });
  const [loading, setLoading] = useState(false);

  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (
      !formData.title ||
      !formData.issueDescription ||
      !formData.issueCity ||
      !formData.issueArea
    ) {
      toast.error("Please fill all required fields");
      return;
    }

    setLoading(true);
    try {
      const token = localStorage.getItem("auth_token");
      if (!token) {
        toast.error("You must be logged in");
        return;
      }

      const address = `${formData.issueArea}, ${formData.issueCity}`;

      const response = await fetch(
        `${VITE_BACKEND_URL}/api/v1/citizen/create-issue`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            title: formData.title,
            description: formData.issueDescription,
            issueType: formData.issueType,
            address: address,
          }),
        }
      );

      const result = await response.json();
      if (response.ok) {
        toast.success("Issue reported successfully!");
        navigate("/citizen");
      } else {
        toast.error(result.message || "Failed to report issue");
      }
    } catch (error) {
      console.error("Error reporting issue:", error);
      toast.error("Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  const issueTypes = [
    { value: "Pothole", label: "Pothole" },
    { value: "Water Leakage", label: "Water Leakage" },
    { value: "Garbage Accumulation", label: "Garbage Accumulation" },
    {
      value: "Street Light Malfunction",
      label: "Street Light Malfunction",
    },
    { value: "Drainage Blockage", label: "Drainage Blockage" },
  ];

  return (
    <div className="min-h-screen bg-[#f3f6f8]">
      {/* Header */}
      <header className="w-full border-b bg-white/10 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            <div className="flex items-center space-x-4">
              <Link to="/citizen">
                <Button
                  variant="ghost"
                  size="sm"
                  className="flex items-center space-x-2 text-slate-500"
                >
                  <ArrowLeft className="h-4 w-4 text-blue-600" />
                  <span>Back to Dashboard</span>
                </Button>
              </Link>
            </div>
            <div>
              <h1 className="text-xl font-bold text-cyan-600">
                Report New Issue
              </h1>
            </div>
            <div className="w-24"></div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-2xl mx-auto">
          {/* Form Section */}
          <Card className="shadow-lg bg-white/80  text-slate-600">
            <CardHeader>
              <CardTitle>Issue Details</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Personal Information */}

                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="title">Issue Title *</Label>
                    <Input
                      id="title"
                      type="text"
                      value={formData.title}
                      onChange={(e) =>
                        handleInputChange("title", e.target.value)
                      }
                      placeholder="Enter your issue title"
                      required
                      className="shadow-sm"
                    />
                  </div>
                </div>

                {/* Issue Information */}

                <div className="space-y-4">
                  <h3 className="text-lg font-medium">Issue Information</h3>

                  <div className="space-y-2">
                    <Label>Issue Type *</Label>
                    <RadioGroup
                      value={formData.issueType}
                      onValueChange={(value) =>
                        handleInputChange("issueType", value)
                      }
                      className="grid grid-cols-2 gap-4"
                    >
                      {issueTypes.map((type) => (
                        <div
                          key={type.value}
                          className="flex items-center space-x-2"
                        >
                          <RadioGroupItem value={type.value} id={type.value} />
                          <Label htmlFor={type.value} className="text-sm">
                            {type.label}
                          </Label>
                        </div>
                      ))}
                    </RadioGroup>
                  </div>

                  <div className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="issueCity">City *</Label>
                      <Input
                        id="issueCity"
                        type="text"
                        value={formData.issueCity}
                        onChange={(e) =>
                          handleInputChange("issueCity", e.target.value)
                        }
                        placeholder="Enter city name"
                        className="shadow-sm"
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="issueArea">Area / Locality *</Label>
                      <Input
                        id="issueArea"
                        type="text"
                        value={formData.issueArea}
                        onChange={(e) =>
                          handleInputChange("issueArea", e.target.value)
                        }
                        placeholder="Enter area or locality"
                        className="shadow-sm"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="issueDescription">
                      Issue Description *
                    </Label>
                    <Textarea
                      id="issueDescription"
                      value={formData.issueDescription}
                      onChange={(e) =>
                        handleInputChange("issueDescription", e.target.value)
                      }
                      placeholder="Describe the issue in detail..."
                      className="min-h-24 shadow-sm"
                      required
                    />
                  </div>
                </div>

                {/* Submit Button */}

                <Button
                  type="submit"
                  className="w-full bg-blue-600 border-0 text-white hover:bg-blue-700"
                  disabled={loading}
                  size="lg"
                >
                  {loading ? (
                    "Submitting..."
                  ) : (
                    <>
                      <Send className="h-5 w-5 mr-2" /> Submit Issue
                    </>
                  )}
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  );
};

export default ReportIssue;
