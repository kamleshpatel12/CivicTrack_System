import { useEffect, useState } from "react";
import { useAuth } from "../contexts/AuthContext";
import { useNavigate } from "react-router-dom";
import { VITE_BACKEND_URL } from "../config/config";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { LogOut, CheckCircle } from "lucide-react";

interface Issue {
  id: number;
  title: string;
  description: string;
  issue_type: string;
  city: string;
  area_name: string;
  status: string;
  priority_name?: string;
  citizen_name: string;
  department_name: string;
  assigned_to?: string;
  created_at: string;
}

const HeadAdminHome = () => {
  const { user, token, logout } = useAuth();
  const navigate = useNavigate();
  const [issues, setIssues] = useState<Issue[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedIssue, setSelectedIssue] = useState<Issue | null>(null);
  const [showPriorityModal, setShowPriorityModal] = useState(false);
  const [selectedPriority, setSelectedPriority] = useState("");
  const [assigningPriority, setAssigningPriority] = useState(false);
  const [filterStatus, setFilterStatus] = useState("All");
  const [stats, setStats] = useState({
    total: 0,
    reported: 0,
    pending: 0,
    inProgress: 0,
    resolved: 0,
  });

  useEffect(() => {
    if (user?.role !== "head-admin") {
      navigate("/");
      return;
    }

    fetchAllIssues();
  }, [user, token]);

  const fetchAllIssues = async () => {
    try {
      console.log("Fetching issues with token:", token ? "Present" : "Missing");
      const response = await fetch(`${VITE_BACKEND_URL}/api/v1/admin/head-admin-issues`, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      console.log("Response status:", response.status);

      if (!response.ok) {
        const errorData = await response.json();
        console.error("API Error:", response.status, errorData);
        setLoading(false);
        return;
      }

      const data = await response.json();
      console.log("Issues data received:", data);
      const issueList = data.issues || [];
      setIssues(issueList);

      // Calculate stats
      const totalIssues = issueList.length;
      const reportedCount = issueList.filter((i: Issue) => i.status === "Reported").length;
      const pendingCount = issueList.filter((i: Issue) => i.status === "Pending").length;
      const inProgressCount = issueList.filter((i: Issue) => i.status === "In Progress").length;
      const resolvedCount = issueList.filter((i: Issue) => i.status === "Resolved").length;

      setStats({
        total: totalIssues,
        reported: reportedCount,
        pending: pendingCount,
        inProgress: inProgressCount,
        resolved: resolvedCount,
      });
    } catch (error) {
      console.error("Error fetching issues:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  const openPriorityModal = (issue: Issue) => {
    setSelectedIssue(issue);
    setSelectedPriority(issue.priority_name || "");
    setShowPriorityModal(true);
  };

  const handleAssignPriority = async () => {
    if (!selectedIssue || !selectedPriority) return;

    setAssigningPriority(true);
    try {
      const response = await fetch(`${VITE_BACKEND_URL}/api/v1/admin/head/assign-priority`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          issueId: selectedIssue.id,
          priority: selectedPriority,
          remarks: `Priority assigned by Head Admin`,
        }),
      });

      if (response.ok) {
        alert("✓ Priority assigned successfully!");
        setShowPriorityModal(false);
        fetchAllIssues();
      } else {
        alert("Failed to assign priority");
      }
    } catch (error) {
      console.error("Error assigning priority:", error);
      alert("Error assigning priority");
    } finally {
      setAssigningPriority(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "Reported":
        return "bg-blue-100 text-blue-800";
      case "Pending":
        return "bg-yellow-100 text-yellow-800";
      case "In Progress":
        return "bg-purple-100 text-purple-800";
      case "Resolved":
        return "bg-green-100 text-green-800";
      case "Rejected":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority?.toLowerCase()) {
      case "high":
        return "bg-red-100 text-red-800";
      case "medium":
        return "bg-orange-100 text-orange-800";
      case "low":
        return "bg-green-100 text-green-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const filteredIssues =
    filterStatus === "All"
      ? issues
      : issues.filter((i) => i.status === filterStatus);

  if (loading) {
    return <div className="text-center py-10">Loading issues...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation Header */}
      <nav className="bg-white shadow-sm border-b border-gray-200 p-4">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">
              CivicTrack - Head Admin
            </h2>
            <p className="text-sm text-gray-600">
              Welcome, {user?.fullName || "Head Admin"}
            </p>
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center gap-2 px-4 py-2 text-red-600 hover:bg-red-50 rounded-lg transition"
          >
            <LogOut size={18} />
            Logout
          </button>
        </div>
      </nav>

      <div className="p-6">
        <div className="max-w-7xl mx-auto">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              Issue Management Dashboard
            </h1>
            <p className="text-gray-600">
              View all citizen issues and assign priorities for admin teams to
              resolve
            </p>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-8">
            <Card>
              <CardHeader className="py-3">
                <CardTitle className="text-sm">Total Issues</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-blue-600">{stats.total}</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="py-3">
                <CardTitle className="text-sm">Reported</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-orange-600">
                  {stats.reported}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="py-3">
                <CardTitle className="text-sm">Pending</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-yellow-600">
                  {stats.pending}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="py-3">
                <CardTitle className="text-sm">In Progress</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-purple-600">
                  {stats.inProgress}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="py-3">
                <CardTitle className="text-sm">Resolved</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-green-600">
                  {stats.resolved}
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Filter Buttons */}
          <div className="mb-6 flex gap-2 flex-wrap">
            {["All", "Reported", "Pending", "In Progress", "Resolved"].map(
              (status) => (
                <button
                  key={status}
                  onClick={() => setFilterStatus(status)}
                  className={`px-4 py-2 rounded-lg font-medium transition ${
                    filterStatus === status
                      ? "bg-blue-600 text-white"
                      : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  {status}
                </button>
              )
            )}
          </div>

          {/* All Issues Table */}
          <Card>
            <CardHeader>
              <CardTitle className="text-xl">
                All Issues ({filteredIssues.length} total)
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-100 border-b">
                    <tr>
                      <th className="px-4 py-3 text-left font-semibold">
                        Issue
                      </th>
                      <th className="px-4 py-3 text-left font-semibold">Type</th>
                      <th className="px-4 py-3 text-left font-semibold">
                        Location
                      </th>
                      <th className="px-4 py-3 text-left font-semibold">
                        Reported By
                      </th>
                      <th className="px-4 py-3 text-left font-semibold">
                        Status
                      </th>
                      <th className="px-4 py-3 text-left font-semibold">
                        Priority
                      </th>
                      <th className="px-4 py-3 text-left font-semibold">
                        Assigned To
                      </th>
                      <th className="px-4 py-3 text-left font-semibold">
                        Action
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredIssues.length === 0 ? (
                      <tr>
                        <td
                          colSpan={8}
                          className="px-4 py-6 text-center text-gray-500"
                        >
                          No issues found
                        </td>
                      </tr>
                    ) : (
                      filteredIssues.map((issue) => (
                        <tr key={issue.id} className="border-b hover:bg-gray-50">
                          <td
                            className="px-4 py-3 font-medium text-gray-900 max-w-xs truncate"
                            title={issue.title}
                          >
                            {issue.title}
                          </td>
                          <td className="px-4 py-3 text-gray-700">
                            {issue.issue_type}
                          </td>
                          <td className="px-4 py-3 text-gray-700">
                            {issue.city}, {issue.area_name}
                          </td>
                          <td className="px-4 py-3 text-gray-700">
                            {issue.citizen_name}
                          </td>
                          <td className="px-4 py-3">
                            <span
                              className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(
                                issue.status
                              )}`}
                            >
                              {issue.status}
                            </span>
                          </td>
                          <td className="px-4 py-3">
                            {issue.priority_name ? (
                              <span
                                className={`px-3 py-1 rounded-full text-xs font-medium ${getPriorityColor(
                                  issue.priority_name
                                )}`}
                              >
                                {issue.priority_name}
                              </span>
                            ) : (
                              <span className="text-gray-500 text-xs">
                                Not Set
                              </span>
                            )}
                          </td>
                          <td className="px-4 py-3 text-gray-700">
                            {issue.assigned_to || "-"}
                          </td>
                          <td className="px-4 py-3">
                            <button
                              onClick={() => openPriorityModal(issue)}
                              className="px-3 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 text-xs font-medium transition"
                            >
                              Assign Priority
                            </button>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>

          {/* Priority Assignment Modal */}
          {showPriorityModal && selectedIssue && (
            <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
              <Card className="w-full max-w-md">
                <CardHeader>
                  <CardTitle>Assign Priority to Issue</CardTitle>
                  <p className="text-sm text-gray-600 mt-2">
                    {selectedIssue.title}
                  </p>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <label className="block text-sm font-medium">
                      Select Priority Level:
                    </label>
                    <div className="space-y-2">
                      {["High", "Medium", "Low"].map((priority) => (
                        <label
                          key={priority}
                          className="flex items-center gap-3 p-3 border rounded-lg cursor-pointer hover:bg-gray-50"
                        >
                          <input
                            type="radio"
                            name="priority"
                            value={priority}
                            checked={selectedPriority === priority}
                            onChange={(e) => setSelectedPriority(e.target.value)}
                            className="w-4 h-4"
                          />
                          <span
                            className={`px-3 py-1 rounded text-sm font-medium ${getPriorityColor(
                              priority
                            )}`}
                          >
                            {priority}
                          </span>
                        </label>
                      ))}
                    </div>
                  </div>

                  <div className="flex gap-3 mt-6">
                    <button
                      onClick={() => setShowPriorityModal(false)}
                      className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 font-medium transition"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleAssignPriority}
                      disabled={!selectedPriority || assigningPriority}
                      className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 font-medium transition flex items-center justify-center gap-2"
                    >
                      {assigningPriority ? (
                        "Assigning..."
                      ) : (
                        <>
                          <CheckCircle size={18} /> Assign Priority
                        </>
                      )}
                    </button>
                  </div>
                </CardContent>
              </Card>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default HeadAdminHome;
