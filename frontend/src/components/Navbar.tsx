import { Link, NavLink } from "react-router-dom";
import { useEffect, useState } from "react";
import { Menu, X, ShoppingCart, User, LogOut, ChevronRight } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { useCart } from "@/lib/cart";

const baseLinks = [
  { to: "/", label: "Home" },
  { to: "/products", label: "Products" },
  { to: "/about", label: "About Us" },
  { to: "/contact", label: "Contact Us" },
  { to: "/faq", label: "FAQ" },
];

export function Navbar() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [visible, setVisible] = useState(true);
  const { isLoggedIn, isAdmin, logout } = useAuth();
  const { cartItems } = useCart();
  const totalCartCount = (cartItems || []).reduce((acc, item) => acc + (item?.quantity || 1), 0);

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

  // Hide header navigation completely on admin portal
  if (typeof window !== "undefined" && window.location.pathname.startsWith("/admin")) {
    return null;
  }

  const accountPath = isAdmin ? "/admin" : "/dashboard";

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
          {/* Brand Logo & Name (Optimized for Mobile Responsive) */}
          <Link to="/" className="group flex items-center gap-2.5 sm:gap-3 leading-none shrink-0">
            <img
              src="/favicon.svg"
              alt="VEXA Logo"
              loading="lazy"
              decoding="async"
              className="size-7 sm:size-8 rounded-md transition-transform duration-300 group-hover:scale-105 shrink-0"
            />
            <div className="flex flex-col justify-center">
              <span className="font-display text-xl sm:text-2xl font-bold tracking-[0.28em] sm:tracking-[0.35em] text-gold-gradient leading-none">
                VEXA
              </span>
              <span className="mt-0.5 sm:mt-1 text-[8px] sm:text-[9px] font-semibold tracking-[0.22em] sm:tracking-[0.34em] text-muted-foreground whitespace-nowrap leading-none">
                WEAR CONFIDENCE
              </span>
            </div>
          </Link>

          {/* Navigation Links */}
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
          <div className="flex items-center gap-2 sm:gap-3">
            {/* Cart Button */}
            <Link
              to="/dashboard?tab=cart"
              className="relative flex items-center justify-center p-2 text-gold hover:text-gold/80 sm:bg-gold sm:text-primary-foreground sm:hover:bg-gold/90 sm:px-3.5 sm:py-2 sm:rounded-sm sm:shadow-goldy transition-all cursor-pointer active:scale-95 text-xs font-bold uppercase tracking-[0.16em]"
              title="View Cart"
            >
              <ShoppingCart className="size-5 sm:size-4" />
              <span className="hidden sm:inline sm:ml-2">Cart</span>
              {totalCartCount > 0 && (
                <span className="absolute -top-1.5 -right-1.5 sm:static sm:ml-1.5 flex size-4.5 items-center justify-center rounded-full bg-gold text-primary-foreground sm:bg-background sm:text-gold text-[10px] font-extrabold shadow border border-gold/50 font-mono">
                  {totalCartCount}
                </span>
              )}
            </Link>

            {/* Desktop Web App: Three-Lines Icon -> Opens My Account Page */}
            <Link
              to={isLoggedIn ? accountPath : "/login"}
              className="hidden lg:flex items-center justify-center p-2.5 rounded-sm border border-gold/50 bg-gold/15 text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer shadow-sm active:scale-95"
              title={isLoggedIn ? (isAdmin ? "Admin Portal" : "My Account Dashboard") : "Login / Account"}
            >
              <Menu className="size-5" />
            </Link>

            {/* Mobile View: Three-Lines Icon -> Opens Right Slide-Over Navigation Drawer */}
            <button
              type="button"
              aria-label="Toggle Navigation Menu"
              onClick={() => setOpen((o) => !o)}
              className="flex lg:hidden items-center justify-center p-2 text-gold hover:text-gold/80 transition-all cursor-pointer active:scale-95"
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
            <img src="/favicon.svg" alt="VEXA" className="size-7 rounded-md" />
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
                  <span>{isAdmin ? "Admin Portal" : "My Account"}</span>
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

