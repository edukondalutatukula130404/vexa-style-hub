import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useState, useEffect, useMemo } from "react";
import {
  IndianRupee,
  ShoppingCart,
  Users,
  Boxes,
  Package,
  PlusCircle,
  BarChart3,
  ShieldCheck,
  CheckCircle2,
  Clock,
  RefreshCw,
  LogOut,
  Sparkles,
  Search,
  ChevronDown,
  Image,
  Upload,
  Save,
  Check,
  Edit,
  Trash2,
  X,
  Plus
} from "lucide-react";
import heroLuxuryImg from "@/assets/hero_luxury_tshirt.png";
import promoBanner1 from "@/assets/promo_banner_1.png";
import promoBanner2 from "@/assets/promo_banner_2.png";
import { products, type Product, useProducts } from "@/lib/products";
import { Reveal } from "@/components/Reveal";
import { useAuth, API_URL } from "@/lib/auth";

export const Route = createFileRoute("/admin")({
  head: () => ({
    meta: [
      { title: "Admin Portal & Collections | VEXA" },
      {
        name: "description",
        content:
          "VEXA admin dashboard: manage customer bookings, update shipment statuses, add new collection items, and review user accounts.",
      },
    ],
  }),
  component: Admin,
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

type DbUser = {
  _id: string;
  name: string;
  email: string;
  role: string;
  createdAt: string;
};

const kpis = [
  { icon: IndianRupee, label: "Total Revenue", value: "₹8,42,600", delta: "+18.4%" },
  { icon: ShoppingCart, label: "Total Bookings", value: "1,284", delta: "+9.2%" },
  { icon: Users, label: "Registered Users", value: "376", delta: "+12.7%" },
  { icon: Boxes, label: "Items in Collection", value: "8", delta: "Active" },
];

const sales = [42, 58, 51, 74, 66, 88, 79, 96, 84, 108, 97, 124];
const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

export function Admin() {
  const navigate = useNavigate();
  const { user, isLoggedIn, logout } = useAuth();
  const { products: catalogProducts } = useProducts();
  const [activeTab, setActiveTab] = useState<"overview" | "orders" | "add-item" | "users" | "home-media">("overview");
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  // Orders State
  const [orders, setOrders] = useState<OrderItem[]>([]);
  const [loadingOrders, setLoadingOrders] = useState(false);

  // Registered Users State
  const [usersList, setUsersList] = useState<DbUser[]>([]);
  const [loadingUsers, setLoadingUsers] = useState(false);

  const adminTabsList = useMemo(() => [
    { id: "overview", label: "Overview & Sales", icon: BarChart3 },
    { id: "home-media", label: "Home Page Media & Banners", icon: Image },
    { id: "orders", label: `Customer Bookings (${orders.length})`, icon: Package },
    { id: "add-item", label: `Collection Catalog (${catalogProducts.length})`, icon: PlusCircle },
    { id: "users", label: `Registered Users (${usersList.length})`, icon: Users },
    { id: "logout", label: "Logout", icon: LogOut, isLogout: true },
  ], [orders.length, usersList.length, catalogProducts.length]);

  // Home Page Media State
  const [heroImgUrl, setHeroImgUrl] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("vexa_home_hero_img") || heroLuxuryImg;
    }
    return heroLuxuryImg;
  });
  const [banner1ImgUrl, setBanner1ImgUrl] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("vexa_home_banner1_img") || promoBanner1;
    }
    return promoBanner1;
  });
  const [banner2ImgUrl, setBanner2ImgUrl] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("vexa_home_banner2_img") || promoBanner2;
    }
    return promoBanner2;
  });
  const [savedMediaMsg, setSavedMediaMsg] = useState("");

  const handleSaveMedia = (e: React.FormEvent) => {
    e.preventDefault();
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_home_hero_img", heroImgUrl);
      localStorage.setItem("vexa_home_banner1_img", banner1ImgUrl);
      localStorage.setItem("vexa_home_banner2_img", banner2ImgUrl);
      window.dispatchEvent(new Event("vexa_media_updated"));
    }
    setSavedMediaMsg("Home Page images updated successfully! Changes are live.");
    setTimeout(() => setSavedMediaMsg(""), 4000);
  };

  const [uploadingState, setUploadingState] = useState(false);
  const [uploadStatusMsg, setUploadStatusMsg] = useState("");

  const handleFileUpload = async (
    e: React.ChangeEvent<HTMLInputElement>,
    setter: (val: string) => void
  ) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingState(true);
    setUploadStatusMsg("Uploading file to Cloudinary...");

    try {
      const formData = new FormData();
      formData.append("image", file);

      const res = await fetch(`${API_URL}/upload`, {
        method: "POST",
        body: formData,
      });

      const data = await res.json();

      if (res.ok && data.success && data.url) {
        setter(data.url);
        setUploadStatusMsg("✅ Image uploaded to Cloudinary successfully!");
        setTimeout(() => setUploadStatusMsg(""), 4000);
      } else {
        // Fallback to Data URL preview if Cloudinary credentials pending in backend
        const reader = new FileReader();
        reader.onloadend = () => {
          if (typeof reader.result === "string") {
            setter(reader.result);
          }
        };
        reader.readAsDataURL(file);
        setUploadStatusMsg(
          data.message || "Cloudinary configuration pending in backend/.env"
        );
        setTimeout(() => setUploadStatusMsg(""), 5000);
      }
    } catch (err) {
      console.warn("Cloudinary upload network error, using preview mode:", err);
      const reader = new FileReader();
      reader.onloadend = () => {
        if (typeof reader.result === "string") {
          setter(reader.result);
        }
      };
      reader.readAsDataURL(file);
    } finally {
      setUploadingState(false);
    }
  };

  useEffect(() => {
    if (!isLoggedIn) {
      navigate({ to: "/login" });
    }
  }, [isLoggedIn, navigate]);

  // Order Filters State
  const [orderSearchQuery, setOrderSearchQuery] = useState("");
  const [orderStatusFilter, setOrderStatusFilter] = useState("All");

  const filteredOrders = useMemo(() => {
    return orders.filter((ord) => {
      const matchStatus =
        orderStatusFilter === "All" || ord.status === orderStatusFilter;
      const q = orderSearchQuery.toLowerCase().trim();
      const matchQuery =
        !q ||
        (ord._id && ord._id.toLowerCase().includes(q)) ||
        (ord.userName && ord.userName.toLowerCase().includes(q)) ||
        (ord.userEmail && ord.userEmail.toLowerCase().includes(q));
      return matchStatus && matchQuery;
    });
  }, [orders, orderSearchQuery, orderStatusFilter]);

  // Catalog Management State & Handlers
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingItem, setEditingItem] = useState<Product | null>(null);
  const [catalogSearch, setCatalogSearch] = useState("");

  // New Collection Form State
  const [newItemName, setNewItemName] = useState("");
  const [newItemPrice, setNewItemPrice] = useState("");
  const [newItemCategory, setNewItemCategory] = useState("Oversized");
  const [newItemColor, setNewItemColor] = useState("Black");
  const [newItemCollectionType, setNewItemCollectionType] = useState("Explore Collections");
  const [newItemImage, setNewItemImage] = useState("");
  const [newItemDesc, setNewItemDesc] = useState("");
  const [itemAddedMsg, setItemAddedMsg] = useState("");

  const filteredCatalog = useMemo(() => {
    if (!catalogSearch.trim()) return catalogProducts;
    const q = catalogSearch.toLowerCase().trim();
    return catalogProducts.filter(
      (p) =>
        p.name.toLowerCase().includes(q) ||
        (p.color && p.color.toLowerCase().includes(q)) ||
        p.category.toLowerCase().includes(q)
    );
  }, [catalogProducts, catalogSearch]);

  const handleDeleteItem = async (productId: string, productName: string) => {
    if (!window.confirm(`Are you sure you want to delete "${productName}" from the collection catalog?`)) {
      return;
    }

    try {
      await fetch(`${API_URL}/items/${productId}`, { method: "DELETE" });
    } catch (err) {
      console.warn("Delete API notice:", err);
    }

    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("vexa_custom_items");
        if (stored) {
          const list = JSON.parse(stored);
          const updated = list.filter(
            (p: any) => p._id !== productId && p.id !== productId && p.name !== productName
          );
          localStorage.setItem("vexa_custom_items", JSON.stringify(updated));
        }
      } catch (err) {
        console.warn("Error updating local storage after delete:", err);
      }
      window.dispatchEvent(new Event("vexa_items_updated"));
    }

    setItemAddedMsg(`Item "${productName}" deleted from collection!`);
    setTimeout(() => setItemAddedMsg(""), 4000);
  };

  const handleUpdateItem = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingItem) return;

    const payload = {
      name: editingItem.name,
      price: Number(editingItem.price),
      category: editingItem.category,
      collectionType: (editingItem as any).collectionType || "Explore Collections",
      image: editingItem.image,
      description: editingItem.description || `${editingItem.name} heavyweight cotton tee.`,
      inStock: editingItem.stock > 0,
    };

    if (editingItem.id && !editingItem.id.startsWith("local-") && !editingItem.id.startsWith("vx-")) {
      try {
        await fetch(`${API_URL}/items/${editingItem.id}`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
      } catch (err) {
        console.warn("PUT item API error:", err);
      }
    }

    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("vexa_custom_items");
        let list = stored ? JSON.parse(stored) : [];
        let found = false;
        list = list.map((item: any) => {
          if (item._id === editingItem.id || item.id === editingItem.id || item.name === editingItem.name) {
            found = true;
            return { ...item, ...payload };
          }
          return item;
        });
        if (!found) {
          list.unshift({ ...payload, _id: editingItem.id || `local-${Date.now()}` });
        }
        localStorage.setItem("vexa_custom_items", JSON.stringify(list));
      } catch (err) {
        console.warn("Error updating local custom items:", err);
      }
      window.dispatchEvent(new Event("vexa_items_updated"));
    }

    setItemAddedMsg(`Item "${editingItem.name}" updated successfully!`);
    setEditingItem(null);
    setTimeout(() => setItemAddedMsg(""), 4000);
  };

  const fetchOrders = async () => {
    setLoadingOrders(true);
    try {
      const res = await fetch(`${API_URL}/orders`);
      if (res.ok) {
        const data = await res.json();
        const list = Array.isArray(data) ? data : (data.data || []);
        setOrders(list);
      }
    } catch (err) {
      console.warn("Error fetching admin orders:", err);
    } finally {
      setLoadingOrders(false);
    }
  };

  const fetchUsers = async () => {
    setLoadingUsers(true);
    try {
      const res = await fetch(`${API_URL}/users`);
      if (res.ok) {
        const data = await res.json();
        const list = Array.isArray(data) ? data : (data.data || []);
        setUsersList(list);
      }
    } catch (err) {
      console.warn("Error fetching users list:", err);
    } finally {
      setLoadingUsers(false);
    }
  };

  useEffect(() => {
    fetchOrders();
    fetchUsers();
  }, []);

  const [statusUpdatedMsg, setStatusUpdatedMsg] = useState("");

  const handleUpdateStatus = async (orderId: string, newStatus: string) => {
    setOrders((prev) =>
      prev.map((o) => (o._id === orderId || o.id === orderId ? { ...o, status: newStatus as any } : o))
    );
    setStatusUpdatedMsg(`Booking #${String(orderId).slice(-8).toUpperCase()} status updated to "${newStatus}"!`);
    setTimeout(() => setStatusUpdatedMsg(""), 3500);

    try {
      await fetch(`${API_URL}/orders/${orderId}/status`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });
    } catch (err) {
      console.warn("Status update error:", err);
    }
  };

  const handleAddItem = async (e: React.FormEvent) => {
    e.preventDefault();
    setItemAddedMsg("");

    let finalImage = newItemImage;

    // If image is a base64 Data URL, upload it to Cloudinary database first
    if (finalImage && finalImage.startsWith("data:")) {
      try {
        setUploadStatusMsg("Uploading image to Cloudinary database...");
        const uploadRes = await fetch(`${API_URL}/upload`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ image: finalImage, folder: "vexa_items" }),
        });
        const uploadData = await uploadRes.json();
        if (uploadRes.ok && uploadData.success && uploadData.url) {
          finalImage = uploadData.url;
        }
      } catch (err) {
        console.warn("Base64 Cloudinary upload notice:", err);
      }
    }

    const payload = {
      name: newItemName,
      price: Number(newItemPrice),
      category: newItemCategory,
      collectionType: newItemCollectionType,
      image: finalImage || undefined,
      description: newItemDesc || `${newItemCollectionType} - ${newItemCategory} heavyweight cotton tee in ${newItemColor}.`,
      inStock: true,
    };

    // Save to local storage backup immediately
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("vexa_custom_items");
        const list = stored ? JSON.parse(stored) : [];
        list.unshift({ ...payload, _id: `local-${Date.now()}` });
        localStorage.setItem("vexa_custom_items", JSON.stringify(list));
      } catch (err) {
        console.warn("Could not save to local custom items:", err);
      }
    }

    try {
      const res = await fetch(`${API_URL}/items`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      await res.json();
    } catch (err) {
      console.warn("API item creation notice:", err);
    }

    if (typeof window !== "undefined") {
      window.dispatchEvent(new Event("vexa_items_updated"));
    }
    setItemAddedMsg(`New Tee "${newItemName}" added under [${newItemCollectionType}] successfully!`);
    setNewItemName("");
    setNewItemPrice("");
    setNewItemDesc("");
    setNewItemImage("");
  };

  const maxSales = Math.max(...sales);

  return (
    <div className="min-h-screen bg-background pt-20">
      <div className="mx-auto max-w-7xl px-3 sm:px-4 py-6 sm:py-8">
        <div className="grid gap-6 lg:gap-8 lg:grid-cols-[300px_1fr]">
          {/* MOBILE ADMIN DROPDOWN (< lg) */}
          <div className="lg:hidden space-y-3">
            <div className="flex items-center gap-3 rounded-xl border border-gold/40 bg-card p-4 shadow-sm">
              <div className="flex size-9 items-center justify-center rounded-full border border-gold bg-gold/20 text-gold shrink-0">
                <ShieldCheck className="size-5" />
              </div>
              <div>
                <h3 className="font-display text-sm font-semibold text-foreground">Admin Control Panel</h3>
                <p className="text-[10px] text-gold uppercase tracking-wider font-semibold">VEXA Store Manager</p>
              </div>
            </div>

            {/* Custom Mobile Dropdown Menu */}
            <div className="relative">
              <label className="text-[10px] uppercase tracking-widest text-gold font-bold block mb-1">
                Admin Section
              </label>

              <button
                type="button"
                onClick={() => setMobileNavOpen(!mobileNavOpen)}
                className="flex w-full items-center justify-between rounded-xl border border-gold/50 bg-card py-3.5 px-4 text-xs font-bold uppercase tracking-wider text-foreground shadow-goldy transition-all hover:border-gold"
              >
                <div className="flex items-center gap-2.5">
                  {activeTab === "overview" && <BarChart3 className="size-4 text-gold" />}
                  {activeTab === "home-media" && <Image className="size-4 text-gold" />}
                  {activeTab === "orders" && <Package className="size-4 text-gold" />}
                  {activeTab === "add-item" && <PlusCircle className="size-4 text-gold" />}
                  {activeTab === "users" && <Users className="size-4 text-gold" />}

                  <span>
                    {activeTab === "overview" && "Overview & Sales"}
                    {activeTab === "home-media" && "Home Page Media & Banners"}
                    {activeTab === "orders" && `Customer Bookings (${orders.length})`}
                    {activeTab === "add-item" && "Add Collection Item"}
                    {activeTab === "users" && `Registered Users (${usersList.length})`}
                  </span>
                </div>
                <ChevronDown className={`size-4 text-gold transition-transform duration-300 ${mobileNavOpen ? "rotate-180" : ""}`} />
              </button>

              {mobileNavOpen && (
                <div className="absolute left-0 right-0 top-full z-50 mt-2 space-y-1 rounded-xl border border-gold/50 bg-background/95 p-2 shadow-2xl backdrop-blur-xl animate-in fade-in zoom-in-95 duration-200">
                  {adminTabsList.map((t) => {
                    const Icon = t.icon;
                    const isSelected = activeTab === t.id && !t.isLogout;
                    return (
                      <button
                        key={t.id}
                        type="button"
                        onClick={() => {
                          if (t.isLogout) {
                            logout();
                          } else {
                            setActiveTab(t.id as any);
                          }
                          setMobileNavOpen(false);
                        }}
                        className={`flex w-full items-center justify-between rounded-lg px-3.5 py-3 text-xs font-bold uppercase tracking-wider transition-all ${
                          t.isLogout
                            ? "text-destructive hover:bg-destructive/10 border-t border-border/60 mt-1 pt-3"
                            : isSelected
                            ? "bg-gold text-primary-foreground shadow-goldy"
                            : "text-muted-foreground hover:bg-surface hover:text-gold"
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <Icon className="size-4 shrink-0" />
                          <span>{t.label}</span>
                        </div>
                        {isSelected && <CheckCircle2 className="size-4 text-primary-foreground" />}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* DESKTOP ADMIN SIDEBAR (>= lg) */}
          <aside className="hidden lg:block h-fit rounded-xl border border-gold/40 bg-card p-5 shadow-goldy">
            <div className="flex items-center gap-3 border-b border-border pb-5">
              <div className="flex size-11 items-center justify-center rounded-full border border-gold bg-gold/20 text-gold shrink-0">
                <ShieldCheck className="size-6" />
              </div>
              <div className="overflow-hidden">
                <h3 className="font-display text-sm font-semibold text-foreground truncate">Admin Control Panel</h3>
                <p className="text-[10px] text-gold uppercase tracking-wider font-semibold">VEXA Store Manager</p>
              </div>
            </div>

            <nav className="mt-6 space-y-1.5">
              <button
                onClick={() => setActiveTab("overview")}
                className={`flex w-full items-center gap-2.5 rounded-lg px-3.5 py-3 text-[11px] font-semibold uppercase tracking-wider whitespace-nowrap transition-all ${
                  activeTab === "overview"
                    ? "bg-gold text-primary-foreground shadow-goldy"
                    : "text-muted-foreground hover:bg-surface hover:text-gold"
                }`}
              >
                <BarChart3 className="size-4 shrink-0" /> Overview & Sales
              </button>

              <button
                onClick={() => setActiveTab("home-media")}
                className={`flex w-full items-center gap-2.5 rounded-lg px-3.5 py-3 text-[11px] font-semibold uppercase tracking-wider whitespace-nowrap transition-all ${
                  activeTab === "home-media"
                    ? "bg-gold text-primary-foreground shadow-goldy"
                    : "text-muted-foreground hover:bg-surface hover:text-gold"
                }`}
              >
                <Image className="size-4 shrink-0" /> Home Page Media
              </button>

              <button
                onClick={() => setActiveTab("orders")}
                className={`flex w-full items-center justify-between rounded-lg px-3.5 py-3 text-[11px] font-semibold uppercase tracking-wider whitespace-nowrap transition-all ${
                  activeTab === "orders"
                    ? "bg-gold text-primary-foreground shadow-goldy font-bold"
                    : "text-muted-foreground hover:bg-surface hover:text-gold"
                }`}
              >
                <div className="flex items-center gap-2.5 whitespace-nowrap">
                  <Package className="size-4 shrink-0" /> Customer Bookings
                </div>
                {orders.length > 0 && (
                  <span className={`rounded-full px-2 py-0.5 text-[9px] font-bold shrink-0 ${activeTab === "orders" ? "bg-black/20 text-white" : "bg-gold/20 text-gold"}`}>
                    {orders.length}
                  </span>
                )}
              </button>

              <button
                onClick={() => setActiveTab("add-item")}
                className={`flex w-full items-center justify-between rounded-lg px-3.5 py-3 text-[11px] font-semibold uppercase tracking-wider whitespace-nowrap transition-all ${
                  activeTab === "add-item"
                    ? "bg-gold text-primary-foreground shadow-goldy font-bold"
                    : "text-muted-foreground hover:bg-surface hover:text-gold"
                }`}
              >
                <div className="flex items-center gap-2.5 whitespace-nowrap">
                  <PlusCircle className="size-4 shrink-0" /> Collection Catalog
                </div>
                {catalogProducts.length > 0 && (
                  <span className={`rounded-full px-2 py-0.5 text-[9px] font-bold shrink-0 ${activeTab === "add-item" ? "bg-black/20 text-white" : "bg-gold/20 text-gold"}`}>
                    {catalogProducts.length}
                  </span>
                )}
              </button>

              <button
                onClick={() => setActiveTab("users")}
                className={`flex w-full items-center justify-between rounded-lg px-3.5 py-3 text-[11px] font-semibold uppercase tracking-wider whitespace-nowrap transition-all ${
                  activeTab === "users"
                    ? "bg-gold text-primary-foreground shadow-goldy"
                    : "text-muted-foreground hover:bg-surface hover:text-gold"
                }`}
              >
                <div className="flex items-center gap-2.5 whitespace-nowrap">
                  <Users className="size-4 shrink-0" /> Registered Users
                </div>
                {usersList.length > 0 && (
                  <span className={`rounded-full px-2 py-0.5 text-[9px] font-bold shrink-0 ${activeTab === "users" ? "bg-black/20 text-white" : "bg-gold/20 text-gold"}`}>
                    {usersList.length}
                  </span>
                )}
              </button>

              <button
                type="button"
                onClick={logout}
                className="flex w-full items-center gap-2.5 rounded-lg px-3.5 py-3 text-[11px] font-semibold uppercase tracking-wider whitespace-nowrap text-muted-foreground transition-all hover:bg-destructive/15 hover:text-destructive cursor-pointer"
              >
                <LogOut className="size-4 shrink-0 text-destructive/80" /> Logout
              </button>
            </nav>
          </aside>

          {/* MAIN CONTENT AREA */}
          <main className="min-h-[500px] rounded-xl border border-border bg-card p-4 sm:p-8 shadow-sm">
            {/* TAB 1: OVERVIEW */}
            {activeTab === "overview" && (
              <div className="space-y-8">
                <div className="border-b border-border pb-4">
                  <h2 className="font-display text-2xl font-semibold text-foreground">Analytics & Store Metrics</h2>
                  <p className="text-xs text-muted-foreground mt-1">Live metrics across sales, bookings, and inventory.</p>
                </div>

                <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
                  {kpis.map((k) => (
                    <div key={k.label} className="rounded-xl border border-border bg-card p-6 shadow-sm">
                      <div className="flex items-center justify-between">
                        <k.icon className="size-6 text-gold" />
                        <span className="text-xs font-semibold text-gold">{k.delta}</span>
                      </div>
                      <p className="mt-4 font-display text-2xl font-bold text-foreground">{k.value}</p>
                      <p className="mt-1 text-[10px] uppercase tracking-wider text-muted-foreground">{k.label}</p>
                    </div>
                  ))}
                </div>

                {/* Sales & Inventory split */}
                <div className="grid gap-8 lg:grid-cols-2">
                  <div className="rounded-xl border border-border bg-card p-6 shadow-sm">
                    <div className="flex items-center justify-between border-b border-border pb-4">
                      <div>
                        <h3 className="font-display text-lg font-semibold text-foreground">Monthly Order Volume</h3>
                        <p className="text-xs text-muted-foreground mt-0.5">Order distribution & volume performance</p>
                      </div>
                      <span className="rounded-md bg-gold/10 px-2.5 py-1 text-xs font-bold text-gold border border-gold/30">
                        1,284 Bookings Total
                      </span>
                    </div>

                    <div className="mt-6 flex h-64 items-end gap-1.5 sm:gap-2.5 rounded-xl bg-surface/50 p-4 border border-border/80">
                      {sales.map((v, i) => {
                        const heightPercent = Math.max(12, Math.round((v / maxSales) * 100));
                        return (
                          <div key={i} className="group relative flex h-full flex-1 flex-col items-center justify-end gap-1.5">
                            {/* Hover Tooltip */}
                            <div className="absolute -top-7 opacity-0 transition-opacity group-hover:opacity-100 bg-gold text-primary-foreground text-[10px] font-bold px-1.5 py-0.5 rounded shadow pointer-events-none z-10 whitespace-nowrap">
                              {v} orders
                            </div>

                            <span className="text-[9px] font-mono font-bold text-gold opacity-90">{v}</span>
                            
                            <div className="w-full flex-1 flex items-end">
                              <div
                                className="w-full rounded-t-md bg-gradient-to-t from-gold/30 via-gold/80 to-gold transition-all duration-300 group-hover:from-gold/50 group-hover:to-amber-300 shadow-sm"
                                style={{ height: `${heightPercent}%` }}
                              />
                            </div>

                            <span className="text-[10px] text-muted-foreground font-semibold group-hover:text-gold transition-colors">
                              {months[i]}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  <div className="rounded-xl border border-border bg-card p-6">
                    <h3 className="font-display text-lg font-semibold text-foreground">Collection Inventory Levels</h3>
                    <div className="mt-6 space-y-4">
                      {products.map((p) => (
                        <div key={p.id}>
                          <div className="flex justify-between text-xs">
                            <span className="font-semibold text-foreground">{p.name}</span>
                            <span className="text-gold font-bold">{p.stock} in stock</span>
                          </div>
                          <div className="mt-1.5 h-2 w-full rounded-full bg-surface overflow-hidden">
                            <div className="h-full bg-gold rounded-full" style={{ width: `${(p.stock / 50) * 100}%` }} />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* TAB: HOME PAGE MEDIA & BANNERS */}
            {activeTab === "home-media" && (
              <div className="space-y-6">
                <div className="border-b border-border pb-4">
                  <h2 className="font-display text-2xl font-semibold text-foreground">Home Page Media & Banner Manager</h2>
                  <p className="text-xs text-muted-foreground mt-1">Upload or update image URLs for the Home Page hero section and promotional banners.</p>
                </div>

                {uploadStatusMsg && (
                  <div className="flex items-center gap-3 rounded-lg border border-gold/40 bg-gold/10 p-4 text-xs text-gold font-bold animate-in fade-in duration-300">
                    <Sparkles className="size-5 shrink-0 animate-spin" />
                    <span>{uploadStatusMsg}</span>
                  </div>
                )}

                {savedMediaMsg && (
                  <div className="flex items-center gap-3 rounded-lg border border-gold/40 bg-gold/10 p-4 text-xs text-gold font-bold animate-in fade-in duration-300">
                    <CheckCircle2 className="size-5 shrink-0" />
                    <span>{savedMediaMsg}</span>
                  </div>
                )}

                <form onSubmit={handleSaveMedia} className="space-y-8">
                  {/* HERO IMAGE MANAGER */}
                  <div className="rounded-xl border border-gold/40 bg-card p-6 shadow-sm space-y-4">
                    <div className="flex items-center justify-between border-b border-border pb-3">
                      <div>
                        <h3 className="font-display text-lg font-bold text-foreground">1. Main Hero T-Shirt Image</h3>
                        <p className="text-xs text-muted-foreground">The primary luxury t-shirt image displayed in the Home page hero frame.</p>
                      </div>
                      <span className="rounded-full bg-gold/15 px-3 py-1 text-[10px] font-bold text-gold border border-gold/40">HERO IMAGE</span>
                    </div>

                    <div className="grid gap-6 sm:grid-cols-[180px_1fr] items-center">
                      <div className="relative h-48 w-full overflow-hidden rounded-xl border border-gold/40 bg-background shadow-sm">
                        <img src={heroImgUrl} alt="Hero Preview" className="h-full w-full object-cover object-center" />
                      </div>

                      <div className="space-y-4">
                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-gold font-bold block mb-1">Image URL</label>
                          <input
                            type="text"
                            value={heroImgUrl}
                            onChange={(e) => setHeroImgUrl(e.target.value)}
                            placeholder="https://example.com/hero-tshirt.png"
                            className="w-full rounded-sm border border-border bg-background px-4 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                          />
                        </div>

                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-bold block mb-1">Or Upload Local Image File</label>
                          <label className="flex cursor-pointer items-center justify-center gap-2 rounded-sm border border-dashed border-gold/50 bg-gold/5 py-2.5 px-4 text-xs font-bold text-gold transition-colors hover:bg-gold/15">
                            <Upload className="size-4" /> Upload New Hero Image
                            <input
                              type="file"
                              accept="image/*"
                              className="hidden"
                              onChange={(e) => handleFileUpload(e, setHeroImgUrl)}
                            />
                          </label>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* PROMO BANNER 1 MANAGER */}
                  <div className="rounded-xl border border-gold/40 bg-card p-6 shadow-sm space-y-4">
                    <div className="flex items-center justify-between border-b border-border pb-3">
                      <div>
                        <h3 className="font-display text-lg font-bold text-foreground">2. Promotional Showcase Banner 1</h3>
                        <p className="text-xs text-muted-foreground">Banner image for "URBAN SILHOUETTE COLLECTION" slide.</p>
                      </div>
                      <span className="rounded-full bg-gold/15 px-3 py-1 text-[10px] font-bold text-gold border border-gold/40">BANNER 1</span>
                    </div>

                    <div className="grid gap-6 sm:grid-cols-[180px_1fr] items-center">
                      <div className="relative h-36 w-full overflow-hidden rounded-xl border border-gold/40 bg-background shadow-sm">
                        <img src={banner1ImgUrl} alt="Banner 1 Preview" className="h-full w-full object-cover object-center" />
                      </div>

                      <div className="space-y-4">
                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-gold font-bold block mb-1">Image URL</label>
                          <input
                            type="text"
                            value={banner1ImgUrl}
                            onChange={(e) => setBanner1ImgUrl(e.target.value)}
                            placeholder="https://example.com/banner1.png"
                            className="w-full rounded-sm border border-border bg-background px-4 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                          />
                        </div>

                        <div>
                          <label className="flex cursor-pointer items-center justify-center gap-2 rounded-sm border border-dashed border-gold/50 bg-gold/5 py-2.5 px-4 text-xs font-bold text-gold transition-colors hover:bg-gold/15">
                            <Upload className="size-4" /> Upload Banner 1 File
                            <input
                              type="file"
                              accept="image/*"
                              className="hidden"
                              onChange={(e) => handleFileUpload(e, setBanner1ImgUrl)}
                            />
                          </label>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* PROMO BANNER 2 MANAGER */}
                  <div className="rounded-xl border border-gold/40 bg-card p-6 shadow-sm space-y-4">
                    <div className="flex items-center justify-between border-b border-border pb-3">
                      <div>
                        <h3 className="font-display text-lg font-bold text-foreground">3. Promotional Showcase Banner 2</h3>
                        <p className="text-xs text-muted-foreground">Banner image for "BESPOKE CUSTOMISATION" slide.</p>
                      </div>
                      <span className="rounded-full bg-gold/15 px-3 py-1 text-[10px] font-bold text-gold border border-gold/40">BANNER 2</span>
                    </div>

                    <div className="grid gap-6 sm:grid-cols-[180px_1fr] items-center">
                      <div className="relative h-36 w-full overflow-hidden rounded-xl border border-gold/40 bg-background shadow-sm">
                        <img src={banner2ImgUrl} alt="Banner 2 Preview" className="h-full w-full object-cover object-center" />
                      </div>

                      <div className="space-y-4">
                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-gold font-bold block mb-1">Image URL</label>
                          <input
                            type="text"
                            value={banner2ImgUrl}
                            onChange={(e) => setBanner2ImgUrl(e.target.value)}
                            placeholder="https://example.com/banner2.png"
                            className="w-full rounded-sm border border-border bg-background px-4 py-2.5 text-xs text-foreground outline-none focus:border-gold"
                          />
                        </div>

                        <div>
                          <label className="flex cursor-pointer items-center justify-center gap-2 rounded-sm border border-dashed border-gold/50 bg-gold/5 py-2.5 px-4 text-xs font-bold text-gold transition-colors hover:bg-gold/15">
                            <Upload className="size-4" /> Upload Banner 2 File
                            <input
                              type="file"
                              accept="image/*"
                              className="hidden"
                              onChange={(e) => handleFileUpload(e, setBanner2ImgUrl)}
                            />
                          </label>
                        </div>
                      </div>
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="btn-gold hover:btn-gold-hover flex w-full items-center justify-center gap-2 rounded-sm py-4 text-xs font-bold uppercase tracking-wider shadow-sm"
                  >
                    <Save className="size-4" /> Save Home Page Media Changes
                  </button>
                </form>
              </div>
            )}

            {/* TAB 2: MANAGE CUSTOMER BOOKINGS & ORDERS */}
            {activeTab === "orders" && (
              <div className="space-y-6">
                <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between border-b border-border pb-4">
                  <div>
                    <h2 className="font-display text-2xl font-semibold text-foreground">Manage Customer Bookings</h2>
                    <p className="text-xs text-muted-foreground mt-1">Review orders placed across the system and update shipment status.</p>
                  </div>
                  <button
                    onClick={fetchOrders}
                    className="flex items-center justify-center gap-2 rounded-sm border border-gold/40 px-4 py-2 text-xs font-semibold text-gold transition-colors hover:bg-gold hover:text-primary-foreground"
                  >
                    <RefreshCw className="size-3.5" /> Refresh Orders
                  </button>
                </div>

                {statusUpdatedMsg && (
                  <div className="flex items-center gap-2.5 rounded-lg border border-gold/40 bg-gold/10 p-3.5 text-xs font-semibold text-gold animate-in fade-in duration-300">
                    <CheckCircle2 className="size-4 shrink-0 text-gold" />
                    <span>{statusUpdatedMsg}</span>
                  </div>
                )}

                {/* Filter Controls & Search */}
                <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                  <div className="flex flex-wrap gap-2">
                    {["All", "Processing", "Shipped", "Delivered", "Cancelled"].map((st) => (
                      <button
                        key={st}
                        onClick={() => setOrderStatusFilter(st)}
                        className={`rounded-full px-4 py-1.5 text-[10px] uppercase tracking-wider font-bold transition-all ${
                          orderStatusFilter === st
                            ? "bg-gold text-primary-foreground shadow-goldy"
                            : "border border-border bg-card text-muted-foreground hover:border-gold hover:text-gold"
                        }`}
                      >
                        {st}
                      </button>
                    ))}
                  </div>

                  <div className="relative min-w-[240px]">
                    <Search className="absolute left-3.5 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground" />
                    <input
                      type="text"
                      value={orderSearchQuery}
                      onChange={(e) => setOrderSearchQuery(e.target.value)}
                      placeholder="Search customer, email or ID..."
                      className="w-full rounded-sm border border-border bg-card py-2 pl-9 pr-3 text-xs outline-none focus:border-gold placeholder:text-muted-foreground/60"
                    />
                  </div>
                </div>

                {filteredOrders.length > 0 ? (
                  <div className="space-y-5">
                    {filteredOrders.map((ord) => (
                      <div key={ord._id} className="rounded-xl border border-border bg-card p-6 shadow-sm space-y-4">
                        {/* Header Row */}
                        <div className="flex flex-wrap items-center justify-between border-b border-border pb-4 gap-4">
                          <div>
                            <div className="flex items-center gap-2">
                              <span className="text-[10px] uppercase tracking-widest text-gold font-bold">Booking ID</span>
                              <span className="rounded-md bg-gold/10 px-2 py-0.5 text-[10px] text-gold font-mono font-bold border border-gold/30">
                                #{String(ord._id || ord.id || "ORD").slice(-8).toUpperCase()}
                              </span>
                            </div>
                            <h4 className="font-display text-base font-bold text-foreground mt-1">
                              Customer: {ord.userName || "Customer"}
                            </h4>
                            <p className="text-xs text-muted-foreground">
                              Email: <span className="text-gold font-medium">{ord.userEmail}</span> • Date: {new Date(ord.createdAt || Date.now()).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                            </p>
                          </div>

                          <div className="flex items-center gap-4">
                            <div className="text-right">
                              <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold block">Total Amount</span>
                              <span className="font-display text-xl font-bold text-gold">
                                ₹{(ord.totalAmount || 0).toLocaleString("en-IN")}
                              </span>
                            </div>

                            {/* Status Selector Dropdown */}
                            <select
                              value={ord.status || "Processing"}
                              onChange={(e) => handleUpdateStatus(ord._id, e.target.value)}
                              className={`rounded-lg border px-3 py-2 text-xs font-bold outline-none cursor-pointer transition-colors ${
                                ord.status === "Delivered"
                                  ? "border-emerald-500/50 bg-emerald-500/10 text-emerald-600"
                                  : ord.status === "Shipped"
                                  ? "border-blue-500/50 bg-blue-500/10 text-blue-600"
                                  : ord.status === "Cancelled"
                                  ? "border-destructive/50 bg-destructive/10 text-destructive"
                                  : "border-gold/60 bg-gold/10 text-gold"
                              }`}
                            >
                              <option value="Processing">Processing</option>
                              <option value="Shipped">Shipped</option>
                              <option value="Delivered">Delivered</option>
                              <option value="Cancelled">Cancelled</option>
                            </select>
                          </div>
                        </div>

                        {/* Items List */}
                        <div className="space-y-3 pt-1">
                          <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Booked Items</span>
                          {(ord.items || []).map((item, idx) => (
                            <div key={idx} className="flex items-center justify-between gap-4 rounded-lg border border-border/70 bg-surface/50 p-3 text-xs">
                              <div className="flex items-center gap-3">
                                {item && item.image ? (
                                  <img
                                    src={item.image}
                                    alt={item.name || "Item"}
                                    className="size-12 rounded-md object-cover border border-border shrink-0"
                                  />
                                ) : (
                                  <div className="size-12 rounded-md bg-gold/10 border border-gold/30 flex items-center justify-center text-gold font-bold text-[10px]">
                                    TEE
                                  </div>
                                )}
                                <div>
                                  <h5 className="font-display font-semibold text-foreground">{item?.name || "Oversized Tee"}</h5>
                                  <p className="text-[11px] text-muted-foreground">
                                    Size: <span className="text-gold font-bold">{item?.size || "M"}</span> • Color: {item?.color || "Standard"} • Qty: {item?.quantity || 1}
                                  </p>
                                </div>
                              </div>
                              <span className="font-semibold text-foreground">
                                ₹{((item?.price || 0) * (item?.quantity || 1)).toLocaleString("en-IN")}
                              </span>
                            </div>
                          ))}
                        </div>

                        {/* Footer Details */}
                        <div className="border-t border-border pt-3 text-[11px] text-muted-foreground flex flex-wrap justify-between gap-2">
                          <p><span className="text-gold font-semibold">Delivery Address:</span> {ord.shippingAddress}</p>
                          <p><span className="text-gold font-semibold">Payment Method:</span> {ord.paymentMethod}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="py-16 text-center text-muted-foreground border border-dashed border-border rounded-xl">
                    <Package className="mx-auto size-10 text-gold/50" />
                    <p className="mt-3 font-display text-base font-semibold text-foreground">No customer bookings found</p>
                    <p className="mt-1 text-xs">When users place orders, they will appear here for status management.</p>
                  </div>
                )}
              </div>
            )}

            {/* TAB 3: MANAGE COLLECTION CATALOG & ITEMS */}
            {activeTab === "add-item" && (
              <div className="space-y-6">
                <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between border-b border-border pb-4">
                  <div>
                    <h2 className="font-display text-2xl font-semibold text-foreground">Collection Catalog & Items</h2>
                    <p className="text-xs text-muted-foreground mt-1">Manage all products in the database catalog with Edit, Delete and Add controls.</p>
                  </div>
                  <button
                    onClick={() => setShowAddForm(!showAddForm)}
                    className="flex items-center justify-center gap-2 rounded-sm bg-gold px-4 py-2.5 text-xs font-bold text-primary-foreground transition-all hover:bg-amber-400 shadow-goldy cursor-pointer"
                  >
                    {showAddForm ? <X className="size-4" /> : <Plus className="size-4" />}
                    <span>{showAddForm ? "Close Form" : "Add New Tee"}</span>
                  </button>
                </div>

                {uploadStatusMsg && (
                  <div className="flex items-center gap-3 rounded-lg border border-gold/40 bg-gold/10 p-4 text-xs text-gold font-bold animate-in fade-in duration-300">
                    <Sparkles className="size-5 shrink-0 animate-spin" />
                    <span>{uploadStatusMsg}</span>
                  </div>
                )}

                {itemAddedMsg && (
                  <div className="flex items-center gap-3 rounded-lg border border-gold/40 bg-gold/10 p-4 text-xs text-gold font-semibold">
                    <CheckCircle2 className="size-5 shrink-0" />
                    <span>{itemAddedMsg}</span>
                  </div>
                )}

                {/* ADD NEW ITEM FORM (COLLAPSIBLE / CONDITIONAL) */}
                {showAddForm && (
                  <form onSubmit={handleAddItem} className="rounded-xl border border-gold/50 bg-card p-6 shadow-goldy space-y-5 max-w-xl animate-in fade-in zoom-in-95 duration-200">
                    <div className="flex items-center justify-between border-b border-border pb-3">
                      <h3 className="font-display text-lg font-bold text-foreground">Add New Collection Tee</h3>
                      <span className="rounded-full bg-gold/15 px-3 py-1 text-[10px] font-bold text-gold border border-gold/40">NEW PRODUCT</span>
                    </div>

                    <div>
                      <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">T-Shirt Name</label>
                      <input
                        required
                        type="text"
                        value={newItemName}
                        onChange={(e) => setNewItemName(e.target.value)}
                        placeholder="e.g. Emerald Silk Oversized Tee"
                        className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs outline-none focus:border-gold"
                      />
                    </div>

                    <div className="grid gap-5 sm:grid-cols-2">
                      <div>
                        <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Price (INR)</label>
                        <input
                          required
                          type="number"
                          value={newItemPrice}
                          onChange={(e) => setNewItemPrice(e.target.value)}
                          placeholder="2499"
                          className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs outline-none focus:border-gold"
                        />
                      </div>

                      <div>
                        <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Category</label>
                        <select
                          value={newItemCategory}
                          onChange={(e) => setNewItemCategory(e.target.value)}
                          className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs outline-none focus:border-gold"
                        >
                          <option value="Oversized">Oversized Fit</option>
                          <option value="Classic">Classic Fit</option>
                          <option value="Limited">Limited Drop</option>
                          <option value="Graphic">Graphic Edition</option>
                        </select>
                      </div>
                    </div>

                    <div>
                      <label className="text-[10px] uppercase tracking-wider text-gold font-bold block mb-1">
                        Collection Placement / Section Type
                      </label>
                      <select
                        value={newItemCollectionType}
                        onChange={(e) => setNewItemCollectionType(e.target.value)}
                        className="w-full rounded-sm border border-gold/50 bg-background px-4 py-3 text-xs font-bold text-foreground outline-none focus:border-gold shadow-sm cursor-pointer"
                      >
                        <option value="Explore Collections">Explore Collections (Featured)</option>
                        <option value="New Arrivals">New Arrivals</option>
                        <option value="Best Sellers">Best Sellers</option>
                        <option value="Limited Edition">Limited Edition</option>
                      </select>
                      <p className="mt-1 text-[10px] text-muted-foreground">Select which collection section this item will be featured under.</p>
                    </div>

                    <div className="space-y-2">
                      <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">T-Shirt Image (URL or Upload File)</label>
                      <div className="flex gap-2 items-center">
                        <input
                          type="text"
                          value={newItemImage}
                          onChange={(e) => setNewItemImage(e.target.value)}
                          placeholder="https://example.com/tshirt.jpg or leave blank for default"
                          className="flex-1 rounded-sm border border-border bg-background px-4 py-2.5 text-xs outline-none focus:border-gold"
                        />
                        <label className="cursor-pointer shrink-0 rounded-sm border border-gold/40 bg-gold/10 px-3 py-2.5 text-xs font-bold text-gold transition-colors hover:bg-gold hover:text-primary-foreground">
                          <Upload className="size-4 inline mr-1" /> File
                          <input
                            type="file"
                            accept="image/*"
                            className="hidden"
                            onChange={(e) => handleFileUpload(e, setNewItemImage)}
                          />
                        </label>
                      </div>
                    </div>

                    <div>
                      <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Description</label>
                      <textarea
                        rows={3}
                        value={newItemDesc}
                        onChange={(e) => setNewItemDesc(e.target.value)}
                        placeholder="240 GSM heavy cotton construction with reinforced collar..."
                        className="mt-1.5 w-full rounded-sm border border-border bg-background p-3 text-xs outline-none focus:border-gold"
                      />
                    </div>

                    <button className="btn-gold hover:btn-gold-hover w-full rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider">
                      Add Tee to Collection Catalog
                    </button>
                  </form>
                )}

                {/* SEARCH & CATALOG COUNT CONTROL */}
                <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between pt-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-foreground">Catalog Items ({filteredCatalog.length})</span>
                    <span className="rounded-full bg-gold/15 px-2.5 py-0.5 text-[10px] font-bold text-gold border border-gold/30">
                      Live Store Sync
                    </span>
                  </div>

                  <div className="relative min-w-[260px]">
                    <Search className="absolute left-3.5 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground" />
                    <input
                      type="text"
                      value={catalogSearch}
                      onChange={(e) => setCatalogSearch(e.target.value)}
                      placeholder="Search item title or category..."
                      className="w-full rounded-sm border border-border bg-card py-2 pl-9 pr-3 text-xs outline-none focus:border-gold placeholder:text-muted-foreground/60"
                    />
                  </div>
                </div>

                {/* CATALOG ITEMS LIST (HORIZONTAL ROW CARDS) */}
                <div className="space-y-3.5">
                  {filteredCatalog.length > 0 ? (
                    <div className="space-y-3">
                      {filteredCatalog.map((prod) => (
                        <div
                          key={prod.id}
                          className="group relative flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 rounded-xl border border-border bg-card p-4 shadow-sm transition-all hover:border-gold/60 hover:shadow-goldy"
                        >
                          {/* Left Section: Thumbnail & Main Info */}
                          <div className="flex items-center gap-4 w-full sm:w-auto flex-1 min-w-0">
                            {/* Product Thumbnail */}
                            <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-lg border border-border bg-surface shadow-xs">
                              <img
                                src={prod.image}
                                alt={prod.name}
                                className="h-full w-full object-cover object-center transition-transform duration-500 group-hover:scale-110"
                              />
                            </div>

                            {/* Product Info */}
                            <div className="space-y-1 overflow-hidden flex-1">
                              <div className="flex flex-wrap items-center gap-2">
                                <h4 className="font-display text-sm font-bold text-foreground group-hover:text-gold transition-colors truncate">
                                  {prod.name}
                                </h4>
                                <span className="rounded-full bg-black/80 px-2.5 py-0.5 text-[9px] font-bold uppercase tracking-wider text-gold border border-gold/40">
                                  {prod.category}
                                </span>
                              </div>

                              <p className="text-xs text-muted-foreground">
                                Price: <span className="font-bold text-gold">₹{prod.price.toLocaleString("en-IN")}</span> • Color: <span className="text-foreground font-semibold">{prod.color || "Standard"}</span> • Rating: ⭐ {prod.rating}
                              </p>

                              {prod.description && (
                                <p className="text-[11px] text-muted-foreground/80 line-clamp-1 truncate">
                                  {prod.description}
                                </p>
                              )}
                            </div>
                          </div>

                          {/* Right Section: Stock Status & Action Buttons */}
                          <div className="flex items-center justify-between sm:justify-end gap-4 w-full sm:w-auto border-t sm:border-t-0 pt-3 sm:pt-0 border-border shrink-0">
                            <span
                              className={`text-[10px] font-bold uppercase tracking-wider ${
                                prod.stock > 0 ? "text-emerald-500" : "text-destructive"
                              }`}
                            >
                              {prod.stock > 0 ? "In Stock" : "Out of Stock"}
                            </span>

                            <div className="flex items-center gap-2 shrink-0">
                              <button
                                type="button"
                                onClick={() => setEditingItem(prod)}
                                className="flex items-center gap-1.5 rounded-md border border-gold/40 bg-gold/10 px-3.5 py-2 text-xs font-bold text-gold transition-all hover:bg-gold hover:text-primary-foreground cursor-pointer shadow-xs"
                              >
                                <Edit className="size-3.5" /> Edit
                              </button>

                              <button
                                type="button"
                                onClick={() => handleDeleteItem(prod.id, prod.name)}
                                className="flex items-center gap-1.5 rounded-md border border-destructive/40 bg-destructive/10 px-3.5 py-2 text-xs font-bold text-destructive transition-all hover:bg-destructive hover:text-destructive-foreground cursor-pointer shadow-xs"
                              >
                                <Trash2 className="size-3.5" /> Delete
                              </button>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="py-16 text-center text-muted-foreground border border-dashed border-border rounded-xl">
                      <Boxes className="mx-auto size-10 text-gold/50" />
                      <p className="mt-3 font-display text-base font-semibold text-foreground">No catalog items found</p>
                      <p className="mt-1 text-xs">Add new collection items using the form above.</p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* EDIT ITEM MODAL */}
            {editingItem && (
              <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-sm p-4 overflow-y-auto animate-in fade-in duration-200">
                <div className="relative w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-2xl border border-gold/50 bg-card p-6 sm:p-8 shadow-2xl space-y-5">
                  <button
                    onClick={() => setEditingItem(null)}
                    className="absolute right-5 top-5 rounded-full border border-border bg-background p-2 text-muted-foreground transition-colors hover:border-gold hover:text-gold"
                  >
                    <X className="size-4" />
                  </button>

                  <div className="border-b border-border pb-3">
                    <h3 className="font-display text-xl font-bold text-foreground">Edit Collection Item</h3>
                    <p className="text-xs text-muted-foreground mt-0.5">Modify product details, category, price or image URL.</p>
                  </div>

                  <form onSubmit={handleUpdateItem} className="space-y-4">
                    <div>
                      <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">T-Shirt Name</label>
                      <input
                        required
                        type="text"
                        value={editingItem.name}
                        onChange={(e) => setEditingItem({ ...editingItem, name: e.target.value })}
                        className="mt-1 w-full rounded-sm border border-border bg-background px-4 py-2.5 text-xs outline-none focus:border-gold"
                      />
                    </div>

                    <div className="grid gap-4 sm:grid-cols-2">
                      <div>
                        <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Price (INR)</label>
                        <input
                          required
                          type="number"
                          value={editingItem.price}
                          onChange={(e) => setEditingItem({ ...editingItem, price: Number(e.target.value) })}
                          className="mt-1 w-full rounded-sm border border-border bg-background px-4 py-2.5 text-xs outline-none focus:border-gold"
                        />
                      </div>

                      <div>
                        <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Category</label>
                        <select
                          value={editingItem.category}
                          onChange={(e) => setEditingItem({ ...editingItem, category: e.target.value as any })}
                          className="mt-1 w-full rounded-sm border border-border bg-background px-4 py-2.5 text-xs outline-none focus:border-gold"
                        >
                          <option value="Oversized">Oversized Fit</option>
                          <option value="Classic">Classic Fit</option>
                          <option value="Limited">Limited Drop</option>
                          <option value="Graphic">Graphic Edition</option>
                        </select>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Image URL or Cloudinary Upload</label>
                      <div className="flex gap-2 items-center">
                        <input
                          type="text"
                          value={editingItem.image}
                          onChange={(e) => setEditingItem({ ...editingItem, image: e.target.value })}
                          className="flex-1 rounded-sm border border-border bg-background px-4 py-2.5 text-xs outline-none focus:border-gold"
                        />
                        <label className="cursor-pointer shrink-0 rounded-sm border border-gold/40 bg-gold/10 px-3 py-2 text-xs font-bold text-gold transition-colors hover:bg-gold hover:text-primary-foreground">
                          <Upload className="size-3.5 inline mr-1" /> File
                          <input
                            type="file"
                            accept="image/*"
                            className="hidden"
                            onChange={(e) => handleFileUpload(e, (url) => setEditingItem({ ...editingItem, image: url }))}
                          />
                        </label>
                      </div>
                    </div>

                    <div>
                      <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Description</label>
                      <textarea
                        rows={3}
                        value={editingItem.description || ""}
                        onChange={(e) => setEditingItem({ ...editingItem, description: e.target.value })}
                        className="mt-1 w-full rounded-sm border border-border bg-background p-3 text-xs outline-none focus:border-gold"
                      />
                    </div>

                    <div className="pt-2 flex justify-end gap-3">
                      <button
                        type="button"
                        onClick={() => setEditingItem(null)}
                        className="rounded-sm border border-border px-4 py-2.5 text-xs font-bold text-muted-foreground hover:bg-surface cursor-pointer"
                      >
                        Cancel
                      </button>

                      <button
                        type="submit"
                        className="btn-gold hover:btn-gold-hover rounded-sm px-6 py-2.5 text-xs font-bold uppercase tracking-wider cursor-pointer"
                      >
                        Save Changes
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            )}

            {/* TAB 4: REGISTERED USERS */}
            {activeTab === "users" && (
              <div className="space-y-6">
                <div className="flex items-center justify-between border-b border-border pb-4">
                  <div>
                    <h2 className="font-display text-2xl font-semibold text-foreground">Registered Users Database</h2>
                    <p className="text-xs text-muted-foreground mt-1">Users registered in the system MongoDB database.</p>
                  </div>
                  <button
                    onClick={fetchUsers}
                    className="rounded-sm border border-gold/40 px-3 py-1.5 text-xs text-gold hover:bg-gold hover:text-primary-foreground"
                  >
                    Refresh Users
                  </button>
                </div>

                <div className="rounded-xl border border-border bg-card overflow-hidden shadow-sm">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="border-b border-border text-[10px] uppercase tracking-wider text-muted-foreground bg-surface">
                        <th className="p-4">User Name</th>
                        <th className="p-4">Email</th>
                        <th className="p-4">Role</th>
                        <th className="p-4">Registered Date</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {usersList.length > 0 ? (
                        usersList.map((u) => (
                          <tr key={u._id} className="hover:bg-surface/50">
                            <td className="p-4 font-semibold text-foreground">{u.name}</td>
                            <td className="p-4 text-muted-foreground">{u.email}</td>
                            <td className="p-4 font-bold uppercase text-gold">{u.role}</td>
                            <td className="p-4 text-muted-foreground">
                              {new Date(u.createdAt).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                            </td>
                          </tr>
                        ))
                      ) : (
                        <tr>
                          <td colSpan={4} className="p-8 text-center text-muted-foreground">
                            No users fetched.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </main>
        </div>
      </div>
    </div>
  );
}
