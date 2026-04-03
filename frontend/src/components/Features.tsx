import { Camera, Users, Zap, Shield } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";

const Features = () => {
  const features = [
    {
      icon: Camera,
      title: "Report Issues",
      description: "Citizens can report civic issues with photos and details",
    },
    {
      icon: Users,
      title: "Track Status",
      description: "View and monitor the status of reported issues in real-time",
    },
    {
      icon: Zap,
      title: "Receive Updates",
      description: "Get notified about changes and resolutions to reported issues",
    },
    {
      icon: Shield,
      title: "Admin Management",
      description: "Administrators can review, assign, and resolve reported issues",
    },
  ];

  return (
    <section id="features" className="py-16 bg-white">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-2xl sm:text-3xl font-bold text-slate-900 mb-3">
            Key Features
          </h2>
          <p className="text-slate-600 max-w-2xl mx-auto">
            Simple and effective tools for reporting and managing civic issues
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {features.map((feature) => (
            <Card key={feature.title} className="border border-slate-200">
              <CardHeader>
                <div className="mb-3">
                  <feature.icon className="h-8 w-8 text-slate-700" />
                </div>
                <CardTitle className="text-lg text-slate-900">
                  {feature.title}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-slate-600">
                  {feature.description}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Features;
