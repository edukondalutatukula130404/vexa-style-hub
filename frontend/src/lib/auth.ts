import { useState, useEffect } from "react";

export type UserRole = "user" | "admin";

export type AuthUser = {
  _id?: string;
  name: string;
  email: string;
  role: UserRole;
  token?: string;
};

export const getApiUrl = (): string => {
  if (typeof window !== "undefined") {
    const host = window.location.hostname;
    if (host === "localhost" || host === "127.0.0.1" || host.startsWith("192.168.")) {
      return `${window.location.protocol}//${host}:5000/api`;
    }
  }
  if (typeof import.meta !== "undefined" && import.meta.env && import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL;
  }
  return "http://localhost:5000/api";
};

export const API_URL = getApiUrl();

export function getAuthUser(): AuthUser | null {
  if (typeof window === "undefined") return null;
  const data = localStorage.getItem("vexa_auth_user");
  if (!data) return null;
  try {
    const parsed = JSON.parse(data);
    if (parsed && typeof parsed === "object") {
      // If cached session is Guest Collector, upgrade to real user profile
      if (parsed.email === "guest@vexa.app" || (parsed.name && parsed.name.toLowerCase().includes("guest"))) {
        const upgradedUser: AuthUser = {
          name: "Tatukula Edukondalu",
          email: "tatukulaedukondalu@gmail.com",
          role: "user",
          token: parsed.token || "vexa-user-token",
        };
        localStorage.setItem("vexa_auth_user", JSON.stringify(upgradedUser));
        return upgradedUser;
      }
    }
    return parsed;
  } catch {
    return null;
  }
}

export function getIsLoggedIn(): boolean {
  return getAuthUser() !== null;
}

export function getUserRole(): UserRole | null {
  const user = getAuthUser();
  return user ? user.role : null;
}

export function setLoggedIn(user: AuthUser | boolean, token?: string) {
  if (typeof window === "undefined") return;
  if (typeof user === "boolean") {
    if (!user) {
      localStorage.removeItem("vexa_auth_user");
      localStorage.removeItem("vexa_token");
    }
  } else {
    localStorage.setItem("vexa_auth_user", JSON.stringify(user));
    if (token) {
      localStorage.setItem("vexa_token", token);
    }
  }
  window.dispatchEvent(new Event("vexa-auth-change"));
}

export function logoutUser() {
  if (typeof window !== "undefined") {
    localStorage.removeItem("vexa_auth_user");
    localStorage.removeItem("vexa_token");
    localStorage.removeItem("vexa_cart");
    window.dispatchEvent(new Event("vexa-auth-change"));
    window.location.href = "/login";
  }
}

export async function loginApi(email: string, password: string): Promise<{ token: string; user: AuthUser }> {
  try {
    const res = await fetch(`${API_URL}/users/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.message || "Invalid email or password");
    }
    return data;
  } catch (err: any) {
    if (err.message === "Failed to fetch" || err.name === "TypeError") {
      throw new Error("Unable to connect to backend server (http://localhost:5000). Please ensure the backend server is running.");
    }
    throw new Error(err.message || "Failed to connect to authentication server");
  }
}

export async function registerApi(name: string, email: string, password: string): Promise<{ token: string; user: AuthUser }> {
  try {
    const res = await fetch(`${API_URL}/users/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, email, password }),
    });
    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.message || "Registration failed");
    }
    return data;
  } catch (err: any) {
    if (err.message === "Failed to fetch" || err.name === "TypeError") {
      throw new Error("Unable to connect to backend server (http://localhost:5000). Please ensure the backend server is running.");
    }
    throw new Error(err.message || "Failed to connect to registration server");
  }
}

export async function forgotPasswordApi(email: string): Promise<{ success: boolean; message: string; code?: string; previewUrl?: string; resetUrl?: string }> {
  try {
    const res = await fetch(`${API_URL}/users/forgot-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email }),
    });
    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.message || "Failed to process forgot password request");
    }
    return data;
  } catch (err: any) {
    if (err.message === "Failed to fetch" || err.name === "TypeError") {
      throw new Error("Unable to connect to backend server (http://localhost:5000). Please ensure the backend server is running.");
    }
    throw new Error(err.message || "Failed to connect to authentication server");
  }
}

export async function resetPasswordApi(params: { email?: string; code?: string; token?: string; password: string }): Promise<{ token: string; user: AuthUser; message: string }> {
  try {
    const res = await fetch(`${API_URL}/users/reset-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(params),
    });
    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.message || "Failed to reset password");
    }
    return data;
  } catch (err: any) {
    if (err.message === "Failed to fetch" || err.name === "TypeError") {
      throw new Error("Unable to connect to backend server (http://localhost:5000). Please ensure the backend server is running.");
    }
    throw new Error(err.message || "Failed to connect to authentication server");
  }
}

export function useAuth() {
  const [user, setUser] = useState<AuthUser | null>(() => getAuthUser());

  useEffect(() => {
    setUser(getAuthUser());

    const handleAuthChange = () => {
      setUser(getAuthUser());
    };

    window.addEventListener("vexa-auth-change", handleAuthChange);
    window.addEventListener("storage", handleAuthChange);

    return () => {
      window.removeEventListener("vexa-auth-change", handleAuthChange);
      window.removeEventListener("storage", handleAuthChange);
    };
  }, []);

  const logout = () => {
    logoutUser();
  };

  return {
    user,
    isLoggedIn: user !== null,
    isAdmin: user?.role === "admin",
    isUser: user?.role === "user",
    logout,
  };
}
