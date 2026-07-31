import { Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Menu, X, ShoppingBag, User } from "lucide-react";
import { useAuth } from "@/lib/auth";

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
  const { isLoggedIn, isAdmin } = useAuth();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    onScroll();
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const accountPath = isAdmin ? "/admin" : "/dashboard";

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition-all duration-500 ${
        scrolled
          ? "border-b border-border bg-background/85 backdrop-blur-xl py-3"
          : "py-5"
      }`}
    >
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-5">
        {/* Brand Logo */}
        <Link to="/" className="group flex items-center gap-3 leading-none">
          <img
            src="/favicon.svg"
            alt="VEXA Logo"
            loading="lazy"
            decoding="async"
            className="size-8 rounded-md transition-transform duration-300 group-hover:scale-105"
          />
          <div className="flex flex-col">
            <span className="font-display text-2xl tracking-[0.35em] text-gold-gradient">
              VEXA
            </span>
            <span className="mt-1 text-[9px] tracking-[0.34em] text-muted-foreground">
              WEAR CONFIDENCE
            </span>
          </div>
        </Link>

        {/* Navigation Links (Shown for both logged in and logged out users) */}
        <ul className="hidden items-center gap-8 lg:flex">
          {baseLinks.map((l) => (
            <li key={l.to}>
              <Link
                to={l.to}
                activeProps={{ className: "text-gold font-semibold" }}
                activeOptions={{ exact: l.to === "/" }}
                className="relative text-xs uppercase tracking-[0.22em] text-muted-foreground transition-colors duration-300 hover:text-gold after:absolute after:-bottom-2 after:left-0 after:h-px after:w-0 after:bg-gold after:transition-all after:duration-300 hover:after:w-full"
              >
                {l.label}
              </Link>
            </li>
          ))}
        </ul>

        {/* Right Section Controls */}
        <div className="flex items-center gap-3 sm:gap-4">
          {isLoggedIn ? (
            <div className="flex items-center gap-2">
              <Link
                to={accountPath}
                activeProps={{ className: "border-gold text-gold font-bold bg-gold/15" }}
                className="hidden sm:flex items-center gap-1.5 rounded-sm border border-gold/40 bg-gold/10 px-4 py-2 text-xs font-bold uppercase tracking-[0.18em] text-gold transition-all hover:bg-gold hover:text-primary-foreground shadow-sm"
              >
                <User className="size-3.5" />
                {isAdmin ? "Admin" : "My Account"}
              </Link>
              <button
                aria-label="Toggle menu"
                onClick={() => setOpen((o) => !o)}
                className="text-gold lg:hidden p-1"
              >
                {open ? <X className="size-6" /> : <Menu className="size-6" />}
              </button>
            </div>
          ) : (
            <>
              <Link
                to="/login"
                className="hidden text-xs uppercase tracking-[0.2em] text-muted-foreground transition-colors hover:text-gold sm:block"
              >
                Login
              </Link>
              <Link
                to="/products"
                className="btn-gold hover:btn-gold-hover flex items-center gap-2 rounded-sm px-5 py-2.5 text-[10px]"
              >
                <ShoppingBag className="size-3.5" />
                Shop
              </Link>
              <button
                aria-label="Toggle menu"
                onClick={() => setOpen((o) => !o)}
                className="text-gold lg:hidden p-1"
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
          open ? "mt-4 max-h-[420px]" : "max-h-0"
        }`}
      >
        <ul className="flex flex-col gap-1 px-6 py-4">
          {baseLinks.map((l) => (
            <li key={l.to}>
              <Link
                to={l.to}
                onClick={() => setOpen(false)}
                className="block py-2.5 text-sm uppercase tracking-[0.2em] text-muted-foreground transition-colors hover:text-gold"
              >
                {l.label}
              </Link>
            </li>
          ))}
          {isLoggedIn ? (
            <li>
              <Link
                to={accountPath}
                onClick={() => setOpen(false)}
                className="block py-2.5 text-sm font-bold uppercase tracking-[0.2em] text-gold"
              >
                {isAdmin ? "Admin Portal" : "My Account"}
              </Link>
            </li>
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
