import { Link } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Menu, X, ShoppingBag } from "lucide-react";

const links = [
  { to: "/", label: "Home" },
  { to: "/products", label: "Products" },
  { to: "/about", label: "About Us" },
  { to: "/contact", label: "Contact Us" },
  { to: "/faq", label: "FAQ" },
  { to: "/dashboard", label: "Dashboard" },
];

export function Navbar() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    onScroll();
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition-all duration-500 ${
        scrolled
          ? "border-b border-border bg-background/85 backdrop-blur-xl py-3"
          : "py-6"
      }`}
    >
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-5">
        <Link to="/" className="group flex flex-col leading-none">
          <span className="font-display text-2xl tracking-[0.35em] text-gold-gradient">
            VEXA
          </span>
          <span className="mt-1 text-[9px] tracking-[0.34em] text-muted-foreground">
            WEAR CONFIDENCE
          </span>
        </Link>

        <ul className="hidden items-center gap-8 lg:flex">
          {links.map((l) => (
            <li key={l.to}>
              <Link
                to={l.to}
                activeProps={{ className: "text-gold" }}
                activeOptions={{ exact: l.to === "/" }}
                className="relative text-xs uppercase tracking-[0.22em] text-muted-foreground transition-colors duration-300 hover:text-gold after:absolute after:-bottom-2 after:left-0 after:h-px after:w-0 after:bg-gold after:transition-all after:duration-300 hover:after:w-full"
              >
                {l.label}
              </Link>
            </li>
          ))}
        </ul>

        <div className="flex items-center gap-3">
          <Link
            to="/login"
            className="hidden text-xs uppercase tracking-[0.2em] text-muted-foreground transition-colors hover:text-gold sm:block"
          >
            Login
          </Link>
          <Link
            to="/products"
            className="btn-gold hover:btn-gold-hover hidden items-center gap-2 rounded-sm px-5 py-2.5 text-[10px] sm:flex"
          >
            <ShoppingBag className="size-3.5" />
            Shop
          </Link>
          <button
            aria-label="Toggle menu"
            onClick={() => setOpen((o) => !o)}
            className="text-gold lg:hidden"
          >
            {open ? <X className="size-6" /> : <Menu className="size-6" />}
          </button>
        </div>
      </nav>

      <div
        className={`overflow-hidden border-t border-border bg-background/95 backdrop-blur-xl transition-all duration-500 lg:hidden ${
          open ? "mt-4 max-h-[420px]" : "max-h-0"
        }`}
      >
        <ul className="flex flex-col gap-1 px-6 py-4">
          {[...links, { to: "/login", label: "Login" }, { to: "/register", label: "Register" }].map(
            (l) => (
              <li key={l.to}>
                <Link
                  to={l.to}
                  onClick={() => setOpen(false)}
                  className="block py-2.5 text-sm uppercase tracking-[0.2em] text-muted-foreground transition-colors hover:text-gold"
                >
                  {l.label}
                </Link>
              </li>
            ),
          )}
        </ul>
      </div>
    </header>
  );
}
