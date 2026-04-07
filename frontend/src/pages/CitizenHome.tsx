import { useEffect, useState } from "react";
import { Button } from "../components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "../components/ui/card";
import { Plus, MapPin, Clock, User } from "lucide-react";
import { Link } from "react-router-dom";
import { VITE_BACKEND_URL } from "../config/config";
import HeaderAfterAuth from "../components/HeaderAfterAuth";
import { motion } from "framer-motion";
import { useLoader } from "../contexts/LoaderContext";

interface Issues {
  id: string;
  title: string;
  description: string;
  type_name: string;
  address: string;
  full_name: string;
  created_at: string;
  status: string;
  image?: string;
}

const MIN_LOADER_DURATION = 2500; // Minimum loader display time (ms)

const CitizenHome = () => {
  const [reportedIssues, setReportedIssues] = useState<Issues[]>([]);
  const [loading, setLoading] = useState(true);
  const { hideLoader } = useLoader();

  useEffect(() => {
    const fetchIssues = async () => {
      const startTime = Date.now();

      try {
        const response = await fetch(`${VITE_BACKEND_URL}/api/v1/citizen/issues`, {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("auth_token")}`,
          },
        });

        const data = await response.json();
        let apiIssues: Issues[] = [];
        if (Array.isArray(data.issues)) {
          apiIssues = data.issues;
        }

        setReportedIssues(apiIssues);
      } catch (error) {
        console.error("Error fetching issues:", error);
      } finally {
        const elapsed = Date.now() - startTime;
        const delay = Math.max(MIN_LOADER_DURATION - elapsed, 0);

        setTimeout(() => {
          setLoading(false);
          hideLoader();
        }, delay);
      }
    };

    fetchIssues();
  }, [hideLoader]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "Rejected":
        return "bg-red-200/70 text-red-900";
      case "Pending":
        return "bg-yellow-200/70 text-yellow-900";
      case "Resolved":
        return "bg-green-200/70 text-green-900";
      case "In Progress":
        return "bg-blue-200/70 text-blue-900";
      default:
        return "bg-gray-200/70 text-gray-900";
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col justify-center items-center h-screen bg-white">
        <p className="text-muted-foreground">Loading issues...</p>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.6 }}
      className="min-h-screen bg-[#f3f6f8]"
    >
      <div className="min-h-screen bg-[#f3f6f8]">
        <HeaderAfterAuth />
        <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8 pt-20 space-y-10">
          {/* Top Bar: Report Button and Profile */}
          <div className="flex items-center gap-4">
            <Link to="/citizen/create-issue">
              <Button
                size="lg"
                className="bg-blue-600 text-white border-0 h-12 px-6 rounded-full shadow-lg hover:shadow-xl hover:scale-105 transition-transform duration-300 whitespace-nowrap"
              >
                <Plus className="h-5 w-5 mr-2" />
                Report Issue
              </Button>
            </Link>
            <Link to={`/citizen/profile`}>
              <Button
                variant="outline"
                className="flex items-center space-x-2 rounded-full shadow-sm hover:shadow-md transition-all text-slate-500"
              >
                <User className="h-4 w-4 text-purple-700" />
                <span>My Profile</span>
              </Button>
            </Link>
          </div>

          {/* Welcome Section */}
          <div>
            <h1 className="text-4xl font-extrabold text-[#0577b7] tracking-wide">
              Welcome, Citizen!
            </h1>
            <p className="text-gray-500 mt-2 text-base">
              Help improve your community by reporting issues
            </p>
          </div>

          <div>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-semibold text-sky-600">
                My Reported Issues
              </h2>
              <div className="text-sm text-gray-400">
                {reportedIssues.length} issue
                {reportedIssues.length !== 1 ? "s" : ""} found
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 max-h-[600px] overflow-y-auto">
              {reportedIssues.map((issue) => (
                <Card
                  key={issue.id}
                  className={`rounded-2xl bg-white/70 backdrop-blur-md border border-gray-200 shadow-md hover:shadow-xl hover:scale-[1.02] transition-all ${
                    issue.status === "Rejected"
                      ? "opacity-30 grayscale"
                      : "opacity-100"
                  }`}
                >
                  <div className="relative bg-gradient-to-r from-blue-100 to-purple-100 h-48 overflow-hidden rounded-t-2xl flex items-center justify-center">
                    {issue.image ? (
                      <img
                        src={issue.image}
                        alt={issue.title}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="text-center">
                        <p className="text-4xl mb-2">📋</p>
                        <p className="text-sm font-semibold text-gray-600">
                          {issue.type_name}
                        </p>
                      </div>
                    )}
                    <div
                      className={`absolute top-3 right-3 px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(
                        issue.status
                      )}`}
                    >
                      {issue.status}
                    </div>
                  </div>
                  <CardHeader className="pb-2">
                    <CardTitle className="text-lg text-gray-800">
                      {issue.title}
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-gray-500 text-sm mb-3 line-clamp-2">
                      {issue.description}
                    </p>
                    <div className="space-y-2 text-xs text-gray-500">
                      <div className="flex items-center space-x-2">
                        <MapPin className="h-3 w-3 text-gray-400" />
                        <span>{issue.address}</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <User className="h-3 w-3 text-gray-400" />
                        <span>Reported by {issue.full_name}</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Clock className="h-3 w-3 text-gray-400" />
                        <span>{new Date(issue.created_at).toLocaleDateString()}</span>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>

            {reportedIssues.length === 0 && (
              <div className="flex flex-col items-center justify-center text-center py-12">
                <p className="text-gray-400">
                  You haven't reported any issues yet.
                </p>
              </div>
            )}
          </div>
        </main>
      </div>
    </motion.div>
  );
};

export default CitizenHome;
