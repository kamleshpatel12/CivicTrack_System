import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter } from "react-router-dom";
import { AuthProvider } from "./contexts/AuthContext";
import { LoaderProvider } from "./contexts/LoaderContext";
import { Toaster as Sonner, Toaster } from "sonner";
import AnimatedRoutes from "./AnimateRoutes";
import "./index.css";



const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <AuthProvider>
      <LoaderProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <AnimatedRoutes />
        </BrowserRouter>
      </LoaderProvider>
    </AuthProvider>
  </QueryClientProvider>
);

export default App;
