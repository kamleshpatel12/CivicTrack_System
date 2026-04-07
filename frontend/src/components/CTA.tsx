import { Link } from "react-router-dom";
import { Button } from "./ui/button";

const CTA = () => {
  return (
    <section className="py-16 bg-slate-100">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-2xl sm:text-3xl font-bold text-slate-900 mb-6">
            Get Started with CivicTrack
          </h2>
          <p className="text-slate-600 mb-10">
            Choose your role to access the application
          </p>
        </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-6xl mx-auto px-2">
            <div className="bg-white border border-slate-200 rounded-lg p-12 text-center hover:shadow-lg transition-shadow">
              <h3 className="text-xl font-semibold text-slate-900 mb-4">
                Citizen
              </h3>
              <p className="text-slate-600 mb-8">
                Report issues and track their status
              </p>
              <Link to="/signin?role=citizen" className="w-full">
                <Button variant="outline" className="w-full">
                  Enter as Citizen
                </Button>
              </Link>
            </div>

            <div className="bg-white border border-slate-200 rounded-lg p-12 text-center hover:shadow-lg transition-shadow">
              <h3 className="text-xl font-semibold text-slate-900 mb-4">
                Administrator
              </h3>
              <p className="text-slate-600 mb-8">
                Manage and resolve reported issues
              </p>
              <Link to="/signin?role=admin" className="w-full">
                <Button variant="outline" className="w-full">
                  Enter as Admin
                </Button>
              </Link>
            </div>

            <div className="bg-white border border-slate-200 rounded-lg p-12 text-center hover:shadow-lg transition-shadow">
              <h3 className="text-xl font-semibold text-slate-900 mb-4">
                Head Admin
              </h3>
              <p className="text-slate-600 mb-8">
                View and manage all issues system-wide
              </p>
              <Link to="/signin?role=head-admin" className="w-full">
                <Button variant="outline" className="w-full">
                  Enter as Head Admin
                </Button>
              </Link>
            </div>
          </div>
      </div>
    </section>
  );
};

export default CTA;
