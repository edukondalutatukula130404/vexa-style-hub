import { Link, useLocation } from "react-router-dom";
import {
  LayoutGrid,
  Package,
  Home as HomeIcon,
  Heart,
  User as UserIcon,
  ShoppingBag,
} from "lucide-react";
import { useWishlist } from "@/lib/wishlist";
import { useCart } from "@/lib/cart";
import { useAuth } from "@/lib/auth";

export function MobileBottomNav() {
  const location = useLocation();
  const { wishlistItems } = useWishlist();
  const { cartItems } = useCart();
  const { isLoggedIn } = useAuth();

  // Hide on admin routes completely
  if (location.pathname.startsWith("/admin")) {
    return null;
  }

  const pathname = location.pathname;
  const search = location.search;

  const isHome = pathname === "/";
  const isProducts = pathname === "/products" || pathname.startsWith("/product/");
  const isOrders = pathname === "/dashboard" && search.includes("tab=orders");
  const isWishlist = pathname === "/dashboard" && search.includes("tab=wishlist");
  const isProfile =
    pathname === "/login" ||
    pathname === "/register" ||
    (pathname === "/dashboard" && (search.includes("tab=profile") || (!search.includes("tab=orders") && !search.includes("tab=wishlist") && !search.includes("tab=cart"))));

  const wishlistCount = (wishlistItems || []).length;
  const totalCartCount = (cartItems || []).reduce((acc, i) => acc + (i.quantity || 1), 0);
  const showFloatingCart = !search.includes("tab=cart") && !pathname.startsWith("/product") && (isHome || isWishlist || totalCartCount > 0);

  return (
    <>
      {/* Floating Cart Button (Matches Mobile App Home & Wishlist Floating Cart) */}
      {showFloatingCart && (
        <Link
          to="/dashboard?tab=cart"
          className="fixed right-4 bottom-22 z-40 flex size-12 items-center justify-center rounded-full bg-[#F2D370] text-[#0F172A] shadow-xl border-2 border-white active:scale-90 transition-transform md:hidden"
          aria-label="View Cart"
        >
          <div className="relative flex items-center justify-center">
            <ShoppingBag className="size-5" />
            {totalCartCount > 0 && (
              <span className="absolute -top-2.5 -right-2.5 flex size-4.5 items-center justify-center rounded-full bg-[#0C2340] text-[10px] font-bold text-white shadow">
                {totalCartCount}
              </span>
            )}
          </div>
        </Link>
      )}

      {/* Luxury Radiant Gold Bottom Navigation Bar */}
      <div className="fixed inset-x-0 bottom-0 z-40 md:hidden pointer-events-auto">
        <div className="w-full rounded-t-[28px] border-t border-white/70 bg-gradient-to-b from-[#FBE89C] via-[#F2D370] to-[#E5BF4E] px-2 pt-2 pb-1 shadow-[0_-5px_20px_rgba(0,0,0,0.18)]">
          <nav className="flex items-center justify-around">
            {/* 1. Products */}
            <Link
              to="/products"
              className={`flex flex-col items-center justify-center px-3 py-1.5 transition-all duration-200 rounded-[18px] ${
                isProducts
                  ? "bg-[#0F172A] text-[#FFD700] shadow-md border border-[#FFD700]/70"
                  : "text-[#0F172A] hover:opacity-80 active:scale-95"
              }`}
            >
              <LayoutGrid className={isProducts ? "size-5.5 text-[#FFD700]" : "size-5 text-[#0F172A]"} />
              <span className={`text-[10px] tracking-tight mt-0.5 ${isProducts ? "font-extrabold text-[#FFD700]" : "font-bold text-[#0F172A]"}`}>
                Products
              </span>
            </Link>

            {/* 2. My Orders */}
            <Link
              to={isLoggedIn ? "/dashboard?tab=orders" : "/login?redirect=/dashboard?tab=orders"}
              className={`flex flex-col items-center justify-center px-3 py-1.5 transition-all duration-200 rounded-[18px] ${
                isOrders
                  ? "bg-[#0F172A] text-[#FFD700] shadow-md border border-[#FFD700]/70"
                  : "text-[#0F172A] hover:opacity-80 active:scale-95"
              }`}
            >
              <Package className={isOrders ? "size-5.5 text-[#FFD700]" : "size-5 text-[#0F172A]"} />
              <span className={`text-[10px] tracking-tight mt-0.5 ${isOrders ? "font-extrabold text-[#FFD700]" : "font-bold text-[#0F172A]"}`}>
                My Orders
              </span>
            </Link>

            {/* 3. Home */}
            <Link
              to="/"
              className={`flex flex-col items-center justify-center px-3 py-1.5 transition-all duration-200 rounded-[18px] ${
                isHome
                  ? "bg-[#0F172A] text-[#FFD700] shadow-md border border-[#FFD700]/70"
                  : "text-[#0F172A] hover:opacity-80 active:scale-95"
              }`}
            >
              <HomeIcon className={isHome ? "size-5.5 text-[#FFD700]" : "size-5 text-[#0F172A]"} />
              <span className={`text-[10px] tracking-tight mt-0.5 ${isHome ? "font-extrabold text-[#FFD700]" : "font-bold text-[#0F172A]"}`}>
                Home
              </span>
            </Link>

            {/* 4. Wishlist */}
            <Link
              to={isLoggedIn ? "/dashboard?tab=wishlist" : "/login?redirect=/dashboard?tab=wishlist"}
              className={`relative flex flex-col items-center justify-center px-3 py-1.5 transition-all duration-200 rounded-[18px] ${
                isWishlist
                  ? "bg-[#0F172A] text-[#FFD700] shadow-md border border-[#FFD700]/70"
                  : "text-[#0F172A] hover:opacity-80 active:scale-95"
              }`}
            >
              <div className="relative">
                <Heart className={isWishlist ? "size-5.5 text-[#FFD700] fill-current" : "size-5 text-[#0F172A]"} />
                {wishlistCount > 0 && (
                  <span className="absolute -top-1.5 -right-2 flex size-3.5 items-center justify-center rounded-full bg-[#EF4444] text-[8px] font-bold text-white">
                    {wishlistCount}
                  </span>
                )}
              </div>
              <span className={`text-[10px] tracking-tight mt-0.5 ${isWishlist ? "font-extrabold text-[#FFD700]" : "font-bold text-[#0F172A]"}`}>
                Wishlist
              </span>
            </Link>

            {/* 5. Profile */}
            <Link
              to={isLoggedIn ? "/dashboard?tab=profile" : "/login"}
              className={`flex flex-col items-center justify-center px-3 py-1.5 transition-all duration-200 rounded-[18px] ${
                isProfile
                  ? "bg-[#0F172A] text-[#FFD700] shadow-md border border-[#FFD700]/70"
                  : "text-[#0F172A] hover:opacity-80 active:scale-95"
              }`}
            >
              <UserIcon className={isProfile ? "size-5.5 text-[#FFD700]" : "size-5 text-[#0F172A]"} />
              <span className={`text-[10px] tracking-tight mt-0.5 ${isProfile ? "font-extrabold text-[#FFD700]" : "font-bold text-[#0F172A]"}`}>
                Profile
              </span>
            </Link>
          </nav>

          {/* Bottom Device Home Indicator Bar */}
          <div className="pt-1 pb-1">
            <div className="h-1 w-28 rounded-full bg-black/40 mx-auto" />
          </div>
        </div>
      </div>
    </>
  );
}
