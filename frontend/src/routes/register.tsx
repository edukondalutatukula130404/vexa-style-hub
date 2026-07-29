import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useState } from "react";
import { Lock, Mail, User } from "lucide-react";
import { Reveal } from "@/components/Reveal";
import { IconField } from "./login";

export const Route = createFileRoute("/register")({
  head: () => ({
    meta: [
      { title: "Create Account | VEXA" },
      {
        name: "description",
        content:
          "Register for a VEXA account and unlock member pricing, early drop access and free express shipping.",
      },
      { property: "og:title", content: "Create Account | VEXA" },
      {
        property: "og:description",
        content: "Member pricing, early drops and free express shipping.",
      },
    ],
  }),
  component: Register,
});

function Register() {
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
            <h1 className="mt-6 font-display text-3xl">Create account</h1>
            <p className="mt-2 text-sm text-muted-foreground">
              Members get 30% off their first order.
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
            <IconField icon={User} type="text" placeholder="Aarav Sharma" label="Full name" />
            <IconField icon={Mail} type="email" placeholder="you@email.com" label="Email" />
            <IconField icon={Lock} type="password" placeholder="••••••••" label="Password" />
            <IconField
              icon={Lock}
              type="password"
              placeholder="••••••••"
              label="Confirm password"
            />

            <label className="flex items-start gap-2 text-xs text-muted-foreground">
              <input required type="checkbox" className="mt-0.5 accent-[var(--gold)]" />
              I agree to the terms of service and privacy policy.
            </label>

            <button
              disabled={loading}
              className="btn-gold hover:btn-gold-hover w-full rounded-sm py-4 text-xs disabled:opacity-70"
            >
              {loading ? "Creating…" : "Create account"}
            </button>
          </form>

          <p className="mt-7 text-center text-sm text-muted-foreground">
            Already a member?{" "}
            <Link to="/login" className="text-gold hover:underline">
              Sign in
            </Link>
          </p>
        </div>
      </Reveal>
    </section>
  );
}
