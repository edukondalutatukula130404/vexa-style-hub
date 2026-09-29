import { NavLink, useLocation } from "react-router-dom";
import { Compass, LayoutGrid, ShoppingBag, User } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { useCart } from "@/lib/cart";

export function MobileBottomNav() {
  const location = useLocation();
  const { isLoggedIn, isAdmin } = useAuth();
  const { cartItems } = useCart();

  const totalCartCount = (cartItems || []).reduce((acc, item) => acc + (item?.quantity || 1), 0);
  const profilePath = isLoggedIn ? (isAdmin ? "/admin" : "/dashboard?tab=profile") : "/login";

  // Hide bottom nav on admin portal
  if (location.pathname.startsWith("/admin")) {
    return null;
  }

  return (
    <nav aria-label="Mobile Bottom Navigation" className="fixed bottom-0 inset-x-0 z-50 bg-gradient-to-b from-[#FBE89C] via-[#F2D370] to-[#E5BF4E] rounded-t-3xl border-t border-white/60 py-2 px-3 flex items-center justify-around text-[#0F172A] md:hidden shadow-[0_-6px_20px_rgba(0,0,0,0.2)]">
      {/* 1. DISCOVER */}
      <NavLink
        to="/"
        end
        className={({ isActive }) =>
          `flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-2xl transition-all ${
            isActive ? "bg-[#0F172A] text-[#FFD700] font-extrabold shadow-md border border-[#FFD700]/30 scale-105" : "text-[#0F172A] font-bold hover:text-[#0F172A]/80"
          }`
        }
      >
        {({ isActive }) => (
          <>
            <Compass className={`size-5 transition-transform ${isActive ? "text-[#FFD700]" : "text-[#0F172A]"}`} />
            <span className="text-[10px] tracking-wider">Discover</span>
          </>
        )}
      </NavLink>

      {/* 2. PRODUCTS */}
      <NavLink
        to="/products"
        className={({ isActive }) =>
          `flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-2xl transition-all ${
            isActive ? "bg-[#0F172A] text-[#FFD700] font-extrabold shadow-md border border-[#FFD700]/30 scale-105" : "text-[#0F172A] font-bold hover:text-[#0F172A]/80"
          }`
        }
      >
        {({ isActive }) => (
          <>
            <LayoutGrid className={`size-5 transition-transform ${isActive ? "text-[#FFD700]" : "text-[#0F172A]"}`} />
            <span className="text-[10px] tracking-wider">Products</span>
          </>
        )}
      </NavLink>

      {/* 3. CART */}
      <NavLink
        to="/cart"
        className={({ isActive }) =>
          `relative flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-2xl transition-all ${
            isActive ? "bg-[#0F172A] text-[#FFD700] font-extrabold shadow-md border border-[#FFD700]/30 scale-105" : "text-[#0F172A] font-bold hover:text-[#0F172A]/80"
          }`
        }
      >
        {({ isActive }) => (
          <>
            <div className="relative">
              <ShoppingBag className={`size-5 ${isActive ? "text-[#FFD700]" : "text-[#0F172A]"}`} />
              {totalCartCount > 0 && (
                <span className="absolute -top-1.5 -right-2 flex size-4 items-center justify-center rounded-full bg-[#EF4444] text-white text-[9px] font-extrabold shadow font-mono">
                  {totalCartCount}
                </span>
              )}
            </div>
            <span className="text-[10px] tracking-wider">Cart</span>
          </>
        )}
      </NavLink>

      {/* 4. PROFILE */}
      <NavLink
        to={profilePath}
        className={({ isActive }) =>
          `flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-2xl transition-all ${
            isActive ? "bg-[#0F172A] text-[#FFD700] font-extrabold shadow-md border border-[#FFD700]/30 scale-105" : "text-[#0F172A] font-bold hover:text-[#0F172A]/80"
          }`
        }
      >
        {({ isActive }) => (
          <>
            <User className={`size-5 transition-transform ${isActive ? "text-[#FFD700]" : "text-[#0F172A]"}`} />
            <span className="text-[10px] tracking-wider">Profile</span>
          </>
        )}
      </NavLink>
    </nav>
  );
}
