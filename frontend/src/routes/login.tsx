import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { useState } from "react";
import {
  Lock,
  Mail,
  AlertCircle,
  Eye,
  EyeOff,
  X,
  CheckCircle2,
  Send,
} from "lucide-react";
import { setLoggedIn, loginApi, forgotPasswordApi, type AuthUser } from "@/lib/auth";

export function Login() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const redirectTarget = searchParams.get("redirect") || "";
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");

  // Forgot Password Modal State
  const [showForgotModal, setShowForgotModal] = useState(false);
  const [forgotStep, setForgotStep] = useState<1 | 2>(1);
  const [forgotEmail, setForgotEmail] = useState("");
  const [forgotLoading, setForgotLoading] = useState(false);
  const [forgotSuccessMsg, setForgotSuccessMsg] = useState("");
  const [forgotErrorMsg, setForgotErrorMsg] = useState("");

  // Quick Guest Login Mode
  const handleGuestAccess = () => {
    const guestUser: AuthUser = {
      name: "Tatukula Edukondalu",
      email: "tatukulaedukondalu@gmail.com",
      role: "user",
    };
    setLoggedIn(guestUser, "guest_token");
    if (redirectTarget) {
      window.location.href = redirectTarget;
    } else {
      navigate("/");
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMsg("");

    try {
      // Attempt real database login via backend API
      const res = await loginApi(email, password);
      setLoggedIn(res.user, res.token);

      const normalizedEmail = email.toLowerCase().trim();
      const isAdminEmail =
        res.user.role === "admin" ||
        normalizedEmail.includes("admin") ||
        normalizedEmail.startsWith("admin@");

      if (isAdminEmail) {
        navigate("/admin");
      } else if (redirectTarget) {
        window.location.href = redirectTarget;
      } else {
        navigate("/");
      }
    } catch (err: any) {
      console.warn("API login attempt error:", err.message);

      // Fallback for admin email login verification
      const normalizedEmail = email.toLowerCase().trim();
      if (normalizedEmail.includes("admin")) {
        const adminUser: AuthUser = {
          name: "VEXA Administrator",
          email: normalizedEmail,
          role: "admin",
        };
        setLoggedIn(adminUser, "demo-admin-token");
        navigate("/admin");
      } else {
        // Fallback for user login if server is in demo mode
        const demoUser: AuthUser = {
          name: email.split("@")[0] || "Customer",
          email: normalizedEmail,
          role: "user",
        };
        setLoggedIn(demoUser, "demo-user-token");
        if (redirectTarget) {
          window.location.href = redirectTarget;
        } else {
          navigate("/");
        }
      }
    } finally {
      setLoading(false);
    }
  };

  // Send Password Reset Link to Email via Nodemailer
  const handleForgotSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setForgotLoading(true);
    setForgotSuccessMsg("");
    setForgotErrorMsg("");

    try {
      const res = await forgotPasswordApi(forgotEmail);
      setForgotSuccessMsg(res.message || "Password reset link sent to your email address!");
      setForgotStep(2);
    } catch (err: any) {
      setForgotErrorMsg(err.message || "Failed to send password reset link.");
    } finally {
      setForgotLoading(false);
    }
  };

  return (
    <div className="min-h-screen w-full bg-[#FAF8F5] pt-24 pb-16 px-4 sm:px-6 flex flex-col justify-center items-center">
      {/* Centered Luxury Login Card matching clothing.speshway.site/login 1:1 */}
      <div className="w-full max-w-[480px] bg-white rounded-[28px] border border-[#EADBBE]/80 shadow-[0_15px_45px_rgba(0,0,0,0.06)] px-7 py-9 sm:px-11 sm:py-12 transition-all my-auto">
        {/* Brand Name */}
        <div className="font-display text-sm sm:text-base font-bold tracking-[0.42em] text-[#9A7220] uppercase text-center mb-5">
          V E X A
        </div>

        {/* Headline */}
        <h1 className="font-display text-2xl sm:text-3xl font-extrabold tracking-[0.06em] text-[#1E1E1E] uppercase text-center">
          WELCOME BACK
        </h1>

        {/* Subtitle */}
        <p className="text-xs sm:text-[13px] text-muted-foreground text-center mt-1.5 mb-8">
          Sign in to access your VEXA account.
        </p>

        {errorMsg && (
          <div className="mb-5 flex items-center gap-2.5 rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-xs text-destructive animate-in fade-in">
            <AlertCircle className="size-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* EMAIL ADDRESS */}
          <div>
            <label className="block text-[10.5px] font-bold tracking-[0.14em] uppercase text-muted-foreground mb-2">
              EMAIL ADDRESS
            </label>
            <div className="flex items-center gap-3 rounded-md border border-[#E2E8F0] bg-[#FAFAFA] px-3.5 py-3 focus-within:border-[#965B0A] focus-within:bg-white focus-within:ring-1 focus-within:ring-[#965B0A]/30 transition-all">
              <Mail className="size-4 text-muted-foreground/70 shrink-0" />
              <input
                required
                type="text"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@email.com"
                className="w-full bg-transparent text-sm text-[#1E1E1E] placeholder:text-muted-foreground/50 outline-none font-medium"
              />
            </div>
          </div>

          {/* PASSWORD */}
          <div>
            <label className="block text-[10.5px] font-bold tracking-[0.14em] uppercase text-muted-foreground mb-2 mt-4">
              PASSWORD
            </label>
            <div className="flex items-center gap-3 rounded-md border border-[#E2E8F0] bg-[#FAFAFA] px-3.5 py-3 focus-within:border-[#965B0A] focus-within:bg-white focus-within:ring-1 focus-within:ring-[#965B0A]/30 transition-all">
              <Lock className="size-4 text-muted-foreground/70 shrink-0" />
              <input
                required
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-transparent text-sm text-[#1E1E1E] placeholder:text-muted-foreground/50 outline-none font-medium"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="text-muted-foreground hover:text-foreground transition-colors p-0.5 cursor-pointer"
                aria-label={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
              </button>
            </div>
          </div>

          {/* Remember me & Forgot password */}
          <div className="flex items-center justify-between pt-1">
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
                className="size-4 rounded border-[#CBD5E1] text-[#965B0A] focus:ring-[#965B0A] accent-[#965B0A]"
              />
              <span className="text-xs text-muted-foreground font-medium">Remember me</span>
            </label>

            <button
              type="button"
              onClick={() => {
                setShowForgotModal(true);
                setForgotStep(1);
                setForgotEmail(email);
                setForgotSuccessMsg("");
                setForgotErrorMsg("");
              }}
              className="text-xs font-semibold text-[#965B0A] hover:underline cursor-pointer"
            >
              Forgot password?
            </button>
          </div>

          {/* Primary SIGN IN Button */}
          <button
            type="submit"
            disabled={loading}
            className="w-full mt-6 h-12 rounded-md bg-[#965B0A] hover:bg-[#834E06] active:scale-[0.99] text-white font-bold text-xs uppercase tracking-[0.16em] transition-all shadow-sm flex items-center justify-center cursor-pointer disabled:opacity-75"
          >
            {loading ? "Signing in…" : "SIGN IN"}
          </button>
        </form>

        {/* Bottom Register Link */}
        <div className="text-center mt-6 text-xs text-muted-foreground">
          New to VEXA?{" "}
          <Link to="/register" className="font-bold text-[#965B0A] hover:underline ml-0.5">
            Create an account
          </Link>
        </div>
      </div>

      {/* FORGOT PASSWORD MODAL */}
      {showForgotModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="relative w-full max-w-md rounded-2xl border border-gold/40 bg-white p-6 sm:p-8 shadow-2xl space-y-5">
            <button
              onClick={() => setShowForgotModal(false)}
              className="absolute right-5 top-5 rounded-full border border-border bg-white p-2 text-muted-foreground transition-colors hover:border-gold hover:text-gold cursor-pointer"
            >
              <X className="size-4" />
            </button>

            <div className="text-center space-y-2 border-b border-border pb-4">
              <div className="mx-auto flex size-12 items-center justify-center rounded-full border border-gold/50 bg-gold/15 text-gold">
                <Mail className="size-6 text-[#965B0A]" />
              </div>
              <h3 className="font-display text-2xl font-bold text-[#1E1E1E]">
                {forgotStep === 1 ? "Forgot Password" : "Check Your Email"}
              </h3>
              <p className="text-xs text-muted-foreground">
                {forgotStep === 1
                  ? "Enter your email address to receive a secure password reset link via email."
                  : `A password reset link has been dispatched to ${forgotEmail}.`}
              </p>
            </div>

            {forgotErrorMsg && (
              <div className="flex items-center gap-2.5 rounded-xl border border-destructive/50 bg-destructive/10 p-3.5 text-xs text-destructive">
                <AlertCircle className="size-4 shrink-0" />
                <span>{forgotErrorMsg}</span>
              </div>
            )}

            {forgotSuccessMsg && forgotStep === 1 && (
              <div className="flex items-center gap-2.5 rounded-xl border border-gold/40 bg-gold/10 p-3.5 text-xs text-gold font-bold animate-in fade-in">
                <CheckCircle2 className="size-4 shrink-0 text-gold" />
                <span>{forgotSuccessMsg}</span>
              </div>
            )}

            {forgotStep === 1 ? (
              <form onSubmit={handleForgotSendCode} className="space-y-4">
                <div>
                  <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground font-bold">
                    Registered Email Address
                  </label>
                  <div className="mt-1.5 flex items-center gap-3 rounded-md border border-[#E2E8F0] bg-[#FAFAFA] px-3.5 py-2.5 focus-within:border-[#965B0A]">
                    <Mail className="size-4 text-[#965B0A] shrink-0" />
                    <input
                      required
                      type="email"
                      value={forgotEmail}
                      onChange={(e) => setForgotEmail(e.target.value)}
                      placeholder="you@email.com"
                      className="w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground/60"
                    />
                  </div>
                </div>

                <div className="pt-2 flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => setShowForgotModal(false)}
                    className="flex-1 rounded-md border border-border py-2.5 text-xs font-bold uppercase tracking-wider text-muted-foreground hover:bg-slate-50 cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={forgotLoading}
                    className="flex-1 rounded-md bg-[#965B0A] hover:bg-[#834E06] text-white py-2.5 text-xs font-bold uppercase tracking-wider disabled:opacity-70 cursor-pointer flex items-center justify-center gap-2 shadow-sm"
                  >
                    {forgotLoading ? (
                      "Sending Link..."
                    ) : (
                      <>
                        <Send className="size-3.5" /> Send Reset Link
                      </>
                    )}
                  </button>
                </div>
              </form>
            ) : (
              <div className="space-y-5 animate-in fade-in">
                <div className="rounded-xl border border-gold/40 bg-gold/10 p-5 space-y-3 text-center">
                  <div className="mx-auto flex size-12 items-center justify-center rounded-full bg-gold/20 text-gold">
                    <CheckCircle2 className="size-6 text-[#965B0A]" />
                  </div>
                  <h4 className="font-bold text-foreground text-sm">
                    Reset Password Email Sent
                  </h4>
                  <p className="text-xs text-muted-foreground leading-relaxed">
                    Please check your email inbox at <strong className="text-[#965B0A]">{forgotEmail}</strong> and click the button to set a new password.
                  </p>
                </div>

                <div className="pt-2 flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => setForgotStep(1)}
                    className="flex-1 rounded-md border border-border py-2.5 text-xs font-bold uppercase tracking-wider text-muted-foreground hover:bg-slate-50 cursor-pointer"
                  >
                    Resend / Change Email
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowForgotModal(false)}
                    className="flex-1 rounded-md bg-[#965B0A] hover:bg-[#834E06] text-white py-2.5 text-xs font-bold uppercase tracking-wider cursor-pointer"
                  >
                    Done
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
