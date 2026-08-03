import { Link, NavLink } from "react-router-dom";
import { useEffect, useState } from "react";
import { Menu, X, ShoppingCart, User, LogOut } from "lucide-react";
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

      // Automatically close mobile menu options drawer on scroll up/down
      setOpen(false);

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

  // Hide header navigation completely on admin portal
  if (typeof window !== "undefined" && window.location.pathname.startsWith("/admin")) {
    return null;
  }

  const accountPath = isAdmin ? "/admin" : "/dashboard";

  return (
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
        <div className="flex items-center gap-2 sm:gap-4">
          {/* Cart Button (Desktop only, hidden on mobile screens) */}
          <Link
            to="/dashboard?tab=cart"
            className="btn-gold hover:btn-gold-hover hidden sm:flex items-center gap-2 rounded-sm px-4 py-2 text-xs font-bold uppercase tracking-[0.16em] cursor-pointer shadow-goldy"
          >
            <ShoppingCart className="size-4" />
            <span>Cart</span>
            {totalCartCount > 0 && (
              <span className="ml-1 flex size-5 items-center justify-center rounded-full bg-background text-[10px] font-extrabold text-gold shadow border border-gold/50 font-mono">
                {totalCartCount}
              </span>
            )}
          </Link>

          {isLoggedIn ? (
            <div className="flex items-center gap-2">
              <Link
                to={accountPath}
                className="hidden sm:flex items-center gap-1.5 rounded-sm border border-gold/40 bg-gold/10 px-4 py-2 text-xs font-bold uppercase tracking-[0.18em] text-gold transition-all hover:bg-gold hover:text-primary-foreground shadow-sm"
              >
                <User className="size-3.5" />
                {isAdmin ? "Admin" : "My Account"}
              </Link>
              <button
                aria-label="Toggle menu"
                onClick={() => setOpen((o) => !o)}
                className="text-gold lg:hidden p-1.5 cursor-pointer rounded-md hover:bg-gold/10 transition-colors"
              >
                {open ? <X className="size-6" /> : <Menu className="size-6" />}
              </button>
            </div>
          ) : (
            <>
              <Link
                to="/login"
                className="hidden text-xs font-bold uppercase tracking-[0.2em] text-muted-foreground transition-colors hover:text-gold sm:block"
              >
                Login
              </Link>
              <button
                aria-label="Toggle menu"
                onClick={() => setOpen((o) => !o)}
                className="text-gold lg:hidden p-1.5 cursor-pointer rounded-md hover:bg-gold/10 transition-colors"
              >
                {open ? <X className="size-6" /> : <Menu className="size-6" />}
              </button>
            </>
          )}
        </div>
      </nav>

      {/* Mobile Drawer */}
      <div
        className={`overflow-hidden border-t border-border bg-background/95 backdrop-blur-xl transition-all duration-500 lg:hidden ${
          open ? "mt-3 max-h-[480px]" : "max-h-0"
        }`}
      >
        <ul className="flex flex-col gap-1 px-6 py-4">
          {baseLinks.map((l) => (
            <li key={l.to}>
              <NavLink
                to={l.to}
                onClick={() => setOpen(false)}
                className={({ isActive }) =>
                  `block py-2.5 text-sm uppercase tracking-[0.2em] transition-colors ${
                    isActive ? "text-gold font-bold" : "text-muted-foreground hover:text-gold"
                  }`
                }
              >
                {l.label}
              </NavLink>
            </li>
          ))}
          <li>
            <Link
              to="/dashboard?tab=cart"
              onClick={() => setOpen(false)}
              className="flex items-center gap-2 py-2.5 text-sm font-bold uppercase tracking-[0.2em] text-gold"
            >
              <ShoppingCart className="size-4" /> My Cart ({totalCartCount})
            </Link>
          </li>
          {isLoggedIn ? (
            <>
              <li>
                <Link
                  to={accountPath}
                  onClick={() => setOpen(false)}
                  className="block py-2.5 text-sm font-bold uppercase tracking-[0.2em] text-gold"
                >
                  {isAdmin ? "Admin Portal" : "My Account"}
                </Link>
              </li>
              <li className="pt-2 border-t border-border/50">
                <button
                  onClick={() => {
                    setOpen(false);
                    logout();
                  }}
                  className="flex items-center gap-2.5 py-2.5 text-sm font-bold uppercase tracking-[0.2em] text-destructive hover:opacity-80 transition-opacity cursor-pointer w-full text-left"
                >
                  <LogOut className="size-4" /> Log Out
                </button>
              </li>
            </>
          ) : (
            <li>
              <Link
                to="/login"
                onClick={() => setOpen(false)}
                className="block py-2.5 text-sm uppercase tracking-[0.2em] text-muted-foreground transition-colors hover:text-gold"
              >
                Login
              </Link>
            </li>
          )}
        </ul>
      </div>
    </header>
  );
}
