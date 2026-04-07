import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import Header from "../components/Header.tsx";
import Features from "../components/Features.tsx";
import HowItWorks from "../components/HowItWorks.tsx";
import Hero from "../components/Hero.tsx";
import CTA from "../components/CTA.tsx";
import Footer from "../components/Footer.tsx";
import { AuthProvider } from "../contexts/AuthContext.tsx";

const Index = () => {
  const [featuresAnimationKey, setFeaturesAnimationKey] = useState(0);
  const [howItWorksAnimationKey, setHowItWorksAnimationKey] = useState(0);
  const navigate = useNavigate();
  const { user } = useAuth();

  useEffect(() => {
    // Auto-redirect logged-in users to their dashboard
    if (user) {
      if (user.role === "head-admin") {
        navigate("/head-admin");
      } else if (user.role === "admin") {
        navigate("/admin");
      } else if (user.role === "citizen") {
        navigate("/citizen");
      }
    }
  }, [user, navigate]);

  const handleFeaturesClick = () => {
    setFeaturesAnimationKey((prev) => prev + 1);
    document.getElementById("features")?.scrollIntoView({ behavior: "smooth" });
  };

  const handleHowItWorksClick = () => {
    setHowItWorksAnimationKey((prev) => prev + 1);
    document
      .getElementById("how-it-works")
      ?.scrollIntoView({ behavior: "smooth" });
  };

  return (
    <div className="relative min-h-screen overflow-hidden">
      <div
        className="fixed inset-0 z-0 "
        style={{
          backgroundImage: `
    radial-gradient(circle at top left, rgba(255,255,255,0.6) 0%, transparent 35%),
    radial-gradient(circle at bottom right, rgba(255,255,255,0.5) 0%, transparent 35%),
    linear-gradient(135deg, #f2f6f6 0%, #e8ecef 35%, #f9eeee 100%)
  `,
          backgroundAttachment: "fixed",
          backgroundBlendMode: "screen",
        }}
      />
      <div className="relative z-10">
        <AuthProvider>
          <Header
            onFeaturesClick={handleFeaturesClick}
            onHowItWorksClick={handleHowItWorksClick}
          />
          <Hero />
          <Features key={`features-${featuresAnimationKey}`} />
          <HowItWorks key={`how-${howItWorksAnimationKey}`} />
          <CTA />
          <Footer />
        </AuthProvider>
      </div>
    </div>
  );
};

export default Index;
