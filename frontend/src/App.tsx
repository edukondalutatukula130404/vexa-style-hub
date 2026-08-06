import { useEffect } from "react";
import { BrowserRouter, Routes, Route, Outlet, useLocation } from "react-router-dom";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";

// Route Pages
import { Home } from "@/routes/index";
import { Products } from "@/routes/products";
import { ProductDetailPage } from "@/routes/product.$id";
import { Login } from "@/routes/login";
import { Register } from "@/routes/register";
import { CartRedirect } from "@/routes/cart";
import { UserDashboard } from "@/routes/dashboard";
import { Admin } from "@/routes/admin";
import { About } from "@/routes/about";
import { Contact } from "@/routes/contact";
import { Faq } from "@/routes/faq";
import { ResetPassword } from "@/routes/reset-password";

function ScrollToTop() {
  const { pathname, search } = useLocation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname, search]);

  return null;
}

function Layout() {
  const location = useLocation();
  const hideFooter =
    location.pathname === "/dashboard" ||
    location.pathname === "/admin" ||
    location.pathname === "/login" ||
    location.pathname === "/register";

  return (
    <div className="flex min-h-screen flex-col bg-background font-sans text-foreground antialiased selection:bg-gold selection:text-primary-foreground">
      <ScrollToTop />
      <Navbar />
      <main className="flex-1">
        <Outlet />
      </main>
      {!hideFooter && <Footer />}
    </div>
  );
}

function NotFound() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-7xl font-bold text-foreground">404</h1>
        <h2 className="mt-4 text-xl font-semibold text-foreground">Page not found</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <div className="mt-6">
          <a
            href="/"
            className="inline-flex items-center justify-center rounded-md bg-gold px-6 py-3 text-xs font-bold uppercase tracking-wider text-primary-foreground transition-all shadow-goldy hover:bg-gold/90"
          >
            Go Home
          </a>
        </div>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<Home />} />
          <Route path="/products" element={<Products />} />
          <Route path="/product/:id" element={<ProductDetailPage />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/cart" element={<CartRedirect />} />
          <Route path="/dashboard" element={<UserDashboard />} />
          <Route path="/admin" element={<Admin />} />
          <Route path="/about" element={<About />} />
          <Route path="/contact" element={<Contact />} />
          <Route path="/faq" element={<Faq />} />
          <Route path="/reset-password" element={<ResetPassword />} />
          <Route path="*" element={<NotFound />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
