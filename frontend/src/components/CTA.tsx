import { Link } from "react-router-dom";
import { Button } from "./ui/button";

const CTA = () => {
  return (
    <section className="py-16 bg-slate-100">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="max-w-3xl mx-auto text-center">
          <h2 className="text-2xl sm:text-3xl font-bold text-slate-900 mb-6">
            Get Started with CivicTrack
          </h2>
          <p className="text-slate-600 mb-10">
            Choose your role to access the application
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-white border border-slate-200 rounded-lg p-8 text-center">
              <h3 className="text-lg font-semibold text-slate-900 mb-3">
                Citizen
              </h3>
              <p className="text-slate-600 text-sm mb-6">
                Report issues and track their status
              </p>
              <Link to="/citizen" className="w-full">
                <Button variant="outline" className="w-full">
                  Enter as Citizen
                </Button>
              </Link>
            </div>

            <div className="bg-white border border-slate-200 rounded-lg p-8 text-center">
              <h3 className="text-lg font-semibold text-slate-900 mb-3">
                Administrator
              </h3>
              <p className="text-slate-600 text-sm mb-6">
                Manage and resolve reported issues
              </p>
              <Link to="/admin" className="w-full">
                <Button variant="outline" className="w-full">
                  Enter as Admin
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default CTA;
