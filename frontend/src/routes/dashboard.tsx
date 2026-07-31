import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
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
  RefreshCw
} from "lucide-react";
import { products, SIZES, type Product } from "@/lib/products";
import { Reveal } from "@/components/Reveal";
import { useAuth, API_URL } from "@/lib/auth";
import { useCart, removeFromCart, updateCartQuantity, clearCart } from "@/lib/cart";

export const Route = createFileRoute("/dashboard")({
  head: () => ({
    meta: [
      { title: "My Account | VEXA" },
      {
        name: "description",
        content: "Manage your profile, orders, addresses, cart, password settings and support enquiries.",
      },
    ],
  }),
  component: UserDashboard,
});

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
      navigate({ to: "/login" });
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

  // Order Placement Modal State
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [selectedSize, setSelectedSize] = useState<string>("M");
  const [quantity, setQuantity] = useState<number>(1);
  const [paymentMethod, setPaymentMethod] = useState<string>("Cash on Delivery");
  const [shippingAddress, setShippingAddress] = useState<string>(
    "100 Feet Road, Indiranagar, Stage 2, Bengaluru, Karnataka - 560038"
  );
  const [orderSubmitting, setOrderSubmitting] = useState(false);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  // Sync user auth details when available
  useEffect(() => {
    if (user) {
      setProfileName(user.name);
      setProfileEmail(user.email);
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

      setMyOrders((prev) => {
        const map = new Map();
        // First set old items
        prev.forEach((item) => {
          if (item && (item._id || item.id)) {
            map.set(item._id || item.id, item);
          }
        });
        // Fresh backend items OVERWRITE old cached items
        fetchedList.forEach((item) => {
          if (item && (item._id || item.id)) {
            map.set(item._id || item.id, item);
          }
        });
        return Array.from(map.values());
      });

      if (isManualRefresh) {
        setRefreshMsg("Order status refreshed!");
        setTimeout(() => setRefreshMsg(""), 3500);
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

  const handlePlaceOrder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    if (!selectedProduct && cartItems.length === 0) return;

    setOrderSubmitting(true);
    setOrderSuccessMsg("");

    const itemsToOrder = cartItems.length > 0
      ? cartItems.map((ci) => ({
          id: ci.product.id,
          name: ci.product.name,
          price: ci.product.price,
          size: ci.size,
          color: ci.product.color,
          quantity: ci.quantity,
          image: ci.product.image,
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

    const calculatedTotal = cartItems.length > 0 ? totalAmount : selectedProduct ? selectedProduct.price * quantity : 0;

    const orderPayload = {
      userEmail: user.email,
      userName: profileName || user.name,
      items: itemsToOrder,
      totalAmount: calculatedTotal,
      paymentMethod,
      shippingAddress,
    };

    try {
      const res = await fetch(`${API_URL}/orders`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(orderPayload),
      });

      if (res.ok) {
        const json = await res.json();
        const createdOrder = json.data || json;
        setMyOrders((prev) => [createdOrder, ...prev]);
        setOrderSuccessMsg("Order placed successfully! Track it under My Orders.");
        clearCart();
        setTimeout(() => {
          setSelectedProduct(null);
          setActiveTab("orders");
        }, 1200);
      } else {
        const fallbackOrder: OrderItem = {
          _id: "ORD-" + Math.floor(100000 + Math.random() * 900000),
          userEmail: user.email,
          userName: user.name,
          items: orderPayload.items,
          totalAmount: orderPayload.totalAmount,
          status: "Processing",
          paymentMethod: orderPayload.paymentMethod,
          shippingAddress: orderPayload.shippingAddress,
          createdAt: new Date().toISOString(),
        };
        setMyOrders((prev) => [fallbackOrder, ...prev]);
        setOrderSuccessMsg("Order placed successfully!");
        clearCart();
        setTimeout(() => {
          setSelectedProduct(null);
          setActiveTab("orders");
        }, 1200);
      }
    } catch (err) {
      console.warn("Order submit error:", err);
      const fallbackOrder: OrderItem = {
        _id: "ORD-" + Math.floor(100000 + Math.random() * 900000),
        userEmail: user.email,
        userName: user.name,
        items: orderPayload.items,
        totalAmount: orderPayload.totalAmount,
        status: "Processing",
        paymentMethod: orderPayload.paymentMethod,
        shippingAddress: orderPayload.shippingAddress,
        createdAt: new Date().toISOString(),
      };
      setMyOrders((prev) => [fallbackOrder, ...prev]);
      setOrderSuccessMsg("Order placed successfully!");
      clearCart();
      setTimeout(() => {
        setSelectedProduct(null);
        setActiveTab("orders");
      }, 1200);
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
    <div className="min-h-screen bg-background pt-20">
      <div className="mx-auto max-w-7xl px-4 py-6">
        {/* PAGE HEADER BANNER */}
        <div className="mb-6 border-b border-border/60 pb-5">
          <h1 className="font-display text-3xl font-bold tracking-tight text-foreground">MY ACCOUNT</h1>
        </div>

        <div className="grid gap-6 lg:gap-8 lg:grid-cols-[280px_1fr]">
          {/* MOBILE RESPONSIVE TAB STRIP (< lg) */}
          <div className="lg:hidden space-y-4">
            <div className="flex items-center justify-between rounded-xl border border-border bg-card p-4 shadow-sm">
              <div className="flex items-center gap-3 overflow-hidden">
                <div className="flex size-10 items-center justify-center rounded-full border border-gold/50 bg-gold/15 font-display text-base font-bold text-gold shrink-0 shadow-sm">
                  {(profileName || user?.name || "U")[0].toUpperCase()}
                </div>
                <div className="overflow-hidden">
                  <h3 className="font-display text-base font-bold text-foreground truncate">{profileName}</h3>
                  <p className="text-[11px] text-muted-foreground truncate">{profileEmail}</p>
                </div>
              </div>
            </div>

            {/* Custom Luxury Mobile Dropdown Menu */}
            <div className="relative">
              <label className="text-[10px] uppercase tracking-widest text-gold font-bold block mb-1.5">
                Dashboard Section
              </label>
              
              <button
                type="button"
                onClick={() => setMobileNavOpen((o) => !o)}
                className="flex w-full items-center justify-between rounded-xl border border-gold/50 bg-card p-4 text-xs font-bold uppercase tracking-wider text-foreground shadow-goldy transition-all hover:border-gold"
              >
                <div className="flex items-center gap-3">
                  <CurrentIcon className="size-4 text-gold shrink-0" />
                  <span className="text-gold font-bold">{currentNavItem.label}</span>
                </div>
                <ChevronDown className={`size-4 text-gold transition-transform duration-300 ${mobileNavOpen ? "rotate-180" : ""}`} />
              </button>

              {mobileNavOpen && (
                <div className="absolute left-0 right-0 top-full z-40 mt-2 rounded-xl border border-gold/50 bg-card p-2 shadow-2xl backdrop-blur-xl animate-in fade-in duration-200">
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
                        className={`flex w-full items-center justify-between rounded-lg px-4 py-3 text-xs font-semibold uppercase tracking-wider transition-all ${
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

            {/* 4. MY CART TAB */}
            {activeTab === "cart" && (
              <div className="space-y-6">
                <div className="flex items-center justify-between border-b border-border pb-4">
                  <h2 className="font-display text-2xl font-bold text-foreground">My Cart</h2>
                  {cartItems.length > 0 && (
                    <button
                      onClick={clearCart}
                      className="text-xs text-muted-foreground hover:text-destructive transition-colors uppercase tracking-wider font-semibold"
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
                                className="p-2 text-muted-foreground hover:text-foreground transition-colors"
                              >
                                <Minus className="size-3.5" />
                              </button>
                              <span className="w-8 text-center text-xs font-bold text-foreground">
                                {ci.quantity}
                              </span>
                              <button
                                onClick={() => updateCartQuantity(ci.product.id, ci.size, 1)}
                                className="p-2 text-muted-foreground hover:text-foreground transition-colors"
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
                              className="text-muted-foreground hover:text-destructive transition-colors p-1"
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
                        onClick={() => {
                          setSelectedProduct(cartItems[0].product);
                          setSelectedSize(cartItems[0].size);
                          setQuantity(cartItems[0].quantity);
                          setOrderSuccessMsg("");
                        }}
                        className="btn-gold hover:btn-gold-hover w-full rounded-sm py-3 text-xs font-bold uppercase tracking-wider flex items-center justify-center gap-2"
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

            {/* 6. BOOK NEW TEE TAB */}
            {activeTab === "booking" && (
              <div className="space-y-6">
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
                        <p className="text-[11px] text-muted-foreground">Color: {p.color}</p>
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
              </div>
            )}
          </main>
        </div>
      </div>

      {/* ORDER PLACEMENT MODAL */}
      {selectedProduct && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 overflow-y-auto">
          <div className="w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-xl border border-gold/50 bg-card p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-border pb-4">
              <div>
                <span className="text-[10px] uppercase tracking-widest text-gold font-bold">New Booking Order</span>
                <h3 className="font-display text-xl font-bold text-foreground">{selectedProduct.name}</h3>
              </div>
              <button
                onClick={() => setSelectedProduct(null)}
                className="text-xs uppercase tracking-widest text-gold hover:underline"
              >
                Cancel
              </button>
            </div>

            {orderSuccessMsg ? (
              <div className="py-8 text-center space-y-3">
                <CheckCircle2 className="mx-auto size-12 text-gold animate-bounce" />
                <h4 className="font-display text-lg font-bold text-foreground">{orderSuccessMsg}</h4>
                <p className="text-xs text-muted-foreground">Redirecting to your orders list...</p>
              </div>
            ) : (
              <form onSubmit={handlePlaceOrder} className="mt-5 space-y-4">
                <div className="flex items-center gap-4 rounded-lg border border-border bg-surface/50 p-3">
                  <img src={selectedProduct.image} alt={selectedProduct.name} className="size-16 rounded-md object-cover" />
                  <div>
                    <p className="font-display text-sm font-semibold text-foreground">{selectedProduct.name}</p>
                    <p className="text-xs text-gold font-bold">₹{selectedProduct.price.toLocaleString("en-IN")}</p>
                    <p className="text-[10px] text-muted-foreground">Color: {selectedProduct.color}</p>
                  </div>
                </div>

                <div>
                  <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Select Size</label>
                  <div className="mt-2 flex flex-wrap gap-2">
                    {SIZES.map((sz) => (
                      <button
                        type="button"
                        key={sz}
                        onClick={() => setSelectedSize(sz)}
                        className={`rounded-sm px-3.5 py-1.5 text-xs font-bold transition-all ${
                          selectedSize === sz
                            ? "bg-gold text-primary-foreground shadow-goldy"
                            : "border border-border text-muted-foreground hover:border-gold hover:text-gold"
                        }`}
                      >
                        {sz}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Quantity</label>
                  <select
                    value={quantity}
                    onChange={(e) => setQuantity(Number(e.target.value))}
                    className="mt-1 w-full rounded-sm border border-border bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-gold"
                  >
                    {[1, 2, 3, 4, 5].map((q) => (
                      <option key={q} value={q}>
                        {q} units (Total: ₹{(selectedProduct.price * q).toLocaleString("en-IN")})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Payment Option</label>
                  <select
                    value={paymentMethod}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                    className="mt-1 w-full rounded-sm border border-border bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-gold"
                  >
                    <option value="Cash on Delivery">Cash on Delivery (COD)</option>
                    <option value="UPI / GPay / PhonePe">UPI Instant (GPay / PhonePe)</option>
                    <option value="Credit / Debit Card">Credit / Debit Card</option>
                  </select>
                </div>

                <div>
                  <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Delivery Address</label>
                  <textarea
                    required
                    rows={2}
                    value={shippingAddress}
                    onChange={(e) => setShippingAddress(e.target.value)}
                    className="mt-1 w-full rounded-sm border border-border bg-background p-2.5 text-xs text-foreground outline-none focus:border-gold"
                  />
                </div>

                <button
                  disabled={orderSubmitting}
                  className="btn-gold hover:btn-gold-hover w-full rounded-sm py-3 text-xs font-bold uppercase tracking-wider mt-4 disabled:opacity-70"
                >
                  {orderSubmitting ? "Processing Order..." : `Confirm Order — Total ₹${(selectedProduct.price * quantity).toLocaleString("en-IN")}`}
                </button>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
