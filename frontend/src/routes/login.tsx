import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useState } from "react";
import { Lock, Mail } from "lucide-react";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/login")({
  head: () => ({
    meta: [
      { title: "Login | VEXA Account" },
      {
        name: "description",
        content: "Sign in to your VEXA account to track orders, save sizes and access member drops.",
      },
      { property: "og:title", content: "Login | VEXA" },
      { property: "og:description", content: "Sign in to your VEXA account." },
    ],
  }),
  component: Login,
});

function Login() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);

  return (
    <section className="mx-auto grid max-w-md px-5 py-20">
      <Reveal>
        <div className="rounded-sm border border-border bg-card p-9 shadow-goldy">
          <div className="text-center">
            <span className="font-display text-2xl tracking-[0.35em] text-gold-gradient">
              VEXA
            </span>
            <h1 className="mt-6 font-display text-3xl">Welcome back</h1>
            <p className="mt-2 text-sm text-muted-foreground">
              Sign in to continue to your dashboard.
            </p>
          </div>

          <form
            onSubmit={(e) => {
              e.preventDefault();
              setLoading(true);
              setTimeout(() => navigate({ to: "/dashboard" }), 600);
            }}
            className="mt-9 space-y-5"
          >
            <IconField icon={Mail} type="email" placeholder="you@email.com" label="Email" />
            <IconField icon={Lock} type="password" placeholder="••••••••" label="Password" />

            <div className="flex items-center justify-between text-xs text-muted-foreground">
              <label className="flex items-center gap-2">
                <input type="checkbox" className="accent-[var(--gold)]" /> Remember me
              </label>
              <a href="#" className="text-gold hover:underline">
                Forgot password?
              </a>
            </div>

            <button
              disabled={loading}
              className="btn-gold hover:btn-gold-hover w-full rounded-sm py-4 text-xs disabled:opacity-70"
            >
              {loading ? "Signing in…" : "Sign in"}
            </button>
          </form>

          <p className="mt-7 text-center text-sm text-muted-foreground">
            New to VEXA?{" "}
            <Link to="/register" className="text-gold hover:underline">
              Create an account
            </Link>
          </p>
        </div>
      </Reveal>
    </section>
  );
}

export function IconField({
  icon: Icon,
  type,
  placeholder,
  label,
}: {
  icon: React.ElementType;
  type: string;
  placeholder: string;
  label: string;
}) {
  return (
    <div>
      <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
        {label}
      </label>
      <div className="mt-2 flex items-center gap-3 rounded-sm border border-border bg-background px-4 transition-colors duration-300 focus-within:border-gold">
        <Icon className="size-4 text-gold" />
        <input
          required
          type={type}
          placeholder={placeholder}
          className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground/60"
        />
      </div>
    </div>
  );
}
