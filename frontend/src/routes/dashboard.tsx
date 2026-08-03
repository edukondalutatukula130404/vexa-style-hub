import { useNavigate, Link, useSearchParams } from "react-router-dom";
import { useState, useEffect } from "react";
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
  ArrowLeft
} from "lucide-react";
import { products, SIZES, type Product } from "@/lib/products";
import { Reveal } from "@/components/Reveal";
import { useAuth, API_URL } from "@/lib/auth";
import { useCart, removeFromCart, updateCartQuantity, clearCart } from "@/lib/cart";

type OrderItem = {
  _id: string;
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

type TabType = "profile" | "orders" | "addresses" | "cart" | "support" | "booking";

export function UserDashboard() {
  const navigate = useNavigate();
  const { user, isLoggedIn, logout } = useAuth();
  const { cartItems, totalAmount } = useCart();
  
  const [activeTab, setActiveTab] = useState<TabType>(() => {
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const tabParam = params.get("tab");
      if (tabParam && ["profile", "orders", "addresses", "cart", "support", "booking"].includes(tabParam)) {
        return tabParam as TabType;
      }
    }
    return "orders";
  });

  useEffect(() => {
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const tabParam = params.get("tab");
      if (tabParam && ["profile", "orders", "addresses", "cart", "support"].includes(tabParam)) {
        setActiveTab(tabParam as TabType);
      }
    }
  }, []);

  useEffect(() => {
    if (!isLoggedIn) {
      navigate("/login");
    }
  }, [isLoggedIn, navigate]);

  // Orders State
  const [myOrders, setMyOrders] = useState<OrderItem[]>([]);
  const [loadingOrders, setLoadingOrders] = useState(false);

  // Profile Form State
  const [profileName, setProfileName] = useState(user?.name || "Aarav Sharma");
  const [profileEmail, setProfileEmail] = useState(user?.email || "aarav@example.com");
  const [profileMobile, setProfileMobile] = useState("9876543210");
  const [profileSavedMsg, setProfileSavedMsg] = useState("");

  // Address Form State
  const [savedAddresses, setSavedAddresses] = useState([
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
  ]);
  const [showAddAddress, setShowAddAddress] = useState(false);
  const [newStreet, setNewStreet] = useState("");
  const [newCity, setNewCity] = useState("");
  const [newState, setNewState] = useState("");
  const [newPincode, setNewPincode] = useState("");

  // Order Placement State & Checkout Flow
  const [cartCheckoutStep, setCartCheckoutStep] = useState<"cart" | "address" | "payment">("cart");
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
  const [paymentMethod, setPaymentMethod] = useState<string>("Demo Cash on Delivery (COD)");
  const [shippingAddress, setShippingAddress] = useState<string>(
    "EDUKONDALU (+91 9876543210), 100 Feet Road, Indiranagar, Stage 2, Bengaluru, Karnataka - 560038"
  );
  const [orderSubmitting, setOrderSubmitting] = useState(false);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  // Sync user auth details when available
  useEffect(() => {
    if (user) {
      setProfileName(user.name);
      setProfileEmail(user.email);
      if (user.name) setShippingName(user.name);
    }
  }, [user]);

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

      setMyOrders((prev) => {
        const map = new Map();
        // First set cached demo orders
        cachedDemoOrders.forEach((item) => {
          if (item && (item._id || (item as any).id)) {
            map.set(item._id || (item as any).id, item);
          }
        });
        // Set prev state items
        prev.forEach((item) => {
          if (item && (item._id || (item as any).id)) {
            map.set(item._id || (item as any).id, item);
          }
        });
        // Fresh backend items OVERWRITE old cached items
        fetchedList.forEach((item) => {
          if (item && (item._id || (item as any).id)) {
            map.set(item._id || (item as any).id, item);
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

  useEffect(() => {
    fetchMyOrders();
  }, [user?.email, activeTab]);

  const handleUpdateProfile = (e: React.FormEvent) => {
    e.preventDefault();
    setProfileSavedMsg("Profile updated successfully!");
    setTimeout(() => setProfileSavedMsg(""), 3000);
  };

  const handleAddAddress = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newStreet || !newCity || !newPincode) return;

    const newAddr = {
      id: String(Date.now()),
      name: "Secondary Location",
      address: newStreet,
      city: newCity,
      state: newState || "Karnataka",
      pincode: newPincode,
      mobile: profileMobile,
      isDefault: false,
    };

    setSavedAddresses([...savedAddresses, newAddr]);
    setShowAddAddress(false);
    setNewStreet("");
    setNewCity("");
    setNewState("");
    setNewPincode("");
  };

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

      const calculatedTotal = isCart
        ? totalAmount
        : selectedProduct
        ? selectedProduct.price * quantity
        : 0;

      const fullAddr = shippingAddress || `${shippingName} (+91 ${shippingPhone}), ${shippingStreet}, ${shippingCity}, ${shippingState} - ${shippingPincode}`;

      const demoOrderObj: OrderItem = {
        _id: "ORD-" + Math.floor(100000 + Math.random() * 900000),
        userEmail: email,
        userName: name,
        items: itemsToOrder,
        totalAmount: calculatedTotal,
        status: "Processing",
        paymentMethod: paymentMethod || "Demo Cash on Delivery (COD)",
        shippingAddress: fullAddr,
        createdAt: new Date().toISOString(),
      };

      // 1. Instantly append to order state & localStorage cache
      setMyOrders((prev) => [demoOrderObj, ...prev]);

      if (typeof window !== "undefined") {
        try {
          const cached = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
          localStorage.setItem("vexa_demo_orders", JSON.stringify([demoOrderObj, ...cached]));
        } catch (e) {
          console.warn("Failed to cache demo order:", e);
        }
      }

      // 2. Clear Cart
      if (isCart || cartItems.length > 0) {
        clearCart();
      }

      // 3. Reset Checkout Flow State
      setSelectedProduct(null);
      setIsCartCheckout(false);
      setCartCheckoutStep("cart");
      setCheckoutStep(1);

      // 4. Update URL to ?tab=orders & switch tab directly to MY ORDERS
      if (typeof window !== "undefined") {
        window.history.pushState({}, "", "/dashboard?tab=orders");
      }
      setActiveTab("orders");

      // 5. Post to backend asynchronously in background (non-blocking)
      fetch(`${API_URL}/orders`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userEmail: email,
          userName: name,
          items: itemsToOrder,
          totalAmount: calculatedTotal,
          paymentMethod: demoOrderObj.paymentMethod,
          shippingAddress: fullAddr,
        }),
      }).catch((err) => console.warn("Background order POST notice:", err));

    } catch (err) {
      console.error("Order placement handler error:", err);
    } finally {
      setOrderSubmitting(false);
    }
  };

  const navItems = [
    { id: "profile", label: "My Profile", icon: UserIcon },
    { id: "orders", label: "My Orders", icon: Package },
    { id: "cart", label: "My Cart", icon: ShoppingBag },
    { id: "booking", label: "Book New Tee", icon: Sparkles },
    { id: "addresses", label: "Addresses", icon: MapPin },
    { id: "support", label: "Support", icon: HelpCircle },
    { id: "logout", label: "Logout", icon: LogOut },
  ] as const;

  const currentNavItem = navItems.find((n) => n.id === activeTab) || navItems[0];
  const CurrentIcon = currentNavItem.icon;

  return (
    <div className="min-h-screen bg-background">
      <div className="mx-auto max-w-7xl px-4 py-6">
        {/* PAGE HEADER BANNER */}
        <div className="mb-6 border-b border-border/60 pb-5">
          <h1 className="font-display text-3xl font-bold tracking-tight text-foreground">MY ACCOUNT</h1>
        </div>

        <div className="grid gap-6 lg:gap-8 lg:grid-cols-[280px_1fr]">
          {/* MOBILE RESPONSIVE TAB STRIP (< lg) */}
          <div className="lg:hidden space-y-3">
            {/* Interactive Profile Card - Clicking opens Dashboard Sections slide-down */}
            <button
              type="button"
              onClick={() => setMobileNavOpen((o) => !o)}
              className="flex w-full items-center justify-between rounded-xl border border-gold/40 bg-card p-4 shadow-sm transition-all hover:border-gold cursor-pointer"
            >
              <div className="flex items-center gap-3 overflow-hidden">
                <div className="flex size-10 items-center justify-center rounded-full border border-gold/50 bg-gold/15 font-display text-base font-bold text-gold shrink-0 shadow-sm">
                  {(profileName || user?.name || "U")[0].toUpperCase()}
                </div>
                <div className="overflow-hidden text-left">
                  <h3 className="font-display text-base font-bold text-foreground truncate">{profileName}</h3>
                  <p className="text-[11px] text-muted-foreground truncate">{profileEmail}</p>
                </div>
              </div>
              <ChevronDown className={`size-5 text-gold shrink-0 transition-transform duration-300 ${mobileNavOpen ? "rotate-180" : ""}`} />
            </button>

            {/* Dashboard Sections Slide-Down Menu */}
            <div className="relative">

              {mobileNavOpen && (
                <div className="rounded-xl border border-gold/50 bg-card p-2 shadow-2xl backdrop-blur-xl animate-in slide-in-from-top-2 duration-300 space-y-1 mb-4 z-40">
                  {navItems.map((item) => {
                    const Icon = item.icon;
                    const isActive = activeTab === item.id;
                    const isLogout = item.id === "logout";
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

          {/* DESKTOP SIDEBAR (>= lg) */}
          <aside className="hidden lg:block h-fit rounded-xl border border-border bg-card p-6 shadow-sm">
            <div className="flex items-center gap-3 border-b border-border pb-6">
              <div className="flex size-11 items-center justify-center rounded-full border border-gold/50 bg-gold/15 font-display text-lg font-bold text-gold shrink-0 shadow-sm">
                {(profileName || user?.name || "U")[0].toUpperCase()}
              </div>
              <div className="overflow-hidden">
                <h3 className="font-display text-base font-bold text-foreground truncate">{profileName}</h3>
                <p className="text-xs text-muted-foreground truncate">{profileEmail}</p>
              </div>
            </div>

            <nav className="mt-6 space-y-1">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = activeTab === item.id;
                const isLogout = item.id === "logout";
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      if (isLogout) {
                        logout();
                      } else {
                        setActiveTab(item.id as TabType);
                      }
                    }}
                    className={`flex w-full items-center gap-3 rounded-lg px-4 py-3 text-xs font-semibold uppercase tracking-wider transition-all ${
                      isLogout
                        ? "text-destructive hover:bg-destructive/20 font-bold mt-4 border border-destructive/40 bg-destructive/10 justify-center shadow-sm"
                        : isActive
                        ? "bg-gold text-primary-foreground shadow-goldy font-bold"
                        : "text-muted-foreground hover:bg-surface hover:text-foreground"
                    }`}
                  >
                    <Icon className="size-4" /> {item.label}
                  </button>
                );
              })}
            </nav>
          </aside>

          {/* MAIN TAB CONTENT AREA */}
          <main className="min-h-[520px] rounded-xl border border-border bg-card p-4 sm:p-8 shadow-sm">
            {/* 1. MY PROFILE TAB */}
            {activeTab === "profile" && (
              <div className="space-y-6 max-w-2xl">
                <div className="border-b border-border pb-4">
                  <h2 className="font-display text-2xl font-bold text-foreground">My Profile</h2>
                  <p className="text-xs text-muted-foreground mt-1">Manage your personal profile and account credentials.</p>
                </div>

                {profileSavedMsg && (
                  <div className="flex items-center gap-2.5 rounded-lg border border-gold/40 bg-gold/10 p-3.5 text-xs text-gold font-semibold">
                    <CheckCircle2 className="size-4 shrink-0" />
                    <span>{profileSavedMsg}</span>
                  </div>
                )}

                <form onSubmit={handleUpdateProfile} className="space-y-5">
                  <div className="grid gap-5 sm:grid-cols-2">
                    <div>
                      <label className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">Full Name</label>
                      <input
                        type="text"
                        value={profileName}
                        onChange={(e) => setProfileName(e.target.value)}
                        className="mt-2 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs text-foreground outline-none focus:border-gold"
                      />
                    </div>

                    <div>
                      <label className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">Email Address</label>
                      <input
                        disabled
                        type="email"
                        value={profileEmail}
                        className="mt-2 w-full rounded-sm border border-border bg-surface px-4 py-3 text-xs text-muted-foreground outline-none cursor-not-allowed"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-muted-foreground font-semibold">Mobile Number</label>
                    <input
                      type="text"
                      value={profileMobile}
                      onChange={(e) => setProfileMobile(e.target.value)}
                      placeholder="9876543210"
                      className="mt-2 w-full max-w-md rounded-sm border border-border bg-background px-4 py-3 text-xs text-foreground outline-none focus:border-gold font-mono"
                    />
                  </div>

                  <button
                    type="submit"
                    className="mt-4 bg-foreground text-background hover:bg-gold hover:text-primary-foreground inline-flex items-center gap-2 rounded-sm px-8 py-3.5 text-xs font-bold uppercase tracking-wider transition-colors shadow-sm"
                  >
                    <Save className="size-4" /> UPDATE PROFILE
                  </button>
                </form>
              </div>
            )}

            {/* 2. MY ORDERS TAB */}
            {activeTab === "orders" && (
              <div className="space-y-6">
                <div className="flex items-center justify-between border-b border-border pb-4 gap-4">
                  <div>
                    <h2 className="font-display text-2xl font-bold text-foreground">My Orders</h2>
                    <p className="text-xs text-muted-foreground mt-1">Track your placed orders and shipment progress.</p>
                  </div>
                  <div className="flex items-center gap-3">
                    {refreshMsg && (
                      <span className="text-xs text-gold font-semibold animate-in fade-in duration-300">
                        {refreshMsg}
                      </span>
                    )}
                    <button
                      type="button"
                      onClick={() => fetchMyOrders(true)}
                      disabled={loadingOrders}
                      className="flex items-center gap-1.5 rounded-lg border border-gold/50 bg-gold/10 px-4 py-2 text-xs text-gold hover:bg-gold hover:text-primary-foreground font-bold transition-all disabled:opacity-50 cursor-pointer shadow-sm"
                    >
                      <RefreshCw className={`size-3.5 ${loadingOrders ? "animate-spin" : ""}`} />
                      {loadingOrders ? "Refreshing..." : "Refresh"}
                    </button>
                  </div>
                </div>

                {myOrders.length > 0 ? (
                  <div className="space-y-4">
                    {myOrders.map((ord, idx) => (
                      <div key={ord._id || ord.id || idx} className="rounded-xl border border-border bg-background p-6 shadow-sm">
                        <div className="flex flex-wrap items-center justify-between border-b border-border pb-4 gap-2">
                          <div>
                            <span className="text-[10px] uppercase tracking-widest text-gold font-semibold">Order ID</span>
                            <h4 className="font-display text-base font-bold text-foreground">
                              #{String(ord._id || ord.id || "ORD-NEW").slice(-8).toUpperCase()}
                            </h4>
                            <p className="text-[10px] text-muted-foreground mt-0.5">
                              Date: {new Date(ord.createdAt).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                            </p>
                          </div>

                          <div className="flex items-center gap-3">
                            <span
                              className={`rounded-full border px-3 py-1 text-[10px] uppercase tracking-wider font-bold ${
                                ord.status === "Delivered"
                                  ? "border-emerald-500/50 bg-emerald-500/10 text-emerald-600"
                                  : ord.status === "Shipped"
                                  ? "border-blue-500/50 bg-blue-500/10 text-blue-600"
                                  : "border-gold/60 bg-gold/10 text-gold"
                              }`}
                            >
                              {ord.status}
                            </span>
                            <span className="font-display text-lg font-bold text-foreground">
                              ₹{ord.totalAmount.toLocaleString("en-IN")}
                            </span>
                          </div>
                        </div>

                        <div className="mt-4 space-y-3">
                          {ord.items.map((item, idx) => (
                            <div key={idx} className="flex items-center gap-4">
                              <img
                                src={item.image}
                                alt={item.name}
                                className="size-14 rounded-lg object-cover border border-border"
                              />
                              <div className="flex-1">
                                <h5 className="font-display text-sm font-semibold text-foreground">{item.name}</h5>
                                <p className="text-xs text-muted-foreground">
                                  Size: <span className="text-gold font-bold">{item.size}</span> • Color: {item.color} • Qty: {item.quantity}
                                </p>
                              </div>
                              <span className="text-xs font-semibold text-foreground">
                                ₹{(item.price * item.quantity).toLocaleString("en-IN")}
                              </span>
                            </div>
                          ))}
                        </div>

                        <div className="mt-5 border-t border-border pt-3 flex items-center justify-between text-xs text-muted-foreground">
                          <p><span className="text-gold">Address:</span> {ord.shippingAddress}</p>
                          <p><span className="text-gold">Payment:</span> {ord.paymentMethod}</p>
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
              <div className="space-y-6 max-w-3xl">
                <div className="flex items-center justify-between border-b border-border pb-4">
                  <div>
                    <h2 className="font-display text-2xl font-bold text-foreground">Addresses</h2>
                    <p className="text-xs text-muted-foreground mt-1">Manage saved shipping locations for fast checkout.</p>
                  </div>
                  <button
                    onClick={() => setShowAddAddress(!showAddAddress)}
                    className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2 rounded-sm px-4 py-2 text-xs font-bold"
                  >
                    <Plus className="size-4" /> Add New Address
                  </button>
                </div>

                {showAddAddress && (
                  <form onSubmit={handleAddAddress} className="rounded-xl border border-gold/40 bg-surface/50 p-6 space-y-4">
                    <h3 className="font-display text-base font-semibold text-foreground">New Delivery Location</h3>
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
                    <div className="grid gap-4 sm:grid-cols-3">
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
                    <button type="submit" className="btn-gold hover:btn-gold-hover rounded-sm px-6 py-2.5 text-xs font-bold">
                      Save Location
                    </button>
                  </form>
                )}

                <div className="grid gap-4 md:grid-cols-2">
                  {savedAddresses.map((addr) => (
                    <div key={addr.id} className="rounded-xl border border-border bg-background p-6 space-y-2 relative">
                      {addr.isDefault && (
                        <span className="absolute top-4 right-4 rounded-full bg-gold/10 border border-gold/40 px-3 py-0.5 text-[9px] font-bold text-gold uppercase tracking-wider">
                          Default
                        </span>
                      )}
                      <h4 className="font-display text-sm font-semibold text-foreground">{addr.name}</h4>
                      <p className="text-xs text-muted-foreground">{addr.address}</p>
                      <p className="text-xs text-muted-foreground">{addr.city}, {addr.state} — {addr.pincode}</p>
                      <p className="text-xs text-gold font-mono font-semibold pt-2">Phone: +91 {addr.mobile}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* 4. MY CART TAB (3-Step Page-Level Checkout Flow: Cart -> Address Details -> Payment Option) */}
            {activeTab === "cart" && (
              <div className="space-y-6">
                {cartCheckoutStep === "cart" && (
                  <>
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-border pb-4 gap-3">
                      <div className="flex items-center gap-3">
                        <Link
                          to="/products"
                          className="flex items-center gap-1.5 rounded-md border border-gold/40 bg-gold/10 px-3 py-1.5 text-xs font-bold uppercase tracking-wider text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer shadow-sm"
                        >
                          <ArrowLeft className="size-3.5" /> Back to Products
                        </Link>
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
                                  <p className="text-xs text-gold font-bold mt-1">
                                    ₹{ci.product.price.toLocaleString("en-IN")}
                                  </p>
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

                        {/* Cart Summary */}
                        <div className="h-fit rounded-xl border border-gold/40 bg-card p-6 space-y-4 shadow-sm">
                          <h3 className="font-display text-lg font-bold text-foreground border-b border-border pb-3">
                            Order Summary
                          </h3>

                          <div className="space-y-2 text-xs text-muted-foreground">
                            <div className="flex justify-between">
                              <span>Items ({cartItems.reduce((acc, i) => acc + i.quantity, 0)})</span>
                              <span className="text-foreground font-semibold">₹{totalAmount.toLocaleString("en-IN")}</span>
                            </div>
                            <div className="flex justify-between">
                              <span>Pan-India Delivery</span>
                              <span className="text-gold font-bold">FREE</span>
                            </div>
                          </div>

                          <div className="flex justify-between border-t border-border pt-3 font-display text-lg font-bold text-foreground">
                            <span>Total Price</span>
                            <span className="text-gold">₹{totalAmount.toLocaleString("en-IN")}</span>
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

                {/* PAGE STEP 1: ADDRESS DETAILS */}
                {cartCheckoutStep === "address" && (
                  <div className="space-y-6 max-w-2xl animate-in fade-in duration-300">
                    <div className="flex items-center justify-between border-b border-border pb-4">
                      <div>
                        <span className="text-[10px] uppercase tracking-widest text-gold font-bold">Checkout Step 1 of 2</span>
                        <h2 className="font-display text-2xl font-bold text-foreground">Delivery Address Details</h2>
                      </div>
                      <button
                        type="button"
                        onClick={() => setCartCheckoutStep("cart")}
                        className="text-xs font-semibold uppercase tracking-wider text-gold hover:underline cursor-pointer"
                      >
                        ← Back to Cart
                      </button>
                    </div>

                    <form
                      onSubmit={(e) => {
                        e.preventDefault();
                        const fullAddr = `${shippingName} (+91 ${shippingPhone}), ${shippingStreet}, ${shippingCity}, ${shippingState} - ${shippingPincode}`;
                        setShippingAddress(fullAddr);
                        setCartCheckoutStep("payment");
                      }}
                      className="rounded-xl border border-gold/40 bg-card p-6 shadow-sm space-y-5"
                    >
                      <div className="border-b border-border pb-3">
                        <h3 className="font-display text-base font-bold text-foreground">Enter Recipient & Shipping Address</h3>
                        <p className="text-xs text-muted-foreground">Please enter your complete address details before proceeding to payment.</p>
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

                      <div className="flex items-center gap-3 pt-2">
                        <button
                          type="button"
                          onClick={() => setCartCheckoutStep("cart")}
                          className="btn-outline-gold rounded-sm px-6 py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer"
                        >
                          ← Back to Cart
                        </button>
                        <button
                          type="submit"
                          className="btn-gold hover:btn-gold-hover flex-1 rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer flex items-center justify-center gap-2 shadow-sm"
                        >
                          Proceed to Payment <ArrowRight className="size-4" />
                        </button>
                      </div>
                    </form>
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
                            Select Demo Payment Method
                          </label>
                          <span className="rounded-full bg-gold/15 border border-gold/40 px-2.5 py-0.5 text-[9px] font-bold text-gold uppercase tracking-wider">
                            🧪 Demo Mode
                          </span>
                        </div>

                        <div className="grid gap-2.5 sm:grid-cols-2">
                          {[
                            { id: "Demo Cash on Delivery (COD)", label: "Demo Cash on Delivery", desc: "Pay cash upon simulated delivery" },
                            { id: "Demo UPI (GPay / PhonePe / Paytm)", label: "Demo UPI Instant", desc: "Simulated GPay, PhonePe or Paytm" },
                            { id: "Demo Credit / Debit Card", label: "Demo Card Payment", desc: "Simulated Visa, MasterCard, RuPay" },
                            { id: "Demo NetBanking", label: "Demo NetBanking", desc: "Simulated instant bank transfer" },
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
                        <div className="flex justify-between text-muted-foreground">
                          <span>Express Pan-India Shipping:</span>
                          <span className="text-gold font-bold">FREE</span>
                        </div>
                        <div className="flex justify-between border-t border-gold/30 pt-2 font-bold text-foreground text-base">
                          <span>Total Payable:</span>
                          <span className="text-gold">₹{totalAmount.toLocaleString("en-IN")}</span>
                        </div>
                      </div>

                      <div className="flex items-center gap-3 pt-2">
                        <button
                          type="button"
                          onClick={() => setCartCheckoutStep("address")}
                          className="btn-outline-gold rounded-sm px-6 py-3.5 text-xs font-bold uppercase tracking-wider cursor-pointer"
                        >
                          ← Back to Address
                        </button>
                        <button
                          type="submit"
                          onClick={handlePlaceOrder}
                          disabled={orderSubmitting}
                          className="btn-gold hover:btn-gold-hover flex-1 rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider disabled:opacity-70 cursor-pointer flex items-center justify-center gap-2 shadow-sm"
                        >
                          {orderSubmitting ? (
                            <>
                              <RefreshCw className="size-4 animate-spin" /> Processing Order...
                            </>
                          ) : (
                            <>
                              <CheckCircle2 className="size-4" /> Proceed to Place Order — Total ₹{totalAmount.toLocaleString("en-IN")}
                            </>
                          )}
                        </button>
                      </div>
                    </form>
                  </div>
                )}
              </div>
            )}

            {/* 5. SUPPORT TAB */}
            {activeTab === "support" && (
              <div className="space-y-6 max-w-2xl">
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
              <div className="space-y-6">
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
                              Select Demo Payment Method
                            </label>
                            <span className="rounded-full bg-gold/15 border border-gold/40 px-2.5 py-0.5 text-[9px] font-bold text-gold uppercase tracking-wider">
                              🧪 Demo Payment Mode
                            </span>
                          </div>

                          <div className="grid gap-2.5 sm:grid-cols-2">
                            {[
                              { id: "Demo Cash on Delivery (COD)", label: "Demo Cash on Delivery", desc: "Pay cash upon simulated delivery" },
                              { id: "Demo UPI (GPay / PhonePe / Paytm)", label: "Demo UPI Instant", desc: "Simulated GPay, PhonePe or Paytm" },
                              { id: "Demo Credit / Debit Card", label: "Demo Card Payment", desc: "Simulated Visa, MasterCard, RuPay" },
                              { id: "Demo NetBanking", label: "Demo NetBanking", desc: "Simulated instant bank transfer" },
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
                  /* DEFAULT CATALOG GRID */
                  <>
                    <div className="border-b border-border pb-4">
                      <span className="text-[10px] uppercase tracking-widest text-gold font-bold">VEXA Collection</span>
                      <h2 className="font-display text-2xl font-bold text-foreground">Book New Heavyweight Tee</h2>
                      <p className="text-xs text-muted-foreground mt-1">Select any premium 240 GSM tee to configure size, address & place a direct booking.</p>
                    </div>

                    <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                      {products.map((p) => (
                        <div
                          key={p.id}
                          onClick={() => {
                            setSelectedProduct(p);
                            setIsCartCheckout(false);
                            setSelectedSize("M");
                            setQuantity(1);
                            setOrderSuccessMsg("");
                          }}
                          className="group cursor-pointer rounded-xl border border-border bg-background p-4 transition-all duration-300 hover:border-gold hover:shadow-goldy space-y-3"
                        >
                          <div className="relative overflow-hidden rounded-lg">
                            <img
                              src={p.image}
                              alt={p.name}
                              className="h-48 w-full object-cover transition-transform duration-500 group-hover:scale-105"
                            />
                            <span className="absolute top-2 left-2 rounded-full bg-gold/90 text-primary-foreground px-2.5 py-0.5 text-[9px] font-bold uppercase tracking-wider">
                              {p.category}
                            </span>
                          </div>

                          <div className="space-y-1">
                            <h4 className="font-display text-sm font-semibold text-foreground group-hover:text-gold transition-colors">
                              {p.name}
                            </h4>
                            <p className="text-[11px] text-muted-foreground font-semibold">Color: {p.color}</p>
                            <div className="flex items-center justify-between pt-1">
                              <span className="font-display text-base font-bold text-gold">₹{p.price.toLocaleString("en-IN")}</span>
                              <span className="btn-gold rounded px-3 py-1 text-[10px] uppercase font-bold tracking-wider">
                                Book Now
                              </span>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </>
                )}
              </div>
            )}
          </main>
        </div>
      </div>


    </div>
  );
}
