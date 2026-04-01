import { ArrowRight, Camera, MapPin, Users } from "lucide-react";
import { Button } from "./ui/button";
import { Link } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";

const Hero = () => {
  const { user } = useAuth();

  return (
    <section className="relative overflow-hidden">
      {/* Background gradient */}
      {/* <div className="absolute inset-0 civic-gradient opacity-5"></div> */}

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-16 mt-20">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div className="space-y-8 animate-slide-in-left">
            <div className="space-y-4">
              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-foreground leading-tight">
                Citizens Speak.
                <br />
                Authorities Listen.
              </h1>
              <p className="text-xl text-muted-foreground max-w-lg">
                CivicTrack gives you a direct line to local government. Report
                issues, track progress, and hold authorities accountable.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row gap-4">
              <Link
                to={
                  user?.role === "citizen"
                    ? "/citizen/create-issue"
                    : user?.role === "admin"
                    ? "/"
                    : "/signin"
                }
              >
                <Button
                  variant="outline"
                  size="lg"
                  className="flex items-center space-x-2 cursor-pointer"
                >
                  <Camera className="h-5 w-5 transition-transform duration-300 group-hover:-translate-y-0.5" />
                  <span>Report an Issue</span>
                  <ArrowRight className="h-5 w-5 transition-transform duration-300 group-hover:translate-x-1" />
                </Button>
              </Link>
              <Link to={user?.role === "citizen" ? "/citizen" : "/admin"}>
                <Button
                  variant="outline"
                  size="lg"
                  className="flex items-center space-x-2 cursor-pointer"
                >
                  <MapPin className="h-5 w-5 text-green-600" />
                  <span>View Reports</span>
                </Button>
              </Link>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-6 pt-8 border-t">
              <div className="text-center">
                <div className="text-2xl font-bold text-sky-500">2,847</div>
                <div className="text-sm text-muted-foreground">
                  Issues Resolved
                </div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-sky-500">15,239</div>
                <div className="text-sm text-muted-foreground">
                  Active Citizens
                </div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-sky-500">48h</div>
                <div className="text-sm text-muted-foreground">
                  Avg Response
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
