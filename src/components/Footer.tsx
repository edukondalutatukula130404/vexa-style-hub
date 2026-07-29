import { Link } from "@tanstack/react-router";
import { Instagram, Twitter, Facebook, Mail } from "lucide-react";

export function Footer() {
  return (
    <footer className="border-t border-border bg-surface/40">
      <div className="mx-auto grid max-w-7xl gap-12 px-5 py-16 md:grid-cols-4">
        <div>
          <span className="font-display text-2xl tracking-[0.35em] text-gold-gradient">
            VEXA
          </span>
          <p className="mt-4 max-w-xs text-sm leading-relaxed text-muted-foreground">
            Premium oversized essentials, engineered from long-staple cotton and
            finished by hand. Wear confidence. Wear style.
          </p>
          <div className="mt-6 flex gap-4">
            {[Instagram, Twitter, Facebook, Mail].map((Icon, i) => (
              <a
                key={i}
                href="#"
                aria-label="social link"
                className="flex size-9 items-center justify-center rounded-full border border-border text-muted-foreground transition-all duration-300 hover:-translate-y-1 hover:border-gold hover:text-gold"
              >
                <Icon className="size-4" />
              </a>
            ))}
          </div>
        </div>

        <div>
          <h3 className="text-xs uppercase tracking-[0.25em] text-gold">Shop</h3>
          <ul className="mt-5 space-y-3 text-sm text-muted-foreground">
            {["Oversized", "Classic", "Limited Drops", "Gift Cards"].map((t) => (
              <li key={t}>
                <Link to="/products" className="transition-colors hover:text-gold">
                  {t}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        <div>
          <h3 className="text-xs uppercase tracking-[0.25em] text-gold">Company</h3>
          <ul className="mt-5 space-y-3 text-sm text-muted-foreground">
            <li><Link to="/about" className="transition-colors hover:text-gold">About Us</Link></li>
            <li><Link to="/contact" className="transition-colors hover:text-gold">Contact Us</Link></li>
            <li><Link to="/faq" className="transition-colors hover:text-gold">FAQ</Link></li>
            <li><Link to="/admin" className="transition-colors hover:text-gold">Admin Dashboard</Link></li>
          </ul>
        </div>

        <div>
          <h3 className="text-xs uppercase tracking-[0.25em] text-gold">Newsletter</h3>
          <p className="mt-5 text-sm text-muted-foreground">
            Early access to limited drops and 30% off your first order.
          </p>
          <form
            onSubmit={(e) => e.preventDefault()}
            className="mt-4 flex overflow-hidden rounded-sm border border-border"
          >
            <input
              type="email"
              required
              placeholder="your@email.com"
              className="w-full bg-transparent px-3 py-2.5 text-sm outline-none placeholder:text-muted-foreground focus:border-gold"
            />
            <button className="btn-gold hover:btn-gold-hover px-4 text-[10px]">Join</button>
          </form>
        </div>
      </div>

      <div className="border-t border-border py-6 text-center text-xs tracking-[0.15em] text-muted-foreground">
        © {new Date().getFullYear()} VEXA APPAREL — ALL RIGHTS RESERVED
      </div>
    </footer>
  );
}
