import { Link, NavLink, useLocation, useNavigate } from "react-router-dom";
import { useEffect, useState, useMemo } from "react";
import { Menu, X, ShoppingCart, User, LogOut, ChevronRight, ChevronLeft, ChevronDown, Heart, ArrowLeft, Bell } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { useCart } from "@/lib/cart";
import { useWishlist } from "@/lib/wishlist";

const baseLinks = [
  { to: "/", label: "Home" },
  { to: "/about", label: "About Us" },
  { to: "/products", label: "Products" },
  { to: "/contact", label: "Contact Us" },
  { to: "/faq", label: "FAQ" },
];

export function Navbar() {
  const navigate = useNavigate();
  const location = useLocation();
  const isHomePage = location.pathname === "/";

  // Dynamic screen title for native mobile experience on non-home pages
  const screenTitle = useMemo(() => {
    const pathname = location.pathname;
    const searchParams = new URLSearchParams(location.search);
    const tab = searchParams.get("tab");

    if (pathname === "/products") return "All Products";
    if (pathname.startsWith("/product/")) return "Product Details";
    if (pathname === "/cart") return "Shopping Bag";
    if (pathname === "/dashboard") {
      if (tab === "orders") return "My Orders";
      if (tab === "wishlist") return "My Wishlist";
      if (tab === "cart") return "Shopping Bag";
      if (tab === "profile") return "My Profile";
      if (tab === "addresses") return "Saved Addresses";
      if (tab === "wallet") return "VEXA Wallet";
      if (tab === "support") return "Customer Support";
      return "My Profile";
    }
    if (pathname === "/about") return "About Us";
    if (pathname === "/contact") return "Contact Us";
    if (pathname === "/faq") return "Help & FAQ";
    if (pathname === "/register") return "Create Account";
    if (pathname === "/reset-password") return "Reset Password";

    const clean = pathname.replace(/^\//, "").replace(/[-_]/g, " ");
    return clean ? clean.charAt(0).toUpperCase() + clean.slice(1) : "";
  }, [location.pathname, location.search]);
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [visible, setVisible] = useState(true);
  const { isLoggedIn, isAdmin, logout } = useAuth();
  const { cartItems } = useCart();
  const { wishlistItems } = useWishlist();
  const totalCartCount = (cartItems || []).reduce((acc, item) => acc + (item?.quantity || 1), 0);
  const wishlistCount = (wishlistItems || []).length;

  const handleBack = () => {
    if (window.history.length > 1) {
      navigate(-1);
    } else {
      navigate("/");
    }
  };

  useEffect(() => {
    let lastScrollY = window.scrollY;

    const onScroll = () => {
      const currentScrollY = window.scrollY;
      setScrolled(currentScrollY > 20);

      if (currentScrollY > lastScrollY && currentScrollY > 80) {
        // Scrolling down -> hide navbar
        setVisible(false);
      } else {
        // Scrolling up -> show navbar
        setVisible(true);
      }
      lastScrollY = currentScrollY;
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Lock body scroll when mobile drawer is open
  useEffect(() => {
    if (open) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  // Hide header navigation on admin portal and on login page (for native mobile experience)
  if (location.pathname.startsWith("/admin") || location.pathname === "/login") {
    return null;
  }

  const accountPath = isAdmin ? "/admin" : "/dashboard?tab=profile";

  return (
    <>
      <header
        className={`fixed inset-x-0 top-0 z-50 transition-all duration-500 transform ${
          visible ? "translate-y-0 opacity-100" : "-translate-y-full opacity-0 pointer-events-none"
        } ${
          scrolled
            ? "border-b border-border bg-background/90 backdrop-blur-xl py-2.5 sm:py-3 shadow-sm"
            : "py-3.5 sm:py-5"
        }`}
      >
        <nav className="mx-auto flex max-w-7xl items-center justify-between px-4 sm:px-6">
          <div className="flex items-center gap-2 sm:gap-3">
            {/* Header Back Button Symbol (Visible on all non-home pages) */}
            {!isHomePage && (
              <button
                type="button"
                onClick={handleBack}
                className="flex size-8.5 sm:size-8.5 items-center justify-center rounded-full text-foreground hover:bg-muted/50 transition-all duration-200 cursor-pointer active:scale-90 shrink-0 -ml-1 sm:ml-0 sm:border sm:border-gold/40 sm:bg-card/90 sm:text-gold sm:hover:bg-gold sm:hover:text-primary-foreground"
                title="Go Back"
                aria-label="Go Back"
              >
                <ChevronLeft className="size-6 text-foreground sm:size-4.5 sm:text-inherit" strokeWidth={2.4} />
              </button>
            )}

            {/* Brand Logo on Home Screen, or Dynamic Screen Title on other screens for Mobile */}
            {isHomePage ? (
              <Link to="/" className="group flex items-center gap-2 sm:gap-3 leading-none shrink-0">
                <div className="flex size-8 sm:size-9 items-center justify-center rounded-[10px] bg-white border border-border/60 shadow-xs transition-transform duration-300 group-hover:scale-105 shrink-0 overflow-hidden p-0.5">
                  <img
                    src="/vexa_logo.png"
                    alt="VEXA Logo"
                    loading="lazy"
                    decoding="async"
                    className="size-full rounded-[8px] object-cover"
                  />
                </div>
                <div className="flex flex-col justify-center">
                  <span className="font-display text-lg sm:text-2xl font-black tracking-[0.32em] sm:tracking-[0.35em] text-gold-gradient leading-none">
                    V E X A
                  </span>
                  <span className="mt-1 text-[7.5px] sm:text-[9px] font-semibold tracking-[0.24em] sm:tracking-[0.34em] text-muted-foreground whitespace-nowrap leading-none">
                    WEAR CONFIDENCE
                  </span>
                </div>
              </Link>
            ) : (
              <>
                {/* Mobile View: Dynamic Screen Title (Hidden on desktop) */}
                {location.pathname === "/dashboard" && (!new URLSearchParams(location.search).get("tab") || new URLSearchParams(location.search).get("tab") === "profile") ? (
                  <div className="flex flex-col justify-center sm:hidden min-w-0">
                    <span className="font-display text-[15px] font-black tracking-[0.08em] text-foreground leading-tight uppercase truncate">
                      PROFILE &amp; SETTINGS
                    </span>
                    <span className="text-[10.5px] text-muted-foreground font-medium leading-tight mt-0.5 truncate">
                      Manage account &amp; preferences
                    </span>
                  </div>
                ) : (
                  <div className="flex items-center sm:hidden">
                    <span className="text-[18px] font-bold tracking-tight text-foreground leading-none ml-0.5">
                      {screenTitle}
                    </span>
                  </div>
                )}

                {/* Desktop View: Brand Logo */}
                <Link to="/" className="group hidden sm:flex items-center gap-2 sm:gap-3 leading-none shrink-0">
                  <div className="flex size-8 sm:size-9 items-center justify-center rounded-[10px] bg-white border border-border/60 shadow-xs transition-transform duration-300 group-hover:scale-105 shrink-0 overflow-hidden p-0.5">
                    <img
                      src="/vexa_logo.png"
                      alt="VEXA Logo"
                      loading="lazy"
                      decoding="async"
                      className="size-full rounded-[8px] object-cover"
                    />
                  </div>
                  <div className="flex flex-col justify-center">
                    <span className="font-display text-lg sm:text-2xl font-black tracking-[0.32em] sm:tracking-[0.35em] text-gold-gradient leading-none">
                      V E X A
                    </span>
                    <span className="mt-1 text-[7.5px] sm:text-[9px] font-semibold tracking-[0.24em] sm:tracking-[0.34em] text-muted-foreground whitespace-nowrap leading-none">
                      WEAR CONFIDENCE
                    </span>
                  </div>
                </Link>
              </>
            )}
          </div>

        {/* Navigation Links (Desktop) */}
          <ul className="hidden items-center gap-8 lg:flex">
            {baseLinks.map((l) => (
              <li key={l.to}>
                <NavLink
                  to={l.to}
                  className={({ isActive }) =>
                    `relative text-xs uppercase tracking-[0.22em] transition-colors duration-300 after:absolute after:-bottom-2 after:left-0 after:h-px after:w-0 after:bg-gold after:transition-all after:duration-300 hover:after:w-full ${
                      isActive ? "text-gold font-bold after:w-full" : "text-muted-foreground hover:text-gold"
                    }`
                  }
                >
                  {l.label}
                </NavLink>
              </li>
            ))}
          </ul>

          {/* Right Section Controls */}
          <div className="flex items-center gap-1.5 sm:gap-3">
            {/* Mobile Home Screen Notification Bell (Matches Flutter Mobile App Home Header 1:1) */}
            {isHomePage && (
              <div className="relative flex items-center sm:hidden mr-1">
                <Link
                  to="/dashboard?tab=support"
                  className="flex size-10 items-center justify-center rounded-full border border-border bg-white dark:bg-[#1E293B] text-[#0F172A] dark:text-foreground shadow-sm active:scale-90 transition-transform"
                  title="Notifications"
                >
                  <Bell className="size-5" />
                </Link>
                <span className="absolute -top-1 -right-1 flex min-w-4.5 h-4.5 px-1 items-center justify-center rounded-full bg-[#E5BF4E] text-[#0F172A] text-[9.5px] font-black border-2 border-white dark:border-[#0F172A] shadow-xs font-mono">
                  57
                </span>
              </div>
            )}

            {/* Wishlist Symbol / Icon (Desktop / Tablet) */}
            {isLoggedIn && (
              <Link
                to="/dashboard?tab=wishlist"
                className="relative hidden sm:flex items-center justify-center p-2 text-gold hover:text-gold/80 transition-all cursor-pointer active:scale-95"
                title="My Wishlist"
              >
                <Heart className="size-5 sm:size-6" />
                {wishlistCount > 0 && (
                  <span className="absolute -top-1 -right-1 flex size-4.5 items-center justify-center rounded-full bg-red-500 text-white text-[10px] font-extrabold shadow border border-background font-mono">
                    {wishlistCount}
                  </span>
                )}
              </Link>
            )}

            {/* Cart Symbol / Icon (Hidden on mobile < sm; accessible via bottom nav & floating action) */}
            {isLoggedIn && (
              <Link
                to="/dashboard?tab=cart"
                className="relative hidden sm:flex items-center justify-center p-2 text-gold hover:text-gold/80 transition-all cursor-pointer active:scale-95"
                title="View Cart"
              >
                <ShoppingCart className="size-5 sm:size-6" />
                {totalCartCount > 0 && (
                  <span className="absolute -top-1 -right-1 flex size-4.5 items-center justify-center rounded-full bg-gold text-primary-foreground text-[10px] font-extrabold shadow border border-background font-mono">
                    {totalCartCount}
                  </span>
                )}
              </Link>
            )}

            {/* Account / Login Option in Navbar (Shown on >= sm) */}
            {isLoggedIn ? (
              <Link
                to={accountPath}
                className="relative hidden sm:flex items-center justify-center p-2 text-gold hover:text-gold/80 transition-all cursor-pointer active:scale-95"
                title={isAdmin ? "Admin Portal" : "My Profile Dashboard"}
              >
                <User className="size-5 sm:size-6" />
              </Link>
            ) : (
              <Link
                to="/login"
                className="btn-gold hover:btn-gold-hover inline-flex items-center gap-1.5 rounded-sm px-3.5 py-1.5 text-xs font-bold uppercase tracking-[0.16em] transition-all shadow-goldy cursor-pointer active:scale-95 ml-1"
                title="Login to Account"
              >
                <User className="size-3.5" />
                <span>Login</span>
              </Link>
            )}

            {/* Tablet/Desktop View: Hamburger Menu Button (Drawer for secondary pages like FAQ, About, Contact; hidden on mobile < sm) */}
            <button
              type="button"
              aria-label="Toggle Navigation Menu"
              onClick={() => setOpen((o) => !o)}
              className="hidden sm:flex lg:hidden items-center justify-center p-2 text-gold hover:text-gold/80 transition-all cursor-pointer active:scale-95 ml-0.5"
              title="Toggle Menu"
            >
              {open ? <X className="size-5" /> : <Menu className="size-5" />}
            </button>
          </div>
        </nav>
      </header>

      {/* Backdrop Overlay for Mobile Drawer */}
      <div
        onClick={() => setOpen(false)}
        className={`fixed inset-0 z-[9998] bg-black/60 backdrop-blur-sm transition-opacity duration-300 lg:hidden ${
          open ? "opacity-100" : "opacity-0 pointer-events-none"
        }`}
      />

      {/* Right-Side Mobile Slide-Over Navigation Drawer Panel */}
      <aside
        className={`fixed inset-y-0 right-0 z-[9999] flex w-[280px] xs:w-[320px] flex-col bg-card/98 backdrop-blur-2xl border-l border-gold/40 shadow-2xl transition-transform duration-300 ease-in-out lg:hidden ${
          open ? "translate-x-0" : "translate-x-full"
        }`}
      >
        {/* Drawer Header */}
        <div className="flex items-center justify-between border-b border-gold/30 p-5">
          <div className="flex items-center gap-2.5">
            <img src="/vexa_logo.png" alt="VEXA" className="size-7 rounded-md object-cover" />
            <span className="font-display text-lg font-bold tracking-[0.25em] text-gold-gradient">
              VEXA
            </span>
          </div>
          <button
            type="button"
            onClick={() => setOpen(false)}
            className="flex size-8 items-center justify-center rounded-full border border-gold/40 bg-gold/10 text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer"
            title="Close Menu"
          >
            <X className="size-4" />
          </button>
        </div>

        {/* Drawer Scrollable Links Container */}
        <div className="flex-1 overflow-y-auto px-5 py-6 space-y-6">
          <div className="space-y-1">
            <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-gold mb-3">Navigation Menu</p>
            <ul className="space-y-1.5">
              {baseLinks.map((l) => (
                <li key={l.to}>
                  <NavLink
                    to={l.to}
                    onClick={() => setOpen(false)}
                    className={({ isActive }) =>
                      `flex items-center justify-between rounded-lg px-4 py-3 text-xs font-bold uppercase tracking-[0.2em] transition-all duration-300 ${
                        isActive
                          ? "bg-gold text-primary-foreground font-extrabold shadow-sm"
                          : "text-muted-foreground hover:bg-surface hover:text-gold"
                      }`
                    }
                  >
                    {({ isActive }) => (
                      <>
                        <span>{l.label}</span>
                        {isActive && <ChevronRight className="size-4 shrink-0" />}
                      </>
                    )}
                  </NavLink>
                </li>
              ))}
            </ul>
          </div>

          <div className="border-t border-border/40 pt-5 space-y-1">
            <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-gold mb-3">Account Options</p>
            {isLoggedIn ? (
              <div className="space-y-2">
                <Link
                  to={accountPath}
                  onClick={() => setOpen(false)}
                  className="flex items-center gap-3 rounded-lg border border-gold/40 bg-gold/10 px-4 py-3 text-xs font-bold uppercase tracking-[0.2em] text-gold hover:bg-gold hover:text-primary-foreground transition-all"
                >
                  <User className="size-4 shrink-0" />
                  <span>{isAdmin ? "Admin Portal" : "Profile"}</span>
                </Link>
                <button
                  type="button"
                  onClick={() => {
                    setOpen(false);
                    logout();
                  }}
                  className="flex w-full items-center gap-3 rounded-lg border border-destructive/40 bg-destructive/10 px-4 py-3 text-xs font-bold uppercase tracking-[0.2em] text-destructive hover:bg-destructive hover:text-white transition-all cursor-pointer"
                >
                  <LogOut className="size-4 shrink-0" />
                  <span>Log Out</span>
                </button>
              </div>
            ) : (
              <Link
                to="/login"
                onClick={() => setOpen(false)}
                className="flex items-center gap-3 rounded-lg border border-gold/50 bg-gold px-4 py-3 text-xs font-bold uppercase tracking-[0.2em] text-primary-foreground shadow-goldy hover:bg-gold/90 transition-all"
              >
                <User className="size-4 shrink-0" />
                <span>Login / Sign Up</span>
              </Link>
            )}
          </div>
        </div>

        {/* Drawer Footer Tagline */}
        <div className="border-t border-border/40 p-4 text-center text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
          WEAR CONFIDENCE • WEAR STYLE
        </div>
      </aside>
    </>
  );
}

