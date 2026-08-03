import { useNavigate, useSearchParams } from "react-router-dom";
import { useState } from "react";
import { Lock, AlertCircle, Eye, EyeOff, CheckCircle2, ShieldCheck, KeyRound } from "lucide-react";
import { Reveal } from "@/components/Reveal";
import { setLoggedIn, resetPasswordApi } from "@/lib/auth";

export function ResetPassword() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const token = searchParams.get("token") || "";
  const userEmail = searchParams.get("email") || "";

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg("");
    setSuccessMsg("");

    if (!token && !userEmail) {
      setErrorMsg("Missing or invalid password reset token. Please request a new link.");
      return;
    }

    if (password.length < 6) {
      setErrorMsg("Password must be at least 6 characters long.");
      return;
    }

    if (password !== confirmPassword) {
      setErrorMsg("Passwords do not match. Please verify your entries.");
      return;
    }

    setLoading(true);

    try {
      const res = await resetPasswordApi({ token, email: userEmail, password });
      setSuccessMsg(res.message || "Password updated successfully!");
      setLoggedIn(res.user, res.token);

      setTimeout(() => {
        if (res.user.role === "admin") {
          navigate("/admin");
        } else {
          navigate("/");
        }
      }, 2000);
    } catch (err: any) {
      setErrorMsg(err.message || "Failed to reset password. The link may be expired.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="mx-auto grid max-w-md px-5 py-20">
      <Reveal>
        <div className="rounded-sm border border-border bg-card p-9 shadow-goldy space-y-6">
          <div className="text-center">
            <div className="mx-auto flex size-14 items-center justify-center rounded-full border border-gold bg-gold/15 text-gold shadow-goldy mb-4">
              <KeyRound className="size-7" />
            </div>
            <span className="font-display text-2xl tracking-[0.35em] text-gold-gradient">
              VEXA
            </span>
            <h1 className="mt-4 font-display text-3xl">Set New Password</h1>
            {userEmail && (
              <p className="mt-1 text-xs text-gold font-semibold">
                Resetting password for: <span className="text-foreground">{userEmail}</span>
              </p>
            )}
          </div>

          {!token && !userEmail ? (
            <div className="space-y-4 text-center py-4">
              <div className="flex items-center justify-center gap-2.5 rounded-sm border border-destructive/50 bg-destructive/10 p-4 text-xs text-destructive">
                <AlertCircle className="size-5 shrink-0" />
                <span>Invalid or missing reset token link. Please request a new password reset link.</span>
              </div>
              <button
                onClick={() => navigate("/login")}
                className="btn-gold hover:btn-gold-hover w-full rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider"
              >
                Back to Sign In
              </button>
            </div>
          ) : successMsg ? (
            <div className="space-y-4 text-center py-4 animate-in fade-in duration-300">
              <div className="flex items-center justify-center gap-2 text-emerald-500 font-bold text-sm">
                <CheckCircle2 className="size-6" />
                <span>{successMsg}</span>
              </div>
              <p className="text-xs text-muted-foreground">
                Redirecting you to your account dashboard...
              </p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-5">
              {errorMsg && (
                <div className="flex items-center gap-2.5 rounded-sm border border-destructive/50 bg-destructive/10 p-3.5 text-xs text-destructive">
                  <AlertCircle className="size-4 shrink-0" />
                  <span>{errorMsg}</span>
                </div>
              )}

              <div>
                <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
                  New Password
                </label>
                <div className="mt-2 flex items-center gap-3 rounded-sm border border-border bg-background px-4 focus-within:border-gold">
                  <Lock className="size-4 text-gold shrink-0" />
                  <input
                    required
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="At least 6 characters"
                    className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground/60"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="text-muted-foreground hover:text-gold transition-colors p-1"
                  >
                    {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                  </button>
                </div>
              </div>

              <div>
                <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
                  Confirm New Password
                </label>
                <div className="mt-2 flex items-center gap-3 rounded-sm border border-border bg-background px-4 focus-within:border-gold">
                  <Lock className="size-4 text-gold shrink-0" />
                  <input
                    required
                    type={showPassword ? "text" : "password"}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Re-enter new password"
                    className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground/60"
                  />
                </div>
              </div>

              <button
                disabled={loading}
                className="btn-gold hover:btn-gold-hover w-full rounded-sm py-4 text-xs font-bold uppercase tracking-widest disabled:opacity-70 cursor-pointer"
              >
                {loading ? "Updating Password..." : "Update Password & Sign In"}
              </button>
            </form>
          )}
        </div>
      </Reveal>
    </section>
  );
}
