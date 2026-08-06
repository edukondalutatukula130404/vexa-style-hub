import { Link, useNavigate } from "react-router-dom";
import { useState } from "react";
import { Lock, Mail, User, AlertCircle, Eye, EyeOff } from "lucide-react";
import { Reveal } from "@/components/Reveal";
import { setLoggedIn, registerApi, type AuthUser } from "@/lib/auth";

export function Register() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg("");

    if (password !== confirmPassword) {
      setErrorMsg("Passwords do not match. Please re-enter.");
      return;
    }

    if (password.length < 6) {
      setErrorMsg("Password must be at least 6 characters long.");
      return;
    }

    setLoading(true);

    try {
      // Create user document in MongoDB database
      const res = await registerApi(name, email, password);
      setLoggedIn(res.user, res.token);

      const redirectTarget = localStorage.getItem("vexa_redirect_after_login");
      localStorage.removeItem("vexa_redirect_after_login");

      if (redirectTarget) {
        window.location.href = redirectTarget;
      } else {
        navigate("/");
      }
    } catch (err: any) {
      console.warn("Registration API error:", err.message);

      // Local fallback if API server disconnected
      const newUser: AuthUser = {
        name: name.trim(),
        email: email.trim(),
        role: "user",
      };
      setLoggedIn(newUser, "demo-user-token");

      const redirectTarget = localStorage.getItem("vexa_redirect_after_login");
      localStorage.removeItem("vexa_redirect_after_login");

      if (redirectTarget) {
        window.location.href = redirectTarget;
      } else {
        navigate("/dashboard");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="mx-auto grid max-w-md px-5 pt-24 sm:pt-28 pb-16">
      <div className="rounded-2xl border border-gold/40 bg-card p-6 sm:p-9 shadow-goldy">
        <div className="text-center">
            <span className="font-display text-2xl tracking-[0.35em] text-gold-gradient">
              VEXA
            </span>
            <h1 className="mt-6 font-display text-3xl">Create account</h1>
            <p className="mt-2 text-sm text-muted-foreground">
              Members get 30% off their first order and early drop access.
            </p>
          </div>

          {errorMsg && (
            <div className="mt-6 flex items-center gap-2.5 rounded-sm border border-destructive/50 bg-destructive/10 p-3.5 text-xs text-destructive">
              <AlertCircle className="size-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="mt-7 space-y-5">
            <div>
              <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
                Full Name
              </label>
              <div className="mt-2 flex items-center gap-3 rounded-sm border border-border bg-background px-4 transition-colors duration-300 focus-within:border-gold">
                <User className="size-4 text-gold shrink-0" />
                <input
                  required
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Aarav Sharma"
                  className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground/60"
                />
              </div>
            </div>

            <div>
              <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
                Email Address
              </label>
              <div className="mt-2 flex items-center gap-3 rounded-sm border border-border bg-background px-4 transition-colors duration-300 focus-within:border-gold">
                <Mail className="size-4 text-gold shrink-0" />
                <input
                  required
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@email.com"
                  className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground/60"
                />
              </div>
            </div>

            <div>
              <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
                Password
              </label>
              <div className="mt-2 flex items-center gap-3 rounded-sm border border-border bg-background px-4 transition-colors duration-300 focus-within:border-gold">
                <Lock className="size-4 text-gold shrink-0" />
                <input
                  required
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground/60"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="text-muted-foreground hover:text-gold transition-colors p-1"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                >
                  {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </div>

            <div>
              <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
                Confirm Password
              </label>
              <div className="mt-2 flex items-center gap-3 rounded-sm border border-border bg-background px-4 transition-colors duration-300 focus-within:border-gold">
                <Lock className="size-4 text-gold shrink-0" />
                <input
                  required
                  type={showConfirmPassword ? "text" : "password"}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground/60"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="text-muted-foreground hover:text-gold transition-colors p-1"
                  aria-label={showConfirmPassword ? "Hide password" : "Show password"}
                >
                  {showConfirmPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </div>

            <label className="flex items-start gap-2 text-xs text-muted-foreground cursor-pointer">
              <input required type="checkbox" className="mt-0.5 accent-[var(--gold)]" />
              I agree to the VEXA terms of service and privacy policy.
            </label>

            <button
              disabled={loading}
              className="btn-gold hover:btn-gold-hover w-full rounded-sm py-4 text-xs font-bold uppercase tracking-widest disabled:opacity-70"
            >
              {loading ? "Creating Account…" : "Create Account"}
            </button>
          </form>

          <p className="mt-7 text-center text-sm text-muted-foreground">
            Already a member?{" "}
            <Link to="/login" className="text-gold font-semibold hover:underline">
              Sign in
            </Link>
          </p>
        </div>
    </section>
  );
}
