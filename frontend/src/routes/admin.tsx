import { useNavigate } from "react-router-dom";
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
  Plus,
  ArrowLeft,
  Menu,
  Ticket,
  Star,
  Settings
} from "lucide-react";
import heroLuxuryImg from "@/assets/hero_luxury_tshirt.png";
import promoBanner1 from "@/assets/promo_banner_1.png";
import promoBanner2 from "@/assets/promo_banner_2.png";
import { products, type Product, useProducts } from "@/lib/products";
import { Reveal } from "@/components/Reveal";
import { useAuth, API_URL } from "@/lib/auth";

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
  const [activeTab, setActiveTab] = useState<"overview" | "inventory" | "orders" | "add-item" | "categories" | "users" | "home-media">("overview");
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  // Category Manager State
  const [categoriesList, setCategoriesList] = useState<string[]>(() => {
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("vexa_custom_categories");
        if (stored) return JSON.parse(stored);
      } catch (e) {}
    }
    return ["Oversized Fit", "Classic Fit", "Limited Drop", "Signature Drop", "Luxury Heavyweight", "Graphic Series"];
  });
  const [newCatInput, setNewCatInput] = useState("");
  const [catMsg, setCatMsg] = useState("");

  const handleAddCategory = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCatInput.trim()) return;
    const catName = newCatInput.trim();
    if (categoriesList.includes(catName)) {
      setCatMsg(`Category "${catName}" already exists!`);
      setTimeout(() => setCatMsg(""), 3000);
      return;
    }
    const updated = [...categoriesList, catName];
    setCategoriesList(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_custom_categories", JSON.stringify(updated));
    }
    setNewCatInput("");
    setCatMsg(`New Category "${catName}" added successfully!`);
    setTimeout(() => setCatMsg(""), 3500);
  };

  const handleDeleteCategory = (catName: string) => {
    const updated = categoriesList.filter((c) => c !== catName);
    setCategoriesList(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_custom_categories", JSON.stringify(updated));
    }
    setCatMsg(`Category "${catName}" removed.`);
    setTimeout(() => setCatMsg(""), 3000);
  };

  // Category Edit State
  const [editingCatName, setEditingCatName] = useState<string | null>(null);
  const [editingCatValue, setEditingCatValue] = useState("");

  const handleStartEditCategory = (catName: string) => {
    setEditingCatName(catName);
    setEditingCatValue(catName);
  };

  const handleSaveEditCategory = (oldName: string) => {
    if (!editingCatValue.trim()) return;
    const newName = editingCatValue.trim();
    if (oldName === newName) {
      setEditingCatName(null);
      return;
    }
    const updated = categoriesList.map((c) => (c === oldName ? newName : c));
    setCategoriesList(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_custom_categories", JSON.stringify(updated));
    }
    setEditingCatName(null);
    setCatMsg(`Category updated to "${newName}" successfully!`);
    setTimeout(() => setCatMsg(""), 3500);
  };

  // Inventory & Stock State
  const [stockMap, setStockMap] = useState<Record<string, number>>(() => {
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("vexa_product_stock");
        if (stored) return JSON.parse(stored);
      } catch (e) {}
    }
    const initial: Record<string, number> = {};
    catalogProducts.forEach((p, idx) => {
      initial[p.id] = idx % 3 === 0 ? 5 : idx % 4 === 0 ? 0 : 35 + idx * 5;
    });
    return initial;
  });
  const [inventorySearch, setInventorySearch] = useState("");
  const [stockUpdatedMsg, setStockUpdatedMsg] = useState("");

  const handleUpdateStock = (productId: string, newQty: number) => {
    const safeQty = Math.max(0, newQty);
    const updated = { ...stockMap, [productId]: safeQty };
    setStockMap(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_product_stock", JSON.stringify(updated));
    }
    setStockUpdatedMsg("Stock units updated successfully!");
    setTimeout(() => setStockUpdatedMsg(""), 2500);
  };

  // Orders State
  const [orders, setOrders] = useState<OrderItem[]>([]);
  const [loadingOrders, setLoadingOrders] = useState(false);
  const [selectedOrderDetails, setSelectedOrderDetails] = useState<OrderItem | null>(null);

  // Registered Users State
  const [usersList, setUsersList] = useState<DbUser[]>([]);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [selectedUserDetails, setSelectedUserDetails] = useState<DbUser | null>(null);

  // Coupons State
  type Coupon = {
    code: string;
    discount: string;
    minOrder: number;
    usageCount: number;
    active: boolean;
  };
  const [couponsList, setCouponsList] = useState<Coupon[]>(() => {
    if (typeof window !== "undefined") {
      const saved = localStorage.getItem("vexa_coupons_data");
      if (saved) {
        try { return JSON.parse(saved); } catch (e) { console.error(e); }
      }
    }
    return [
      { code: "VEXA30", discount: "30% OFF", minOrder: 1499, usageCount: 142, active: true },
      { code: "WELCOME100", discount: "₹100 OFF", minOrder: 999, usageCount: 89, active: true },
      { code: "FREESHIP", discount: "Free Shipping", minOrder: 1999, usageCount: 310, active: true },
    ];
  });
  const [newCouponCode, setNewCouponCode] = useState("");
  const [newCouponDiscount, setNewCouponDiscount] = useState("");
  const [newCouponMinOrder, setNewCouponMinOrder] = useState("999");
  const [couponMsg, setCouponMsg] = useState("");

  const handleAddCoupon = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCouponCode.trim() || !newCouponDiscount.trim()) return;
    const newItem: Coupon = {
      code: newCouponCode.trim().toUpperCase(),
      discount: newCouponDiscount.trim(),
      minOrder: Number(newCouponMinOrder) || 0,
      usageCount: 0,
      active: true,
    };
    const updated = [newItem, ...couponsList];
    setCouponsList(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_coupons_data", JSON.stringify(updated));
    }
    setNewCouponCode("");
    setNewCouponDiscount("");
    setCouponMsg("Promo coupon created successfully!");
    setTimeout(() => setCouponMsg(""), 3000);
  };

  const handleToggleCoupon = (code: string) => {
    const updated = couponsList.map((c) => c.code === code ? { ...c, active: !c.active } : c);
    setCouponsList(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_coupons_data", JSON.stringify(updated));
    }
  };

  const handleDeleteCoupon = (code: string) => {
    const updated = couponsList.filter((c) => c.code !== code);
    setCouponsList(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_coupons_data", JSON.stringify(updated));
    }
  };

  // Reviews State
  type ReviewItem = {
    id: string;
    author: string;
    rating: number;
    productName: string;
    comment: string;
    date: string;
    featured: boolean;
  };
  const [reviewsList, setReviewsList] = useState<ReviewItem[]>(() => {
    if (typeof window !== "undefined") {
      const saved = localStorage.getItem("vexa_reviews_data");
      if (saved) {
        try { return JSON.parse(saved); } catch (e) { console.error(e); }
      }
    }
    return [
      { id: "rev-1", author: "Kabir Mehta", rating: 5, productName: "Gold-Embroidered Crest Oversized Tee", comment: "The weight and drape on this tee are unreal. Easily competes with luxury designer brands.", date: "02 Aug 2026", featured: true },
      { id: "rev-2", author: "Rohan Kapoor", rating: 5, productName: "Obsidian Black Heavyweight Tee", comment: "Mastered the balance between structured heavyweight cotton and breathable comfort.", date: "01 Aug 2026", featured: true },
      { id: "rev-3", author: "Ananya Desai", rating: 5, productName: "Minimalist Typographic Streetwear Tee", comment: "Washed my tee 15 times and it still looks and feels brand new. No fading!", date: "29 Jul 2026", featured: true },
      { id: "rev-4", author: "Siddharth Rao", rating: 4, productName: "Emerald Heavyweight Boxy Tee", comment: "Great thick fabric quality. Sizing runs perfectly oversized.", date: "28 Jul 2026", featured: false },
    ];
  });
  const [reviewMsg, setReviewMsg] = useState("");

  const handleToggleFeaturedReview = (id: string) => {
    const updated = reviewsList.map((r) => r.id === id ? { ...r, featured: !r.featured } : r);
    setReviewsList(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_reviews_data", JSON.stringify(updated));
    }
    setReviewMsg("Review status updated!");
    setTimeout(() => setReviewMsg(""), 3000);
  };

  const handleDeleteReview = (id: string) => {
    const updated = reviewsList.filter((r) => r.id !== id);
    setReviewsList(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_reviews_data", JSON.stringify(updated));
    }
  };

  // Store Settings State
  const [storeSettings, setStoreSettings] = useState(() => {
    if (typeof window !== "undefined") {
      const saved = localStorage.getItem("vexa_store_settings");
      if (saved) {
        try { return JSON.parse(saved); } catch (e) { console.error(e); }
      }
    }
    return {
      freeShippingMin: 1999,
      supportPhone: "+91 98765 43210",
      supportEmail: "support@vexa.store",
      announcementBar: "FREE EXPRESS SHIPPING ON ORDERS OVER ₹1999 ✦ 30% OFF FIRST ORDER WITH VEXA30",
      gstPercentage: 5,
    };
  });
  const [settingsSavedMsg, setSettingsSavedMsg] = useState("");

  const handleSaveSettings = (e: React.FormEvent) => {
    e.preventDefault();
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_store_settings", JSON.stringify(storeSettings));
    }
    setSettingsSavedMsg("Store settings saved successfully!");
    setTimeout(() => setSettingsSavedMsg(""), 3000);
  };

  const adminTabsList = useMemo(() => [
    { id: "overview", label: "Overview & Sales", icon: BarChart3 },
    { id: "inventory", label: `Inventory Management (${catalogProducts.length})`, icon: Boxes },
    { id: "add-item", label: `Collection Catalog (${catalogProducts.length})`, icon: PlusCircle },
    { id: "orders", label: `Customer Bookings (${orders.length})`, icon: Package },
    { id: "users", label: `Registered Users (${usersList.length})`, icon: Users },
    { id: "coupons", label: `Promo Coupons (${couponsList.length})`, icon: Ticket },
    { id: "reviews", label: `Customer Reviews (${reviewsList.length})`, icon: Star },
    { id: "home-media", label: "Home Page Media", icon: Image },
    { id: "settings", label: "Store Settings", icon: Settings },
    { id: "logout", label: "Logout", icon: LogOut, isLogout: true },
  ], [orders.length, usersList.length, catalogProducts.length, couponsList.length, reviewsList.length]);

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
    setter: (val: string) => void,
    storageKey?: string
  ) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingState(true);
    setUploadStatusMsg("Uploading file...");

    const saveLive = (url: string) => {
      setter(url);
      if (storageKey && typeof window !== "undefined") {
        localStorage.setItem(storageKey, url);
        window.dispatchEvent(new Event("vexa_media_updated"));
      }
    };

    try {
      const formData = new FormData();
      formData.append("image", file);

      const res = await fetch(`${API_URL}/upload`, {
        method: "POST",
        body: formData,
      });

      const data = await res.json();

      if (res.ok && data.success && data.url) {
        saveLive(data.url);
        setUploadStatusMsg("✅ Image updated live across store!");
        setTimeout(() => setUploadStatusMsg(""), 4000);
      } else {
        const reader = new FileReader();
        reader.onloadend = () => {
          if (typeof reader.result === "string") {
            saveLive(reader.result);
          }
        };
        reader.readAsDataURL(file);
        setUploadStatusMsg("✅ Image updated live across store!");
        setTimeout(() => setUploadStatusMsg(""), 4000);
      }
    } catch (err) {
      const reader = new FileReader();
      reader.onloadend = () => {
        if (typeof reader.result === "string") {
          saveLive(reader.result);
        }
      };
      reader.readAsDataURL(file);
      setUploadStatusMsg("✅ Image updated live across store!");
      setTimeout(() => setUploadStatusMsg(""), 4000);
    } finally {
      setUploadingState(false);
    }
  };

  useEffect(() => {
    if (!isLoggedIn) {
      navigate("/login");
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

  // Warehouse Inventory Stock Management State
  const [inventoryStocks, setInventoryStocks] = useState<Record<string, number>>({});

  const fetchInventory = () => {
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("vexa_inventory_stocks");
        if (stored) {
          setInventoryStocks(JSON.parse(stored));
        }
      } catch (e) {}
    }
  };

  useEffect(() => {
    fetchInventory();
    window.addEventListener("vexa_inventory_updated", fetchInventory);
    window.addEventListener("vexa_items_updated", fetchInventory);
    return () => {
      window.removeEventListener("vexa_inventory_updated", fetchInventory);
      window.removeEventListener("vexa_items_updated", fetchInventory);
    };
  }, []);

  const handleRestockProduct = (productName: string, addQty: number) => {
    if (typeof window !== "undefined") {
      try {
        const current = { ...inventoryStocks };
        const newQty = (current[productName] !== undefined ? current[productName] : 15) + addQty;
        current[productName] = newQty;
        setInventoryStocks(current);
        localStorage.setItem("vexa_inventory_stocks", JSON.stringify(current));
        window.dispatchEvent(new Event("vexa_inventory_updated"));
        window.dispatchEvent(new Event("vexa_items_updated"));
      } catch (e) {
        console.warn("Restock error:", e);
      }
    }
  };

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

  const fetchOrders = async (isManual = false) => {
    if (isManual) setLoadingOrders(true);
    try {
      let fetchedList: OrderItem[] = [];
      const res = await fetch(`${API_URL}/orders`);
      if (res.ok) {
        const data = await res.json();
        fetchedList = Array.isArray(data) ? data : (data.data || []);
      }

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

      setOrders(() => {
        const map = new Map();

        // 1. Add all backend API orders
        fetchedList.forEach((item) => {
          const key = item._id || (item as any).id;
          const shortCode = String(key || "").slice(-8).toUpperCase();
          if (key && !deletedIds.includes(key) && !deletedIds.includes(shortCode)) {
            map.set(key, item);
          }
        });

        // 2. Overlay cached demo orders & user status updates (matched by ID, booking code, or email+amount)
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
    const handleOrdersUpdated = () => {
      fetchOrders();
    };
    window.addEventListener("vexa_orders_updated", handleOrdersUpdated);
    const interval = setInterval(() => {
      fetchOrders();
    }, 4000);
    return () => {
      window.removeEventListener("vexa_orders_updated", handleOrdersUpdated);
      clearInterval(interval);
    };
  }, []);

  const handleDeleteOrderAdmin = async (orderId: string, bookingIdStr: string) => {
    if (!window.confirm(`Are you sure you want to delete order booking record #${bookingIdStr}?`)) {
      return;
    }

    setOrders((prev) => prev.filter((o) => o._id !== orderId && o.id !== orderId));
    if (selectedOrderDetails && (selectedOrderDetails._id === orderId || (selectedOrderDetails as any).id === orderId)) {
      setSelectedOrderDetails(null);
    }

    if (typeof window !== "undefined") {
      try {
        const deletedIds = JSON.parse(localStorage.getItem("vexa_deleted_order_ids") || "[]");
        if (!deletedIds.includes(orderId)) {
          deletedIds.push(orderId);
          localStorage.setItem("vexa_deleted_order_ids", JSON.stringify(deletedIds));
        }

        const cached = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
        const updated = cached.filter((o: any) => o._id !== orderId && o.id !== orderId);
        localStorage.setItem("vexa_demo_orders", JSON.stringify(updated));
        window.dispatchEvent(new Event("vexa_orders_updated"));
      } catch (e) {
        console.warn("Failed to delete cached order:", e);
      }
    }

    try {
      await fetch(`${API_URL}/orders/${orderId}`, {
        method: "DELETE",
      });
    } catch (err) {
      console.warn("API delete order notice:", err);
    }

    setStatusUpdatedMsg(`Order #${bookingIdStr} deleted successfully.`);
    setTimeout(() => setStatusUpdatedMsg(""), 3500);
  };

  const [statusUpdatedMsg, setStatusUpdatedMsg] = useState("");

  // Cancellation Reason Modal State
  const [cancellingOrder, setCancellingOrder] = useState<{ id: string; currentStatus: string; bookingIdStr: string } | null>(null);
  const [cancelReasonPreset, setCancelReasonPreset] = useState("Item Out of Stock / Inventory Shortage");
  const [customCancelReason, setCustomCancelReason] = useState("");

  const handleStatusSelectChange = (orderId: string, newStatus: string, bookingIdStr: string) => {
    if (newStatus === "Cancelled") {
      setCancellingOrder({ id: orderId, currentStatus: newStatus, bookingIdStr });
      setCancelReasonPreset("Item Out of Stock / Inventory Shortage");
      setCustomCancelReason("");
    } else {
      handleUpdateStatus(orderId, newStatus);
    }
  };

  const handleConfirmCancellation = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!cancellingOrder) return;

    const finalReason =
      cancelReasonPreset === "Custom Reason"
        ? customCancelReason.trim() || "Administrative Cancellation"
        : cancelReasonPreset;

    await handleUpdateStatus(cancellingOrder.id, "Cancelled", finalReason);
    setCancellingOrder(null);
    setCancelReasonPreset("Item Out of Stock / Inventory Shortage");
    setCustomCancelReason("");
  };

  const handleUpdateStatus = async (orderId: string, newStatus: string, cancelReason = "") => {
    setOrders((prev) =>
      prev.map((o) =>
        o._id === orderId || o.id === orderId
          ? { ...o, status: newStatus as any, cancelReason }
          : o
      )
    );

    if (selectedOrderDetails && (selectedOrderDetails._id === orderId || (selectedOrderDetails as any).id === orderId)) {
      setSelectedOrderDetails((prev) => (prev ? { ...prev, status: newStatus as any, cancelReason } : null));
    }

    setStatusUpdatedMsg(`Booking #${String(orderId).slice(-8).toUpperCase()} status updated to "${newStatus}"!`);
    setTimeout(() => setStatusUpdatedMsg(""), 3500);

    // Sync status update to local demo orders in localStorage & dispatch update event
    if (typeof window !== "undefined") {
      try {
        const cached = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
        const updated = cached.map((o: any) =>
          o._id === orderId || o.id === orderId ? { ...o, status: newStatus, cancelReason } : o
        );
        localStorage.setItem("vexa_demo_orders", JSON.stringify(updated));
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
    <div className="min-h-screen bg-background">
      <div className="mx-auto max-w-7xl px-3 sm:px-4 py-4 sm:py-6">
        <div className={`grid gap-6 lg:gap-8 items-start transition-all duration-300 ${sidebarCollapsed ? "lg:grid-cols-[84px_1fr]" : "lg:grid-cols-[300px_1fr]"}`}>
          {/* MOBILE ADMIN HEADER (< lg) */}
          <div className="lg:hidden space-y-3 sticky top-2 z-30 bg-background/95 backdrop-blur-md pb-2">
            <div className="flex items-center justify-between rounded-xl border border-gold/40 bg-card p-4 shadow-sm">
              <div className="flex items-center gap-3 shrink-0">
                <div className="flex size-10 items-center justify-center rounded-[10px] bg-black text-gold font-extrabold text-xl leading-none shadow-md border border-gold/40 shrink-0">
                  V
                </div>
                <div className="flex flex-col justify-center space-y-1">
                  <span className="font-display text-base font-extrabold tracking-[0.25em] text-gold leading-none">
                    V E X A
                  </span>
                  <span className="text-[8px] uppercase tracking-[0.28em] text-muted-foreground font-semibold leading-none">
                    WEAR CONFIDENCE
                  </span>
                </div>
              </div>

              <button
                type="button"
                onClick={() => setMobileNavOpen(!mobileNavOpen)}
                className="flex size-9 items-center justify-center rounded-lg border border-gold/50 bg-gold/15 text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer shadow-goldy shrink-0"
                title="Toggle Admin Menu"
              >
                <Menu className="size-5" />
              </button>
            </div>

            {/* Custom Mobile Dropdown Menu */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setMobileNavOpen(!mobileNavOpen)}
                className="flex w-full items-center justify-between rounded-xl border border-gold/50 bg-card py-3.5 px-4 text-xs font-bold uppercase tracking-wider text-foreground shadow-goldy transition-all hover:border-gold cursor-pointer"
              >
                <div className="flex items-center gap-2.5">
                  <Menu className="size-4 text-gold shrink-0" />
                  <span>
                    {adminTabsList.find((t) => t.id === activeTab)?.label || "Admin Menu"}
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
                        className={`flex w-full items-center justify-between rounded-lg px-3.5 py-3 text-xs font-bold uppercase tracking-wider transition-all cursor-pointer ${
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
          <aside className={`hidden lg:block sticky top-6 h-fit rounded-xl border border-gold/40 bg-card p-4 sm:p-5 shadow-goldy transition-all duration-300 ${sidebarCollapsed ? "w-[84px] text-center" : "w-full"}`}>
            <div className={`flex items-center border-b border-border pb-5 gap-3 ${sidebarCollapsed ? "justify-center" : "justify-between"}`}>
              {!sidebarCollapsed ? (
                <>
                  <div className="flex items-center gap-3 shrink-0 overflow-hidden">
                    <div className="flex size-10 items-center justify-center rounded-[10px] bg-black text-gold font-extrabold text-xl leading-none shadow-md border border-gold/40 shrink-0">
                      V
                    </div>
                    <div className="flex flex-col justify-center overflow-hidden space-y-1">
                      <span className="font-display text-base font-extrabold tracking-[0.25em] text-gold leading-none truncate">
                        V E X A
                      </span>
                      <span className="text-[8px] uppercase tracking-[0.28em] text-muted-foreground font-semibold leading-none truncate">
                        WEAR CONFIDENCE
                      </span>
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
                    className="flex size-10 items-center justify-center rounded-lg border border-gold/50 bg-gold/15 text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer shadow-goldy shrink-0"
                    title="Collapse Admin Panel Sidebar"
                  >
                    <Menu className="size-5" />
                  </button>
                </>
              ) : (
                <div className="flex flex-col items-center gap-2">
                  <div className="flex size-10 items-center justify-center rounded-[10px] bg-black text-gold font-extrabold text-xl leading-none shadow-md border border-gold/40 shrink-0">
                    V
                  </div>
                  <button
                    type="button"
                    onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
                    className="flex size-8 items-center justify-center rounded-lg border border-gold/50 bg-gold/15 text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer shadow-goldy shrink-0 mt-1"
                    title="Expand Admin Panel Sidebar"
                  >
                    <Menu className="size-4" />
                  </button>
                </div>
              )}
            </div>

            <nav className="mt-5 space-y-1.5">
              {adminTabsList.map((t) => {
                const Icon = t.icon;
                const isSelected = activeTab === t.id && !t.isLogout;
                return (
                  <button
                    key={t.id}
                    type="button"
                    title={t.label}
                    onClick={() => {
                      if (t.isLogout) {
                        logout();
                      } else {
                        setActiveTab(t.id as any);
                      }
                    }}
                    className={`flex w-full items-center rounded-lg py-3 text-[11px] font-semibold uppercase tracking-wider whitespace-nowrap transition-all cursor-pointer ${
                      sidebarCollapsed ? "justify-center px-0" : "justify-between px-3.5"
                    } ${
                      t.isLogout
                        ? "text-muted-foreground hover:bg-destructive/15 hover:text-destructive mt-3 pt-3 border-t border-border/60"
                        : isSelected
                        ? "bg-gold text-primary-foreground shadow-goldy font-bold"
                        : "text-muted-foreground hover:bg-surface hover:text-gold"
                    }`}
                  >
                    <div className="flex items-center gap-2.5 whitespace-nowrap">
                      <Icon className="size-4 shrink-0" />
                      {!sidebarCollapsed && <span>{t.label}</span>}
                    </div>
                  </button>
                );
              })}
            </nav>
          </aside>

          {/* MAIN CONTENT AREA */}
          <main className="min-h-[500px] rounded-xl border border-border bg-card p-4 sm:p-8 shadow-sm lg:max-h-[calc(100vh-48px)] lg:overflow-y-auto">
            {/* TAB: INVENTORY MANAGEMENT */}
            {activeTab === "inventory" && (
              <div className="space-y-8 animate-in fade-in duration-300">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-4">
                  <div>
                    <span className="text-[10px] uppercase tracking-widest text-gold font-bold">Stock Control Panel</span>
                    <h2 className="font-display text-2xl font-semibold text-foreground">Inventory & Warehouse Management</h2>
                    <p className="text-xs text-muted-foreground mt-1">Track warehouse stock levels, low-stock warnings, and update product quantities live.</p>
                  </div>
                  {stockUpdatedMsg && (
                    <span className="rounded-md bg-emerald-500/15 border border-emerald-500/40 px-3 py-1.5 text-xs font-bold text-emerald-400 animate-in fade-in">
                      ✓ {stockUpdatedMsg}
                    </span>
                  )}
                </div>

                {/* Stock KPI Summary Cards */}
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  <div className="rounded-xl border border-gold/40 bg-gold/10 p-5 shadow-sm">
                    <span className="text-[10px] uppercase tracking-wider text-gold font-bold">Total Catalog Products</span>
                    <p className="font-display text-2xl font-bold text-foreground mt-1">{catalogProducts.length} Items</p>
                  </div>
                  <div className="rounded-xl border border-emerald-500/40 bg-emerald-500/10 p-5 shadow-sm">
                    <span className="text-[10px] uppercase tracking-wider text-emerald-400 font-bold">In Stock Items</span>
                    <p className="font-display text-2xl font-bold text-emerald-400 mt-1">
                      {catalogProducts.filter((p) => (stockMap[p.id] ?? 25) > 10).length} Items
                    </p>
                  </div>
                  <div className="rounded-xl border border-amber-500/40 bg-amber-500/10 p-5 shadow-sm">
                    <span className="text-[10px] uppercase tracking-wider text-amber-400 font-bold">Low Stock Warning</span>
                    <p className="font-display text-2xl font-bold text-amber-400 mt-1">
                      {catalogProducts.filter((p) => (stockMap[p.id] ?? 25) >= 1 && (stockMap[p.id] ?? 25) <= 10).length} Items
                    </p>
                  </div>
                  <div className="rounded-xl border border-rose-500/40 bg-rose-500/10 p-5 shadow-sm">
                    <span className="text-[10px] uppercase tracking-wider text-rose-400 font-bold">Out of Stock</span>
                    <p className="font-display text-2xl font-bold text-rose-400 mt-1">
                      {catalogProducts.filter((p) => (stockMap[p.id] ?? 25) === 0).length} Items
                    </p>
                  </div>
                </div>

                {/* Search Bar */}
                <div className="flex items-center justify-between gap-4">
                  <div className="relative flex-1 max-w-md">
                    <Search className="absolute left-3.5 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground" />
                    <input
                      type="text"
                      value={inventorySearch}
                      onChange={(e) => setInventorySearch(e.target.value)}
                      placeholder="Search inventory by title or category..."
                      className="w-full rounded-sm border border-border bg-card py-2.5 pl-9 pr-3 text-xs outline-none focus:border-gold"
                    />
                  </div>
                </div>

                {/* Inventory Table */}
                <div className="space-y-3">
                  {catalogProducts
                    .filter((p) =>
                      p.name.toLowerCase().includes(inventorySearch.toLowerCase()) ||
                      p.category.toLowerCase().includes(inventorySearch.toLowerCase())
                    )
                    .map((item) => {
                      const qty = stockMap[item.id] ?? 25;
                      const isOut = qty === 0;
                      const isLow = qty > 0 && qty <= 10;

                      return (
                        <div
                          key={item.id}
                          className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 rounded-xl border border-border bg-card p-4 shadow-sm hover:border-gold/50 transition-all"
                        >
                          <div className="flex items-center gap-4">
                            <img
                              src={item.image}
                              alt={item.name}
                              className="size-16 rounded-lg object-cover border border-border shrink-0"
                            />
                            <div>
                              <div className="flex items-center gap-2">
                                <h4 className="font-display text-sm font-bold text-foreground">{item.name}</h4>
                                <span className="rounded-full bg-gold/15 px-2.5 py-0.5 text-[9px] font-bold uppercase tracking-wider text-gold border border-gold/30">
                                  {item.category}
                                </span>
                              </div>
                              <p className="text-xs text-muted-foreground mt-0.5">
                                Price: <span className="font-bold text-gold">₹{item.price.toLocaleString("en-IN")}</span>
                              </p>
                              <div className="mt-1.5 flex items-center gap-2">
                                <span
                                  className={`rounded-md px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider ${
                                    isOut
                                      ? "bg-rose-500/20 text-rose-400 border border-rose-500/40"
                                      : isLow
                                      ? "bg-amber-500/20 text-amber-400 border border-amber-500/40"
                                      : "bg-emerald-500/20 text-emerald-400 border border-emerald-500/40"
                                  }`}
                                >
                                  {isOut ? "🔴 Out of Stock" : isLow ? "🟡 Low Stock Warning" : "🟢 In Stock"}
                                </span>
                                <span className="text-xs font-bold text-foreground">({qty} units)</span>
                              </div>
                            </div>
                          </div>

                          {/* Stock Quantity Direct Input Control */}
                          <div className="flex items-center gap-2 shrink-0 border-t sm:border-t-0 pt-3 sm:pt-0 border-border">
                            <input
                              type="number"
                              min={0}
                              value={qty}
                              onChange={(e) => handleUpdateStock(item.id, Math.max(0, Number(e.target.value)))}
                              className="w-20 rounded-lg border border-gold/50 bg-background py-1.5 px-3 text-center font-display text-sm font-bold text-gold outline-none focus:border-gold focus:ring-1 focus:ring-gold/30 shadow-xs"
                              placeholder="0"
                              title="Stock Quantity"
                            />
                          </div>
                        </div>
                      );
                    })}
                </div>
              </div>
            )}

            {/* TAB: CATEGORY MANAGER */}
            {activeTab === "categories" && (
              <div className="space-y-8 animate-in fade-in duration-300">
                <div className="border-b border-border pb-4">
                  <span className="text-[10px] uppercase tracking-widest text-gold font-bold">Catalog Taxonomy</span>
                  <h2 className="font-display text-2xl font-semibold text-foreground">Category Manager & Custom Collections</h2>
                  <p className="text-xs text-muted-foreground mt-1">Add new product categories dynamically for assigning collection items and organizing the store.</p>
                </div>

                {catMsg && (
                  <div className="rounded-lg border border-gold/40 bg-gold/10 p-4 text-xs font-bold text-gold">
                    ✓ {catMsg}
                  </div>
                )}

                {/* ADD NEW CATEGORY FORM */}
                <form onSubmit={handleAddCategory} className="rounded-xl border border-gold/40 bg-card p-6 shadow-sm space-y-4">
                  <h3 className="font-display text-base font-bold text-foreground">Add New Category</h3>
                  <div className="flex flex-col sm:flex-row gap-3">
                    <input
                      type="text"
                      value={newCatInput}
                      onChange={(e) => setNewCatInput(e.target.value)}
                      placeholder="e.g. Acid Wash Drops, Heavyweight Hoodies, Winter Wear..."
                      className="flex-1 rounded-sm border border-border bg-background px-4 py-3 text-xs outline-none focus:border-gold text-foreground"
                    />
                    <button
                      type="submit"
                      className="btn-gold hover:btn-gold-hover rounded-sm px-6 py-3 text-xs font-bold uppercase tracking-wider shrink-0 cursor-pointer"
                    >
                      + Add Category
                    </button>
                  </div>
                </form>

                {/* CATEGORIES GRID */}
                <div className="space-y-4">
                  <h3 className="font-display text-base font-bold text-foreground">Active Catalog Categories ({categoriesList.length})</h3>
                  <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                    {categoriesList.map((catName) => {
                      const count = catalogProducts.filter((p) => p.category.toLowerCase() === catName.toLowerCase()).length;
                      const isEditingThis = editingCatName === catName;

                      return (
                        <div
                          key={catName}
                          className="flex items-center justify-between gap-3 rounded-xl border border-border bg-card p-4 shadow-sm hover:border-gold/60 transition-all"
                        >
                          {isEditingThis ? (
                            <div className="flex items-center gap-2 w-full">
                              <input
                                type="text"
                                value={editingCatValue}
                                onChange={(e) => setEditingCatValue(e.target.value)}
                                className="flex-1 rounded-sm border border-gold bg-background px-3 py-1.5 text-xs font-bold text-foreground outline-none"
                                autoFocus
                              />
                              <button
                                type="button"
                                onClick={() => handleSaveEditCategory(catName)}
                                className="rounded-sm bg-gold px-2.5 py-1.5 text-xs font-bold text-primary-foreground hover:bg-amber-400 cursor-pointer shadow-sm"
                                title="Save Category"
                              >
                                <Check className="size-4" />
                              </button>
                              <button
                                type="button"
                                onClick={() => setEditingCatName(null)}
                                className="rounded-sm border border-border bg-surface px-2.5 py-1.5 text-xs font-bold text-muted-foreground hover:text-foreground cursor-pointer"
                                title="Cancel"
                              >
                                <X className="size-4" />
                              </button>
                            </div>
                          ) : (
                            <>
                              <div>
                                <span className="font-display text-sm font-bold text-foreground block">{catName}</span>
                                <span className="text-[11px] text-muted-foreground">{count} items in collection</span>
                              </div>
                              <div className="flex items-center gap-1 shrink-0">
                                <button
                                  type="button"
                                  onClick={() => handleStartEditCategory(catName)}
                                  className="text-xs font-bold text-muted-foreground hover:text-gold transition-colors cursor-pointer p-1.5 rounded-md hover:bg-gold/10"
                                  title="Edit category name"
                                >
                                  <Edit className="size-4" />
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleDeleteCategory(catName)}
                                  className="text-xs font-bold text-muted-foreground hover:text-destructive transition-colors cursor-pointer p-1.5 rounded-md hover:bg-destructive/10"
                                  title="Delete category"
                                >
                                  <Trash2 className="size-4" />
                                </button>
                              </div>
                            </>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            )}

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

            {/* TAB 2: MANAGE CUSTOMER BOOKINGS */}
            {activeTab === "orders" && (
              selectedOrderDetails ? (
                <div className="space-y-6 animate-in fade-in duration-300">
                  {/* Sub-page Navigation Header (Hidden on Print) */}
                  <div className="flex items-center justify-between border-b border-border pb-4 no-print">
                    <button
                      type="button"
                      onClick={() => setSelectedOrderDetails(null)}
                      className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-gold hover:underline cursor-pointer"
                    >
                      <ArrowLeft className="size-4" /> Back to Customer Bookings
                    </button>
                    <span className="rounded-full bg-gold/15 px-3 py-1 text-[10px] font-bold text-gold uppercase tracking-wider border border-gold/30">
                      Order Details Inspection
                    </span>
                  </div>

                  {/* Order Details Main Printable Invoice Container */}
                  <div className="printable-invoice-box rounded-xl border border-gold/40 bg-card p-6 shadow-goldy space-y-6">
                    {/* Printable Official Brand Logo Header */}
                    <div className="flex items-center justify-between border-b border-border pb-4">
                      <div className="flex items-center gap-3">
                        <div className="flex size-10 items-center justify-center rounded-[10px] bg-black text-gold font-extrabold text-xl leading-none shadow-md border border-gold/40 shrink-0">
                          V
                        </div>
                        <div className="flex flex-col justify-center space-y-0.5">
                          <span className="font-display text-base font-extrabold tracking-[0.25em] text-gold leading-none">
                            V E X A
                          </span>
                          <span className="text-[8px] uppercase tracking-[0.28em] text-muted-foreground font-semibold leading-none">
                            WEAR CONFIDENCE
                          </span>
                        </div>
                      </div>

                      <div className="text-right">
                        <span className="text-[10px] uppercase tracking-widest text-gold font-extrabold block">Official Tax Invoice</span>
                        <span className="text-[11px] font-bold text-foreground font-mono">
                          INV-{String(selectedOrderDetails._id || (selectedOrderDetails as any).id || "ORD").slice(-8).toUpperCase()}
                        </span>
                      </div>
                    </div>

                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-4">
                      <div>
                        <span className="text-[10px] uppercase tracking-widest text-gold font-bold">Booking Reference</span>
                        <h2 className="font-display text-2xl font-bold text-foreground mt-0.5">
                          Booking #{String(selectedOrderDetails._id || (selectedOrderDetails as any).id || "ORD").slice(-8).toUpperCase()}
                        </h2>
                        <p className="text-xs text-muted-foreground mt-1">
                          Placed on: {new Date(selectedOrderDetails.createdAt || Date.now()).toLocaleDateString("en-IN", { day: "numeric", month: "long", year: "numeric", hour: "2-digit", minute: "2-digit" })}
                        </p>
                      </div>

                      {/* Shipment Status Selector (On Screen) & Status Badge (On Print) */}
                      <div className="flex items-center gap-3">
                        <span className="text-xs text-muted-foreground font-semibold">Shipment Status:</span>
                        <div className="no-print">
                          <select
                            value={selectedOrderDetails.status || "Processing"}
                            onChange={(e) => {
                              const newStatus = e.target.value as any;
                              handleStatusSelectChange(
                                selectedOrderDetails._id,
                                newStatus,
                                String(selectedOrderDetails._id || (selectedOrderDetails as any).id || "ORD").slice(-8).toUpperCase()
                              );
                            }}
                            className={`rounded-lg border px-3 py-2 text-xs font-bold outline-none cursor-pointer ${
                              selectedOrderDetails.status === "Delivered"
                                ? "border-emerald-500/50 bg-emerald-500/10 text-emerald-600"
                                : selectedOrderDetails.status === "Shipped"
                                ? "border-blue-500/50 bg-blue-500/10 text-blue-600"
                                : selectedOrderDetails.status === "Cancelled"
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
                        <span className="hidden print:inline-block rounded-full bg-gold/15 px-3 py-1 text-xs font-bold text-gold border border-gold/40">
                          {selectedOrderDetails.status || "Processing"}
                        </span>
                      </div>
                    </div>

                    {selectedOrderDetails.status === "Cancelled" && (
                      <div className="rounded-lg border border-destructive/40 bg-destructive/10 p-4 text-xs space-y-1">
                        <p className="font-bold text-destructive text-sm flex items-center gap-2">
                          <X className="size-4" /> Order Cancelled by Administrator
                        </p>
                        <p className="text-foreground">
                          Reason for Cancellation:{" "}
                          <span className="font-bold text-destructive">
                            {selectedOrderDetails.cancelReason || (selectedOrderDetails as any).cancelReason || "Item Out of Stock / Administrative Cancellation"}
                          </span>
                        </p>
                      </div>
                    )}

                    {/* Customer Info & Shipping Address Grid */}
                    <div className="grid gap-6 sm:grid-cols-2 text-xs">
                      <div className="rounded-lg border border-border/80 bg-surface/50 p-4 space-y-2">
                        <span className="text-[10px] uppercase tracking-wider text-gold font-bold">Customer Account Details</span>
                        <p className="font-bold text-foreground text-sm">{selectedOrderDetails.userName || "Customer Name"}</p>
                        <p className="text-muted-foreground">Email: <span className="text-foreground font-semibold">{selectedOrderDetails.userEmail}</span></p>
                        <p className="text-muted-foreground">Account Type: <span className="text-gold font-bold">Verified Buyer</span></p>
                      </div>

                      <div className="rounded-lg border border-border/80 bg-surface/50 p-4 space-y-2">
                        <span className="text-[10px] uppercase tracking-wider text-gold font-bold">Delivery & Payment Info</span>
                        <p className="text-muted-foreground"><span className="font-bold text-foreground">Delivery Address:</span> {selectedOrderDetails.shippingAddress}</p>
                        <p className="text-muted-foreground"><span className="font-bold text-foreground">Payment Method:</span> {selectedOrderDetails.paymentMethod}</p>
                        <p className="text-muted-foreground"><span className="font-bold text-foreground">Payment Status:</span> <span className="text-emerald-500 font-bold">✓ Confirmed</span></p>
                      </div>
                    </div>

                    {/* Booked Products Breakdown */}
                    <div className="space-y-3 pt-2">
                      <h3 className="font-display text-base font-bold text-foreground">Booked Products Breakdown</h3>
                      <div className="space-y-3">
                        {(selectedOrderDetails.items || []).map((item, idx) => (
                          <div
                            key={idx}
                            className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 rounded-xl border border-border/80 bg-surface/40 p-4"
                          >
                            <div className="flex items-center gap-4">
                              <img
                                src={item?.image || ""}
                                alt={item?.name || "Product"}
                                className="size-14 rounded-lg object-cover border border-border shrink-0"
                              />
                              <div>
                                <h4 className="font-display text-sm font-bold text-foreground">{item?.name || "Product Tee"}</h4>
                                <p className="text-xs text-muted-foreground mt-0.5">
                                  Size: <span className="text-gold font-bold">{item?.size || "M"}</span> • Color: <span className="text-foreground font-semibold">{item?.color || "Standard"}</span>
                                </p>
                                <p className="text-xs text-muted-foreground mt-0.5">
                                  Quantity: <span className="font-bold text-foreground">{item?.quantity || 1}</span> × ₹{(item?.price || 0).toLocaleString("en-IN")}
                                </p>
                              </div>
                            </div>
                            <div className="text-right shrink-0">
                              <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold block">Item Total</span>
                              <span className="font-bold text-gold text-base">
                                ₹{((item?.price || 0) * (item?.quantity || 1)).toLocaleString("en-IN")}
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Total Amount Breakdown */}
                    <div className="rounded-lg border border-gold/40 bg-gold/10 p-4 space-y-2 text-xs">
                      <div className="flex justify-between text-muted-foreground">
                        <span>Items Subtotal:</span>
                        <span className="text-foreground font-semibold">₹{(selectedOrderDetails.totalAmount || 0).toLocaleString("en-IN")}</span>
                      </div>
                      <div className="flex justify-between text-muted-foreground">
                        <span>Express Pan-India Shipping:</span>
                        <span className="text-gold font-bold">FREE</span>
                      </div>
                      <div className="flex justify-between border-t border-gold/30 pt-2 text-base font-bold text-foreground">
                        <span>Total Payable Amount:</span>
                        <span className="text-gold">₹{(selectedOrderDetails.totalAmount || 0).toLocaleString("en-IN")}</span>
                      </div>
                    </div>

                    {/* Printable Official Footer Note */}
                    <div className="hidden print:block border-t border-border pt-4 text-center text-[10px] text-muted-foreground space-y-1">
                      <p className="font-bold text-foreground">Thank you for your order with VEXA Luxury Apparel</p>
                      <p>For support or inquiries, visit <span className="text-gold font-semibold">www.vexa.store</span> or email <span className="text-gold font-semibold">support@vexa.store</span></p>
                    </div>

                    {/* On-Screen Action Controls (Hidden on Print) */}
                    <div className="flex items-center gap-3 pt-2 no-print">
                      <button
                        type="button"
                        onClick={() => setSelectedOrderDetails(null)}
                        className="btn-outline-gold rounded-sm px-6 py-3 text-xs font-bold uppercase tracking-wider cursor-pointer"
                      >
                        ← Back to Customer Bookings
                      </button>
                      <button
                        type="button"
                        onClick={() => window.print()}
                        className="btn-gold hover:btn-gold-hover flex-1 rounded-sm py-3 text-xs font-bold uppercase tracking-wider cursor-pointer shadow-sm"
                      >
                        🖨️ Print Order Invoice
                      </button>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="space-y-6">
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between border-b border-border pb-4">
                    <div>
                      <h2 className="font-display text-2xl font-semibold text-foreground">Manage Customer Bookings</h2>
                      <p className="text-xs text-muted-foreground mt-1">Review orders placed across the system and update shipment status. Click any product item to view full order details.</p>
                    </div>

                    <button
                      onClick={() => fetchOrders(true)}
                      className="flex items-center gap-2 rounded-sm border border-gold/40 bg-gold/10 px-4 py-2 text-xs font-semibold text-gold transition-colors hover:bg-gold hover:text-primary-foreground shadow-sm w-fit cursor-pointer"
                    >
                      <RefreshCw className={`size-3.5 ${loadingOrders ? "animate-spin" : ""}`} /> Refresh Orders
                    </button>
                  </div>

                  {statusUpdatedMsg && (
                    <div className="flex items-center gap-3 rounded-lg border border-gold/40 bg-gold/10 p-4 text-xs text-gold font-semibold animate-in fade-in duration-300">
                      <CheckCircle2 className="size-5 shrink-0" />
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
                                <button
                                  type="button"
                                  onClick={() => setSelectedOrderDetails(ord)}
                                  className="text-[10px] font-bold text-gold hover:underline uppercase tracking-wider ml-2 cursor-pointer"
                                >
                                  View Details →
                                </button>
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
                                onChange={(e) =>
                                  handleStatusSelectChange(
                                    ord._id,
                                    e.target.value,
                                    String(ord._id || ord.id || "ORD").slice(-8).toUpperCase()
                                  )
                                }
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

                          {ord.status === "Cancelled" && (ord.cancelReason || (ord as any).cancelReason) && (
                            <div className="text-xs text-destructive bg-destructive/10 border border-destructive/30 rounded-lg p-2.5 font-semibold flex items-center gap-2">
                              <span>❌ Reason for Cancellation:</span>
                              <span className="font-bold">{ord.cancelReason || (ord as any).cancelReason}</span>
                            </div>
                          )}

                          {/* Items List */}
                          <div className="space-y-3 pt-1">
                            <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                              Booked Items (Click product to view order details)
                            </span>
                            {(ord.items || []).map((item, idx) => (
                              <div
                                key={idx}
                                onClick={() => setSelectedOrderDetails(ord)}
                                className="flex items-center justify-between gap-4 rounded-lg border border-border/70 bg-surface/50 p-3 text-xs cursor-pointer hover:border-gold hover:bg-gold/10 transition-all group"
                              >
                                <div className="flex items-center gap-3">
                                  {item && item.image ? (
                                    <img
                                      src={item.image}
                                      alt={item.name || "Item"}
                                      className="size-12 rounded-md object-cover border border-border shrink-0 group-hover:scale-105 transition-transform"
                                    />
                                  ) : (
                                    <div className="size-12 rounded-md bg-gold/10 border border-gold/30 flex items-center justify-center text-gold font-bold text-[10px]">
                                      TEE
                                    </div>
                                  )}
                                  <div>
                                    <h5 className="font-display font-semibold text-foreground group-hover:text-gold transition-colors">{item?.name || "Oversized Tee"}</h5>
                                    <p className="text-[11px] text-muted-foreground">
                                      Size: <span className="text-gold font-bold">{item?.size || "M"}</span> • Color: {item?.color || "Standard"} • Qty: {item?.quantity || 1}
                                    </p>
                                  </div>
                                </div>
                                <div className="flex items-center gap-3">
                                  <span className="font-semibold text-foreground">
                                    ₹{((item?.price || 0) * (item?.quantity || 1)).toLocaleString("en-IN")}
                                  </span>
                                  <span className="text-[10px] font-bold text-gold opacity-0 group-hover:opacity-100 transition-opacity">
                                    View Details →
                                  </span>
                                </div>
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
              )
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
                        <div className="flex items-center justify-between">
                          <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Category</label>
                          <button
                            type="button"
                            onClick={() => setActiveTab("categories")}
                            className="text-[10px] font-bold text-gold hover:underline uppercase tracking-wider cursor-pointer"
                          >
                            + Add Category
                          </button>
                        </div>
                        <select
                          value={newItemCategory}
                          onChange={(e) => setNewItemCategory(e.target.value)}
                          className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs outline-none focus:border-gold"
                        >
                          {categoriesList.map((cat) => (
                            <option key={cat} value={cat}>
                              {cat}
                            </option>
                          ))}
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
                                <span className="rounded-full bg-[#f4efe6] px-2.5 py-0.5 text-[9px] font-extrabold uppercase tracking-wider text-[#1c1917] border border-gold/60 shadow-xs">
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

                          {/* Right Section: Action Buttons */}
                          <div className="flex items-center gap-2 shrink-0 border-t sm:border-t-0 pt-3 sm:pt-0 border-border">
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
                    <p className="text-xs text-muted-foreground mt-1">Users registered in system database. Click any user row to view complete account details & booking history.</p>
                  </div>
                  <button
                    onClick={fetchUsers}
                    className="flex items-center gap-2 rounded-sm border border-gold/40 bg-gold/10 px-3.5 py-2 text-xs font-semibold text-gold transition-colors hover:bg-gold hover:text-primary-foreground shadow-xs cursor-pointer"
                  >
                    <RefreshCw className={`size-3.5 ${loadingUsers ? "animate-spin" : ""}`} /> Refresh Users
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
                        <th className="p-4 text-right">Account Details</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {usersList.length > 0 ? (
                        usersList.map((u) => (
                          <tr
                            key={u._id}
                            onClick={() => setSelectedUserDetails(u)}
                            className="hover:bg-gold/10 transition-colors cursor-pointer group"
                          >
                            <td className="p-4 font-semibold text-foreground group-hover:text-gold transition-colors">
                              <div className="flex items-center gap-2.5">
                                <div className="flex size-7 items-center justify-center rounded-full bg-gold/15 text-gold font-bold text-xs border border-gold/30">
                                  {u.name ? u.name.charAt(0).toUpperCase() : "U"}
                                </div>
                                <span>{u.name}</span>
                              </div>
                            </td>
                            <td className="p-4 text-muted-foreground font-mono">{u.email}</td>
                            <td className="p-4 font-bold uppercase">
                              <span className={`rounded-full px-2.5 py-0.5 text-[9px] ${
                                u.role === "admin" ? "bg-gold text-primary-foreground shadow-goldy" : "bg-gold/15 text-gold border border-gold/30"
                              }`}>
                                {u.role || "user"}
                              </span>
                            </td>
                            <td className="p-4 text-muted-foreground">
                              {new Date(u.createdAt).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                            </td>
                            <td className="p-4 text-right">
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setSelectedUserDetails(u);
                                }}
                                className="text-xs font-bold text-gold hover:underline uppercase tracking-wider cursor-pointer"
                              >
                                View Details →
                              </button>
                            </td>
                          </tr>
                        ))
                      ) : (
                        <tr>
                          <td colSpan={5} className="p-8 text-center text-muted-foreground">
                            No registered users found in the system.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
            {/* TAB: PROMO COUPONS */}
            {activeTab === "coupons" && (
              <div className="space-y-6">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-4">
                  <div>
                    <h2 className="font-display text-2xl font-semibold text-foreground">Promo Coupons & Discounts</h2>
                    <p className="text-xs text-muted-foreground mt-1">Create, activate, or manage discount codes for checkout.</p>
                  </div>
                  {couponMsg && (
                    <span className="rounded-md bg-emerald-500/15 border border-emerald-500/40 px-3 py-1.5 text-xs font-bold text-emerald-400 animate-in fade-in">
                      ✓ {couponMsg}
                    </span>
                  )}
                </div>

                {/* Create Coupon Form */}
                <form onSubmit={handleAddCoupon} className="rounded-xl border border-gold/40 bg-card p-5 shadow-xs space-y-4">
                  <h3 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">Create New Promo Code</h3>
                  <div className="grid gap-4 sm:grid-cols-3">
                    <div>
                      <label className="block text-[10px] font-bold uppercase tracking-wider text-muted-foreground mb-1">Coupon Code</label>
                      <input
                        type="text"
                        value={newCouponCode}
                        onChange={(e) => setNewCouponCode(e.target.value)}
                        placeholder="e.g. VEXA50"
                        className="w-full rounded-sm border border-border bg-background px-3.5 py-2 text-xs font-bold uppercase tracking-wider outline-none focus:border-gold"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] font-bold uppercase tracking-wider text-muted-foreground mb-1">Discount Offer</label>
                      <input
                        type="text"
                        value={newCouponDiscount}
                        onChange={(e) => setNewCouponDiscount(e.target.value)}
                        placeholder="e.g. 20% OFF or ₹200 OFF"
                        className="w-full rounded-sm border border-border bg-background px-3.5 py-2 text-xs outline-none focus:border-gold"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] font-bold uppercase tracking-wider text-muted-foreground mb-1">Min Order Amount (₹)</label>
                      <input
                        type="number"
                        value={newCouponMinOrder}
                        onChange={(e) => setNewCouponMinOrder(e.target.value)}
                        placeholder="e.g. 1499"
                        className="w-full rounded-sm border border-border bg-background px-3.5 py-2 text-xs outline-none focus:border-gold"
                      />
                    </div>
                  </div>
                  <button
                    type="submit"
                    className="flex items-center gap-2 rounded-md bg-gold px-5 py-2.5 text-xs font-bold text-primary-foreground hover:bg-amber-400 cursor-pointer shadow-goldy"
                  >
                    <Plus className="size-4" />
                    <span>Create Promo Coupon</span>
                  </button>
                </form>

                {/* Coupons List */}
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                  {couponsList.map((c) => (
                    <div key={c.code} className="rounded-xl border border-border bg-card p-5 shadow-xs space-y-3 relative">
                      <div className="flex items-center justify-between">
                        <span className="font-mono text-base font-extrabold text-gold uppercase tracking-wider bg-gold/15 px-3 py-1 rounded-md border border-gold/40">
                          {c.code}
                        </span>
                        <span className={`text-[10px] font-extrabold uppercase tracking-widest px-2.5 py-1 rounded-full border ${
                          c.active ? "bg-emerald-500/15 border-emerald-500/40 text-emerald-400" : "bg-muted/40 border-border text-muted-foreground"
                        }`}>
                          {c.active ? "ACTIVE" : "DISABLED"}
                        </span>
                      </div>
                      <div>
                        <p className="font-display text-lg font-bold text-foreground">{c.discount}</p>
                        <p className="text-xs text-muted-foreground mt-0.5">Min Order: ₹{c.minOrder.toLocaleString("en-IN")}</p>
                        <p className="text-[11px] text-gold/90 font-semibold mt-1">Used {c.usageCount} times</p>
                      </div>
                      <div className="flex items-center justify-between pt-2 border-t border-border/40">
                        <button
                          type="button"
                          onClick={() => handleToggleCoupon(c.code)}
                          className="text-xs font-bold text-gold hover:underline cursor-pointer"
                        >
                          {c.active ? "Disable Code" : "Enable Code"}
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDeleteCoupon(c.code)}
                          className="p-1.5 rounded-md border border-destructive/40 bg-destructive/10 text-destructive hover:bg-destructive hover:text-white transition-all cursor-pointer"
                          title="Delete Coupon"
                        >
                          <Trash2 className="size-3.5" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* TAB: CUSTOMER REVIEWS */}
            {activeTab === "reviews" && (
              <div className="space-y-6">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-4">
                  <div>
                    <h2 className="font-display text-2xl font-semibold text-foreground">Customer Reviews & Ratings</h2>
                    <p className="text-xs text-muted-foreground mt-1">Moderate customer testimonials and feature top reviews on store home page.</p>
                  </div>
                  {reviewMsg && (
                    <span className="rounded-md bg-emerald-500/15 border border-emerald-500/40 px-3 py-1.5 text-xs font-bold text-emerald-400 animate-in fade-in">
                      ✓ {reviewMsg}
                    </span>
                  )}
                </div>

                <div className="space-y-4">
                  {reviewsList.map((r) => (
                    <div key={r.id} className="rounded-xl border border-border bg-card p-5 shadow-xs space-y-3">
                      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-border/40 pb-3">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-display text-sm font-bold text-foreground">{r.author}</span>
                            <span className="text-[10px] text-muted-foreground">• {r.date}</span>
                          </div>
                          <p className="text-xs text-gold font-medium mt-0.5">Product: {r.productName}</p>
                        </div>
                        <div className="flex items-center gap-1 text-gold">
                          {Array.from({ length: 5 }).map((_, idx) => (
                            <Star key={idx} className={`size-3.5 ${idx < r.rating ? "fill-current" : "opacity-30"}`} />
                          ))}
                          <span className="text-xs font-bold text-foreground ml-1">{r.rating}.0</span>
                        </div>
                      </div>
                      <p className="text-xs text-muted-foreground leading-relaxed italic">"{r.comment}"</p>
                      <div className="flex items-center justify-between pt-1">
                        <button
                          type="button"
                          onClick={() => handleToggleFeaturedReview(r.id)}
                          className={`inline-flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-md border transition-all cursor-pointer ${
                            r.featured
                              ? "bg-gold/20 border-gold/60 text-gold"
                              : "bg-surface border-border text-muted-foreground hover:border-gold hover:text-gold"
                          }`}
                        >
                          <Star className={`size-3.5 ${r.featured ? "fill-current" : ""}`} />
                          <span>{r.featured ? "Featured on Home Page" : "Set as Featured"}</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDeleteReview(r.id)}
                          className="p-1.5 rounded-md border border-destructive/40 bg-destructive/10 text-destructive hover:bg-destructive hover:text-white transition-all cursor-pointer"
                          title="Delete Review"
                        >
                          <Trash2 className="size-3.5" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* TAB: STORE SETTINGS */}
            {activeTab === "settings" && (
              <div className="space-y-6">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-4">
                  <div>
                    <h2 className="font-display text-2xl font-semibold text-foreground">Store Settings & Configuration</h2>
                    <p className="text-xs text-muted-foreground mt-1">Configure shipping thresholds, contact lines, tax rates, and site notice bar.</p>
                  </div>
                  {settingsSavedMsg && (
                    <span className="rounded-md bg-emerald-500/15 border border-emerald-500/40 px-3 py-1.5 text-xs font-bold text-emerald-400 animate-in fade-in">
                      ✓ {settingsSavedMsg}
                    </span>
                  )}
                </div>

                <form onSubmit={handleSaveSettings} className="space-y-6">
                  <div className="grid gap-6 sm:grid-cols-2">
                    <div className="rounded-xl border border-border bg-card p-5 shadow-xs space-y-3">
                      <h3 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">Free Shipping Minimum (₹)</h3>
                      <p className="text-xs text-muted-foreground">Orders above this amount get free express shipping at checkout.</p>
                      <input
                        type="number"
                        value={storeSettings.freeShippingMin}
                        onChange={(e) => setStoreSettings({ ...storeSettings, freeShippingMin: Number(e.target.value) })}
                        className="w-full rounded-sm border border-border bg-background px-3.5 py-2 text-xs font-bold outline-none focus:border-gold"
                      />
                    </div>

                    <div className="rounded-xl border border-border bg-card p-5 shadow-xs space-y-3">
                      <h3 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">GST Tax Percentage (%)</h3>
                      <p className="text-xs text-muted-foreground">GST tax rate applied to apparel invoices across India.</p>
                      <input
                        type="number"
                        value={storeSettings.gstPercentage}
                        onChange={(e) => setStoreSettings({ ...storeSettings, gstPercentage: Number(e.target.value) })}
                        className="w-full rounded-sm border border-border bg-background px-3.5 py-2 text-xs font-bold outline-none focus:border-gold"
                      />
                    </div>

                    <div className="rounded-xl border border-border bg-card p-5 shadow-xs space-y-3">
                      <h3 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">Concierge Support Phone</h3>
                      <p className="text-xs text-muted-foreground">Primary WhatsApp & hotline support number shown to users.</p>
                      <input
                        type="text"
                        value={storeSettings.supportPhone}
                        onChange={(e) => setStoreSettings({ ...storeSettings, supportPhone: e.target.value })}
                        className="w-full rounded-sm border border-border bg-background px-3.5 py-2 text-xs font-bold outline-none focus:border-gold"
                      />
                    </div>

                    <div className="rounded-xl border border-border bg-card p-5 shadow-xs space-y-3">
                      <h3 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">Support Email Address</h3>
                      <p className="text-xs text-muted-foreground">Customer service email for inquiries and custom bookings.</p>
                      <input
                        type="email"
                        value={storeSettings.supportEmail}
                        onChange={(e) => setStoreSettings({ ...storeSettings, supportEmail: e.target.value })}
                        className="w-full rounded-sm border border-border bg-background px-3.5 py-2 text-xs font-bold outline-none focus:border-gold"
                      />
                    </div>
                  </div>

                  <div className="rounded-xl border border-border bg-card p-5 shadow-xs space-y-3">
                    <h3 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">Store Announcement Bar Notice</h3>
                    <p className="text-xs text-muted-foreground">Marquee announcement banner text displayed across top header.</p>
                    <textarea
                      rows={2}
                      value={storeSettings.announcementBar}
                      onChange={(e) => setStoreSettings({ ...storeSettings, announcementBar: e.target.value })}
                      className="w-full rounded-sm border border-border bg-background p-3 text-xs outline-none focus:border-gold resize-none"
                    />
                  </div>

                  <button
                    type="submit"
                    className="flex items-center gap-2 rounded-md bg-gold px-6 py-3 text-xs font-bold text-primary-foreground hover:bg-amber-400 cursor-pointer shadow-goldy"
                  >
                    <Save className="size-4" />
                    <span>Save Store Settings</span>
                  </button>
                </form>
              </div>
            )}

            {/* TAB: HOME PAGE MEDIA */}
            {activeTab === "home-media" && (
              <div className="space-y-6">
                <form onSubmit={handleSaveMedia} className="space-y-6">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-4">
                    <div>
                      <h2 className="font-display text-2xl font-semibold text-foreground">Home Page Media Manager</h2>
                      <p className="text-xs text-muted-foreground mt-1">Upload images & save media changes live across the store.</p>
                    </div>
                    <div className="flex items-center gap-3">
                      {savedMediaMsg && (
                        <span className="rounded-md bg-emerald-500/15 border border-emerald-500/40 px-3 py-1.5 text-xs font-bold text-emerald-400 animate-in fade-in">
                          ✓ {savedMediaMsg}
                        </span>
                      )}
                      <button
                        type="submit"
                        className="flex items-center justify-center gap-2 rounded-lg bg-gold px-4 py-2 text-xs font-bold uppercase tracking-wider text-primary-foreground transition-all hover:bg-amber-400 shadow-goldy cursor-pointer shrink-0"
                      >
                        <Save className="size-3.5" />
                        <span>Save Changes</span>
                      </button>
                    </div>
                  </div>

                  {/* Main Hero Image */}
                  <div className="rounded-xl border border-gold/40 bg-card p-5 shadow-xs transition-all hover:border-gold">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                      <div className="flex items-center gap-4">
                        <img src={heroImgUrl} alt="Hero" className="size-16 rounded-xl object-cover border border-gold/40 shrink-0 shadow-sm" />
                        <div>
                          <h3 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">Main Hero Banner Image</h3>
                          <p className="text-xs text-muted-foreground mt-0.5">Primary hero banner background on the store home page.</p>
                        </div>
                      </div>
                      <label className="cursor-pointer shrink-0 rounded-lg border border-gold/50 bg-gold/15 px-3.5 py-2 text-xs font-bold text-gold transition-all hover:bg-gold hover:text-primary-foreground shadow-xs">
                        <Upload className="size-3.5 inline mr-1.5" /> Upload File
                        <input type="file" accept="image/*" className="hidden" onChange={(e) => handleFileUpload(e, setHeroImgUrl)} />
                      </label>
                    </div>
                  </div>

                  {/* Promo Banner 1 */}
                  <div className="rounded-xl border border-border bg-card p-5 shadow-xs transition-all hover:border-gold">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                      <div className="flex items-center gap-4">
                        <img src={banner1ImgUrl} alt="Banner 1" className="size-16 rounded-xl object-cover border border-border shrink-0 shadow-sm" />
                        <div>
                          <h3 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">Promotional Card 1 Image</h3>
                          <p className="text-xs text-muted-foreground mt-0.5">First promotional card banner image featured on home page.</p>
                        </div>
                      </div>
                      <label className="cursor-pointer shrink-0 rounded-lg border border-gold/50 bg-gold/15 px-3.5 py-2 text-xs font-bold text-gold transition-all hover:bg-gold hover:text-primary-foreground shadow-xs">
                        <Upload className="size-3.5 inline mr-1.5" /> Upload File
                        <input type="file" accept="image/*" className="hidden" onChange={(e) => handleFileUpload(e, setBanner1ImgUrl)} />
                      </label>
                    </div>
                  </div>

                  {/* Promo Banner 2 */}
                  <div className="rounded-xl border border-border bg-card p-5 shadow-xs transition-all hover:border-gold">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                      <div className="flex items-center gap-4">
                        <img src={banner2ImgUrl} alt="Banner 2" className="size-20 rounded-xl object-cover border border-border shrink-0 shadow-sm" />
                        <div>
                          <h3 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">Promotional Card 2 Image</h3>
                          <p className="text-xs text-muted-foreground mt-0.5">Second promotional card banner image featured on home page.</p>
                        </div>
                      </div>
                      <label className="cursor-pointer shrink-0 rounded-lg border border-gold/50 bg-gold/15 px-3.5 py-2 text-xs font-bold text-gold transition-all hover:bg-gold hover:text-primary-foreground shadow-xs">
                        <Upload className="size-3.5 inline mr-1.5" /> Upload File
                        <input type="file" accept="image/*" className="hidden" onChange={(e) => handleFileUpload(e, setBanner2ImgUrl)} />
                      </label>
                    </div>
                  </div>
                </form>
              </div>
            )}



          </main>
        </div>
      </div>

      {/* REGISTERED USER DETAILS MODAL POPUP */}
      {selectedUserDetails && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 p-4 backdrop-blur-md animate-in fade-in duration-200">
          <div className="relative w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl border border-gold/50 bg-card p-6 shadow-2xl space-y-6 animate-in zoom-in-95 duration-200">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-border pb-4">
              <div className="flex items-center gap-4">
                <div className="flex size-14 items-center justify-center rounded-xl bg-gold/20 text-gold font-display text-2xl font-extrabold border border-gold/40 shadow-sm">
                  {selectedUserDetails.name ? selectedUserDetails.name.charAt(0).toUpperCase() : "U"}
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-display text-xl font-bold text-foreground">{selectedUserDetails.name}</h3>
                    <span className={`rounded-full px-2.5 py-0.5 text-[9px] font-bold uppercase tracking-wider ${
                      selectedUserDetails.role === "admin" ? "bg-gold text-primary-foreground shadow-goldy" : "bg-gold/15 text-gold border border-gold/30"
                    }`}>
                      {selectedUserDetails.role || "USER"}
                    </span>
                  </div>
                  <p className="text-xs text-muted-foreground font-mono mt-0.5">{selectedUserDetails.email}</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedUserDetails(null)}
                className="flex size-8 items-center justify-center rounded-lg border border-border bg-surface text-muted-foreground hover:border-gold hover:text-gold transition-all cursor-pointer"
              >
                <X className="size-4" />
              </button>
            </div>

            {/* Account Info Stats */}
            {(() => {
              const userOrders = orders.filter(
                (o) =>
                  (o.userEmail && uEquals(o.userEmail, selectedUserDetails.email)) ||
                  (o.userName && uEquals(o.userName, selectedUserDetails.name))
              );
              const totalSpend = userOrders.reduce((sum, o) => sum + (o.totalAmount || 0), 0);

              function uEquals(a: string, b: string) {
                return (a || "").trim().toLowerCase() === (b || "").trim().toLowerCase();
              }

              return (
                <div className="space-y-6">
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-xs">
                    <div className="rounded-xl border border-border/80 bg-surface/60 p-3.5 space-y-1">
                      <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Registered Date</span>
                      <p className="font-bold text-foreground">
                        {new Date(selectedUserDetails.createdAt).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                      </p>
                    </div>
                    <div className="rounded-xl border border-border/80 bg-surface/60 p-3.5 space-y-1">
                      <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Total Bookings</span>
                      <p className="font-bold text-gold text-sm">
                        {userOrders.length} Order(s)
                      </p>
                    </div>
                    <div className="rounded-xl border border-border/80 bg-surface/60 p-3.5 space-y-1 col-span-2 sm:col-span-1">
                      <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Total Spend</span>
                      <p className="font-bold text-emerald-500 text-sm">
                        ₹{totalSpend.toLocaleString("en-IN")}
                      </p>
                    </div>
                  </div>

                  {/* Customer Booking History */}
                  <div className="space-y-3">
                    <h4 className="font-display text-sm font-bold text-foreground uppercase tracking-wider">Customer Order & Booking History</h4>
                    {userOrders.length > 0 ? (
                      <div className="space-y-3 max-h-[260px] overflow-y-auto pr-1">
                        {userOrders.map((ord) => (
                          <div key={ord._id} className="rounded-xl border border-border/80 bg-surface/40 p-4 space-y-2 text-xs">
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <span className="font-mono font-bold text-gold">#{String(ord._id || ord.id || "ORD").slice(-8).toUpperCase()}</span>
                                <span className={`rounded-md px-2 py-0.5 text-[9px] font-bold uppercase ${
                                  ord.status === "Delivered" ? "bg-emerald-500/15 text-emerald-500 border border-emerald-500/30" : "bg-gold/15 text-gold border border-gold/30"
                                }`}>
                                  {ord.status || "Processing"}
                                </span>
                              </div>
                              <span className="font-bold text-foreground">₹{(ord.totalAmount || 0).toLocaleString("en-IN")}</span>
                            </div>
                            <div className="text-[11px] text-muted-foreground flex flex-wrap gap-x-4 gap-y-1">
                              <span>Items: <strong className="text-foreground">{ord.items?.length || 0} product(s)</strong></span>
                              <span>Date: <strong>{new Date(ord.createdAt || Date.now()).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}</strong></span>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="rounded-xl border border-dashed border-border/80 p-6 text-center text-muted-foreground text-xs">
                        No customer booking history found for this user account.
                      </div>
                    )}
                  </div>
                </div>
              );
            })()}

            {/* Footer Close */}
            <div className="flex justify-end border-t border-border pt-4">
              <button
                type="button"
                onClick={() => setSelectedUserDetails(null)}
                className="btn-gold hover:btn-gold-hover rounded-sm px-6 py-2.5 text-xs font-bold uppercase tracking-wider cursor-pointer"
              >
                Close Profile
              </button>
            </div>
          </div>
        </div>
      )}
      {/* CANCELLATION REASON MODAL POPUP */}
      {cancellingOrder && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 p-4 backdrop-blur-md animate-in fade-in duration-200">
          <div className="relative w-full max-w-lg overflow-hidden rounded-xl border border-destructive/50 bg-card p-6 shadow-2xl space-y-5 animate-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between border-b border-border pb-3">
              <div className="flex items-center gap-2.5">
                <div className="flex size-9 items-center justify-center rounded-lg bg-destructive/15 text-destructive font-bold text-lg">
                  ⚠️
                </div>
                <div>
                  <h3 className="font-display text-base font-bold text-foreground">Order Cancellation Reason</h3>
                  <p className="text-[11px] text-muted-foreground font-mono">Booking #{cancellingOrder.bookingIdStr}</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setCancellingOrder(null)}
                className="flex size-8 items-center justify-center rounded-full bg-surface text-muted-foreground hover:text-foreground cursor-pointer"
              >
                <X className="size-4" />
              </button>
            </div>

            <form onSubmit={handleConfirmCancellation} className="space-y-4">
              <div>
                <label className="text-[10px] uppercase tracking-wider text-gold font-bold block mb-2">
                  Select Reason for Cancelling Order
                </label>
                <div className="space-y-2">
                  {[
                    "Item Out of Stock / Inventory Shortage",
                    "Delivery Address / Pincode Unserviceable",
                    "Customer Requested Order Cancellation",
                    "Payment Verification Failed / Suspicious",
                    "Custom Reason",
                  ].map((reason) => (
                    <label
                      key={reason}
                      className={`flex items-center gap-3 rounded-lg border p-3 text-xs font-semibold cursor-pointer transition-all ${
                        cancelReasonPreset === reason
                          ? "border-destructive bg-destructive/10 text-destructive font-bold"
                          : "border-border bg-surface/50 text-foreground hover:border-gold/40"
                      }`}
                    >
                      <input
                        type="radio"
                        name="cancelReasonOption"
                        checked={cancelReasonPreset === reason}
                        onChange={() => setCancelReasonPreset(reason)}
                        className="accent-destructive cursor-pointer"
                      />
                      <span>{reason}</span>
                    </label>
                  ))}
                </div>
              </div>

              {cancelReasonPreset === "Custom Reason" && (
                <div>
                  <label className="text-[10px] uppercase tracking-wider text-gold font-bold block mb-1">
                    Enter Custom Cancellation Explanation
                  </label>
                  <textarea
                    required
                    value={customCancelReason}
                    onChange={(e) => setCustomCancelReason(e.target.value)}
                    placeholder="Provide specific details on why this booking is being cancelled..."
                    className="w-full rounded-sm border border-border bg-background p-3 text-xs text-foreground outline-none focus:border-destructive min-h-[80px]"
                  />
                </div>
              )}

              <div className="flex items-center gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setCancellingOrder(null)}
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
    </div>
  );
}
