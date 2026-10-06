import { useEffect } from "react";
import { BrowserRouter, Routes, Route, Outlet, useLocation, useNavigate } from "react-router-dom";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { MobileFrameWrapper } from "@/components/MobileFrameWrapper";
import { MobileBottomNav } from "@/components/MobileBottomNav";
import { NoInternetOverlay } from "@/components/NoInternetOverlay";
import { vexaSocket } from "@/lib/socket";

import { Toaster } from "@/components/ui/sonner";
import { toast } from "sonner";
import { requestWebNotificationPermission, onForegroundMessage, triggerWebTestPushNotification } from "@/lib/firebase";

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

function ProductQueryRedirect() {
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const searchParams = new URLSearchParams(location.search);
    const productId = searchParams.get("id") || searchParams.get("product");
    if (productId && (location.pathname === "/" || location.pathname === "")) {
      navigate(`/product/${productId}`, { replace: true });
    }
  }, [location, navigate]);

  return null;
}

function ScrollToTop() {
  const { pathname, search } = useLocation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname, search]);

  return null;
}

function Layout() {
  const location = useLocation();

  useEffect(() => {
    vexaSocket.connect();

    // Initialize Web Push Notifications
    requestWebNotificationPermission().then((token) => {
      if (token) {
        console.log("Firebase Web Push Notifications active. FCM Token:", token);
      }
    });

    onForegroundMessage((payload) => {
      const title = payload?.notification?.title || "VEXA Notification";
      const body = payload?.notification?.body || "";
      toast.info(title, {
        description: body,
      });
      triggerWebTestPushNotification(title, body);
    });

    // Listen to live WebSocket broadcast events for system push notifications
    const unsubscribe = vexaSocket.subscribe((event) => {
      const { type, data } = event;
      if (type === "ADMIN_MESSAGE" || type === "ANNOUNCEMENT" || type === "NOTIFICATION") {
        const title = data?.title || "Message from VEXA Admin 📢";
        const body = data?.body || data?.message || "Notification from Admin";
        toast.info(title, { description: body });
        triggerWebTestPushNotification(title, body);
      } else if (type === "ORDER_CREATED" || type === "ORDER_PLACED") {
        const orderId = data?._id || data?.id || "#VX-ORDER";
        const title = "Order Confirmed! 📦";
        const body = `Order ${orderId} placed successfully.`;
        toast.success(title, { description: body });
        triggerWebTestPushNotification(title, body);
      }
    });

    return () => {
      if (unsubscribe) unsubscribe();
    };
  }, []);
  const hideFooter =
    location.pathname === "/dashboard" ||
    location.pathname === "/admin" ||
    location.pathname === "/login" ||
    location.pathname === "/register";

  return (
    <MobileFrameWrapper>
      <div className="flex min-h-screen flex-col bg-background font-sans text-foreground antialiased selection:bg-gold selection:text-primary-foreground pb-16 md:pb-0">
        <ScrollToTop />
        <Navbar />
        <main className="flex-1">
          <Outlet />
        </main>
        {!hideFooter && <Footer />}
        <MobileBottomNav />
      </div>
    </MobileFrameWrapper>
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
      <Toaster position="top-right" richColors />
      <NoInternetOverlay />
      <ProductQueryRedirect />
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<Home />} />
          <Route path="/products" element={<Products />} />
          <Route path="/product" element={<ProductDetailPage />} />
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
