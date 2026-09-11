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
    <nav aria-label="Mobile Bottom Navigation" className="fixed bottom-0 inset-x-0 z-50 bg-background/95 backdrop-blur-xl border-t border-border py-2 px-2 flex items-center justify-around text-[#64748B] md:hidden shadow-lg">
      {/* 1. DISCOVER */}
      <NavLink
        to="/"
        end
        className={({ isActive }) =>
          `flex flex-col items-center gap-1 px-3 py-1 transition-all ${
            isActive ? "text-[#B8860B] font-bold" : "text-muted-foreground hover:text-foreground"
          }`
        }
      >
        {({ isActive }) => (
          <>
            <Compass className={`size-5 transition-transform ${isActive ? "scale-110 text-[#B8860B]" : ""}`} />
            <span className="text-[10px] font-semibold tracking-wider">Discover</span>
          </>
        )}
      </NavLink>

      {/* 2. PRODUCTS */}
      <NavLink
        to="/products"
        className={({ isActive }) =>
          `flex flex-col items-center gap-1 px-3 py-1 transition-all ${
            isActive ? "text-[#B8860B] font-bold" : "text-muted-foreground hover:text-foreground"
          }`
        }
      >
        {({ isActive }) => (
          <>
            <LayoutGrid className={`size-5 transition-transform ${isActive ? "scale-110 text-[#B8860B]" : ""}`} />
            <span className="text-[10px] font-semibold tracking-wider">Products</span>
          </>
        )}
      </NavLink>

      {/* 3. CART */}
      <NavLink
        to="/cart"
        className={({ isActive }) =>
          `relative flex flex-col items-center gap-1 px-3 py-1 transition-all ${
            isActive ? "text-[#B8860B] font-bold" : "text-muted-foreground hover:text-foreground"
          }`
        }
      >
        {({ isActive }) => (
          <>
            <div className="relative">
              <ShoppingBag className={`size-5 transition-transform ${isActive ? "scale-110 text-[#B8860B]" : ""}`} />
              {totalCartCount > 0 && (
                <span className="absolute -top-1.5 -right-2 flex size-4 items-center justify-center rounded-full bg-[#B8860B] text-primary-foreground text-[9px] font-extrabold shadow font-mono">
                  {totalCartCount}
                </span>
              )}
            </div>
            <span className="text-[10px] font-semibold tracking-wider">Cart</span>
          </>
        )}
      </NavLink>

      {/* 4. PROFILE */}
      <NavLink
        to={profilePath}
        className={({ isActive }) =>
          `flex flex-col items-center gap-1 px-3 py-1 transition-all ${
            isActive ? "text-[#B8860B] font-bold" : "text-muted-foreground hover:text-foreground"
          }`
        }
      >
        {({ isActive }) => (
          <>
            <User className={`size-5 transition-transform ${isActive ? "scale-110 text-[#B8860B]" : ""}`} />
            <span className="text-[10px] font-semibold tracking-wider">Profile</span>
          </>
        )}
      </NavLink>
    </nav>
  );
}
