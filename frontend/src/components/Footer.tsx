import { Link, useLocation } from "react-router-dom";
import { Instagram, Twitter, Facebook, Mail, Phone } from "lucide-react";

export function Footer() {
  const location = useLocation();

  if (location.pathname.startsWith("/admin") || (typeof window !== "undefined" && window.location.pathname.startsWith("/admin"))) {
    return null;
  }

  return (
    <footer className="border-t border-border bg-surface/40">
      <div className="mx-auto grid max-w-7xl gap-8 sm:gap-12 px-5 py-12 sm:py-16 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        <div>
          <div className="flex items-center gap-2.5">
            <img src="/vexa_logo.png" alt="VEXA Logo" className="size-8 rounded-md object-cover" />
            <span className="font-display text-2xl tracking-[0.35em] text-gold-gradient">
              VEXA
            </span>
          </div>
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
          </ul>
        </div>

        <div>
          <h3 className="text-xs uppercase tracking-[0.25em] text-gold font-bold">Contact & Support</h3>
          <p className="mt-4 text-xs text-muted-foreground leading-relaxed">
            Have questions or need order assistance? Reach out to our support team.
          </p>
          <ul className="mt-4 space-y-2.5 text-xs">
            <li>
              <a
                href="mailto:support@vexa.store"
                className="group flex items-center gap-3 rounded-lg border border-border bg-card/60 p-2.5 transition-all hover:border-gold hover:bg-gold/10 shadow-xs"
              >
                <div className="flex size-8 shrink-0 items-center justify-center rounded-md border border-gold/40 bg-gold/15 text-gold">
                  <Mail className="size-4" />
                </div>
                <div className="overflow-hidden">
                  <span className="block text-[9px] uppercase tracking-wider text-muted-foreground font-semibold">Email Us</span>
                  <span className="font-bold text-foreground group-hover:text-gold transition-colors truncate block">
                    support@vexa.store
                  </span>
                </div>
              </a>
            </li>

            <li>
              <a
                href="tel:+919876543210"
                className="group flex items-center gap-3 rounded-lg border border-border bg-card/60 p-2.5 transition-all hover:border-gold hover:bg-gold/10 shadow-xs"
              >
                <div className="flex size-8 shrink-0 items-center justify-center rounded-md border border-gold/40 bg-gold/15 text-gold">
                  <Phone className="size-4" />
                </div>
                <div>
                  <span className="block text-[9px] uppercase tracking-wider text-muted-foreground font-semibold">Call / WhatsApp</span>
                  <span className="font-bold text-foreground group-hover:text-gold transition-colors">
                    +91 98765 43210
                  </span>
                </div>
              </a>
            </li>
          </ul>
        </div>
      </div>

      <div className="py-6 text-center text-xs tracking-[0.15em] text-muted-foreground space-y-2">
        <div className="flex items-center justify-center gap-3 py-1">
          <img src="/vexa_logo.png" alt="VEXA Logo" className="size-9 sm:size-11 rounded-lg object-cover" />
          <div className="font-display text-3xl sm:text-4xl lg:text-5xl font-extrabold tracking-[0.35em] text-gold-gradient">
            V E X A
          </div>
        </div>
        <p>© {new Date().getFullYear()} VEXA APPAREL — ALL RIGHTS RESERVED</p>
      </div>
    </footer>
  );
}
