import { useNavigate, Link, useSearchParams } from "react-router-dom";
import { useState, useEffect, useMemo } from "react";
import {
  User as UserIcon,
  Package,
  MapPin,
  ShoppingBag,
  Lock,
  HelpCircle,
  LogOut,
  CheckCircle2,
  Phone,
  Mail,
  Send,
  Plus,
  Minus,
  Trash2,
  ArrowRight,
  ShieldCheck,
  Save,
  MessageCircle,
  Truck,
  Eye,
  EyeOff,
  Sparkles,
  ChevronDown,
  RefreshCw,
  Camera,
  Upload,
  X,
  Menu,
  Edit3,
  Home,
  Briefcase,
  Heart,
} from "lucide-react";
import { products, useProducts, SIZES, type Product } from "@/lib/products";
import { Reveal } from "@/components/Reveal";
import { useAuth, API_URL, setLoggedIn } from "@/lib/auth";
import { useCart, addToCart, removeFromCart, updateCartQuantity, clearCart } from "@/lib/cart";
import { useWishlist, removeFromWishlist, clearWishlist } from "@/lib/wishlist";
import { Footer } from "@/components/Footer";

type OrderItem = {
  _id: string;
  id?: string;
  cancelReason?: string;
  userEmail: string;
  userName: string;
  items: Array<{
    name: string;
    price: number;
    size: string;
    color: string;
    quantity: number;
    image: string;
  }>;
  totalAmount: number;
  status: "Processing" | "Shipped" | "Delivered" | "Cancelled";
  paymentMethod: string;
  shippingAddress: string;
  createdAt: string;
};

type TabType = "profile" | "orders" | "addresses" | "cart" | "wishlist" | "support" | "booking";

export function UserDashboard() {
  const navigate = useNavigate();
  const { user, isLoggedIn, logout } = useAuth();
  const { cartItems, totalAmount } = useCart();
  const { wishlistItems } = useWishlist();
  const { products: allProducts } = useProducts();

  const [bookingCategoryFilter, setBookingCategoryFilter] = useState<string>("All");
  const [bookingSearchQuery, setBookingSearchQuery] = useState<string>("");

  const bookingDisplayProducts = useMemo(() => {
    const source = Array.isArray(allProducts) && allProducts.length > 0 ? allProducts : products;
    return source.filter((p) => {
      const matchCategory =
        bookingCategoryFilter === "All" ||
        p.category === bookingCategoryFilter;
      const matchSearch =
        !bookingSearchQuery.trim() ||
        p.name.toLowerCase().includes(bookingSearchQuery.toLowerCase()) ||
        p.color.toLowerCase().includes(bookingSearchQuery.toLowerCase());
      return matchCategory && matchSearch;
    });
  }, [allProducts, bookingCategoryFilter, bookingSearchQuery]);
  
  const [searchParams] = useSearchParams();

  const [activeTab, setActiveTab] = useState<TabType>(() => {
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const tabParam = params.get("tab");
      if (tabParam && ["profile", "orders", "addresses", "cart", "wishlist", "support", "booking"].includes(tabParam)) {
        return tabParam as TabType;
      }
    }
    return "profile";
  });

  useEffect(() => {
    const tabParam = searchParams.get("tab");
    if (tabParam && ["profile", "orders", "addresses", "cart", "wishlist", "support", "booking"].includes(tabParam)) {
      setActiveTab(tabParam as TabType);
    }
  }, [searchParams]);

  useEffect(() => {
    const tabParam = searchParams.get("tab");
    const targetTab = tabParam || activeTab;
    if (!isLoggedIn && targetTab !== "cart" && targetTab !== "wishlist") {
      localStorage.setItem("vexa_redirect_after_login", `/dashboard?tab=${targetTab}`);
      navigate("/login");
    }
  }, [isLoggedIn, navigate, activeTab, searchParams]);

  // Orders State & Sort Options
  const [myOrders, setMyOrders] = useState<OrderItem[]>([]);
  const [loadingOrders, setLoadingOrders] = useState(false);
  const [orderSortBy, setOrderSortBy] = useState<"recent" | "oldest" | "price-high" | "price-low">("recent");
  const [orderStatusFilter, setOrderStatusFilter] = useState<string>("All");

  const sortedOrders = useMemo(() => {
    if (!Array.isArray(myOrders)) return [];
    let result = myOrders.filter((o) => o && typeof o === "object");

    if (orderStatusFilter !== "All") {
      result = result.filter((o) => (o?.status || "").toLowerCase() === orderStatusFilter.toLowerCase());
    }

    return result.sort((a, b) => {
      if (!a || !b) return 0;
      const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;

      if (orderSortBy === "recent") {
        return dateB - dateA;
      } else if (orderSortBy === "oldest") {
        return dateA - dateB;
      } else if (orderSortBy === "price-high") {
        return (b.totalAmount || 0) - (a.totalAmount || 0);
      } else if (orderSortBy === "price-low") {
        return (a.totalAmount || 0) - (b.totalAmount || 0);
      }
      return dateB - dateA;
    });
  }, [myOrders, orderSortBy, orderStatusFilter]);

  // Profile Form & Avatar State
  const [profileName, setProfileName] = useState(user?.name || "Aarav Sharma");
  const [profileEmail, setProfileEmail] = useState(user?.email || "aarav@example.com");
  const [profileMobile, setProfileMobile] = useState("9876543210");
  const [profileSavedMsg, setProfileSavedMsg] = useState("");
  const [profilePic, setProfilePic] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("vexa_profile_avatar") || "";
    }
    return "";
  });

  // Profile Extended Preferences State
  const [preferredSize, setPreferredSize] = useState<string>(() => {
    return typeof window !== "undefined" ? localStorage.getItem("vexa_pref_size") || "M" : "M";
  });
  const [preferredFit, setPreferredFit] = useState<string>(() => {
    return typeof window !== "undefined" ? localStorage.getItem("vexa_pref_fit") || "Oversized Drop-Shoulder" : "Oversized Drop-Shoulder";
  });
  const [orderAlerts, setOrderAlerts] = useState<boolean>(true);
  const [vipAlerts, setVipAlerts] = useState<boolean>(true);
  const [whatsappAlerts, setWhatsappAlerts] = useState<boolean>(true);

  // Security Form State
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPasswordForm, setShowPasswordForm] = useState(false);
  const [passwordSavedMsg, setPasswordSavedMsg] = useState("");

  const handleUpdatePassword = (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword.length < 6) {
      setPasswordSavedMsg("New password must be at least 6 characters long.");
      setTimeout(() => setPasswordSavedMsg(""), 3500);
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordSavedMsg("New password and confirm password do not match.");
      setTimeout(() => setPasswordSavedMsg(""), 3500);
      return;
    }

    setCurrentPassword("");
    setNewPassword("");
    setConfirmPassword("");
    setShowPasswordForm(false);
    setPasswordSavedMsg("Security password updated successfully!");
    setTimeout(() => setPasswordSavedMsg(""), 4000);
  };

  // Preload Razorpay Checkout SDK Script
  useEffect(() => {
    if (typeof window !== "undefined" && !(window as any).Razorpay) {
      const script = document.createElement("script");
      script.src = "https://checkout.razorpay.com/v1/checkout.js";
      script.async = true;
      document.head.appendChild(script);
    }
  }, []);


  const handleAvatarUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 5 * 1024 * 1024) {
      setProfileSavedMsg("Image size should be less than 5MB.");
      setTimeout(() => setProfileSavedMsg(""), 3000);
      return;
    }

    const reader = new FileReader();
    reader.onloadend = () => {
      if (typeof reader.result === "string") {
        const base64 = reader.result;
        setProfilePic(base64);
        if (typeof window !== "undefined") {
          localStorage.setItem("vexa_profile_avatar", base64);
        }
        setProfileSavedMsg("Profile picture updated successfully!");
        setTimeout(() => setProfileSavedMsg(""), 3500);
      }
    };
    reader.readAsDataURL(file);
  };

  const handleRemoveAvatar = () => {
    setProfilePic("");
    if (typeof window !== "undefined") {
      localStorage.removeItem("vexa_profile_avatar");
    }
    setProfileSavedMsg("Profile picture removed.");
    setTimeout(() => setProfileSavedMsg(""), 3000);
  };

  // Address Form State
  const [savedAddresses, setSavedAddresses] = useState(() => {
    if (typeof window !== "undefined") {
      const cached = localStorage.getItem("vexa_saved_addresses");
      if (cached) {
        try {
          return JSON.parse(cached);
        } catch {}
      }
    }
    return [
      {
        id: "1",
        name: "Home Address",
        address: "100 Feet Road, Indiranagar, Stage 2",
        city: "Bengaluru",
        state: "Karnataka",
        pincode: "560038",
        mobile: "9876543210",
        isDefault: true,
      },
    ];
  });
  const [showAddAddress, setShowAddAddress] = useState(false);
  const [newStreet, setNewStreet] = useState("");
  const [newCity, setNewCity] = useState("");
  const [newState, setNewState] = useState("");
  const [newPincode, setNewPincode] = useState("");
  const [newAddressType, setNewAddressType] = useState<"Home" | "Office" | "Other">("Home");
  const [newCustomLabel, setNewCustomLabel] = useState("");

  const handleAddAddress = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newStreet.trim() || !newCity.trim() || !newPincode.trim()) return;

    const labelName =
      newAddressType === "Home"
        ? "Home Address"
        : newAddressType === "Office"
        ? "Office / Work Address"
        : newCustomLabel.trim() || "Saved Address";

    const newAddrObj = {
      id: "addr-" + Date.now(),
      name: labelName,
      address: newStreet.trim(),
      city: newCity.trim(),
      state: newState.trim() || "Karnataka",
      pincode: newPincode.trim(),
      mobile: profileMobile || "9876543210",
      isDefault: savedAddresses.length === 0,
    };

    const updated = [newAddrObj, ...savedAddresses];
    setSavedAddresses(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_saved_addresses", JSON.stringify(updated));
    }

    setNewStreet("");
    setNewCity("");
    setNewState("");
    setNewPincode("");
    setNewAddressType("Home");
    setNewCustomLabel("");
    setShowAddAddress(false);
  };

  // Address Editing State
  const [editingAddressId, setEditingAddressId] = useState<string | null>(null);
  const [editLabel, setEditLabel] = useState("");
  const [editStreet, setEditStreet] = useState("");
  const [editCity, setEditCity] = useState("");
  const [editState, setEditState] = useState("");
  const [editPincode, setEditPincode] = useState("");
  const [editMobile, setEditMobile] = useState("");

  const handleStartEditAddress = (addr: (typeof savedAddresses)[0]) => {
    setEditingAddressId(addr.id);
    setEditLabel(addr.name || "Home Address");
    setEditStreet(addr.address || "");
    setEditCity(addr.city || "");
    setEditState(addr.state || "");
    setEditPincode(addr.pincode || "");
    setEditMobile(addr.mobile || "9876543210");
  };

  const handleSaveEditAddress = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingAddressId) return;

    const updated = savedAddresses.map((addr: any) =>
      addr.id === editingAddressId
        ? {
            ...addr,
            name: editLabel.trim() || "Saved Address",
            address: editStreet.trim(),
            city: editCity.trim(),
            state: editState.trim(),
            pincode: editPincode.trim(),
            mobile: editMobile.trim(),
          }
        : addr
    );

    setSavedAddresses(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_saved_addresses", JSON.stringify(updated));
    }
    setEditingAddressId(null);
  };

  const handleDeleteAddress = (id: string) => {
    const updated = savedAddresses.filter((a: any) => a.id !== id);
    setSavedAddresses(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_saved_addresses", JSON.stringify(updated));
    }
  };

  const handleSetDefaultAddress = (id: string) => {
    const updated = savedAddresses.map((a: any) => ({
      ...a,
      isDefault: a.id === id,
    }));
    setSavedAddresses(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_saved_addresses", JSON.stringify(updated));
    }
  };

  // Order Placement State & Checkout Flow
  const [cartCheckoutStep, setCartCheckoutStep] = useState<"cart" | "address" | "payment" | "success">("cart");
  const [lastPlacedOrder, setLastPlacedOrder] = useState<any>(null);
  const [showAddNewAddressForm, setShowAddNewAddressForm] = useState(false);
  const [selectedSavedAddressId, setSelectedSavedAddressId] = useState<string | null>(null);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [selectedSize, setSelectedSize] = useState<string>("M");
  const [quantity, setQuantity] = useState<number>(1);
  const [isCartCheckout, setIsCartCheckout] = useState(false);
  const [checkoutStep, setCheckoutStep] = useState<1 | 2>(1);
  const [shippingName, setShippingName] = useState("EDUKONDALU");
  const [shippingPhone, setShippingPhone] = useState("9876543210");
  const [shippingStreet, setShippingStreet] = useState("100 Feet Road, Indiranagar, Stage 2");
  const [shippingCity, setShippingCity] = useState("Bengaluru");
  const [shippingState, setShippingState] = useState("Karnataka");
  const [shippingPincode, setShippingPincode] = useState("560038");
  const [paymentMethod, setPaymentMethod] = useState<string>("Demo UPI Instant (GPay / PhonePe / Paytm)");
  const [shippingAddress, setShippingAddress] = useState<string>(
    "EDUKONDALU (+91 9876543210), 100 Feet Road, Indiranagar, Stage 2, Bengaluru, Karnataka - 560038"
  );
  const [orderSubmitting, setOrderSubmitting] = useState(false);
  const [orderSuccessMsg, setOrderSuccessMsg] = useState("");
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [sidebarHovered, setSidebarHovered] = useState(false);
  const isExpanded = !sidebarCollapsed || sidebarHovered;

  // Interactive Demo Payment Modal State (Accepts Any Input e.g. 1234 5678 9123 1222)
  const [showDemoPaymentModal, setShowDemoPaymentModal] = useState(false);
  const [demoCardInput, setDemoCardInput] = useState("1234 5678 9123 1222");
  const [demoExpiryInput, setDemoExpiryInput] = useState("02/29");
  const [demoCvvInput, setDemoCvvInput] = useState("123");
  const [demoHolderName, setDemoHolderName] = useState("EDUKONDALU");
  const [demoProcessing, setDemoProcessing] = useState(false);
  const [demoPaymentSuccess, setDemoPaymentSuccess] = useState(false);
  const [demoTxnId, setDemoTxnId] = useState("");

  // Dynamic Cart Price, Offer Savings & Delivery Fee Calculations
  const totalCartItemsCount = useMemo(() => {
    return cartItems.reduce((sum, item) => sum + (item.quantity || 1), 0);
  }, [cartItems]);

  const totalOfferDiscount = useMemo(() => {
    return cartItems.reduce((sum, item) => {
      const oldP = item.product?.oldPrice || item.product?.price || 0;
      const price = item.product?.price || 0;
      const diff = Math.max(0, oldP - price);
      return sum + diff * (item.quantity || 1);
    }, 0);
  }, [cartItems]);

  const totalOriginalMRP = useMemo(() => {
    return cartItems.reduce((sum, item) => {
      const oldP = item.product?.oldPrice || item.product?.price || 0;
      return sum + oldP * (item.quantity || 1);
    }, 0);
  }, [cartItems]);

  const deliveryCharge = useMemo(() => {
    return totalCartItemsCount === 1 ? 99 : 0;
  }, [totalCartItemsCount]);

  const finalOrderTotal = useMemo(() => {
    return totalAmount + deliveryCharge;
  }, [totalAmount, deliveryCharge]);

  // Scroll to top on active tab or checkout step change
  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: "instant" });
  }, [activeTab, cartCheckoutStep]);

  // Sync user auth details when available
  useEffect(() => {
    if (user) {
      setProfileName(user.name);
      setProfileEmail(user.email);
      if (user.name) setShippingName(user.name);
    }
    if (typeof window !== "undefined") {
      const savedMobile = localStorage.getItem("vexa_profile_mobile");
      if (savedMobile) setProfileMobile(savedMobile);
    }
  }, [user]);

  const handleUpdateProfile = (e: React.FormEvent) => {
    e.preventDefault();
    if (user) {
      const updatedUser = {
        ...user,
        name: profileName,
        email: profileEmail,
      };
      setLoggedIn(updatedUser);
    }
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_profile_mobile", profileMobile);
    }
    setProfileSavedMsg("Profile updated successfully!");
    setTimeout(() => setProfileSavedMsg(""), 4000);
  };

  const [refreshMsg, setRefreshMsg] = useState("");

  // Fetch orders from API on mount / tab change / manual refresh
  const fetchMyOrders = async (isManualRefresh = false) => {
    setLoadingOrders(true);
    try {
      const email = user?.email || (typeof window !== "undefined" ? localStorage.getItem("vexa_user_email") : "") || "";
      let fetchedList: OrderItem[] = [];

      if (email) {
        const res = await fetch(`${API_URL}/orders/myorders?email=${encodeURIComponent(email)}`);
        if (res.ok) {
          const json = await res.json();
          fetchedList = Array.isArray(json) ? json : (json.data || []);
        }
      }

      // Fallback: If filtered user orders returned empty or email was blank, fetch all orders
      if (fetchedList.length === 0) {
        const allRes = await fetch(`${API_URL}/orders`);
        if (allRes.ok) {
          const allJson = await allRes.json();
          const allList = Array.isArray(allJson) ? allJson : (allJson.data || []);
          if (email) {
            fetchedList = allList.filter((o: any) =>
              o.userEmail && o.userEmail.toLowerCase().trim() === email.toLowerCase().trim()
            );
          } else {
            fetchedList = allList;
          }
        }
      }

      // Read local demo orders cached in localStorage
      let cachedDemoOrders: OrderItem[] = [];
      if (typeof window !== "undefined") {
        try {
          cachedDemoOrders = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
        } catch (e) {
          console.warn("Failed to parse cached demo orders", e);
        }
      }

      let deletedIds: string[] = [];
      if (typeof window !== "undefined") {
        try {
          deletedIds = JSON.parse(localStorage.getItem("vexa_deleted_order_ids") || "[]");
        } catch (e) {}
      }

      setMyOrders(() => {
        const map = new Map();

        // 1. Load backend API items
        fetchedList.forEach((item) => {
          const key = item._id || (item as any).id;
          const shortKey = String(key || "").slice(-8).toUpperCase();
          if (key && !deletedIds.includes(key) && !deletedIds.includes(shortKey) && !deletedIds.includes(shortKey.toLowerCase())) {
            map.set(key, item);
          }
        });

        // 2. Overlay cached demo orders & user cancellations
        cachedDemoOrders.forEach((cached) => {
          const cachedKey = cached._id || (cached as any).id;
          const cachedShort = String(cachedKey || "").slice(-8).toUpperCase();

          if (cachedKey && !deletedIds.includes(cachedKey) && !deletedIds.includes(cachedShort)) {
            let matchedKey = cachedKey;
            for (const [k, existingObj] of map.entries()) {
              const existingShort = String(existingObj._id || existingObj.id || "").slice(-8).toUpperCase();
              if (
                k === cachedKey ||
                existingShort === cachedShort ||
                (existingObj.userEmail &&
                  cached.userEmail &&
                  existingObj.userEmail.toLowerCase().trim() === cached.userEmail.toLowerCase().trim() &&
                  existingObj.totalAmount === cached.totalAmount)
              ) {
                matchedKey = k;
                break;
              }
            }

            const existing = map.get(matchedKey);
            if (existing) {
              map.set(matchedKey, {
                ...existing,
                status: cached.status || existing.status,
                cancelReason: cached.cancelReason || (existing as any).cancelReason,
              });
            } else {
              map.set(cachedKey, cached);
            }
          }
        });

        return Array.from(map.values());
      });

      if (isManualRefresh) {
        setRefreshMsg("Orders updated");
        setTimeout(() => setRefreshMsg(""), 3000);
      }
    } catch (err) {
      console.warn("Failed to fetch user orders:", err);
    } finally {
      setLoadingOrders(false);
    }
  };

  // User Cancellation & CRUD Operations State
  const [cancellingOrderUser, setCancellingOrderUser] = useState<{ id: string; bookingIdStr: string } | null>(null);
  const [userCancelReasonPreset, setUserCancelReasonPreset] = useState("Ordered by mistake / Change of mind");
  const [userCustomCancelReason, setUserCustomCancelReason] = useState("");

  const handleUpdateUserOrderStatus = async (orderId: string, newStatus: string, cancelReason = "") => {
    setMyOrders((prev) =>
      prev.map((o) =>
        o._id === orderId || o.id === orderId
          ? { ...o, status: newStatus as any, cancelReason }
          : o
      )
    );

    if (typeof window !== "undefined") {
      try {
        const cached = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
        let found = false;
        let updated = cached.map((o: any) => {
          if (o._id === orderId || o.id === orderId) {
            found = true;
            return { ...o, status: newStatus, cancelReason };
          }
          return o;
        });

        if (!found) {
          const currentOrder = myOrders.find((o) => o._id === orderId || o.id === orderId);
          if (currentOrder) {
            updated.unshift({ ...currentOrder, status: newStatus as any, cancelReason });
          }
        }

        localStorage.setItem("vexa_demo_orders", JSON.stringify(updated));

        // Warehouse Inventory Restock on Order Cancellation
        if (newStatus === "Cancelled") {
          const targetOrder = myOrders.find((o) => o._id === orderId || o.id === orderId);
          if (targetOrder && targetOrder.items) {
            const inventory = JSON.parse(localStorage.getItem("vexa_inventory_stocks") || "{}");
            targetOrder.items.forEach((item) => {
              const key = item.name;
              const qty = item.quantity || 1;
              inventory[key] = (inventory[key] !== undefined ? inventory[key] : 15) + qty;
            });
            localStorage.setItem("vexa_inventory_stocks", JSON.stringify(inventory));
            window.dispatchEvent(new Event("vexa_inventory_updated"));
            window.dispatchEvent(new Event("vexa_items_updated"));
          }
        }

        window.dispatchEvent(new Event("vexa_orders_updated"));
      } catch (e) {
        console.warn("Failed to update cached demo orders:", e);
      }
    }

    try {
      await fetch(`${API_URL}/orders/${orderId}/status`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus, cancelReason }),
      });
    } catch (err) {
      console.warn("Status update error:", err);
    }
  };

  const handleConfirmUserCancellation = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!cancellingOrderUser) return;

    const finalReason =
      userCancelReasonPreset === "Custom Reason"
        ? userCustomCancelReason.trim() || "Cancelled by Customer"
        : userCancelReasonPreset;

    const fullReason = `Cancelled by Customer: ${finalReason}`;
    await handleUpdateUserOrderStatus(cancellingOrderUser.id, "Cancelled", fullReason);
    setCancellingOrderUser(null);
    setUserCancelReasonPreset("Ordered by mistake / Change of mind");
    setUserCustomCancelReason("");
    setRefreshMsg(`Order #${cancellingOrderUser.bookingIdStr} cancelled successfully.`);
    setTimeout(() => setRefreshMsg(""), 3500);
  };

  const handleDeleteOrder = async (orderId: string, bookingIdStr: string) => {
    if (!window.confirm(`Are you sure you want to delete order record #${bookingIdStr}?`)) {
      return;
    }

    const targetObj = myOrders.find((o) => {
      const oId = String(o._id || o.id || "");
      const oShort = oId.slice(-8).toUpperCase();
      return o._id === orderId || o.id === orderId || oId === orderId || oShort === bookingIdStr.toUpperCase();
    });

    const targetKey = targetObj?._id || targetObj?.id || orderId;

    const allIds = Array.from(
      new Set([
        orderId,
        bookingIdStr,
        bookingIdStr.toLowerCase(),
        bookingIdStr.toUpperCase(),
        targetObj?._id,
        targetObj?.id,
        targetKey,
      ].filter(Boolean))
    ) as string[];

    setMyOrders((prev) =>
      prev.filter((o) => {
        const oId = String(o._id || o.id || "");
        const oShort = oId.slice(-8).toUpperCase();
        return (
          !allIds.includes(o._id) &&
          !allIds.includes(o.id || "") &&
          !allIds.includes(oId) &&
          !allIds.includes(oShort)
        );
      })
    );

    if (typeof window !== "undefined") {
      try {
        const deletedIds = JSON.parse(localStorage.getItem("vexa_deleted_order_ids") || "[]");
        allIds.forEach((id) => {
          if (!deletedIds.includes(id)) deletedIds.push(id);
        });
        localStorage.setItem("vexa_deleted_order_ids", JSON.stringify(deletedIds));

        const cached = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
        const updated = cached.filter((o: any) => {
          const oId = String(o._id || o.id || "");
          const oShort = oId.slice(-8).toUpperCase();
          return (
            !allIds.includes(o._id) &&
            !allIds.includes(o.id) &&
            !allIds.includes(oId) &&
            !allIds.includes(oShort)
          );
        });
        localStorage.setItem("vexa_demo_orders", JSON.stringify(updated));
        window.dispatchEvent(new Event("vexa_orders_updated"));
      } catch (e) {
        console.warn("Failed to delete cached order:", e);
      }
    }

    try {
      await fetch(`${API_URL}/orders/${targetKey}`, { method: "DELETE" });
      if (bookingIdStr && bookingIdStr !== targetKey) {
        await fetch(`${API_URL}/orders/${bookingIdStr}`, { method: "DELETE" });
      }
    } catch (err) {
      console.warn("API delete order notice:", err);
    }

    setRefreshMsg(`Order #${bookingIdStr} deleted from records.`);
    setTimeout(() => setRefreshMsg(""), 3500);
  };

  useEffect(() => {
    fetchMyOrders();
    const handleOrdersUpdated = () => {
      fetchMyOrders();
    };
    window.addEventListener("vexa_orders_updated", handleOrdersUpdated);
    const interval = setInterval(() => {
      fetchMyOrders();
    }, 4000);
    return () => {
      window.removeEventListener("vexa_orders_updated", handleOrdersUpdated);
      clearInterval(interval);
    };
  }, [user?.email, activeTab]);



  const handlePlaceOrder = async (e?: React.FormEvent | React.MouseEvent) => {
    if (e) e.preventDefault();
    if (orderSubmitting) return;

    setOrderSubmitting(true);

    try {
      const currentUser = user || (typeof window !== "undefined" ? JSON.parse(localStorage.getItem("vexa_auth_user") || "null") : null);
      const email = currentUser?.email || profileEmail || (typeof window !== "undefined" ? localStorage.getItem("vexa_user_email") || "" : "") || "customer@vexa.store";
      const name = currentUser?.name || profileName || "VEXA Customer";

      const isCart = isCartCheckout || (cartItems.length > 0 && !selectedProduct);

      const itemsToOrder = isCart
        ? cartItems.map((ci) => ({
            id: ci.product?.id || "item-" + Date.now(),
            name: ci.product?.name || "Premium Tee",
            price: ci.product?.price || 0,
            size: ci.size || "M",
            color: ci.product?.color || "Signature Black",
            quantity: ci.quantity || 1,
            image: ci.product?.image || "",
          }))
        : selectedProduct
        ? [
            {
              id: selectedProduct.id,
              name: selectedProduct.name,
              price: selectedProduct.price,
              size: selectedSize,
              color: selectedProduct.color,
              quantity: quantity,
              image: selectedProduct.image,
            },
          ]
        : [];

      let calculatedTotal = isCart
        ? totalAmount
        : selectedProduct
        ? selectedProduct.price * quantity
        : 0;

      let finalPayable = isCart ? finalOrderTotal : calculatedTotal;
      if (!finalPayable || isNaN(finalPayable) || finalPayable <= 0) {
        finalPayable = itemsToOrder.reduce((sum, item) => sum + ((item.price || 0) * (item.quantity || 1)), 0);
      }

      const fullAddr = shippingAddress || `${shippingName} (+91 ${shippingPhone}), ${shippingStreet}, ${shippingCity}, ${shippingState} - ${shippingPincode}`;

      const executeFinalizeOrder = (methodLabel?: string, paymentId?: string) => {
        const finalPaymentMethod = methodLabel || paymentMethod || "Demo Instant Payment (UPI / Card)";
        const displayMethod = paymentId ? `${finalPaymentMethod} (ID: ${paymentId})` : finalPaymentMethod;

        const demoOrderObj: OrderItem = {
          _id: "ORD-" + Math.floor(100000 + Math.random() * 900000),
          userEmail: email,
          userName: name,
          items: itemsToOrder,
          totalAmount: finalPayable,
          status: "Processing",
          paymentMethod: displayMethod,
          shippingAddress: fullAddr,
          createdAt: new Date().toISOString(),
        };

        setLastPlacedOrder(demoOrderObj);

        // 1. Append to order state & localStorage cache
        setMyOrders((prev) => [demoOrderObj, ...prev]);

        if (typeof window !== "undefined") {
          try {
            const cached = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
            localStorage.setItem("vexa_demo_orders", JSON.stringify([demoOrderObj, ...cached]));

            // Deduct Warehouse Stock
            const inventory = JSON.parse(localStorage.getItem("vexa_inventory_stocks") || "{}");
            itemsToOrder.forEach((item) => {
              const key = item.name;
              const qty = item.quantity || 1;
              const currentStock = inventory[key] !== undefined ? inventory[key] : 15;
              inventory[key] = Math.max(0, currentStock - qty);
            });
            localStorage.setItem("vexa_inventory_stocks", JSON.stringify(inventory));
            window.dispatchEvent(new Event("vexa_inventory_updated"));
            window.dispatchEvent(new Event("vexa_items_updated"));
          } catch (e) {
            console.warn("Failed to cache order:", e);
          }
        }

        // 2. Clear Cart
        if (isCart || cartItems.length > 0) {
          clearCart();
        }

        // 3. Reset Checkout Flow State to ORDER SUCCESSFUL PAGE
        setSelectedProduct(null);
        setIsCartCheckout(false);
        setCartCheckoutStep("success");
        setCheckoutStep(1);
        setOrderSubmitting(false);

        // 4. Keep user on Order Successful Page screen
        if (typeof window !== "undefined") {
          window.history.pushState({}, "", "/dashboard?tab=cart");
        }

        // 5. Post to backend asynchronously in background
        fetch(`${API_URL}/orders`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            userEmail: email,
            userName: name,
            items: itemsToOrder,
            totalAmount: finalPayable,
            paymentMethod: demoOrderObj.paymentMethod,
            shippingAddress: fullAddr,
          }),
        })
          .then((res) => res.json())
          .then((data) => {
            if (data && data.success && data.data && data.data._id) {
              const realId = data.data._id;
              setMyOrders((prev) =>
                prev.map((o) =>
                  o._id === demoOrderObj._id ? { ...o, _id: realId, id: realId } : o
                )
              );
            }
          })
          .catch((err) => console.warn("Background order POST notice:", err));
      };

      const handleExecuteDemoPaymentSubmission = (e?: React.FormEvent) => {
        if (e) e.preventDefault();
        if (demoProcessing) return;

        setDemoProcessing(true);
        const txn = `pay_demo_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
        setDemoTxnId(txn);

        setTimeout(() => {
          setDemoProcessing(false);
          setDemoPaymentSuccess(true);

          setTimeout(() => {
            setShowDemoPaymentModal(false);
            setDemoPaymentSuccess(false);

            executeFinalizeOrder(
              `Demo Online Payment (Card: ${demoCardInput || "Any Card"} - Paid)`,
              txn
            );
          }, 1000);
        }, 600);
      };

      const isCod = paymentMethod.toLowerCase().includes("cod") || paymentMethod.toLowerCase().includes("delivery");

      if (isCod) {
        executeFinalizeOrder("Cash on Delivery (COD)");
      } else {
        setShowDemoPaymentModal(true);
        setOrderSubmitting(false);
      }
    } catch (err) {
      console.error("Order placement handler error:", err);
      setOrderSubmitting(false);
    }
  };



  const navItems = [
    { id: "profile", label: "My Profile", icon: UserIcon },
    { id: "orders", label: "My Orders", icon: Package },
    { id: "cart", label: "My Cart", icon: ShoppingBag },
    { id: "wishlist", label: "My Wishlist", icon: Heart },
    { id: "booking", label: "Book New Tee", icon: Sparkles },
    { id: "addresses", label: "Addresses", icon: MapPin },
    { id: "support", label: "Support", icon: HelpCircle },
    { id: "logout", label: "Logout", icon: LogOut },
  ] as const;

  const currentNavItem = navItems.find((n) => n.id === activeTab) || navItems[0];
  const CurrentIcon = currentNavItem.icon;

  return (
    <div className="dashboard-page-root no-scrollbar min-h-screen bg-background pt-20 sm:pt-28 pb-8 sm:pb-12 overflow-x-hidden">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <div className="relative flex flex-col lg:flex-row gap-6 lg:gap-8 items-start">
          {/* MOBILE RESPONSIVE TAB STRIP (< lg) */}
          <div className="lg:hidden w-full sticky top-16 z-30 bg-background/95 backdrop-blur-md py-2 mb-8 sm:mb-8">
            {/* Interactive Section Selector Button */}
            <button
              type="button"
              onClick={() => setMobileNavOpen((o) => !o)}
              className="flex w-full items-center justify-between rounded-xl border border-gold/50 bg-card p-3.5 shadow-goldy transition-all hover:border-gold cursor-pointer"
            >
              <div className="flex items-center gap-3 overflow-hidden">
                <div className="flex size-9 items-center justify-center rounded-lg border border-gold/40 bg-gold/15 text-gold shrink-0">
                  <CurrentIcon className="size-4.5" />
                </div>
                <div className="overflow-hidden text-left">
                  <h3 className="font-display text-sm font-bold text-foreground truncate">{currentNavItem.label}</h3>
                </div>
              </div>
              <ChevronDown className={`size-5 text-gold shrink-0 transition-transform duration-300 ${mobileNavOpen ? "rotate-180" : ""}`} />
            </button>

            {/* Dashboard Sections Slide-Down Menu */}
            <div className="relative">
              {mobileNavOpen && (
                <div className="rounded-xl border border-gold/50 bg-card p-2 shadow-2xl backdrop-blur-xl animate-in slide-in-from-top-2 duration-300 space-y-1 mb-4 z-40">
                  {navItems.filter((item) => item.id !== "logout").map((item) => {
                    const Icon = item.icon;
                    const isActive = (activeTab as string) === item.id;
                    const isLogout = false;
                    return (
                      <button
                        key={item.id}
                        onClick={() => {
                          setMobileNavOpen(false);
                          if (isLogout) {
                            logout();
                          } else {
                            setActiveTab(item.id as TabType);
                          }
                        }}
                        className={`flex w-full items-center justify-between rounded-lg px-4 py-3 text-xs font-semibold uppercase tracking-wider transition-all cursor-pointer ${
                          isLogout
                            ? "text-destructive hover:bg-destructive/10 font-bold"
                            : isActive
                            ? "bg-gold text-primary-foreground font-bold shadow-sm"
                            : "text-muted-foreground hover:bg-surface hover:text-gold"
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <Icon className="size-4 shrink-0" />
                          <span>{item.label}</span>
                        </div>
                        {isActive && <CheckCircle2 className="size-4 shrink-0" />}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* DESKTOP SIDEBAR (>= lg): Permanently Fixed Navigation Panel (No Auto-Hide, No Hamburger) */}
          <aside className="hidden lg:block fixed top-[112px] z-30 w-[280px]">
            <div className="w-[280px] rounded-xl border border-gold/40 bg-card p-4 sm:p-5 shadow-sm">
              <div className="flex items-center justify-between border-b border-border pb-4 gap-3">
                <div className="flex items-center gap-3 shrink-0 overflow-hidden">
                  {profilePic ? (
                    <img src={profilePic} alt={profileName} className="size-10 rounded-full object-cover border border-gold shadow-sm shrink-0" />
                  ) : (
                    <div className="flex size-10 items-center justify-center rounded-full border border-gold/50 bg-gold/15 font-display text-base font-bold text-gold shrink-0 shadow-sm">
                      {(profileName || user?.name || "U")[0].toUpperCase()}
                    </div>
                  )}
                  <div className="flex flex-col justify-center overflow-hidden">
                    <h3 className="font-display text-base font-bold text-foreground truncate">{profileName}</h3>
                    <p className="text-[11px] text-muted-foreground truncate">{profileEmail}</p>
                  </div>
                </div>
              </div>

              <nav className="mt-4 space-y-1.5">
                {navItems.map((item) => {
                  const Icon = item.icon;
                  const isActive = activeTab === item.id;
                  const isLogout = item.id === "logout";
                  return (
                    <button
                      key={item.id}
                      type="button"
                      title={item.label}
                      onClick={() => {
                        if (isLogout) {
                          logout();
                        } else {
                          setActiveTab(item.id as TabType);
                        }
                      }}
                      className={`flex w-full items-center justify-between rounded-lg px-3.5 py-2.5 text-xs font-bold uppercase tracking-wider whitespace-nowrap transition-all cursor-pointer ${
                        isLogout
                          ? "text-muted-foreground hover:bg-destructive/15 hover:text-destructive mt-3 pt-3 border-t border-border/60"
                          : isActive
                          ? "bg-gold text-primary-foreground shadow-goldy font-extrabold"
                          : "text-muted-foreground hover:bg-surface hover:text-gold"
                      }`}
                    >
                      <div className="flex items-center gap-3 whitespace-nowrap">
                        <Icon className="size-4.5 shrink-0" />
                        <span>{item.label}</span>
                      </div>
                    </button>
                  );
                })}
              </nav>
            </div>
          </aside>

          {/* DASHBOARD CONTENT COLUMN: Fixed left margin keeps content aligned beside fixed sidebar */}
          <div className="flex-1 min-w-0 flex flex-col w-full lg:ml-[304px]">
            {/* MAIN TAB CONTENT AREA */}
            <main className="w-full flex-1 min-w-0 rounded-xl border-0 bg-transparent p-0 shadow-none lg:border lg:border-border lg:bg-card lg:p-8 lg:shadow-sm">
            {/* 1. MY PROFILE TAB */}
            {activeTab === "profile" && (
              <div className="space-y-6 w-full pt-2 sm:pt-0">
                {/* Profile Header Avatar Card */}
                <div className="flex flex-col sm:flex-row items-center gap-5 rounded-xl border border-gold/30 bg-card p-5 sm:p-6 shadow-sm">
                  {/* Avatar Container with Hover Overlay */}
                  <div className="relative group size-20 shrink-0">
                    {profilePic ? (
                      <img
                        src={profilePic}
                        alt={profileName}
                        className="size-20 rounded-full object-cover border-2 border-gold shadow-md"
                      />
                    ) : (
                      <div className="flex size-20 items-center justify-center rounded-full border-2 border-gold bg-gold/15 font-display text-3xl font-extrabold text-gold shadow-md">
                        {(profileName || user?.name || "U")[0].toUpperCase()}
                      </div>
                    )}
                    <label
                      htmlFor="profile-pic-input-main"
                      className="absolute inset-0 flex items-center justify-center rounded-full bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer text-gold"
                      title="Upload / Change Photo"
                    >
                      <Camera className="size-6" />
                    </label>
                    <input
                      type="file"
                      id="profile-pic-input-main"
                      accept="image/*"
                      onChange={handleAvatarUpload}
                      className="hidden"
                    />
                  </div>

                  {/* Profile Text & Action Buttons */}
                  <div className="flex-1 text-center sm:text-left space-y-1 overflow-hidden">
                    <h3 className="font-display text-xl font-bold text-foreground truncate">{profileName}</h3>
                    <p className="text-xs text-muted-foreground truncate">{profileEmail}</p>

                    {/* Edit & Delete Profile Pic Controls */}
                    <div className="flex items-center justify-center sm:justify-start gap-2 pt-3">
                      <label
                        htmlFor="profile-pic-input-btn"
                        className="flex items-center gap-1.5 rounded-lg border border-gold/50 bg-gold/10 px-3.5 py-1.5 text-xs font-bold text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer shadow-sm active:scale-95"
                      >
                        <Camera className="size-3.5" />
                        {profilePic ? "Edit Photo" : "Upload Photo"}
                      </label>
                      <input
                        type="file"
                        id="profile-pic-input-btn"
                        accept="image/*"
                        onChange={handleAvatarUpload}
                        className="hidden"
                      />

                      {profilePic && (
                        <button
                          type="button"
                          onClick={handleRemoveAvatar}
                          className="flex items-center gap-1.5 rounded-lg border border-destructive/40 bg-destructive/10 px-3.5 py-1.5 text-xs font-bold text-destructive hover:bg-destructive hover:text-white transition-all cursor-pointer shadow-sm active:scale-95"
                          title="Delete Profile Photo"
                        >
                          <Trash2 className="size-3.5" />
                          Delete Photo
                        </button>
                      )}
                    </div>
                  </div>
                </div>

                {/* Account Quick Stats Grid (Hidden on Mobile Responsive, Visible on Desktop/Tablet sm+) */}
                <div className="hidden sm:grid sm:grid-cols-3 gap-3">
                  <div className="rounded-xl border border-gold/30 bg-surface/40 p-4 text-center">
                    <span className="text-[9px] uppercase tracking-widest text-muted-foreground font-bold block">Member Since</span>
                    <span className="font-display text-sm font-bold text-foreground mt-1 block">August 2026</span>
                  </div>
                  <div className="rounded-xl border border-gold/30 bg-surface/40 p-4 text-center">
                    <span className="text-[9px] uppercase tracking-widest text-muted-foreground font-bold block">Orders Placed</span>
                    <span className="font-display text-sm font-bold text-gold mt-1 block">{myOrders.length} Bookings</span>
                  </div>
                  <div className="rounded-xl border border-gold/30 bg-surface/40 p-4 text-center">
                    <span className="text-[9px] uppercase tracking-widest text-muted-foreground font-bold block">Account Status</span>
                    <span className="font-display text-sm font-bold text-emerald-500 mt-1 block">✓ Verified</span>
                  </div>
                </div>

                {profileSavedMsg && (
                  <div className="flex items-center gap-2.5 rounded-lg border border-gold/50 bg-gold/15 p-4 text-xs text-gold font-bold animate-in fade-in slide-in-from-top-1 duration-300 shadow-sm">
                    <CheckCircle2 className="size-5 shrink-0 text-gold" />
                    <span>{profileSavedMsg}</span>
                  </div>
                )}

                <form onSubmit={handleUpdateProfile} className="space-y-6">
                  {/* Personal Contact Info Card */}
                  <div className="space-y-5 rounded-xl border border-gold/30 bg-card p-5 sm:p-6 shadow-sm">
                    <h3 className="font-display text-base font-bold text-foreground border-b border-border pb-3">
                      Personal & Contact Details
                    </h3>
                    <div className="grid gap-5 sm:grid-cols-2">
                      <div>
                        <label className="text-[10px] uppercase tracking-widest text-gold font-bold flex items-center gap-1.5 mb-2">
                          <UserIcon className="size-3.5 text-gold" /> Full Name
                        </label>
                        <input
                          type="text"
                          value={profileName}
                          onChange={(e) => setProfileName(e.target.value)}
                          className="w-full rounded-lg border border-gold/30 bg-surface/50 px-4 py-3 text-xs text-foreground outline-none focus:border-gold transition-colors"
                          required
                        />
                      </div>

                      <div>
                        <label className="text-[10px] uppercase tracking-widest text-gold font-bold flex items-center gap-1.5 mb-2">
                          <Mail className="size-3.5 text-gold" /> Email Address
                        </label>
                        <input
                          type="email"
                          value={profileEmail}
                          onChange={(e) => setProfileEmail(e.target.value)}
                          className="w-full rounded-lg border border-gold/30 bg-surface/50 px-4 py-3 text-xs text-foreground outline-none focus:border-gold transition-colors"
                          required
                        />
                      </div>
                    </div>

                    <div>
                      <label className="text-[10px] uppercase tracking-widest text-gold font-bold flex items-center gap-1.5 mb-2">
                        <Phone className="size-3.5 text-gold" /> Mobile Number
                      </label>
                      <input
                        type="text"
                        value={profileMobile}
                        onChange={(e) => setProfileMobile(e.target.value)}
                        placeholder="9876543210"
                        className="w-full max-w-md rounded-lg border border-gold/30 bg-surface/50 px-4 py-3 text-xs text-foreground outline-none focus:border-gold font-mono transition-colors"
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="w-full sm:w-auto bg-gold text-primary-foreground hover:bg-gold/90 inline-flex items-center justify-center gap-2 rounded-lg px-8 py-3.5 text-xs font-extrabold uppercase tracking-[0.18em] transition-all shadow-goldy cursor-pointer"
                  >
                    <Save className="size-4" /> UPDATE PROFILE
                  </button>
                </form>
              </div>
            )}

            {/* 2. MY ORDERS TAB */}
            {activeTab === "orders" && (
              <div className="space-y-6 min-w-0 pt-3 sm:pt-0">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-border pb-4 gap-3">
                  <div>
                    <h2 className="font-display text-xl sm:text-2xl font-bold text-foreground">My Orders</h2>
                    <p className="text-xs text-muted-foreground mt-1">Track your placed orders and shipment progress.</p>
                  </div>
                  <div className="flex items-center gap-2.5 self-start sm:self-auto shrink-0">
                    {refreshMsg && (
                      <span className="text-xs text-gold font-semibold animate-in fade-in duration-300">
                        {refreshMsg}
                      </span>
                    )}
                    <button
                      type="button"
                      onClick={() => fetchMyOrders(true)}
                      disabled={loadingOrders}
                      className="flex items-center gap-1.5 rounded-lg border border-gold/50 bg-gold/10 px-3.5 py-1.5 sm:px-4 sm:py-2 text-xs text-gold hover:bg-gold hover:text-primary-foreground font-bold transition-all disabled:opacity-50 cursor-pointer shadow-sm shrink-0"
                    >
                      <RefreshCw className={`size-3.5 ${loadingOrders ? "animate-spin" : ""}`} />
                      {loadingOrders ? "Refreshing..." : "Refresh"}
                    </button>
                  </div>
                </div>

                {/* Sort & Filter Controls Bar */}
                {myOrders.length > 0 && (
                  <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3.5 rounded-xl border border-border bg-card p-3 sm:p-4 shadow-sm min-w-0">
                    {/* Status Filter Chips */}
                    <div className="flex flex-wrap items-center gap-1.5 min-w-0 max-w-full">
                      {["All", "Processing", "Shipped", "Delivered", "Cancelled"].map((st) => (
                        <button
                          key={st}
                          type="button"
                          onClick={() => setOrderStatusFilter(st)}
                          className={`rounded-full px-3 py-1.5 text-[10px] font-bold uppercase tracking-wider transition-all cursor-pointer whitespace-nowrap shrink-0 ${
                            orderStatusFilter === st
                              ? "bg-gold text-primary-foreground shadow-sm"
                              : "border border-border bg-background text-muted-foreground hover:border-gold/50 hover:text-gold"
                          }`}
                        >
                          {st}
                        </button>
                      ))}
                    </div>

                    {/* Sort Selector Dropdown */}
                    <div className="flex items-center justify-between sm:justify-start gap-2 shrink-0 pt-2 sm:pt-0 border-t border-border/40 sm:border-t-0">
                      <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground whitespace-nowrap">Sort By:</span>
                      <select
                        value={orderSortBy}
                        onChange={(e) => setOrderSortBy(e.target.value as any)}
                        className="rounded-lg border border-border bg-background px-3 py-1.5 text-xs font-bold text-gold outline-none focus:border-gold cursor-pointer"
                      >
                        <option value="newest">Newest First</option>
                        <option value="oldest">Oldest First</option>
                        <option value="price-high">Price: High to Low</option>
                        <option value="price-low">Price: Low to High</option>
                      </select>
                    </div>
                  </div>
                )}

                {sortedOrders.length > 0 ? (
                  <div className="space-y-4">
                    {sortedOrders.map((ord, idx) => (
                      <div key={ord._id || ord.id || idx} className="rounded-xl border border-border bg-background p-3.5 sm:p-6 shadow-sm min-w-0 overflow-hidden">
                        <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-border pb-3.5 gap-2.5">
                          <div className="min-w-0">
                            <span className="text-[10px] uppercase tracking-widest text-gold font-semibold block">Order ID</span>
                            <h4 className="font-display text-base font-bold text-foreground tracking-tight truncate">
                              #{String(ord._id || ord.id || "ORD-NEW").slice(-8).toUpperCase()}
                            </h4>
                            <p className="text-[10px] text-muted-foreground mt-0.5">
                              Date: {ord.createdAt ? new Date(ord.createdAt).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" }) : "Recent Order"}
                            </p>
                          </div>

                          <div className="flex items-center justify-between sm:justify-end gap-3 pt-2 sm:pt-0 border-t border-border/40 sm:border-t-0">
                            <span
                              className={`rounded-full border px-2.5 py-0.5 sm:px-3 sm:py-1 text-[10px] uppercase tracking-wider font-bold shrink-0 ${
                                ord.status === "Delivered"
                                  ? "border-emerald-500/50 bg-emerald-500/10 text-emerald-600"
                                  : ord.status === "Shipped"
                                  ? "border-blue-500/50 bg-blue-500/10 text-blue-600"
                                  : ord.status === "Cancelled"
                                  ? "border-destructive/50 bg-destructive/10 text-destructive"
                                  : "border-gold/60 bg-gold/10 text-gold"
                              }`}
                            >
                              {ord.status || "Processing"}
                            </span>
                            <span className="font-display text-base sm:text-lg font-bold text-foreground shrink-0">
                              ₹{(ord.totalAmount || 0).toLocaleString("en-IN")}
                            </span>
                          </div>
                        </div>

                        {ord.status === "Cancelled" && (
                          <div className="mt-3 text-xs text-destructive bg-destructive/10 border border-destructive/30 rounded-lg p-2.5 font-semibold flex flex-wrap items-center gap-1.5 min-w-0 break-words">
                            <span>❌ Order Cancelled. Reason:</span>
                            <span className="font-bold break-all">
                              {ord.cancelReason || (ord as any).cancelReason || "Item Out of Stock / Processing Issue"}
                            </span>
                          </div>
                        )}

                        <div className="mt-3.5 space-y-3">
                          {(ord.items || []).map((item, idx) => (
                            <div key={idx} className="flex items-center gap-3 sm:gap-4 min-w-0">
                              <img
                                src={item.image}
                                alt={item.name}
                                className="size-12 sm:size-14 rounded-lg object-cover border border-border shrink-0"
                              />
                              <div className="flex-1 min-w-0">
                                <h5 className="font-display text-xs sm:text-sm font-semibold text-foreground truncate">{item.name}</h5>
                                <p className="text-[11px] sm:text-xs text-muted-foreground truncate mt-0.5">
                                  Size: <span className="text-gold font-bold">{item.size}</span> • Color: {item.color} • Qty: {item.quantity}
                                </p>
                              </div>
                              <span className="text-xs sm:text-sm font-semibold text-foreground shrink-0 pl-1">
                                ₹{(item.price * item.quantity).toLocaleString("en-IN")}
                              </span>
                            </div>
                          ))}
                        </div>

                        <div className="mt-4 border-t border-border pt-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs text-muted-foreground min-w-0">
                          <div className="space-y-1 min-w-0 flex-1 break-words">
                            <p className="break-words leading-relaxed"><span className="text-gold font-semibold">Address:</span> {ord.shippingAddress}</p>
                            <p className="break-words leading-relaxed"><span className="text-gold font-semibold">Payment:</span> {ord.paymentMethod}</p>
                          </div>

                          <div className="flex items-center gap-2 shrink-0 pt-1 sm:pt-0">
                            {ord.status !== "Cancelled" && ord.status !== "Delivered" && (
                              <button
                                type="button"
                                onClick={() =>
                                  setCancellingOrderUser({
                                    id: ord._id || ord.id || "",
                                    bookingIdStr: String(ord._id || ord.id || "ORD").slice(-8).toUpperCase(),
                                  })
                                }
                                className="w-full sm:w-auto rounded-lg border border-destructive/60 bg-destructive/10 px-3.5 py-1.5 text-xs font-bold text-destructive hover:bg-destructive hover:text-destructive-foreground transition-all cursor-pointer shadow-sm text-center"
                              >
                                Cancel Order
                              </button>
                            )}

                            {ord.status === "Cancelled" && (
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.preventDefault();
                                  e.stopPropagation();
                                  handleDeleteOrder(
                                    ord._id || ord.id || "",
                                    String(ord._id || ord.id || "ORD").slice(-8).toUpperCase()
                                  );
                                }}
                                className="w-full sm:w-auto rounded-lg border border-destructive/40 bg-destructive/5 px-3.5 py-1.5 text-xs font-bold text-destructive hover:bg-destructive hover:text-white transition-all cursor-pointer flex items-center gap-1.5 shadow-sm"
                                title="Delete cancelled order record"
                              >
                                <Trash2 className="size-3.5" /> Delete Order Record
                              </button>
                            )}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="py-16 text-center text-muted-foreground border border-dashed border-border rounded-xl">
                    <Package className="mx-auto size-10 text-gold/50" />
                    <p className="mt-3 font-display text-base font-semibold text-foreground">No orders placed yet</p>
                    <p className="mt-1 text-xs">Browse our tee collection in "My Cart" and place your order!</p>
                    <button
                      onClick={() => setActiveTab("cart")}
                      className="btn-gold hover:btn-gold-hover mt-5 inline-flex items-center gap-2 rounded-sm px-6 py-2.5 text-xs font-bold"
                    >
                      Browse Collection <ArrowRight className="size-4" />
                    </button>
                  </div>
                )}
              </div>
            )}

            {/* 3. ADDRESSES TAB */}
            {activeTab === "addresses" && (
              <div className="space-y-6 max-w-3xl min-w-0 pt-3 sm:pt-0">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-border pb-4 gap-3">
                  <div>
                    <h2 className="font-display text-xl sm:text-2xl font-bold text-foreground">Addresses</h2>
                    <p className="text-xs text-muted-foreground mt-1">Manage saved shipping locations for fast checkout.</p>
                  </div>
                  <button
                    onClick={() => setShowAddAddress(!showAddAddress)}
                    className="btn-gold hover:btn-gold-hover inline-flex items-center justify-center gap-2 rounded-sm px-4 py-2.5 text-xs font-bold shrink-0 self-start sm:self-auto cursor-pointer shadow-sm"
                  >
                    <Plus className="size-4" /> Add New Address
                  </button>
                </div>

                {showAddAddress && (
                  <form onSubmit={handleAddAddress} className="rounded-xl border border-gold/40 bg-surface/50 p-4 sm:p-6 space-y-4 shadow-sm min-w-0">
                    <h3 className="font-display text-base font-semibold text-foreground">New Delivery Location</h3>

                    {/* LOCATION TYPE CHIPS */}
                    <div>
                      <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold block mb-2">
                        Address Category / Location Type
                      </label>
                      <div className="flex flex-wrap items-center gap-2">
                        <button
                          type="button"
                          onClick={() => setNewAddressType("Home")}
                          className={`flex items-center gap-2 rounded-lg border px-3.5 py-2 text-xs font-bold transition-all cursor-pointer ${
                            newAddressType === "Home"
                              ? "border-gold bg-gold text-primary-foreground shadow-goldy"
                              : "border-border bg-background text-muted-foreground hover:border-gold/50 hover:text-gold"
                          }`}
                        >
                          <Home className="size-4" /> Home
                        </button>

                        <button
                          type="button"
                          onClick={() => setNewAddressType("Office")}
                          className={`flex items-center gap-2 rounded-lg border px-3.5 py-2 text-xs font-bold transition-all cursor-pointer ${
                            newAddressType === "Office"
                              ? "border-gold bg-gold text-primary-foreground shadow-goldy"
                              : "border-border bg-background text-muted-foreground hover:border-gold/50 hover:text-gold"
                          }`}
                        >
                          <Briefcase className="size-4" /> Office / Work
                        </button>

                        <button
                          type="button"
                          onClick={() => setNewAddressType("Other")}
                          className={`flex items-center gap-2 rounded-lg border px-3.5 py-2 text-xs font-bold transition-all cursor-pointer ${
                            newAddressType === "Other"
                              ? "border-gold bg-gold text-primary-foreground shadow-goldy"
                              : "border-border bg-background text-muted-foreground hover:border-gold/50 hover:text-gold"
                          }`}
                        >
                          <MapPin className="size-4" /> Other
                        </button>
                      </div>

                      {newAddressType === "Other" && (
                        <div className="mt-3">
                          <input
                            type="text"
                            value={newCustomLabel}
                            onChange={(e) => setNewCustomLabel(e.target.value)}
                            placeholder="Custom Address Tag (e.g., Beach House, Parents' Home)"
                            className="w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                          />
                        </div>
                      )}
                    </div>

                    <div>
                      <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Street Address</label>
                      <input
                        required
                        type="text"
                        value={newStreet}
                        onChange={(e) => setNewStreet(e.target.value)}
                        placeholder="House no, Street name, Area"
                        className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                      />
                    </div>
                    <div className="grid gap-3.5 grid-cols-1 sm:grid-cols-3">
                      <div>
                        <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">City</label>
                        <input
                          required
                          type="text"
                          value={newCity}
                          onChange={(e) => setNewCity(e.target.value)}
                          placeholder="Bengaluru"
                          className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                        />
                      </div>
                      <div>
                        <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">State</label>
                        <input
                          type="text"
                          value={newState}
                          onChange={(e) => setNewState(e.target.value)}
                          placeholder="Karnataka"
                          className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                        />
                      </div>
                      <div>
                        <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Pin Code</label>
                        <input
                          required
                          type="text"
                          value={newPincode}
                          onChange={(e) => setNewPincode(e.target.value)}
                          placeholder="560038"
                          className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold font-mono"
                        />
                      </div>
                    </div>
                    <button type="submit" className="btn-gold hover:btn-gold-hover w-full sm:w-auto rounded-sm px-6 py-2.5 text-xs font-bold cursor-pointer">
                      Save Location
                    </button>
                  </form>
                )}

                <div className="grid gap-4 md:grid-cols-2">
                  {savedAddresses.map((addr: any) => (
                    <div key={addr.id} className="rounded-xl border border-gold/30 bg-card p-4 sm:p-5 space-y-3 shadow-sm transition-all hover:border-gold/60 relative min-w-0 overflow-hidden">
                      {editingAddressId === addr.id ? (
                        <form onSubmit={handleSaveEditAddress} className="space-y-3">
                          <div className="flex items-center justify-between border-b border-border pb-2">
                            <span className="text-xs font-bold uppercase tracking-wider text-gold">Edit Delivery Address</span>
                            <button
                              type="button"
                              onClick={() => setEditingAddressId(null)}
                              className="text-xs text-muted-foreground hover:text-foreground font-semibold cursor-pointer"
                            >
                              ✕ Cancel
                            </button>
                          </div>

                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Address Title</label>
                            <input
                              type="text"
                              value={editLabel}
                              onChange={(e) => setEditLabel(e.target.value)}
                              placeholder="Home / Office / Work"
                              className="mt-1 w-full rounded-sm border border-border bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-gold"
                              required
                            />
                          </div>

                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Street Address</label>
                            <input
                              type="text"
                              value={editStreet}
                              onChange={(e) => setEditStreet(e.target.value)}
                              placeholder="100 Feet Road, Indiranagar"
                              className="mt-1 w-full rounded-sm border border-border bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-gold"
                              required
                            />
                          </div>

                          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                            <div>
                              <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">City</label>
                              <input
                                type="text"
                                value={editCity}
                                onChange={(e) => setEditCity(e.target.value)}
                                className="mt-1 w-full rounded-sm border border-border bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-gold"
                                required
                              />
                            </div>
                            <div>
                              <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">State</label>
                              <input
                                type="text"
                                value={editState}
                                onChange={(e) => setEditState(e.target.value)}
                                className="mt-1 w-full rounded-sm border border-border bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-gold"
                                required
                              />
                            </div>
                            <div>
                              <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Pincode</label>
                              <input
                                type="text"
                                value={editPincode}
                                onChange={(e) => setEditPincode(e.target.value)}
                                className="mt-1 w-full rounded-sm border border-border bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-gold font-mono"
                                required
                              />
                            </div>
                          </div>

                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Mobile Phone</label>
                            <input
                              type="text"
                              value={editMobile}
                              onChange={(e) => setEditMobile(e.target.value)}
                              className="mt-1 w-full rounded-sm border border-border bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-gold font-mono"
                              required
                            />
                          </div>

                          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 pt-2">
                            <button
                              type="submit"
                              className="btn-gold hover:btn-gold-hover flex-1 rounded-sm py-2 text-xs font-bold uppercase tracking-wider cursor-pointer"
                            >
                              Save Address
                            </button>
                            <button
                              type="button"
                              onClick={() => setEditingAddressId(null)}
                              className="btn-outline-gold rounded-sm px-4 py-2 text-xs font-bold uppercase tracking-wider cursor-pointer"
                            >
                              Cancel
                            </button>
                          </div>
                        </form>
                      ) : (
                        <>
                          <div className="flex items-center justify-between gap-2 border-b border-border/40 pb-2">
                            <h4 className="font-display text-base font-bold text-foreground truncate min-w-0">{addr.name}</h4>
                            {addr.isDefault && (
                              <span className="rounded-full bg-gold/15 border border-gold/50 px-2.5 py-0.5 text-[9px] font-bold text-gold uppercase tracking-wider shrink-0 shadow-sm">
                                Default
                              </span>
                            )}
                          </div>

                          <p className="text-xs text-muted-foreground leading-relaxed break-words">{addr.address}</p>
                          <p className="text-xs text-muted-foreground break-words">{addr.city}, {addr.state} — {addr.pincode}</p>
                          <p className="text-xs text-gold font-mono font-bold pt-0.5">Phone: +91 {addr.mobile}</p>

                          {/* ACTION BUTTONS ROW */}
                          <div className="flex flex-wrap items-center gap-2 pt-3 border-t border-border/60 mt-3">
                            <button
                              type="button"
                              onClick={() => handleStartEditAddress(addr)}
                              className="flex items-center justify-center gap-1.5 rounded-md border border-gold/50 bg-gold/10 px-3.5 py-1.5 text-xs font-bold text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer shadow-sm active:scale-95"
                            >
                              <Edit3 className="size-3.5" /> Edit
                            </button>

                            {!addr.isDefault && (
                              <button
                                type="button"
                                onClick={() => handleSetDefaultAddress(addr.id)}
                                className="rounded-md border border-border bg-surface px-3.5 py-1.5 text-xs font-semibold text-muted-foreground hover:text-gold hover:border-gold/50 transition-colors cursor-pointer"
                              >
                                Set Default
                              </button>
                            )}

                            <button
                              type="button"
                              onClick={() => handleDeleteAddress(addr.id)}
                              className="flex items-center justify-center gap-1 rounded-md border border-destructive/40 bg-destructive/10 px-3 py-1.5 text-xs font-semibold text-destructive hover:bg-destructive hover:text-white transition-all ml-auto cursor-pointer"
                              title="Delete Address"
                            >
                              <Trash2 className="size-3.5" /> Delete
                            </button>
                          </div>
                        </>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* 4. MY CART TAB (3-Step Page-Level Checkout Flow: Cart -> Address Details -> Payment Option) */}
            {activeTab === "cart" && (
              <div className="space-y-6 pt-3 sm:pt-0">
                {cartCheckoutStep === "cart" && (
                  <>
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-border pb-4 gap-3">
                      <div className="flex items-center gap-3">
                        <h2 className="font-display text-2xl font-bold text-foreground">My Cart</h2>
                      </div>
                      {cartItems.length > 0 && (
                        <button
                          onClick={clearCart}
                          className="text-xs text-muted-foreground hover:text-destructive transition-colors uppercase tracking-wider font-semibold cursor-pointer w-fit"
                        >
                          Clear Cart
                        </button>
                      )}
                    </div>

                    {cartItems.length > 0 ? (
                      <div className="grid gap-8 lg:grid-cols-[1fr_320px]">
                        {/* Cart Items List */}
                        <div className="space-y-4">
                          {cartItems.map((ci, idx) => (
                            <div
                              key={`${ci.product.id}-${ci.size}-${idx}`}
                              className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 rounded-xl border border-border bg-background p-4 shadow-sm"
                            >
                              <div className="flex items-center gap-4">
                                <img
                                  src={ci.product.image}
                                  alt={ci.product.name}
                                  className="size-20 rounded-lg object-cover border border-border shrink-0"
                                />
                                <div>
                                  <h4 className="font-display text-base font-semibold text-foreground">
                                    {ci.product.name}
                                  </h4>
                                  <p className="text-xs text-muted-foreground mt-0.5">
                                    Color: {ci.product.color} • Size:{" "}
                                    <span className="text-gold font-bold">{ci.size}</span>
                                  </p>
                                  <div className="flex items-baseline gap-2 mt-1">
                                    <span className="text-xs text-gold font-bold">
                                      ₹{ci.product.price.toLocaleString("en-IN")}
                                    </span>
                                    {ci.product.oldPrice && ci.product.oldPrice > ci.product.price && (
                                      <span className="text-[11px] text-muted-foreground line-through">
                                        ₹{ci.product.oldPrice.toLocaleString("en-IN")}
                                      </span>
                                    )}
                                  </div>
                                </div>
                              </div>

                              <div className="flex items-center justify-between sm:justify-end gap-6 pt-2 sm:pt-0 border-t sm:border-t-0 border-border">
                                {/* Quantity Controls */}
                                <div className="flex items-center rounded-md border border-border bg-surface">
                                  <button
                                    onClick={() => updateCartQuantity(ci.product.id, ci.size, -1)}
                                    className="p-2 text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
                                  >
                                    <Minus className="size-3.5" />
                                  </button>
                                  <span className="w-8 text-center text-xs font-bold text-foreground">
                                    {ci.quantity}
                                  </span>
                                  <button
                                    onClick={() => updateCartQuantity(ci.product.id, ci.size, 1)}
                                    className="p-2 text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
                                  >
                                    <Plus className="size-3.5" />
                                  </button>
                                </div>

                                {/* Item Subtotal */}
                                <span className="font-display text-base font-bold text-foreground min-w-[80px] text-right">
                                  ₹{(ci.product.price * ci.quantity).toLocaleString("en-IN")}
                                </span>

                                {/* Remove Item */}
                                <button
                                  onClick={() => removeFromCart(ci.product.id, ci.size)}
                                  className="text-muted-foreground hover:text-destructive transition-colors p-1 cursor-pointer"
                                  title="Remove item"
                                >
                                  <Trash2 className="size-4" />
                                </button>
                              </div>
                            </div>
                          ))}
                        </div>

                        {/* Cart Summary (Sticky on Desktop) */}
                        <div className="lg:sticky lg:top-28 h-fit rounded-xl border border-gold/40 bg-card p-6 space-y-4 shadow-sm z-10">
                          <h3 className="font-display text-lg font-bold text-foreground border-b border-border pb-3">
                            Order Summary
                          </h3>

                          <div className="space-y-2.5 text-xs text-muted-foreground">
                            {/* Original Total Price (MRP) */}
                            {totalOriginalMRP > totalAmount && (
                              <div className="flex justify-between">
                                <span>Original Price (MRP)</span>
                                <span className="text-muted-foreground line-through font-medium">₹{totalOriginalMRP.toLocaleString("en-IN")}</span>
                              </div>
                            )}

                            <div className="flex justify-between">
                              <span>Discounted Price ({totalCartItemsCount})</span>
                              <span className="text-foreground font-semibold">₹{totalAmount.toLocaleString("en-IN")}</span>
                            </div>

                            {/* Offer Savings / Discount */}
                            {totalOfferDiscount > 0 && (
                              <div className="flex justify-between text-emerald-600 font-bold">
                                <span>Offer Savings / Discount</span>
                                <span>- ₹{totalOfferDiscount.toLocaleString("en-IN")}</span>
                              </div>
                            )}

                            {/* Pan-India Express Shipping */}
                            <div className="flex justify-between">
                              <span>Pan-India Express Shipping</span>
                              {deliveryCharge > 0 ? (
                                <span className="text-foreground font-bold text-gold">₹{deliveryCharge}</span>
                              ) : (
                                <span className="text-gold font-bold">FREE (₹0)</span>
                              )}
                            </div>

                            {totalCartItemsCount === 1 && (
                              <div className="rounded-lg bg-gold/10 border border-gold/30 p-2.5 text-[11px] text-gold font-bold text-center mt-1">
                                💡 Add 1 more product to get FREE Delivery!
                              </div>
                            )}
                          </div>

                          <div className="flex justify-between border-t border-border pt-3 font-display text-lg font-bold text-foreground">
                            <span>Total Price</span>
                            <span className="text-gold">₹{finalOrderTotal.toLocaleString("en-IN")}</span>
                          </div>

                          <button
                            type="button"
                            onClick={() => {
                              setIsCartCheckout(true);
                              setCartCheckoutStep("address");
                              setOrderSuccessMsg("");
                            }}
                            className="btn-gold hover:btn-gold-hover w-full rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider flex items-center justify-center gap-2 cursor-pointer shadow-sm"
                          >
                            <ShoppingBag className="size-4" /> Proceed to Place Order
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="flex flex-col items-center justify-center rounded-sm border border-border bg-background py-20 px-6 text-center min-h-[340px] shadow-sm">
                        <p className="text-sm font-medium text-muted-foreground">
                          Your cart is currently empty.
                        </p>
                        <Link
                          to="/products"
                          className="mt-6 inline-block bg-foreground text-background hover:bg-gold hover:text-primary-foreground px-8 py-3.5 text-xs font-bold uppercase tracking-[0.25em] transition-all duration-300 shadow-md"
                        >
                          START SHOPPING
                        </Link>
                      </div>
                    )}
                  </>
                )}

                {/* PAGE STEP 1: ADDRESS DETAILS & SAVED ADDRESS CARDS */}
                {cartCheckoutStep === "address" && (
                  <div className="space-y-6 max-w-2xl animate-in fade-in duration-300 min-w-0">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-border pb-4 gap-2">
                      <div>
                        <span className="text-[10px] uppercase tracking-widest text-gold font-bold block">Checkout Step 1 of 2</span>
                        <h2 className="font-display text-xl sm:text-2xl font-bold text-foreground">Delivery Address Details</h2>
                      </div>
                      <button
                        type="button"
                        onClick={() => setCartCheckoutStep("cart")}
                        className="text-xs font-semibold uppercase tracking-wider text-gold hover:underline cursor-pointer self-start sm:self-auto"
                      >
                        ← Back to Cart
                      </button>
                    </div>

                    {/* Requirement 3: Saved Address Cards + Add New Address Toggle Option */}
                    {savedAddresses.length > 0 && (
                      <div className="space-y-3 rounded-xl border border-gold/40 bg-card p-4 sm:p-5 shadow-sm">
                        <div className="flex items-center justify-between border-b border-border pb-3">
                          <h3 className="font-display text-sm font-bold text-foreground">Select Saved Delivery Address</h3>
                          <button
                            type="button"
                            onClick={() => setShowAddNewAddressForm(!showAddNewAddressForm)}
                            className="flex items-center gap-1.5 rounded-md border border-gold/50 bg-gold/10 px-3 py-1.5 text-xs font-bold text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer shadow-sm"
                          >
                            <Plus className="size-3.5" /> {showAddNewAddressForm ? "Use Saved Address" : "Add New Address"}
                          </button>
                        </div>

                        {!showAddNewAddressForm && (
                          <div className="space-y-4">
                            <div className="grid gap-3 sm:grid-cols-2">
                              {savedAddresses.map((addr: any) => {
                                const isSelected = selectedSavedAddressId === addr.id;
                                return (
                                  <div
                                    key={addr.id}
                                    onClick={() => {
                                      setSelectedSavedAddressId(addr.id);
                                      setShippingName(addr.name || user?.name || "EDUKONDALU");
                                      setShippingPhone(addr.mobile || "9876543210");
                                      setShippingStreet(addr.address || "");
                                      setShippingCity(addr.city || "Bengaluru");
                                      setShippingState(addr.state || "Karnataka");
                                      setShippingPincode(addr.pincode || "560038");
                                      setShippingAddress(`${addr.name} (+91 ${addr.mobile}), ${addr.address}, ${addr.city}, ${addr.state} - ${addr.pincode}`);
                                    }}
                                    className={`rounded-xl border p-4 cursor-pointer transition-all ${
                                      isSelected
                                        ? "border-gold bg-gold/15 shadow-goldy font-bold"
                                        : "border-border bg-background hover:border-gold/50"
                                    }`}
                                  >
                                    <div className="flex items-start justify-between gap-2 border-b border-border/40 pb-2">
                                      <span className="font-bold text-xs text-foreground truncate">{addr.name}</span>
                                      {addr.isDefault && (
                                        <span className="rounded-full bg-gold/15 border border-gold/50 px-2 py-0.5 text-[9px] font-bold text-gold uppercase shrink-0">
                                          Default
                                        </span>
                                      )}
                                    </div>
                                    <p className="text-xs text-muted-foreground mt-2 line-clamp-2">{addr.address}</p>
                                    <p className="text-xs text-muted-foreground mt-0.5">{addr.city}, {addr.state} - {addr.pincode}</p>
                                    <p className="text-xs text-gold font-mono font-bold mt-1.5">+91 {addr.mobile}</p>
                                  </div>
                                );
                              })}
                            </div>

                            <div className="flex flex-col-reverse sm:flex-row items-stretch sm:items-center gap-3 pt-2">
                              <button
                                type="button"
                                onClick={() => setCartCheckoutStep("cart")}
                                className="btn-outline-gold rounded-sm px-6 py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer w-full sm:w-auto text-center"
                              >
                                ← Back to Cart
                              </button>
                              <button
                                type="button"
                                onClick={() => setCartCheckoutStep("payment")}
                                className="btn-gold hover:btn-gold-hover flex-1 rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer flex items-center justify-center gap-2 shadow-sm w-full text-center"
                              >
                                Proceed to Payment <ArrowRight className="size-4" />
                              </button>
                            </div>
                          </div>
                        )}
                      </div>
                    )}

                    {(showAddNewAddressForm || savedAddresses.length === 0) && (
                      <form
                        onSubmit={(e) => {
                          e.preventDefault();
                          const fullAddr = `${shippingName} (+91 ${shippingPhone}), ${shippingStreet}, ${shippingCity}, ${shippingState} - ${shippingPincode}`;
                          setShippingAddress(fullAddr);
                          setCartCheckoutStep("payment");
                        }}
                        className="rounded-xl border border-gold/40 bg-card p-4 sm:p-6 shadow-sm space-y-4 sm:space-y-5 min-w-0"
                      >
                        <div className="border-b border-border pb-3">
                          <h3 className="font-display text-base font-bold text-foreground">Enter New Shipping Address Details</h3>
                          <p className="text-xs text-muted-foreground">Please enter complete recipient details before proceeding to payment.</p>
                        </div>

                        <div className="grid gap-3.5 sm:grid-cols-2">
                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Full Name *</label>
                            <input
                              required
                              type="text"
                              value={shippingName}
                              onChange={(e) => setShippingName(e.target.value)}
                              placeholder="Full Name"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                            />
                          </div>

                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Mobile Phone Number *</label>
                            <input
                              required
                              type="tel"
                              value={shippingPhone}
                              onChange={(e) => setShippingPhone(e.target.value)}
                              placeholder="10-digit mobile number"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold font-mono"
                            />
                          </div>
                        </div>

                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">House No / Building / Street Address *</label>
                          <textarea
                            required
                            rows={2}
                            value={shippingStreet}
                            onChange={(e) => setShippingStreet(e.target.value)}
                            placeholder="House No, Building name, Street name, Area"
                            className="mt-1.5 w-full rounded-sm border border-border bg-background p-3 text-xs text-foreground outline-none focus:border-gold"
                          />
                        </div>

                        <div className="grid gap-3.5 grid-cols-1 sm:grid-cols-3">
                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">City *</label>
                            <input
                              required
                              type="text"
                              value={shippingCity}
                              onChange={(e) => setShippingCity(e.target.value)}
                              placeholder="Bengaluru"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                            />
                          </div>
                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">State *</label>
                            <input
                              required
                              type="text"
                              value={shippingState}
                              onChange={(e) => setShippingState(e.target.value)}
                              placeholder="Karnataka"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                            />
                          </div>
                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Pincode *</label>
                            <input
                              required
                              type="text"
                              value={shippingPincode}
                              onChange={(e) => setShippingPincode(e.target.value)}
                              placeholder="560038"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold font-mono"
                            />
                          </div>
                        </div>

                        <div className="flex flex-col-reverse sm:flex-row items-stretch sm:items-center gap-3 pt-2">
                          <button
                            type="button"
                            onClick={() => setCartCheckoutStep("cart")}
                            className="btn-outline-gold rounded-sm px-6 py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer w-full sm:w-auto text-center"
                          >
                            ← Back to Cart
                          </button>
                          <button
                            type="submit"
                            className="btn-gold hover:btn-gold-hover flex-1 rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer flex items-center justify-center gap-2 shadow-sm w-full text-center"
                          >
                            Proceed to Payment <ArrowRight className="size-4" />
                          </button>
                        </div>
                      </form>
                    )}
                  </div>
                )}

                {/* PAGE STEP 2: DEMO PAYMENT OPTION */}
                {cartCheckoutStep === "payment" && (
                  <div className="space-y-6 max-w-2xl animate-in fade-in duration-300">
                    <div className="flex items-center justify-between border-b border-border pb-4">
                      <div>
                        <span className="text-[10px] uppercase tracking-widest text-gold font-bold">Checkout Step 2 of 2</span>
                        <h2 className="font-display text-2xl font-bold text-foreground">Select Payment Option (Demo)</h2>
                      </div>
                      <button
                        type="button"
                        onClick={() => setCartCheckoutStep("address")}
                        className="text-xs font-semibold uppercase tracking-wider text-gold hover:underline cursor-pointer"
                      >
                        ← Back to Address Details
                      </button>
                    </div>

                    <form onSubmit={handlePlaceOrder} className="rounded-xl border border-gold/40 bg-card p-6 shadow-sm space-y-5">
                      {/* Address Summary Banner */}
                      <div className="flex items-center justify-between rounded-lg border border-gold/30 bg-gold/10 p-4 text-xs">
                        <div>
                          <span className="text-[10px] uppercase tracking-wider text-gold font-bold">Delivery Address Details</span>
                          <p className="font-bold text-foreground mt-0.5">{shippingName} (+91 {shippingPhone})</p>
                          <p className="text-[11px] text-muted-foreground">{shippingStreet}, {shippingCity}, {shippingState} - {shippingPincode}</p>
                        </div>
                        <button
                          type="button"
                          onClick={() => setCartCheckoutStep("address")}
                          className="text-[11px] font-bold text-gold uppercase tracking-wider hover:underline shrink-0 ml-3 cursor-pointer"
                        >
                          Change Address
                        </button>
                      </div>

                      {/* Items Summary */}
                      <div className="space-y-3 max-h-60 overflow-y-auto rounded-lg border border-border bg-surface/50 p-4">
                        <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                          Order Items Summary ({cartItems.reduce((acc, i) => acc + (i.quantity || 1), 0)} items)
                        </p>
                        {cartItems.map((ci, idx) => (
                          <div key={idx} className="flex items-center justify-between gap-3 text-xs border-b border-border/50 pb-2 last:border-0 last:pb-0">
                            <div className="flex items-center gap-3 overflow-hidden">
                              <img src={ci.product?.image || ""} alt={ci.product?.name || "Item"} className="size-12 rounded-md object-cover shrink-0 border border-border" />
                              <div className="overflow-hidden">
                                <p className="font-bold text-foreground truncate">{ci.product?.name || "Product"}</p>
                                <p className="text-[11px] text-muted-foreground">Size: <span className="text-gold font-bold">{ci.size}</span> • Qty: {ci.quantity}</p>
                              </div>
                            </div>
                            <span className="font-bold text-gold shrink-0">₹{((ci.product?.price || 0) * ci.quantity).toLocaleString("en-IN")}</span>
                          </div>
                        ))}
                      </div>

                      {/* DEMO PAYMENT OPTION SELECTOR */}
                      <div className="space-y-3">
                        <div className="flex items-center justify-between">
                          <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                            Select Payment Method
                          </label>
                        </div>

                        <div className="grid gap-2.5 sm:grid-cols-3">
                          {[
                            { id: "Demo UPI Instant (GPay / PhonePe / Paytm)", label: "Demo UPI Instant", desc: "Simulated GPay, PhonePe, Paytm or UPI" },
                            { id: "Demo Credit / Debit Card", label: "Demo Card Payment", desc: "Simulated Visa, MasterCard, RuPay" },
                            { id: "Demo Cash on Delivery (COD)", label: "Cash on Delivery", desc: "Pay cash upon physical delivery" },
                          ].map((pm) => (
                            <div
                              key={pm.id}
                              onClick={() => setPaymentMethod(pm.id)}
                              className={`cursor-pointer rounded-lg border p-3.5 transition-all ${
                                paymentMethod === pm.id
                                  ? "border-gold bg-gold/10 shadow-sm"
                                  : "border-border bg-background hover:border-gold/50"
                              }`}
                            >
                              <div className="flex items-center gap-2.5">
                                <input
                                  type="radio"
                                  name="demoPayment"
                                  checked={paymentMethod === pm.id}
                                  onChange={() => setPaymentMethod(pm.id)}
                                  className="accent-gold"
                                />
                                <div>
                                  <p className="text-xs font-bold text-foreground">{pm.label}</p>
                                  <p className="text-[10px] text-muted-foreground">{pm.desc}</p>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>


                      {/* Price Total */}
                      <div className="rounded-lg border border-gold/40 bg-gold/10 p-4 space-y-2 text-xs">
                        <div className="flex justify-between text-muted-foreground">
                          <span>Subtotal:</span>
                          <span className="text-foreground font-semibold">₹{totalAmount.toLocaleString("en-IN")}</span>
                        </div>

                        {totalOfferDiscount > 0 && (
                          <div className="flex justify-between text-emerald-600 font-bold">
                            <span>Total Offer Savings:</span>
                            <span>- ₹{totalOfferDiscount.toLocaleString("en-IN")}</span>
                          </div>
                        )}

                        <div className="flex justify-between text-muted-foreground">
                          <span>Pan-India Express Shipping:</span>
                          {deliveryCharge > 0 ? (
                            <span className="text-foreground font-bold text-gold">₹{deliveryCharge}</span>
                          ) : (
                            <span className="text-gold font-bold">FREE (₹0)</span>
                          )}
                        </div>

                        <div className="flex justify-between border-t border-gold/30 pt-2 font-bold text-foreground text-base">
                          <span>Total Payable:</span>
                          <span className="text-gold">₹{finalOrderTotal.toLocaleString("en-IN")}</span>
                        </div>
                      </div>

                      <div className="flex flex-col-reverse sm:flex-row items-stretch sm:items-center gap-3 pt-2">
                        <button
                          type="button"
                          onClick={() => setCartCheckoutStep("address")}
                          className="btn-outline-gold rounded-sm px-6 py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer w-full sm:w-auto text-center"
                        >
                          ← Back to Address
                        </button>
                        <button
                          type="submit"
                          disabled={orderSubmitting}
                          className="btn-gold hover:btn-gold-hover flex-1 rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider disabled:opacity-70 cursor-pointer flex items-center justify-center gap-2 shadow-sm w-full text-center"
                        >

                          {orderSubmitting ? (
                            <>
                              <RefreshCw className="size-4 animate-spin" /> Processing Order...
                            </>
                          ) : (
                            <>
                              <CheckCircle2 className="size-4" /> Place Order — Total ₹{finalOrderTotal.toLocaleString("en-IN")}
                            </>
                          )}
                        </button>
                      </div>
                    </form>
                  </div>
                )}

                {/* Requirement 4: Dedicated Order Successful Page Redirection Screen */}
                {cartCheckoutStep === "success" && (
                  <div className="space-y-6 max-w-2xl mx-auto py-8 text-center animate-in fade-in zoom-in-95 duration-300">
                    <div className="rounded-2xl border border-gold/40 bg-card p-6 sm:p-10 shadow-goldy space-y-6">
                      <div className="mx-auto flex size-20 items-center justify-center rounded-full bg-gold/15 border-2 border-gold text-gold shadow-md">
                        <CheckCircle2 className="size-10 text-gold animate-bounce" />
                      </div>

                      <div>
                        <span className="text-xs uppercase tracking-[0.25em] text-gold font-bold">Order Confirmed</span>
                        <h2 className="mt-1 font-display text-2xl sm:text-3xl font-bold text-foreground">
                          Order Placed Successfully! 🎉
                        </h2>
                        <p className="mt-2 text-xs sm:text-sm text-muted-foreground leading-relaxed">
                          Thank you for shopping with VEXA. Your order has been placed successfully and is currently being prepared for dispatch.
                        </p>
                      </div>

                      {/* Order Receipt Box */}
                      {lastPlacedOrder && (
                        <div className="rounded-xl border border-border bg-surface/50 p-4 sm:p-6 text-left space-y-3 text-xs">
                          <div className="flex justify-between border-b border-border pb-3">
                            <div>
                              <span className="text-[10px] uppercase text-muted-foreground font-semibold">Order Reference ID</span>
                              <p className="font-display font-bold text-foreground text-sm">
                                #{String(lastPlacedOrder._id || lastPlacedOrder.id).slice(-8).toUpperCase()}
                              </p>
                            </div>
                            <div className="text-right">
                              <span className="text-[10px] uppercase text-muted-foreground font-semibold">Total Paid</span>
                              <p className="font-display font-bold text-gold text-sm">
                                ₹{(lastPlacedOrder.totalAmount || 0).toLocaleString("en-IN")}
                              </p>
                            </div>
                          </div>

                          <div className="space-y-1.5 pt-1">
                            <p className="text-muted-foreground"><span className="text-gold font-bold">Delivery Address:</span> {lastPlacedOrder.shippingAddress}</p>
                            <p className="text-muted-foreground"><span className="text-gold font-bold">Payment Method:</span> {lastPlacedOrder.paymentMethod}</p>
                            <p className="text-muted-foreground"><span className="text-gold font-bold">Estimated Delivery:</span> 2 – 4 Business Days (Pan-India Express)</p>
                          </div>
                        </div>
                      )}

                      <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-2">
                        <button
                          type="button"
                          onClick={() => {
                            setCartCheckoutStep("cart");
                            setActiveTab("orders");
                          }}
                          className="btn-gold hover:btn-gold-hover w-full sm:w-auto rounded-lg px-8 py-3.5 text-xs font-bold uppercase tracking-wider flex items-center justify-center gap-2 shadow-sm cursor-pointer"
                        >
                          <Package className="size-4" /> View My Orders & Track Status
                        </button>

                        <Link
                          to="/products"
                          onClick={() => setCartCheckoutStep("cart")}
                          className="btn-outline-gold w-full sm:w-auto rounded-lg px-6 py-3.5 text-xs font-bold uppercase tracking-wider flex items-center justify-center gap-2 cursor-pointer text-center"
                        >
                          Continue Shopping <ArrowRight className="size-4" />
                        </Link>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* MY WISHLIST TAB (Full CRUD: View Saved Items, Move to Cart, Delete Item, Clear All) */}
            {activeTab === "wishlist" && (
              <div className="space-y-6 pt-3 sm:pt-0">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-border pb-4 gap-3">
                  <div className="flex items-center gap-3">
                    <h2 className="font-display text-2xl font-bold text-foreground">My Wishlist</h2>
                    <span className="rounded-full bg-gold/15 border border-gold/40 px-3 py-0.5 text-xs font-bold text-gold">
                      {wishlistItems.length} Saved {wishlistItems.length === 1 ? "Item" : "Items"}
                    </span>
                  </div>
                  {wishlistItems.length > 0 && (
                    <button
                      type="button"
                      onClick={clearWishlist}
                      className="text-xs text-muted-foreground hover:text-destructive transition-colors uppercase tracking-wider font-semibold cursor-pointer w-fit"
                    >
                      Clear Wishlist
                    </button>
                  )}
                </div>

                {wishlistItems.length > 0 ? (
                  <div className="grid grid-cols-1 xs:grid-cols-2 lg:grid-cols-3 gap-6">
                    {wishlistItems.map((p) => {
                      const off = Math.round((1 - p.price / p.oldPrice) * 100);
                      return (
                        <div
                          key={p.id}
                          className="group relative flex flex-col justify-between overflow-hidden rounded-xl border border-border bg-card shadow-sm transition-all hover:border-gold hover:shadow-goldy"
                        >
                          <div className="relative overflow-hidden aspect-[3/4] w-full">
                            <img
                              src={p.image}
                              alt={p.name}
                              className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                            />
                            <span className="absolute left-3 top-3 rounded-full border border-gold/60 bg-[#f4efe6] px-3 py-1 text-[10px] uppercase tracking-widest text-[#1c1917] font-extrabold shadow-md">
                              {p.category}
                            </span>
                            <button
                              type="button"
                              onClick={() => removeFromWishlist(p.id)}
                              className="absolute right-3 top-3 z-10 flex size-8 items-center justify-center rounded-full border border-red-500/80 bg-black/90 text-red-500 shadow-md transition-all hover:scale-110 active:scale-95 cursor-pointer"
                              title="Remove from Wishlist"
                            >
                              <Trash2 className="size-4" />
                            </button>
                          </div>

                          <div className="p-4 space-y-3 flex-1 flex flex-col justify-between">
                            <div>
                              <div className="flex items-center justify-between gap-2">
                                <span className="text-[10px] font-bold uppercase tracking-widest text-muted-foreground">{p.color}</span>
                                <span className="rounded-full bg-gold/15 px-2 py-0.5 text-[10px] font-bold text-gold">{off}% OFF</span>
                              </div>
                              <h3 className="font-display text-base font-bold text-foreground mt-1 line-clamp-1">
                                {p.name}
                              </h3>
                              <div className="flex items-baseline gap-2 mt-1.5">
                                <span className="font-display text-lg font-extrabold text-gold">₹{p.price.toLocaleString("en-IN")}</span>
                                <span className="text-xs text-muted-foreground line-through">₹{p.oldPrice.toLocaleString("en-IN")}</span>
                              </div>
                            </div>

                            <button
                              type="button"
                              onClick={() => {
                                addToCart(p, "M", 1);
                                removeFromWishlist(p.id);
                              }}
                              className="btn-gold hover:btn-gold-hover w-full flex items-center justify-center gap-2 rounded-lg py-2.5 text-xs font-extrabold uppercase tracking-wider shadow-goldy cursor-pointer transition-transform active:scale-95"
                            >
                              <ShoppingBag className="size-4" /> Move to Cart
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="rounded-2xl border border-dashed border-border bg-card/50 p-12 text-center space-y-4 max-w-md mx-auto my-8">
                    <div className="mx-auto flex size-16 items-center justify-center rounded-full border border-gold/50 bg-gold/10 text-gold shadow-goldy">
                      <Heart className="size-8" />
                    </div>
                    <div className="space-y-1">
                      <h3 className="font-display text-xl font-bold text-foreground">Your Wishlist is Empty</h3>
                      <p className="text-xs text-muted-foreground">
                        Explore our luxury collection and click the heart icon on any product card to save your favorite drops.
                      </p>
                    </div>
                    <Link
                      to="/products"
                      className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2 rounded-lg px-6 py-3 text-xs font-bold uppercase tracking-widest shadow-goldy"
                    >
                      Explore Products <ArrowRight className="size-4" />
                    </Link>
                  </div>
                )}
              </div>
            )}

            {/* 5. SUPPORT TAB */}
            {activeTab === "support" && (
              <div className="space-y-6 max-w-2xl pt-3 sm:pt-0">
                <div className="border-b border-border pb-4">
                  <h2 className="font-display text-2xl font-bold text-foreground">Support & Client Concierge</h2>
                  <p className="text-xs text-muted-foreground mt-1">Get immediate assistance with sizing, orders, and returns.</p>
                </div>

                <div className="grid gap-4 sm:grid-cols-2">
                  <div className="rounded-xl border border-gold/40 bg-gold/10 p-6 space-y-3">
                    <MessageCircle className="size-6 text-gold" />
                    <h3 className="font-display text-base font-semibold text-foreground">Instant WhatsApp Support</h3>
                    <p className="text-xs text-muted-foreground">Direct chat with our concierge team.</p>
                    <a
                      href="https://wa.me/919876543210"
                      target="_blank"
                      rel="noreferrer"
                      className="btn-gold hover:btn-gold-hover block w-full rounded-sm py-2.5 text-center text-xs font-bold uppercase tracking-wider"
                    >
                      Chat on WhatsApp (+91 98765 43210)
                    </a>
                  </div>

                  <div className="rounded-xl border border-border bg-background p-6 space-y-3">
                    <Mail className="size-6 text-gold" />
                    <h3 className="font-display text-base font-semibold text-foreground">Email Support</h3>
                    <p className="text-xs text-muted-foreground">Average reply time under 3 hours.</p>
                    <a
                      href="mailto:support@vexa.store"
                      className="btn-outline-gold block w-full rounded-sm py-2.5 text-center text-xs font-bold uppercase tracking-wider hover:bg-gold hover:text-primary-foreground"
                    >
                      Email support@vexa.store
                    </a>
                  </div>
                </div>
              </div>
            )}

            {/* 6. BOOK NEW TEE / CHECKOUT PAGE TAB */}
            {activeTab === "booking" && (
              <div className="space-y-6 pt-3 sm:pt-0">
                {isCartCheckout || selectedProduct ? (
                  /* INLINE ORDER CHECKOUT PAGE SECTION WITH 2 STEPS */
                  <div className="space-y-6 max-w-2xl animate-in fade-in duration-300">
                    <div className="flex items-center justify-between border-b border-border pb-4">
                      <div>
                        <span className="text-[10px] uppercase tracking-widest text-gold font-bold">
                          {isCartCheckout ? "Cart Order Checkout" : "Direct Item Booking"}
                        </span>
                        <h2 className="font-display text-2xl font-bold text-foreground">
                          {checkoutStep === 1 ? "Step 1: Delivery Address Details" : "Step 2: Demo Payment & Place Order"}
                        </h2>
                      </div>
                      <button
                        type="button"
                        onClick={() => {
                          setIsCartCheckout(false);
                          setSelectedProduct(null);
                          setCheckoutStep(1);
                        }}
                        className="text-xs font-semibold uppercase tracking-wider text-gold hover:underline cursor-pointer"
                      >
                        ← Back to Catalog
                      </button>
                    </div>

                    {/* STEP PROGRESS BAR */}
                    <div className="flex items-center gap-3">
                      <div className={`flex-1 rounded-full h-1.5 transition-colors ${checkoutStep >= 1 ? "bg-gold" : "bg-border"}`} />
                      <span className="text-[11px] font-bold text-gold uppercase tracking-wider">Step {checkoutStep} of 2</span>
                      <div className={`flex-1 rounded-full h-1.5 transition-colors ${checkoutStep >= 2 ? "bg-gold" : "bg-border"}`} />
                    </div>

                    {orderSuccessMsg ? (
                      <div className="rounded-xl border border-gold/40 bg-card p-8 text-center space-y-3 shadow-goldy">
                        <CheckCircle2 className="mx-auto size-12 text-gold animate-bounce" />
                        <h4 className="font-display text-lg font-bold text-foreground">{orderSuccessMsg}</h4>
                        <p className="text-xs text-muted-foreground">Redirecting to your orders list...</p>
                      </div>
                    ) : checkoutStep === 1 ? (
                      /* STEP 1: ADDRESS DETAILS FORM */
                      <form
                        onSubmit={(e) => {
                          e.preventDefault();
                          const fullAddr = `${shippingName} (+91 ${shippingPhone}), ${shippingStreet}, ${shippingCity}, ${shippingState} - ${shippingPincode}`;
                          setShippingAddress(fullAddr);
                          setCheckoutStep(2);
                        }}
                        className="rounded-xl border border-gold/40 bg-card p-6 shadow-sm space-y-5"
                      >
                        <div className="border-b border-border pb-3">
                          <h3 className="font-display text-base font-bold text-foreground">Enter Delivery Shipping Address</h3>
                          <p className="text-xs text-muted-foreground">Provide full recipient details for delivery.</p>
                        </div>

                        <div className="grid gap-4 sm:grid-cols-2">
                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Full Name *</label>
                            <input
                              required
                              type="text"
                              value={shippingName}
                              onChange={(e) => setShippingName(e.target.value)}
                              placeholder="Full Name"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                            />
                          </div>

                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Mobile Phone Number *</label>
                            <input
                              required
                              type="tel"
                              value={shippingPhone}
                              onChange={(e) => setShippingPhone(e.target.value)}
                              placeholder="10-digit phone number"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold font-mono"
                            />
                          </div>
                        </div>

                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Street / Building / Area Address *</label>
                          <textarea
                            required
                            rows={2}
                            value={shippingStreet}
                            onChange={(e) => setShippingStreet(e.target.value)}
                            placeholder="House No, Building name, Street name, Area"
                            className="mt-1.5 w-full rounded-sm border border-border bg-background p-3 text-xs text-foreground outline-none focus:border-gold"
                          />
                        </div>

                        <div className="grid gap-4 sm:grid-cols-3">
                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">City *</label>
                            <input
                              required
                              type="text"
                              value={shippingCity}
                              onChange={(e) => setShippingCity(e.target.value)}
                              placeholder="Bengaluru"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                            />
                          </div>
                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">State *</label>
                            <input
                              required
                              type="text"
                              value={shippingState}
                              onChange={(e) => setShippingState(e.target.value)}
                              placeholder="Karnataka"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                            />
                          </div>
                          <div>
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Pincode *</label>
                            <input
                              required
                              type="text"
                              value={shippingPincode}
                              onChange={(e) => setShippingPincode(e.target.value)}
                              placeholder="560038"
                              className="mt-1.5 w-full rounded-sm border border-border bg-background px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold font-mono"
                            />
                          </div>
                        </div>

                        <button
                          type="submit"
                          className="btn-gold hover:btn-gold-hover w-full rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer flex items-center justify-center gap-2 shadow-sm"
                        >
                          Continue to Demo Payment <ArrowRight className="size-4" />
                        </button>
                      </form>
                    ) : (
                      /* STEP 2: DEMO PAYMENT OPTION & ORDER CONFIRMATION */
                      <form onSubmit={handlePlaceOrder} className="rounded-xl border border-gold/40 bg-card p-6 shadow-sm space-y-5">
                        {/* Address Summary Banner */}
                        <div className="flex items-center justify-between rounded-lg border border-gold/30 bg-gold/10 p-3.5 text-xs">
                          <div>
                            <span className="text-[10px] uppercase tracking-wider text-gold font-bold">Delivery Address</span>
                            <p className="font-bold text-foreground mt-0.5">{shippingName} (+91 {shippingPhone})</p>
                            <p className="text-[11px] text-muted-foreground">{shippingStreet}, {shippingCity}, {shippingState} - {shippingPincode}</p>
                          </div>
                          <button
                            type="button"
                            onClick={() => setCheckoutStep(1)}
                            className="text-[11px] font-bold text-gold uppercase tracking-wider hover:underline shrink-0 ml-3 cursor-pointer"
                          >
                            Edit Address
                          </button>
                        </div>

                        {/* Items Summary */}
                        {isCartCheckout ? (
                          <div className="space-y-3 max-h-60 overflow-y-auto rounded-lg border border-border bg-surface/50 p-4">
                            <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                              Cart Order Items ({cartItems.reduce((acc, i) => acc + (i.quantity || 1), 0)})
                            </p>
                            {cartItems.map((ci, idx) => (
                              <div key={idx} className="flex items-center justify-between gap-3 text-xs border-b border-border/50 pb-2 last:border-0 last:pb-0">
                                <div className="flex items-center gap-3 overflow-hidden">
                                  <img src={ci.product?.image || ""} alt={ci.product?.name || "Item"} className="size-12 rounded-md object-cover shrink-0 border border-border" />
                                  <div className="overflow-hidden">
                                    <p className="font-bold text-foreground truncate">{ci.product?.name || "Product"}</p>
                                    <p className="text-[11px] text-muted-foreground">Size: <span className="text-gold font-bold">{ci.size}</span> • Qty: {ci.quantity}</p>
                                  </div>
                                </div>
                                <span className="font-bold text-gold shrink-0">₹{((ci.product?.price || 0) * ci.quantity).toLocaleString("en-IN")}</span>
                              </div>
                            ))}
                          </div>
                        ) : selectedProduct ? (
                          <div className="flex items-center gap-4 rounded-lg border border-border bg-surface/50 p-4">
                            <img src={selectedProduct.image} alt={selectedProduct.name} className="size-18 rounded-md object-cover shrink-0 border border-border" />
                            <div>
                              <p className="font-display text-base font-semibold text-foreground">{selectedProduct.name}</p>
                              <p className="text-xs text-gold font-bold">₹{selectedProduct.price.toLocaleString("en-IN")}</p>
                              <p className="text-[10px] text-muted-foreground font-semibold">Color: {selectedProduct.color} • Size: {selectedSize} • Qty: {quantity}</p>
                            </div>
                          </div>
                        ) : null}

                        {/* DEMO PAYMENT OPTION SELECTOR */}
                        <div className="space-y-3">
                          <div className="flex items-center justify-between">
                            <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                              Select Payment Method
                            </label>
                          </div>

                          <div className="grid gap-2.5 sm:grid-cols-3">
                            {[
                              { id: "Demo UPI Instant (GPay / PhonePe / Paytm)", label: "Demo UPI Instant", desc: "Simulated GPay, PhonePe, Paytm or UPI" },
                              { id: "Demo Credit / Debit Card", label: "Demo Card Payment", desc: "Simulated Visa, MasterCard, RuPay" },
                              { id: "Demo Cash on Delivery (COD)", label: "Cash on Delivery", desc: "Pay cash upon physical delivery" },
                            ].map((pm) => (
                              <div
                                key={pm.id}
                                onClick={() => setPaymentMethod(pm.id)}
                                className={`cursor-pointer rounded-lg border p-3.5 transition-all ${
                                  paymentMethod === pm.id
                                    ? "border-gold bg-gold/10 shadow-sm"
                                    : "border-border bg-background hover:border-gold/50"
                                }`}
                              >
                                <div className="flex items-center gap-2.5">
                                  <input
                                    type="radio"
                                    name="demoPayment"
                                    checked={paymentMethod === pm.id}
                                    onChange={() => setPaymentMethod(pm.id)}
                                    className="accent-gold"
                                  />
                                  <div>
                                    <p className="text-xs font-bold text-foreground">{pm.label}</p>
                                    <p className="text-[10px] text-muted-foreground">{pm.desc}</p>
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>


                        {/* Price Total */}
                        <div className="rounded-lg border border-gold/40 bg-gold/10 p-4 space-y-2 text-xs">
                          <div className="flex justify-between text-muted-foreground">
                            <span>Subtotal:</span>
                            <span className="text-foreground font-semibold">₹{(isCartCheckout ? totalAmount : (selectedProduct ? selectedProduct.price * quantity : 0)).toLocaleString("en-IN")}</span>
                          </div>
                          <div className="flex justify-between text-muted-foreground">
                            <span>Express Shipping:</span>
                            <span className="text-gold font-bold">FREE</span>
                          </div>
                          <div className="flex justify-between border-t border-gold/30 pt-2 font-bold text-foreground text-base">
                            <span>Total Payable:</span>
                            <span className="text-gold">₹{(isCartCheckout ? totalAmount : (selectedProduct ? selectedProduct.price * quantity : 0)).toLocaleString("en-IN")}</span>
                          </div>
                        </div>

                        <div className="flex items-center gap-3 pt-2">
                          <button
                            type="button"
                            onClick={() => setCheckoutStep(1)}
                            className="btn-outline-gold rounded-sm px-6 py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer"
                          >
                            ← Edit Address
                          </button>
                          <button
                            type="submit"
                            disabled={orderSubmitting}
                            className="btn-gold hover:btn-gold-hover flex-1 rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider disabled:opacity-70 cursor-pointer flex items-center justify-center gap-2 shadow-sm"
                          >
                            {orderSubmitting ? (
                              <>
                                <RefreshCw className="size-4 animate-spin" /> Processing Demo Order...
                              </>
                            ) : (
                              <>
                                <CheckCircle2 className="size-4" /> Confirm & Place Demo Order — Total ₹{(isCartCheckout ? totalAmount : (selectedProduct ? selectedProduct.price * quantity : 0)).toLocaleString("en-IN")}
                              </>
                            )}
                          </button>
                        </div>
                      </form>
                    )}
                  </div>
                ) : (
                  /* DEFAULT CATALOG GRID WITH FILTERS & NEW DROPS */
                  <>
                    <div className="border-b border-border pb-4 space-y-3">
                      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                        <div>
                          <span className="text-[10px] uppercase tracking-widest text-gold font-bold flex items-center gap-1.5">
                            <Sparkles className="size-3.5" /> VEXA Premium Catalog
                          </span>
                          <h2 className="font-display text-2xl font-bold text-foreground">Book New Heavyweight Tee</h2>
                        </div>
                        
                        {/* Search Input */}
                        <div className="relative max-w-xs w-full">
                          <input
                            type="text"
                            placeholder="Search color or name..."
                            value={bookingSearchQuery}
                            onChange={(e) => setBookingSearchQuery(e.target.value)}
                            className="w-full rounded-lg border border-border bg-background px-3.5 py-1.5 text-xs text-foreground placeholder:text-muted-foreground focus:border-gold focus:outline-none"
                          />
                          {bookingSearchQuery && (
                            <button
                              type="button"
                              onClick={() => setBookingSearchQuery("")}
                              className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs text-muted-foreground hover:text-foreground"
                            >
                              ✕
                            </button>
                          )}
                        </div>
                      </div>

                      <p className="text-xs text-muted-foreground">Select any premium 240 GSM drop to configure custom size, delivery address & place a direct order booking.</p>

                      {/* Category Filter Pills */}
                      <div className="flex flex-wrap items-center gap-2 pt-1">
                        {["All", "Limited", "Oversized", "Classic"].map((cat) => (
                          <button
                            key={cat}
                            type="button"
                            onClick={() => setBookingCategoryFilter(cat)}
                            className={`rounded-full px-3.5 py-1 text-[11px] font-bold uppercase tracking-wider transition-all cursor-pointer ${
                              bookingCategoryFilter === cat
                                ? "bg-gold text-primary-foreground shadow-goldy"
                                : "bg-surface border border-border text-muted-foreground hover:border-gold hover:text-foreground"
                            }`}
                          >
                            {cat}
                          </button>
                        ))}
                        <span className="ml-auto text-[11px] text-muted-foreground font-semibold">
                          Showing <span className="text-gold font-bold">{bookingDisplayProducts.length}</span> Products
                        </span>
                      </div>
                    </div>

                    {bookingDisplayProducts.length === 0 ? (
                      <div className="rounded-xl border border-dashed border-border bg-card/40 p-12 text-center space-y-2">
                        <p className="text-sm font-semibold text-foreground">No products found matching "{bookingSearchQuery}"</p>
                        <button
                          type="button"
                          onClick={() => {
                            setBookingCategoryFilter("All");
                            setBookingSearchQuery("");
                          }}
                          className="text-xs text-gold font-bold hover:underline cursor-pointer"
                        >
                          Clear Filters & View All Products
                        </button>
                      </div>
                    ) : (
                      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                        {bookingDisplayProducts.map((p) => {
                          const discountPercent = p.oldPrice && p.oldPrice > p.price 
                            ? Math.round(((p.oldPrice - p.price) / p.oldPrice) * 100)
                            : 0;

                          return (
                            <div
                              key={p.id}
                              onClick={() => {
                                setSelectedProduct(p);
                                setIsCartCheckout(false);
                                setSelectedSize("M");
                                setQuantity(1);
                                setOrderSuccessMsg("");
                              }}
                              className="group cursor-pointer rounded-xl border border-border bg-background p-4 transition-all duration-300 hover:border-gold hover:shadow-goldy space-y-3 relative flex flex-col justify-between"
                            >
                              <div className="space-y-3">
                                <div className="relative overflow-hidden rounded-lg bg-surface/50">
                                  <img
                                    src={p.image}
                                    alt={p.name}
                                    className="h-52 w-full object-cover transition-transform duration-500 group-hover:scale-105"
                                  />
                                  <div className="absolute top-2 left-2 flex flex-col gap-1">
                                    <span className="rounded-full border border-gold/60 bg-[#f4efe6] px-3 py-1 text-[9px] font-extrabold uppercase tracking-wider text-[#1c1917] shadow-md">
                                      {p.category}
                                    </span>
                                  </div>

                                  {discountPercent > 0 && (
                                    <span className="absolute top-2 right-2 rounded-md bg-black/70 backdrop-blur-md border border-gold/40 text-gold px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-wider">
                                      {discountPercent}% OFF
                                    </span>
                                  )}
                                </div>

                                <div className="space-y-1.5">
                                  <div className="flex items-center justify-between">
                                    <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                                      240 GSM Heavyweight
                                    </span>
                                    <span className="text-[10px] text-gold font-bold">★ {p.rating.toFixed(1)}</span>
                                  </div>

                                  <h4 className="font-display text-sm font-bold text-foreground group-hover:text-gold transition-colors leading-tight">
                                    {p.name}
                                  </h4>
                                  <p className="text-[11px] text-muted-foreground font-medium">
                                    Color: <span className="text-foreground font-semibold">{p.color}</span>
                                  </p>
                                </div>
                              </div>

                              <div className="flex items-center justify-between pt-2 border-t border-border/40 mt-2">
                                <div>
                                  <div className="flex items-baseline gap-1.5">
                                    <span className="font-display text-base font-bold text-gold">₹{p.price.toLocaleString("en-IN")}</span>
                                    {p.oldPrice > p.price && (
                                      <span className="text-[11px] text-muted-foreground line-through">₹{p.oldPrice.toLocaleString("en-IN")}</span>
                                    )}
                                  </div>
                                  <p className="text-[9px] text-emerald-500 font-semibold">In Stock ({p.stock || 12} left)</p>
                                </div>

                                <span className="btn-gold rounded-sm px-3.5 py-1.5 text-[10px] uppercase font-bold tracking-wider group-hover:bg-gold-hover shadow-sm">
                                  Book Now →
                                </span>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </>
                )}
              </div>
            )}
          </main>

            {/* Dashboard Aligned Footer */}
            <div className="w-full mt-auto pt-8">
              <Footer />
            </div>
          </div>
        </div>
      </div>


      {/* USER CANCELLATION REASON MODAL POPUP */}
      {cancellingOrderUser && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 p-4 backdrop-blur-md animate-in fade-in duration-200">
          <div className="relative w-full max-w-lg overflow-hidden rounded-xl border border-destructive/50 bg-card p-6 shadow-2xl space-y-5 animate-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between border-b border-border pb-3">
              <div className="flex items-center gap-2.5">
                <div className="flex size-9 items-center justify-center rounded-lg bg-destructive/15 text-destructive font-bold text-lg">
                  ⚠️
                </div>
                <div>
                  <h3 className="font-display text-base font-bold text-foreground">Cancel Your Order</h3>
                  <p className="text-[11px] text-muted-foreground font-mono">Booking #{cancellingOrderUser.bookingIdStr}</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setCancellingOrderUser(null)}
                className="flex size-8 items-center justify-center rounded-full bg-surface text-muted-foreground hover:text-foreground cursor-pointer"
              >
                <X className="size-4" />
              </button>
            </div>

            <form onSubmit={handleConfirmUserCancellation} className="space-y-4">
              <div>
                <label className="text-[10px] uppercase tracking-wider text-gold font-bold block mb-2">
                  Select Reason for Order Cancellation
                </label>
                <div className="space-y-2">
                  {[
                    "Ordered by mistake / Change of mind",
                    "Delivery taking longer than expected",
                    "Found a better price / discount elsewhere",
                    "Wrong delivery address or size selected",
                    "Custom Reason",
                  ].map((reason) => (
                    <label
                      key={reason}
                      className={`flex items-center gap-3 rounded-lg border p-3 text-xs font-semibold cursor-pointer transition-all ${
                        userCancelReasonPreset === reason
                          ? "border-destructive bg-destructive/10 text-destructive font-bold"
                          : "border-border bg-surface/50 text-foreground hover:border-gold/40"
                      }`}
                    >
                      <input
                        type="radio"
                        name="userCancelReasonOption"
                        checked={userCancelReasonPreset === reason}
                        onChange={() => setUserCancelReasonPreset(reason)}
                        className="accent-destructive cursor-pointer"
                      />
                      <span>{reason}</span>
                    </label>
                  ))}
                </div>
              </div>

              {userCancelReasonPreset === "Custom Reason" && (
                <div>
                  <label className="text-[10px] uppercase tracking-wider text-gold font-bold block mb-1">
                    Enter Custom Reason
                  </label>
                  <textarea
                    required
                    value={userCustomCancelReason}
                    onChange={(e) => setUserCustomCancelReason(e.target.value)}
                    placeholder="Tell us why you are cancelling this booking..."
                    className="w-full rounded-sm border border-border bg-background p-3 text-xs text-foreground outline-none focus:border-destructive min-h-[80px]"
                  />
                </div>
              )}

              <div className="flex items-center gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setCancellingOrderUser(null)}
                  className="flex-1 rounded-sm border border-border py-2.5 text-xs font-bold text-muted-foreground hover:bg-surface cursor-pointer"
                >
                  Nevermind / Keep Active
                </button>
                <button
                  type="submit"
                  className="flex-1 rounded-sm bg-destructive text-destructive-foreground hover:bg-destructive/90 py-2.5 text-xs font-bold uppercase tracking-wider cursor-pointer shadow-md"
                >
                  Confirm & Cancel Order
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {/* Sleek Interactive Demo Payment Gateway Modal (Accepts Any Input e.g. 1234 5678 9123 1222) */}
      {showDemoPaymentModal && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 p-4 backdrop-blur-md animate-in fade-in duration-200">
          <div className="relative w-full max-w-md overflow-hidden rounded-2xl border border-gold/40 bg-card p-6 shadow-2xl space-y-5 animate-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between border-b border-border pb-3">
              <div className="flex items-center gap-2.5">
                <div className="flex size-9 items-center justify-center rounded-xl bg-gold/20 text-gold font-bold text-base border border-gold/30">
                  V
                </div>
                <div>
                  <h3 className="font-display text-base font-bold text-foreground">VEXA Payment Gateway</h3>
                  <p className="text-[10px] text-emerald-500 font-semibold tracking-wider">⚡ Demo Test Mode • Accepts Any Card Number</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowDemoPaymentModal(false)}
                className="flex size-8 items-center justify-center rounded-full bg-surface text-muted-foreground hover:text-foreground cursor-pointer"
              >
                <X className="size-4" />
              </button>
            </div>

            <div className="rounded-xl border border-gold/40 bg-gold/10 p-3.5 flex justify-between items-center text-xs">
              <span className="text-muted-foreground font-semibold">Total Order Payable:</span>
              <span className="text-gold font-bold text-base">₹{(isCartCheckout ? finalOrderTotal : (selectedProduct ? selectedProduct.price * quantity : 0)).toLocaleString("en-IN")}</span>
            </div>

            {demoPaymentSuccess ? (
              <div className="py-8 flex flex-col items-center justify-center space-y-3 text-center animate-in zoom-in-95">
                <div className="size-16 rounded-full bg-emerald-500/20 text-emerald-500 flex items-center justify-center border border-emerald-500/40">
                  <CheckCircle2 className="size-10 stroke-[2.5]" />
                </div>
                <h4 className="text-xl font-bold text-emerald-500">Payment Successful!</h4>
                <p className="text-xs text-muted-foreground">Transaction ID: <span className="font-mono text-gold font-bold">{demoTxnId}</span></p>
                <p className="text-[11px] text-muted-foreground animate-pulse">Finalizing order & redirecting...</p>
              </div>
            ) : (
              <form onSubmit={handleExecuteDemoPaymentSubmission} className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-[11px] font-bold text-gold uppercase tracking-wider block">
                    Card Number (Accepts Any Number)
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Enter ANY Card Number (e.g. 1234 5678 9123 1222)"
                    value={demoCardInput}
                    onChange={(e) => setDemoCardInput(e.target.value)}
                    className="w-full rounded-lg border border-border bg-background px-3.5 py-2.5 text-xs text-foreground font-mono focus:border-gold focus:outline-none"
                  />
                  <p className="text-[10px] text-emerald-500 font-medium">✓ Guaranteed test mode approval for any card format (e.g. 1234 5678 9123 1222)</p>
                </div>

                <div className="space-y-1.5">
                  <label className="text-[11px] font-bold text-gold uppercase tracking-wider block">
                    Cardholder Name
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Name on card"
                    value={demoHolderName}
                    onChange={(e) => setDemoHolderName(e.target.value)}
                    className="w-full rounded-lg border border-border bg-background px-3.5 py-2.5 text-xs text-foreground focus:border-gold focus:outline-none"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="text-[10px] text-muted-foreground uppercase font-bold block">Expiry Date</label>
                    <input
                      type="text"
                      required
                      placeholder="02/29"
                      value={demoExpiryInput}
                      onChange={(e) => setDemoExpiryInput(e.target.value)}
                      className="w-full rounded-lg border border-border bg-background px-3.5 py-2 text-xs text-foreground font-mono focus:border-gold focus:outline-none"
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="text-[10px] text-muted-foreground uppercase font-bold block">CVV / PIN</label>
                    <input
                      type="password"
                      required
                      maxLength={4}
                      placeholder="123"
                      value={demoCvvInput}
                      onChange={(e) => setDemoCvvInput(e.target.value)}
                      className="w-full rounded-lg border border-border bg-background px-3.5 py-2 text-xs text-foreground font-mono focus:border-gold focus:outline-none"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={demoProcessing}
                  className="w-full rounded-xl bg-gold py-3 text-xs font-bold text-black uppercase tracking-widest hover:bg-gold/90 transition-all flex items-center justify-center gap-2 cursor-pointer shadow-lg mt-2"
                >
                  {demoProcessing ? (
                    <>
                      <RefreshCw className="size-4 animate-spin" /> Processing Payment...
                    </>
                  ) : (
                    <>
                      <Lock className="size-4" /> Complete Payment (₹{(isCartCheckout ? finalOrderTotal : (selectedProduct ? selectedProduct.price * quantity : 0)).toLocaleString("en-IN")})
                    </>
                  )}
                </button>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
