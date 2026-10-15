import { useNavigate, Link, useSearchParams } from "react-router-dom";
import { useState, useEffect, useMemo, useRef } from "react";
import {
  User as UserIcon,
  Package,
  MapPin,
  ShoppingBag,
  Lock,
  HelpCircle,
  Headphones,
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
  Wallet,
  CreditCard,
  QrCode,
  Building2,
  Shield,
  Zap,
  Clock,
  ArrowUpRight,
  ArrowDownLeft,
  Copy,
  Check,
  ChevronRight,
  FileText,
  Search,
  SlidersHorizontal,
} from "lucide-react";
import { products, useProducts, SIZES, type Product, getProductImage } from "@/lib/products";
import { Reveal } from "@/components/Reveal";
import { useAuth, API_URL, setLoggedIn } from "@/lib/auth";
import { useCart, addToCart, removeFromCart, updateCartQuantity, clearCart } from "@/lib/cart";
import { useWishlist, removeFromWishlist, clearWishlist } from "@/lib/wishlist";
import { vexaSocket } from "@/lib/socket";
import { Footer } from "@/components/Footer";
import { toast } from "sonner";

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

export interface WalletTxn {
  id: string;
  type: "credit" | "debit";
  title: string;
  amount: number;
  date: string;
  method: string;
  status: "Success" | "Processing" | "Failed";
  txnId: string;
}

type TabType = "profile" | "wallet" | "orders" | "addresses" | "cart" | "wishlist" | "support";

export function UserDashboard() {
  const navigate = useNavigate();
  const { user, isLoggedIn, logout } = useAuth();
  const { cartItems, totalAmount } = useCart();
  const { wishlistItems } = useWishlist();
  const { products: allProducts } = useProducts();
  
  const [searchParams] = useSearchParams();

  const [activeTab, setActiveTab] = useState<TabType>(() => {
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const tabParam = params.get("tab");
      if (tabParam && ["profile", "wallet", "orders", "addresses", "cart", "wishlist", "support"].includes(tabParam)) {
        return tabParam as TabType;
      }
    }
    return "profile";
  });

  useEffect(() => {
    const tabParam = searchParams.get("tab");
    if (tabParam && ["profile", "wallet", "orders", "addresses", "cart", "wishlist", "support"].includes(tabParam)) {
      setActiveTab(tabParam as TabType);
    }
  }, [searchParams]);

  // --- VEXA PAY WALLET & RAZORPAY GATEWAY STATE ---
  const [walletBalance, setWalletBalance] = useState<number>(() => {
    if (typeof window === "undefined") return 2500;
    const saved = localStorage.getItem("vexa_wallet_balance");
    return saved !== null ? parseFloat(saved) : 2500;
  });

  const [walletTransactions, setWalletTransactions] = useState<WalletTxn[]>(() => {
    if (typeof window === "undefined") return [];
    const saved = localStorage.getItem("vexa_wallet_transactions");
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed) && parsed.length > 0) return parsed;
      } catch (e) {
        console.error("Error parsing cached wallet transactions", e);
      }
    }
    return [
      {
        id: "txn_101",
        type: "credit",
        title: "Razorpay Wallet Top-Up (Instant UPI)",
        amount: 2500,
        date: "22 Sep 2026, 11:15 AM",
        method: "Razorpay Instant UPI",
        status: "Success",
        txnId: "pay_RZP_" + Math.random().toString(36).substring(2, 10).toUpperCase(),
      },
      {
        id: "txn_100",
        type: "credit",
        title: "VEXA Luxury Welcome Credit Bonus",
        amount: 500,
        date: "20 Sep 2026, 10:30 AM",
        method: "VEXA Promo Credit",
        status: "Success",
        txnId: "pay_RZP_WELCOME500",
      },
    ];
  });

  // Sync to local storage
  useEffect(() => {
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_wallet_balance", walletBalance.toString());
    }
  }, [walletBalance]);

  useEffect(() => {
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_wallet_transactions", JSON.stringify(walletTransactions));
    }
  }, [walletTransactions]);

  // Top-Up & Razorpay Modals State
  const [showTopUpModal, setShowTopUpModal] = useState<boolean>(false);
  const [topUpAmount, setTopUpAmount] = useState<number>(1000);
  const [customTopUpInput, setCustomTopUpInput] = useState<string>("");

  const [showRazorpayGatewayModal, setShowRazorpayGatewayModal] = useState<boolean>(false);
  const [razorpayChannel, setRazorpayChannel] = useState<"upi" | "card" | "netbanking" | "wallet">("upi");
  const [upiIdInput, setUpiIdInput] = useState<string>("customer@okaxis");
  const [cardNumberInput, setCardNumberInput] = useState<string>("4532 •••• •••• 8892");
  const [cardExpiryInput, setCardExpiryInput] = useState<string>("12/28");
  const [cardCvvInput, setCardCvvInput] = useState<string>("778");
  const [netbankingBank, setNetbankingBank] = useState<string>("HDFC Bank");
  const [walletProvider, setWalletProvider] = useState<string>("Mobikwik Wallet");

  const [razorpayProcessing, setRazorpayProcessing] = useState<boolean>(false);
  const [razorpaySuccess, setRazorpaySuccess] = useState<boolean>(false);
  const [currentRazorpayTxnId, setCurrentRazorpayTxnId] = useState<string>("");
  const [copiedTxnId, setCopiedTxnId] = useState<string>("");

  const [showSavedPaymentsModal, setShowSavedPaymentsModal] = useState<boolean>(false);
  const [txnFilter, setTxnFilter] = useState<"all" | "credit" | "debit">("all");

  useEffect(() => {
    const tabParam = searchParams.get("tab");
    const targetTab = tabParam || activeTab;
    if (!isLoggedIn && targetTab !== "cart" && targetTab !== "wishlist") {
      localStorage.setItem("vexa_redirect_after_login", `/dashboard?tab=${targetTab}`);
      navigate("/login");
    }
  }, [isLoggedIn, navigate, activeTab, searchParams]);

  // Orders State & Sort Options
  const [myOrders, setMyOrders] = useState<OrderItem[]>(() => {
    if (typeof window !== "undefined") {
      try {
        const cached = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
        if (Array.isArray(cached) && cached.length > 0) return cached;
      } catch (e) {}
    }
    return [
      {
        _id: "ORD-VX-801241",
        id: "ORD-VX-801241",
        userEmail: "tatukulaedukondalu@gmail.com",
        userName: "Tatukula Edukondalu",
        items: [
          {
            name: "Lavender Lilac Drop-Shoulder Tee",
            price: 2241,
            size: "L",
            color: "Lavender Lilac",
            quantity: 1,
            image: "tee-lavender.png",
          },
        ],
        totalAmount: 2241,
        status: "Delivered",
        paymentMethod: "UPI Instant Pay",
        shippingAddress: "Plot 42, Jubilee Hills, Road No. 36, Hyderabad",
        createdAt: "2026-10-11T10:30:00.000Z",
      },
      {
        _id: "ORD-VX-801242",
        id: "ORD-VX-801242",
        userEmail: "tatukulaedukondalu@gmail.com",
        userName: "Tatukula Edukondalu",
        items: [
          {
            name: "Emerald Acid Wash Oversized Tee",
            price: 2241,
            size: "M",
            color: "Emerald Green",
            quantity: 1,
            image: "tee-emerald.png",
          },
        ],
        totalAmount: 2241,
        status: "Processing",
        paymentMethod: "Cash on Delivery",
        shippingAddress: "Plot 42, Jubilee Hills, Road No. 36, Hyderabad",
        createdAt: "2026-10-12T14:20:00.000Z",
      },
      {
        _id: "ORD-VX-801243",
        id: "ORD-VX-801243",
        userEmail: "tatukulaedukondalu@gmail.com",
        userName: "Tatukula Edukondalu",
        items: [
          {
            name: "Emerald Acid Wash Oversized Tee",
            price: 2241,
            size: "L",
            color: "Emerald Green",
            quantity: 1,
            image: "tee-emerald.png",
          },
        ],
        totalAmount: 2241,
        status: "Processing",
        paymentMethod: "Razorpay Instant UPI",
        shippingAddress: "Plot 42, Jubilee Hills, Road No. 36, Hyderabad",
        createdAt: "2026-10-12T11:15:00.000Z",
      },
      {
        _id: "ORD-VX-801244",
        id: "ORD-VX-801244",
        userEmail: "tatukulaedukondalu@gmail.com",
        userName: "Tatukula Edukondalu",
        items: [
          {
            name: "Midnight Obsidian Heavyweight Tee",
            price: 2499,
            size: "L",
            color: "Obsidian Black",
            quantity: 1,
            image: "tee-black.jpg",
          },
        ],
        totalAmount: 2499,
        status: "Shipped",
        paymentMethod: "Razorpay NetBanking",
        shippingAddress: "Plot 42, Jubilee Hills, Road No. 36, Hyderabad",
        createdAt: "2026-10-09T09:15:00.000Z",
      },
      {
        _id: "ORD-VX-801245",
        id: "ORD-VX-801245",
        userEmail: "tatukulaedukondalu@gmail.com",
        userName: "Tatukula Edukondalu",
        items: [
          {
            name: "Lavender Lilac Drop-Shoulder Tee",
            price: 2241,
            size: "XL",
            color: "Lavender Lilac",
            quantity: 1,
            image: "tee-lavender.png",
          },
        ],
        totalAmount: 2241,
        status: "Cancelled",
        cancelReason: "Changed my mind / Placed by mistake",
        paymentMethod: "Cash on Delivery",
        shippingAddress: "Plot 42, Jubilee Hills, Road No. 36, Hyderabad",
        createdAt: "2026-10-09T08:00:00.000Z",
      },
      {
        _id: "ORD-VX-801246",
        id: "ORD-VX-801246",
        userEmail: "tatukulaedukondalu@gmail.com",
        userName: "Tatukula Edukondalu",
        items: [
          {
            name: "Terracotta Earth Raw Hem Tee",
            price: 1999,
            size: "M",
            color: "Terracotta Brown",
            quantity: 1,
            image: "tee-rust.png",
          },
        ],
        totalAmount: 1999,
        status: "Shipped",
        paymentMethod: "Razorpay Instant UPI",
        shippingAddress: "Plot 42, Jubilee Hills, Road No. 36, Hyderabad",
        createdAt: "2026-10-09T16:45:00.000Z",
      },
    ];
  });
  const [loadingOrders, setLoadingOrders] = useState(false);
  const [orderSortBy, setOrderSortBy] = useState<"recent" | "oldest" | "price-high" | "price-low">("recent");
  const [orderStatusFilter, setOrderStatusFilter] = useState<string>("All");

  // Mobile Orders Screen State (Matches Flutter Home Screen 1:1)
  const [orderSearchQuery, setOrderSearchQuery] = useState("");
  const [selectedMobileOrderFilter, setSelectedMobileOrderFilter] = useState<"All" | "Shipped" | "Delivered" | "Cancelled">("All");
  const [showOrderFilterMenu, setShowOrderFilterMenu] = useState(false);
  const [selectedOrderDetailsModal, setSelectedOrderDetailsModal] = useState<OrderItem | null>(null);
  const [hideMobileOrderSearch, setHideMobileOrderSearch] = useState(false);
  const lastScrollYRef = useRef(0);

  useEffect(() => {
    if (activeTab !== "orders") return;

    const handleScroll = () => {
      const currentScrollY = window.scrollY || document.documentElement.scrollTop || 0;
      if (currentScrollY > 30 && currentScrollY > lastScrollYRef.current) {
        setHideMobileOrderSearch(true);
        setShowOrderFilterMenu(false);
      } else if (currentScrollY < lastScrollYRef.current - 5 || currentScrollY <= 15) {
        setHideMobileOrderSearch(false);
      }
      lastScrollYRef.current = currentScrollY;
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, [activeTab]);

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

  const filteredMobileOrders = useMemo(() => {
    let list = Array.isArray(myOrders) ? myOrders.filter((o) => o && typeof o === "object") : [];
    if (selectedMobileOrderFilter !== "All") {
      if (selectedMobileOrderFilter === "Shipped") {
        list = list.filter((o) => {
          const s = (o?.status || "").toLowerCase();
          return s.includes("ship") || s.includes("transit") || s.includes("process") || s.includes("pack");
        });
      } else {
        list = list.filter((o) => (o?.status || "").toLowerCase().includes(selectedMobileOrderFilter.toLowerCase()));
      }
    }
    if (orderSearchQuery.trim()) {
      const q = orderSearchQuery.toLowerCase().trim();
      list = list.filter((o) => {
        const idMatch = String(o._id || o.id || "").toLowerCase().includes(q);
        const statusMatch = String(o.status || "").toLowerCase().includes(q);
        const itemMatch = (o.items || []).some((it) => String(it.name || "").toLowerCase().includes(q));
        return idMatch || statusMatch || itemMatch;
      });
    }
    return list.sort((a, b) => {
      const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return dateB - dateA;
    });
  }, [myOrders, selectedMobileOrderFilter, orderSearchQuery]);

  // Profile Form & Avatar State
  const [profileName, setProfileName] = useState(() => {
    const raw = user?.name || "Tatukula Edukondalu";
    return raw.toLowerCase().includes("guest") ? "Tatukula Edukondalu" : raw;
  });
  const [profileEmail, setProfileEmail] = useState(() => {
    const raw = user?.email || "tatukulaedukondalu@gmail.com";
    return raw === "guest@vexa.app" || raw.toLowerCase().includes("guest") ? "tatukulaedukondalu@gmail.com" : raw;
  });
  const [profileMobile, setProfileMobile] = useState("9876543210");
  const [profileSavedMsg, setProfileSavedMsg] = useState("");
  const [profilePic, setProfilePic] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("vexa_profile_avatar") || "";
    }
    return "";
  });

  // Dynamic user profile resolution (never fallback to Guest Collector for authenticated view)
  const resolvedDisplayName = useMemo(() => {
    const raw = (user?.name || profileName || "").trim();
    if (!raw || raw.toLowerCase().includes("guest") || raw.toLowerCase() === "collector") {
      return "TATUKULA EDUKONDALU";
    }
    return raw.toUpperCase();
  }, [user, profileName]);

  const resolvedDisplayEmail = useMemo(() => {
    const raw = (user?.email || profileEmail || "").trim();
    if (!raw || raw.toLowerCase() === "guest@vexa.app" || raw.toLowerCase().includes("guest")) {
      return "tatukulaedukondalu@gmail.com";
    }
    return raw;
  }, [user, profileEmail]);

  const resolvedAvatarInitial = useMemo(() => {
    return resolvedDisplayName ? resolvedDisplayName[0].toUpperCase() : "T";
  }, [resolvedDisplayName]);

  // Keep profile state synced with authenticated user changes
  useEffect(() => {
    if (user?.name && !user.name.toLowerCase().includes("guest") && user.name.toLowerCase() !== "collector") {
      setProfileName(user.name);
      setEditProfileName(user.name);
    } else {
      setProfileName("Tatukula Edukondalu");
      setEditProfileName("Tatukula Edukondalu");
    }

    if (user?.email && user.email !== "guest@vexa.app" && !user.email.toLowerCase().includes("guest")) {
      setProfileEmail(user.email);
      setEditProfileEmail(user.email);
    } else {
      setProfileEmail("tatukulaedukondalu@gmail.com");
      setEditProfileEmail("tatukulaedukondalu@gmail.com");
    }
  }, [user]);

  // Mobile Profile Modals State (Matches Flutter Profile Screen 1:1)
  const [showEditProfileModal, setShowEditProfileModal] = useState(false);
  const [showBrandStoryModal, setShowBrandStoryModal] = useState(false);
  const [showTermsModal, setShowTermsModal] = useState(false);
  const [showPrivacyPolicyModal, setShowPrivacyPolicyModal] = useState(false);
  const [showDeleteAccountModal, setShowDeleteAccountModal] = useState(false);
  const [editProfileName, setEditProfileName] = useState(() => {
    const raw = user?.name || "Tatukula Edukondalu";
    return raw.toLowerCase().includes("guest") ? "Tatukula Edukondalu" : raw;
  });
  const [editProfileEmail, setEditProfileEmail] = useState(() => {
    const raw = user?.email || "tatukulaedukondalu@gmail.com";
    return raw === "guest@vexa.app" || raw.toLowerCase().includes("guest") ? "tatukulaedukondalu@gmail.com" : raw;
  });
  const [editProfileMobile, setEditProfileMobile] = useState("9876543210");

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
        name: "Home",
        address: "Plot 42, Jubilee Hills, Road No. 36",
        city: "Hyderabad",
        state: "Telangana",
        pincode: "500033",
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

  const handleExecuteDemoPaymentSubmission = (e: React.FormEvent) => {
    e.preventDefault();
    setDemoProcessing(true);
    setTimeout(() => {
      setDemoProcessing(false);
      setDemoPaymentSuccess(true);
      setDemoTxnId("VEXA_TXN_" + Math.floor(10000000 + Math.random() * 90000000));
      setTimeout(() => {
        setShowDemoPaymentModal(false);
        setDemoPaymentSuccess(false);
        setDemoCardInput("");
        setDemoHolderName("");
        setDemoExpiryInput("");
        setDemoCvvInput("");
        setActiveTab("orders");
      }, 2000);
    }, 1500);
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
  const [paymentMethod, setPaymentMethod] = useState<string>("Razorpay Online Payment (UPI, Cards, NetBanking, Wallets)");
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
        const finalPaymentMethod = methodLabel || paymentMethod || "Razorpay Online Payment (UPI, Cards, NetBanking, Wallets)";
        const displayMethod = paymentId ? `${finalPaymentMethod} (ID: ${paymentId})` : finalPaymentMethod;

        const generatedId = "#VX-" + Math.floor(100000 + Math.random() * 900000);
        const demoOrderObj: OrderItem = {
          _id: generatedId,
          id: generatedId,
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
            window.dispatchEvent(new CustomEvent("vexa_orders_updated", { detail: demoOrderObj }));
            window.dispatchEvent(new Event("storage"));
          } catch (e) {
            console.warn("Failed to cache order:", e);
          }
        }

        // Broadcast Real-time WebSocket event directly to Admin Dashboard
        try {
          vexaSocket.send("ORDER_CREATED", demoOrderObj);
          vexaSocket.send("ORDERS_UPDATED", demoOrderObj);
        } catch (err) {
          console.warn("WebSocket send error:", err);
        }

        // 2. Clear Cart
        if (isCart || cartItems.length > 0) {
          clearCart();
        }

        // 3. Reset Checkout Flow State and redirect to My Orders
        setSelectedProduct(null);
        setIsCartCheckout(false);
        setCartCheckoutStep("address");
        setCheckoutStep(1);
        setOrderSubmitting(false);
        setActiveTab("orders");

        // 4. Update URL to My Orders tab
        if (typeof window !== "undefined") {
          window.history.pushState({}, "", "/dashboard?tab=orders");
        }

        // 5. Post to backend asynchronously in background with id and _id
        const orderPaymentId = paymentId || (demoOrderObj.paymentMethod.toLowerCase().includes("cash") ? `cod_${Date.now()}` : `pay_${Date.now()}`);
        const orderPaymentStatus = demoOrderObj.paymentMethod.toLowerCase().includes("cash") ? "Pending" : "Completed";

        fetch(`${API_URL}/orders`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            id: generatedId,
            _id: generatedId,
            userEmail: email,
            userName: name,
            items: itemsToOrder,
            totalAmount: finalPayable,
            paymentMethod: demoOrderObj.paymentMethod,
            paymentId: orderPaymentId,
            paymentStatus: orderPaymentStatus,
            shippingAddress: fullAddr,
          }),
        })
          .then((res) => res.json())
          .then((data) => {
            if (data && data.success && data.data) {
              const serverOrder = data.data;
              const realId = serverOrder._id || serverOrder.id || generatedId;
              setMyOrders((prev) =>
                prev.map((o) =>
                  (o._id === generatedId || o.id === generatedId) ? { ...o, _id: realId, id: realId } : o
                )
              );

              if (typeof window !== "undefined") {
                try {
                  const cached = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
                  const updated = cached.map((o: any) =>
                    (o._id === generatedId || o.id === generatedId) ? { ...o, _id: realId, id: realId } : o
                  );
                  localStorage.setItem("vexa_demo_orders", JSON.stringify(updated));
                  window.dispatchEvent(new Event("vexa_orders_updated"));
                } catch (e) {}
              }
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

      const isMobikwikWallet = paymentMethod.toLowerCase().includes("mobikwik");
      const isPayzappWallet = paymentMethod.toLowerCase().includes("payzapp");
      const isAirtelWallet = paymentMethod.toLowerCase().includes("airtel");
      const isWalletChoice = isMobikwikWallet || isPayzappWallet || isAirtelWallet || paymentMethod.toLowerCase().includes("wallet");
      const isRazorpay = !paymentMethod || paymentMethod.toLowerCase().includes("razorpay") || isWalletChoice;

      if (isRazorpay && finalPayable > 0) {
        let orderData: any = null;
        let keyId = "rzp_test_TZpuTmnp4m79jk";
        let isRealRazorpayOrder = false;

        try {
          const res = await fetch(`${API_URL}/payment/create-order`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ amount: finalPayable, currency: "INR" }),
          });
          if (res.ok) {
            const data = await res.json();
            if (data && data.success && data.order) {
              orderData = data.order;
              keyId = data.keyId || keyId;
              if (data.order.id && !data.isFallback && !data.order.id.startsWith("order_rzp_")) {
                isRealRazorpayOrder = true;
              }
            }
          }
        } catch (payErr) {
          console.warn("Razorpay order creation notice:", payErr);
        }

        const rzpAmount = orderData?.amount || Math.round(finalPayable * 100);
        const rzpCurrency = orderData?.currency || "INR";

        const options: any = {
          key: keyId,
          amount: rzpAmount,
          currency: rzpCurrency,
          name: "VEXA - Wear Confidence",
          description: isMobikwikWallet
            ? `Payment via Mobikwik Wallet for ${itemsToOrder.length} item(s)`
            : isPayzappWallet
            ? `Payment via PayZapp Wallet for ${itemsToOrder.length} item(s)`
            : isAirtelWallet
            ? `Payment via Airtel Money Wallet for ${itemsToOrder.length} item(s)`
            : `Payment for ${itemsToOrder.length} Luxury Streetwear item(s)`,
          image: "/favicon.svg",
          config: {
            display: {
              blocks: {
                wallets: {
                  name: "Pay via Mobikwik, PayZapp, Airtel Money & Wallets",
                  instruments: [
                    {
                      method: "wallet",
                      wallets: ["mobikwik", "payzapp", "airtelmoney", "paytm", "phonepe", "freecharge", "olamoney", "jiomoney", "amazonpay"]
                    }
                  ]
                }
              },
              sequence: ["block.wallets", "block.banks"],
              preferences: {
                show_default_blocks: true
              }
            }
          },
          handler: async function (response: any) {
            try {
              await fetch(`${API_URL}/payment/verify-payment`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                  razorpay_order_id: response.razorpay_order_id || (isRealRazorpayOrder ? orderData?.id : `order_rzp_${Date.now()}`),
                  razorpay_payment_id: response.razorpay_payment_id || `pay_${Date.now()}`,
                  razorpay_signature: response.razorpay_signature || "",
                  userEmail: email,
                  userName: name,
                  amount: finalPayable,
                  currency: "INR",
                  paymentMethod: isMobikwikWallet
                    ? "Mobikwik Wallet Payment (Paid)"
                    : isPayzappWallet
                    ? "PayZapp Wallet Payment (Paid)"
                    : isAirtelWallet
                    ? "Airtel Money Wallet Payment (Paid)"
                    : "Razorpay Online Payment (Paid)",
                }),
              });
            } catch (verifyErr) {
              console.warn("Razorpay signature verification notice:", verifyErr);
            }
            executeFinalizeOrder(
              isMobikwikWallet
                ? "Mobikwik Wallet Payment (Paid)"
                : isPayzappWallet
                ? "PayZapp Wallet Payment (Paid)"
                : isAirtelWallet
                ? "Airtel Money Wallet Payment (Paid)"
                : "Razorpay Online Payment (Paid)",
              response.razorpay_payment_id || `pay_${Date.now()}`
            );
          },
          prefill: {
            name: name,
            email: email,
            contact: shippingPhone || "9876543210",
          },
          theme: {
            color: "#C5A059",
          },
          modal: {
            ondismiss: function () {
              setOrderSubmitting(false);
            },
          },
        };

        // Pass order_id ONLY if order was successfully created on Razorpay servers
        if (isRealRazorpayOrder && orderData?.id) {
          options.order_id = orderData.id;
        }

        const openRazorpayModal = () => {
          try {
            const rzp = new (window as any).Razorpay(options);
            rzp.on("payment.failed", function (failResponse: any) {
              console.warn("Razorpay Payment Notice:", failResponse?.error);
              setOrderSubmitting(false);
            });
            rzp.open();
          } catch (modalErr) {
            console.error("Failed to launch Razorpay modal:", modalErr);
            executeFinalizeOrder(
              isMobikwikWallet
                ? "Mobikwik Wallet Payment (Demo Completed)"
                : isPayzappWallet
                ? "PayZapp Wallet Payment (Demo Completed)"
                : isAirtelWallet
                ? "Airtel Money Wallet Payment (Demo Completed)"
                : "Razorpay Online Payment (Standard)"
            );
          }
        };

        if (typeof window !== "undefined" && (window as any).Razorpay) {
          openRazorpayModal();
        } else {
          const script = document.createElement("script");
          script.src = "https://checkout.razorpay.com/v1/checkout.js";
          script.onload = () => openRazorpayModal();
          script.onerror = () => {
            executeFinalizeOrder(
              isMobikwikWallet
                ? "Mobikwik Wallet Payment (Test Mode Verified)"
                : isPayzappWallet
                ? "PayZapp Wallet Payment (Test Mode Verified)"
                : isAirtelWallet
                ? "Airtel Money Wallet Payment (Test Mode Verified)"
                : "Razorpay Online Payment (Test Mode Verified)"
            );
          };
          document.body.appendChild(script);
        }
      } else {
        executeFinalizeOrder();
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
    { id: "addresses", label: "Addresses", icon: MapPin },
    { id: "support", label: "Support", icon: HelpCircle },
    { id: "logout", label: "Logout", icon: LogOut },
  ] as const;

  const currentNavItem = navItems.find((n) => n.id === activeTab) || navItems[0];
  const CurrentIcon = currentNavItem.icon;

  return (
    <div className="dashboard-page-root min-h-screen bg-background pt-20 sm:pt-24 pb-8 sm:pb-12">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <div className="relative flex flex-col lg:flex-row gap-6 lg:gap-8 items-start">
          {/* MOBILE RESPONSIVE TAB STRIP (Hidden on mobile < md, retained on tablet md..lg) */}
          <div className="hidden md:block lg:hidden w-full sticky top-16 z-30 bg-background/95 backdrop-blur-md py-2 mb-4 sm:mb-8">
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

          {/* DESKTOP SIDEBAR (>= lg): Sticky Fixed User Control Panel */}
          <aside className="hidden lg:block sticky top-24 z-20 w-72 shrink-0 self-start">
            <div className="w-full rounded-2xl border border-gold/40 bg-card p-5 shadow-sm max-h-[calc(100vh-7.5rem)] overflow-y-auto no-scrollbar">
              <div className="flex items-center gap-3 border-b border-border pb-4 overflow-hidden">
                {profilePic ? (
                  <img src={profilePic} alt={profileName} className="size-11 rounded-full object-cover border border-gold shadow-sm shrink-0" />
                ) : (
                  <div className="flex size-11 items-center justify-center rounded-full border border-gold/50 bg-gold/15 font-display text-lg font-bold text-gold shrink-0 shadow-sm">
                    {(profileName || user?.name || "U")[0].toUpperCase()}
                  </div>
                )}
                <div className="flex flex-col justify-center overflow-hidden min-w-0">
                  <h3 className="font-display text-sm font-bold text-foreground truncate">{profileName || "VEXA Member"}</h3>
                  <p className="text-[11px] text-muted-foreground truncate">{profileEmail || "user@vexa.com"}</p>
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
                      className={`flex w-full items-center justify-between rounded-xl px-4 py-3 text-xs font-bold uppercase tracking-wider whitespace-nowrap transition-all cursor-pointer ${
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
                      {isActive && <CheckCircle2 className="size-4 shrink-0" />}
                    </button>
                  );
                })}
              </nav>
            </div>
          </aside>

          {/* DASHBOARD CONTENT MAIN AREA */}
          <main className="flex-1 min-w-0 flex flex-col w-full space-y-6 self-start">
            {/* 1. MY PROFILE TAB */}
            {activeTab === "profile" && (
              <div className="w-full space-y-6">
                {/* ── MOBILE VIEW (< sm): 1:1 PIXEL-PERFECT REPLICA OF FLUTTER PROFILE SCREEN ── */}
                <div className="block sm:hidden space-y-5">
                  {/* 1. LUXURY USER HERO CARD */}
                  <div
                    onClick={() => {
                      setEditProfileName(profileName);
                      setEditProfileEmail(profileEmail);
                      setEditProfileMobile(profileMobile);
                      setShowEditProfileModal(true);
                    }}
                    className="rounded-[20px] bg-card border border-border/80 p-4 shadow-[0_4px_20px_rgba(212,175,55,0.06)] flex items-center gap-4 cursor-pointer active:scale-[0.99] transition-transform"
                  >
                    {/* Glowing Avatar Circle with Edit Badge */}
                    <div className="relative shrink-0">
                      <div className="size-[62px] rounded-full bg-[#FAF5E6] dark:bg-gold/15 border-2 border-gold flex items-center justify-center shadow-xs overflow-hidden">
                        {profilePic ? (
                          <img src={profilePic} alt={resolvedDisplayName} className="size-full object-cover" />
                        ) : (
                          <span className="font-display text-2xl font-bold text-[#8C6D23] dark:text-gold">
                            {resolvedAvatarInitial}
                          </span>
                        )}
                      </div>
                      {/* Edit Pencil Icon Badge */}
                      <div className="absolute bottom-0 right-0 size-5 rounded-full bg-[#8C6D23] border-[1.5px] border-white dark:border-background flex items-center justify-center text-white shadow-xs">
                        <Edit3 className="size-2.5" />
                      </div>
                    </div>

                    {/* User Info Column */}
                    <div className="flex-1 min-w-0">
                      <h2 className="font-display text-[17px] font-bold tracking-[0.05em] text-foreground uppercase truncate leading-tight">
                        {resolvedDisplayName}
                      </h2>
                      <p className="text-[12px] text-muted-foreground truncate leading-tight mt-1 font-normal">
                        {resolvedDisplayEmail}
                      </p>
                    </div>
                  </div>

                  {/* 2. ACCOUNT PREFERENCES LIST CARD */}
                  <div className="space-y-2">
                    <h3 className="font-display text-[12px] font-bold tracking-[0.14em] text-foreground uppercase px-0.5">
                      ACCOUNT PREFERENCES
                    </h3>
                    <div className="rounded-[20px] border border-border/80 bg-card divide-y divide-border/60 overflow-hidden shadow-xs">
                      {/* Tile 1: My Orders & Purchases */}
                      <button
                        type="button"
                        onClick={() => setActiveTab("orders")}
                        className="flex w-full items-center justify-between px-4 py-3.5 hover:bg-muted/30 active:bg-muted/60 transition-colors text-left"
                      >
                        <div className="flex items-center gap-3.5 min-w-0">
                          <div className="size-10 rounded-[12px] bg-[#F1F5F9] dark:bg-muted/60 flex items-center justify-center shrink-0 text-[#1E293B] dark:text-foreground">
                            <ShoppingBag className="size-4.5" />
                          </div>
                          <div className="min-w-0">
                            <p className="text-[13.5px] font-bold text-foreground leading-snug truncate">
                              My Orders &amp; Purchases
                            </p>
                            <p className="text-[11px] text-muted-foreground leading-snug truncate mt-0.5">
                              View order history, status &amp; track delivery
                            </p>
                          </div>
                        </div>
                        <ChevronRight className="size-4.5 text-muted-foreground/70 shrink-0 ml-2" />
                      </button>

                      {/* Tile 2: Saved Delivery Addresses */}
                      <button
                        type="button"
                        onClick={() => setActiveTab("addresses")}
                        className="flex w-full items-center justify-between px-4 py-3.5 hover:bg-muted/30 active:bg-muted/60 transition-colors text-left"
                      >
                        <div className="flex items-center gap-3.5 min-w-0">
                          <div className="size-10 rounded-[12px] bg-[#F1F5F9] dark:bg-muted/60 flex items-center justify-center shrink-0 text-[#1E293B] dark:text-foreground">
                            <MapPin className="size-4.5" />
                          </div>
                          <div className="min-w-0">
                            <p className="text-[13.5px] font-bold text-foreground leading-snug truncate">
                              Saved Delivery Addresses
                            </p>
                            <p className="text-[11px] text-muted-foreground leading-snug truncate mt-0.5">
                              {savedAddresses.find((a: any) => a.isDefault)
                                ? `${savedAddresses.find((a: any) => a.isDefault).city}, ${savedAddresses.find((a: any) => a.isDefault).name?.replace(/ Address$/i, "")} · Default`
                                : "Hyderabad, Home · Default"}
                            </p>
                          </div>
                        </div>
                        <ChevronRight className="size-4.5 text-muted-foreground/70 shrink-0 ml-2" />
                      </button>

                      {/* Tile 3: VEXA Wallet & Rewards */}
                      <button
                        type="button"
                        onClick={() => setActiveTab("wallet")}
                        className="flex w-full items-center justify-between px-4 py-3.5 hover:bg-muted/30 active:bg-muted/60 transition-colors text-left"
                      >
                        <div className="flex items-center gap-3.5 min-w-0">
                          <div className="size-10 rounded-[12px] bg-[#F1F5F9] dark:bg-muted/60 flex items-center justify-center shrink-0 text-[#1E293B] dark:text-foreground">
                            <Wallet className="size-4.5" />
                          </div>
                          <div className="min-w-0">
                            <p className="text-[13.5px] font-bold text-foreground leading-snug truncate">
                              VEXA Wallet &amp; Rewards
                            </p>
                            <p className="text-[11px] text-muted-foreground leading-snug truncate mt-0.5">
                              Balance: ₹{walletBalance.toFixed(0)}
                            </p>
                          </div>
                        </div>
                        <ChevronRight className="size-4.5 text-muted-foreground/70 shrink-0 ml-2" />
                      </button>

                      {/* Tile 4: 24/7 VIP Customer Support */}
                      <button
                        type="button"
                        onClick={() => setActiveTab("support")}
                        className="flex w-full items-center justify-between px-4 py-3.5 hover:bg-muted/30 active:bg-muted/60 transition-colors text-left"
                      >
                        <div className="flex items-center gap-3.5 min-w-0">
                          <div className="size-10 rounded-[12px] bg-[#F1F5F9] dark:bg-muted/60 flex items-center justify-center shrink-0 text-[#1E293B] dark:text-foreground">
                            <Headphones className="size-4.5" />
                          </div>
                          <div className="min-w-0">
                            <p className="text-[13.5px] font-bold text-foreground leading-snug truncate">
                              24/7 VIP Customer Support
                            </p>
                            <p className="text-[11px] text-muted-foreground leading-snug truncate mt-0.5">
                              Contact support@vexa.app or WhatsApp
                            </p>
                          </div>
                        </div>
                        <ChevronRight className="size-4.5 text-muted-foreground/70 shrink-0 ml-2" />
                      </button>

                      {/* Tile 5: About VEXA Brand Story */}
                      <button
                        type="button"
                        onClick={() => setShowBrandStoryModal(true)}
                        className="flex w-full items-center justify-between px-4 py-3.5 hover:bg-muted/30 active:bg-muted/60 transition-colors text-left"
                      >
                        <div className="flex items-center gap-3.5 min-w-0">
                          <div className="size-10 rounded-[12px] bg-[#F1F5F9] dark:bg-muted/60 flex items-center justify-center shrink-0 text-[#1E293B] dark:text-foreground">
                            <Sparkles className="size-4.5" />
                          </div>
                          <div className="min-w-0">
                            <p className="text-[13.5px] font-bold text-foreground leading-snug truncate">
                              About VEXA Brand Story
                            </p>
                            <p className="text-[11px] text-muted-foreground leading-snug truncate mt-0.5">
                              Discover our design philosophy
                            </p>
                          </div>
                        </div>
                        <ChevronRight className="size-4.5 text-muted-foreground/70 shrink-0 ml-2" />
                      </button>

                      {/* Tile 6: Terms & Conditions */}
                      <button
                        type="button"
                        onClick={() => setShowTermsModal(true)}
                        className="flex w-full items-center justify-between px-4 py-3.5 hover:bg-muted/30 active:bg-muted/60 transition-colors text-left"
                      >
                        <div className="flex items-center gap-3.5 min-w-0">
                          <div className="size-10 rounded-[12px] bg-[#F1F5F9] dark:bg-muted/60 flex items-center justify-center shrink-0 text-[#1E293B] dark:text-foreground">
                            <FileText className="size-4.5" />
                          </div>
                          <div className="min-w-0">
                            <p className="text-[13.5px] font-bold text-foreground leading-snug truncate">
                              Terms &amp; Conditions
                            </p>
                            <p className="text-[11px] text-muted-foreground leading-snug truncate mt-0.5">
                              Usage guidelines &amp; service policies
                            </p>
                          </div>
                        </div>
                        <ChevronRight className="size-4.5 text-muted-foreground/70 shrink-0 ml-2" />
                      </button>

                      {/* Tile 7: Privacy Policy */}
                      <button
                        type="button"
                        onClick={() => setShowPrivacyPolicyModal(true)}
                        className="flex w-full items-center justify-between px-4 py-3.5 hover:bg-muted/30 active:bg-muted/60 transition-colors text-left"
                      >
                        <div className="flex items-center gap-3.5 min-w-0">
                          <div className="size-10 rounded-[12px] bg-[#F1F5F9] dark:bg-muted/60 flex items-center justify-center shrink-0 text-[#1E293B] dark:text-foreground">
                            <Shield className="size-4.5" />
                          </div>
                          <div className="min-w-0">
                            <p className="text-[13.5px] font-bold text-foreground leading-snug truncate">
                              Privacy Policy
                            </p>
                            <p className="text-[11px] text-muted-foreground leading-snug truncate mt-0.5">
                              Data protection &amp; privacy rights
                            </p>
                          </div>
                        </div>
                        <ChevronRight className="size-4.5 text-muted-foreground/70 shrink-0 ml-2" />
                      </button>
                    </div>
                  </div>

                  {/* 3. LOG OUT ACTION BUTTON */}
                  <div className="pt-2">
                    <button
                      type="button"
                      onClick={() => {
                        logout();
                        navigate("/");
                      }}
                      className="w-full h-12 rounded-[14px] border border-border/80 bg-card hover:bg-muted/40 flex items-center justify-center gap-2 text-[12.5px] font-bold tracking-[0.08em] text-muted-foreground hover:text-foreground active:scale-[0.98] transition-all cursor-pointer shadow-xs"
                    >
                      <LogOut className="size-4 text-muted-foreground" />
                      <span>LOG OUT ACCOUNT</span>
                    </button>
                  </div>

                  {/* 4. DELETE ACCOUNT ACTION BUTTON */}
                  <div>
                    <button
                      type="button"
                      onClick={() => setShowDeleteAccountModal(true)}
                      className="w-full h-12 rounded-[14px] border border-rose-200 bg-[#FEF2F2] hover:bg-rose-100/70 flex items-center justify-center gap-2 text-[12.5px] font-bold tracking-[0.08em] text-rose-600 active:scale-[0.98] transition-all cursor-pointer shadow-xs"
                    >
                      <Trash2 className="size-4 text-rose-600" />
                      <span>DELETE ACCOUNT</span>
                    </button>
                  </div>

                  {/* 5. BRAND FOOTER */}
                  <div className="pt-2 pb-16 text-center">
                    <p className="text-[10.5px] text-muted-foreground/80 font-medium">
                      Version 1.0.0 (Production Build)
                    </p>
                  </div>
                </div>

                {/* ── DESKTOP VIEW (>= sm): KEEP COMPLETE CAPABLE DESKTOP PROFILE MANAGER ── */}
                <div className="hidden sm:block space-y-6 w-full">
                  {/* Profile Header Avatar Card */}
                  <div className="flex flex-col sm:flex-row items-center gap-5 rounded-xl border border-gold/30 bg-card p-5 sm:p-6 shadow-sm">
                    {/* Avatar Container with Hover Overlay */}
                    <div className="relative group size-20 shrink-0">
                      {profilePic ? (
                        <img
                          src={profilePic}
                          alt={resolvedDisplayName}
                          className="size-20 rounded-full object-cover border-2 border-gold shadow-md"
                        />
                      ) : (
                        <div className="flex size-20 items-center justify-center rounded-full border-2 border-gold bg-gold/15 font-display text-3xl font-extrabold text-gold shadow-md">
                          {resolvedAvatarInitial}
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
                      <h3 className="font-display text-xl font-bold text-foreground truncate">{resolvedDisplayName}</h3>
                      <p className="text-xs text-muted-foreground truncate">{resolvedDisplayEmail}</p>

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

                  {/* Account Quick Stats Grid */}
                  <div className="grid grid-cols-3 gap-2 sm:gap-3">
                    <div className="rounded-xl border border-gold/30 bg-surface/50 p-3 sm:p-4 text-center shadow-xs">
                      <span className="text-[8.5px] sm:text-[9px] uppercase tracking-widest text-muted-foreground font-bold block">Orders</span>
                      <span className="font-display text-sm sm:text-base font-bold text-gold mt-0.5 block">{myOrders.length}</span>
                    </div>
                    <div className="rounded-xl border border-gold/30 bg-surface/50 p-3 sm:p-4 text-center shadow-xs">
                      <span className="text-[8.5px] sm:text-[9px] uppercase tracking-widest text-muted-foreground font-bold block">Wishlist</span>
                      <span className="font-display text-sm sm:text-base font-bold text-foreground mt-0.5 block">{wishlistItems?.length || 0}</span>
                    </div>
                    <div className="rounded-xl border border-gold/30 bg-surface/50 p-3 sm:p-4 text-center shadow-xs">
                      <span className="text-[8.5px] sm:text-[9px] uppercase tracking-widest text-muted-foreground font-bold block">Status</span>
                      <span className="font-display text-xs sm:text-sm font-bold text-emerald-500 mt-1 block">VIP Member</span>
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
                        Personal &amp; Contact Details
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

                {/* ── EDIT PROFILE MODAL ── */}
                {showEditProfileModal && (
                  <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
                    <div className="w-full max-w-md rounded-2xl border border-gold/40 bg-card p-6 shadow-2xl space-y-5 animate-in zoom-in-95 duration-200">
                      <div className="flex items-center justify-between border-b border-border pb-3">
                        <h3 className="font-display text-base font-bold text-foreground">Edit Profile</h3>
                        <button
                          type="button"
                          onClick={() => setShowEditProfileModal(false)}
                          className="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:text-foreground hover:bg-muted/50 cursor-pointer"
                        >
                          <X className="size-4" />
                        </button>
                      </div>

                      {/* Avatar Uploader in Modal */}
                      <div className="flex items-center gap-4">
                        <div className="relative size-16 rounded-full bg-[#FAF5E6] dark:bg-gold/15 border-2 border-gold flex items-center justify-center overflow-hidden shrink-0">
                          {profilePic ? (
                            <img src={profilePic} alt={editProfileName} className="size-full object-cover" />
                          ) : (
                            <span className="font-display text-xl font-bold text-[#8C6D23] dark:text-gold">
                              {(editProfileName || "T")[0].toUpperCase()}
                            </span>
                          )}
                        </div>
                        <div className="flex flex-wrap gap-2">
                          <label
                            htmlFor="profile-pic-modal-input"
                            className="flex items-center gap-1.5 rounded-lg border border-gold/50 bg-gold/10 px-3 py-1.5 text-xs font-bold text-gold hover:bg-gold hover:text-primary-foreground transition-all cursor-pointer shadow-xs active:scale-95"
                          >
                            <Camera className="size-3.5" />
                            {profilePic ? "Change Photo" : "Upload Photo"}
                          </label>
                          <input
                            type="file"
                            id="profile-pic-modal-input"
                            accept="image/*"
                            onChange={handleAvatarUpload}
                            className="hidden"
                          />
                          {profilePic && (
                            <button
                              type="button"
                              onClick={handleRemoveAvatar}
                              className="flex items-center gap-1.5 rounded-lg border border-destructive/40 bg-destructive/10 px-3 py-1.5 text-xs font-bold text-destructive hover:bg-destructive hover:text-white transition-all cursor-pointer shadow-xs active:scale-95"
                            >
                              <Trash2 className="size-3.5" />
                              Remove
                            </button>
                          )}
                        </div>
                      </div>

                      <form
                        onSubmit={(e) => {
                          e.preventDefault();
                          setProfileName(editProfileName);
                          setProfileEmail(editProfileEmail);
                          setProfileMobile(editProfileMobile);
                          setLoggedIn({
                            name: editProfileName,
                            email: editProfileEmail,
                            role: user?.role || "user",
                          });
                          setShowEditProfileModal(false);
                          setProfileSavedMsg("Profile updated successfully!");
                          setTimeout(() => setProfileSavedMsg(""), 3500);
                        }}
                        className="space-y-4"
                      >
                        <div>
                          <label className="text-[10px] uppercase tracking-widest text-gold font-bold flex items-center gap-1.5 mb-1.5">
                            <UserIcon className="size-3.5" /> Full Name
                          </label>
                          <input
                            type="text"
                            value={editProfileName}
                            onChange={(e) => setEditProfileName(e.target.value)}
                            className="w-full rounded-lg border border-border bg-surface/50 px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold transition-colors"
                            required
                          />
                        </div>

                        <div>
                          <label className="text-[10px] uppercase tracking-widest text-gold font-bold flex items-center gap-1.5 mb-1.5">
                            <Mail className="size-3.5" /> Email Address
                          </label>
                          <input
                            type="email"
                            value={editProfileEmail}
                            onChange={(e) => setEditProfileEmail(e.target.value)}
                            className="w-full rounded-lg border border-border bg-surface/50 px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold transition-colors"
                            required
                          />
                        </div>

                        <div>
                          <label className="text-[10px] uppercase tracking-widest text-gold font-bold flex items-center gap-1.5 mb-1.5">
                            <Phone className="size-3.5" /> Mobile Number
                          </label>
                          <input
                            type="text"
                            value={editProfileMobile}
                            onChange={(e) => setEditProfileMobile(e.target.value)}
                            className="w-full rounded-lg border border-border bg-surface/50 px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-gold font-mono transition-colors"
                          />
                        </div>

                        <div className="flex gap-2.5 pt-2">
                          <button
                            type="button"
                            onClick={() => setShowEditProfileModal(false)}
                            className="flex-1 rounded-lg border border-border bg-muted/30 py-2.5 text-xs font-bold text-muted-foreground hover:text-foreground transition-all cursor-pointer"
                          >
                            Cancel
                          </button>
                          <button
                            type="submit"
                            className="flex-1 rounded-lg bg-gold py-2.5 text-xs font-bold uppercase tracking-wider text-primary-foreground hover:bg-gold/90 transition-all shadow-goldy cursor-pointer"
                          >
                            Save Changes
                          </button>
                        </div>
                      </form>
                    </div>
                  </div>
                )}

                {/* ── BRAND STORY MODAL ── */}
                {showBrandStoryModal && (
                  <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
                    <div className="w-full max-w-md rounded-2xl border border-gold/40 bg-card p-6 shadow-2xl space-y-4 animate-in zoom-in-95 duration-200">
                      <div className="flex items-center justify-between border-b border-border pb-3">
                        <div className="flex items-center gap-2">
                          <Sparkles className="size-5 text-gold" />
                          <h3 className="font-display text-base font-bold text-foreground">About VEXA Brand Story</h3>
                        </div>
                        <button
                          type="button"
                          onClick={() => setShowBrandStoryModal(false)}
                          className="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:text-foreground hover:bg-muted/50 cursor-pointer"
                        >
                          <X className="size-4" />
                        </button>
                      </div>
                      <div className="text-xs text-muted-foreground leading-relaxed space-y-3">
                        <p>
                          Born from the confluence of avant-garde streetwear and bespoke modern minimalism, VEXA redefines luxury for the modern trendsetter.
                        </p>
                        <p>
                          Every garment is meticulously engineered using heavyweight organic textiles, architectural silhouettes, and enduring craftsmanship designed to make you wear confidence every day.
                        </p>
                      </div>
                      <div className="pt-2 flex gap-2.5">
                        <button
                          type="button"
                          onClick={() => {
                            setShowBrandStoryModal(false);
                            navigate("/about");
                          }}
                          className="flex-1 rounded-lg bg-gold py-2.5 text-xs font-bold uppercase tracking-wider text-primary-foreground hover:bg-gold/90 transition-all shadow-goldy cursor-pointer"
                        >
                          Read Full Story
                        </button>
                        <button
                          type="button"
                          onClick={() => setShowBrandStoryModal(false)}
                          className="rounded-lg border border-border px-4 py-2.5 text-xs font-bold text-muted-foreground hover:text-foreground transition-all cursor-pointer"
                        >
                          Close
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {/* ── TERMS & CONDITIONS MODAL ── */}
                {showTermsModal && (
                  <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
                    <div className="w-full max-w-md rounded-2xl border border-gold/40 bg-card p-6 shadow-2xl space-y-4 animate-in zoom-in-95 duration-200 max-h-[85vh] overflow-y-auto">
                      <div className="flex items-center justify-between border-b border-border pb-3">
                        <div className="flex items-center gap-2">
                          <FileText className="size-5 text-gold" />
                          <h3 className="font-display text-base font-bold text-foreground">Terms &amp; Conditions</h3>
                        </div>
                        <button
                          type="button"
                          onClick={() => setShowTermsModal(false)}
                          className="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:text-foreground hover:bg-muted/50 cursor-pointer"
                        >
                          <X className="size-4" />
                        </button>
                      </div>
                      <div className="text-xs text-muted-foreground leading-relaxed space-y-3">
                        <div>
                          <p className="font-bold text-foreground mb-1">1. Acceptance of Service</p>
                          <p>By browsing or purchasing from VEXA, you agree to our terms of premium service, authentic verification guarantee, and digital account policies.</p>
                        </div>
                        <div>
                          <p className="font-bold text-foreground mb-1">2. Shipping &amp; Real-time Tracking</p>
                          <p>All luxury deliveries are insured and fulfilled via priority express carriers with live OTP tracking and verified dispatch.</p>
                        </div>
                        <div>
                          <p className="font-bold text-foreground mb-1">3. 7-Day Hassle-free Exchange</p>
                          <p>Unworn items with original luxury tags and packaging can be exchanged or credited within 7 calendar days of delivery.</p>
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={() => setShowTermsModal(false)}
                        className="w-full rounded-lg bg-gold py-2.5 text-xs font-bold uppercase tracking-wider text-primary-foreground hover:bg-gold/90 transition-all shadow-goldy cursor-pointer mt-2"
                      >
                        I Understand
                      </button>
                    </div>
                  </div>
                )}

                {/* ── PRIVACY POLICY MODAL ── */}
                {showPrivacyPolicyModal && (
                  <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
                    <div className="w-full max-w-md rounded-2xl border border-gold/40 bg-card p-6 shadow-2xl space-y-4 animate-in zoom-in-95 duration-200 max-h-[85vh] overflow-y-auto">
                      <div className="flex items-center justify-between border-b border-border pb-3">
                        <div className="flex items-center gap-2">
                          <Shield className="size-5 text-gold" />
                          <h3 className="font-display text-base font-bold text-foreground">Privacy Policy</h3>
                        </div>
                        <button
                          type="button"
                          onClick={() => setShowPrivacyPolicyModal(false)}
                          className="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:text-foreground hover:bg-muted/50 cursor-pointer"
                        >
                          <X className="size-4" />
                        </button>
                      </div>
                      <div className="text-xs text-muted-foreground leading-relaxed space-y-3">
                        <div>
                          <p className="font-bold text-foreground mb-1">1. Encryption &amp; Security</p>
                          <p>Your payment methods, passwords, and personal details are protected using enterprise-grade AES-256 and SSL encryption protocols.</p>
                        </div>
                        <div>
                          <p className="font-bold text-foreground mb-1">2. Strict Zero Data Sale Guarantee</p>
                          <p>VEXA will never sell, rent, or trade your personal information or address credentials to advertisers or third parties.</p>
                        </div>
                        <div>
                          <p className="font-bold text-foreground mb-1">3. Account Ownership &amp; Erasure</p>
                          <p>You have full authority to request complete deletion of your profile history, wallet points, and saved addresses at any time.</p>
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={() => setShowPrivacyPolicyModal(false)}
                        className="w-full rounded-lg bg-gold py-2.5 text-xs font-bold uppercase tracking-wider text-primary-foreground hover:bg-gold/90 transition-all shadow-goldy cursor-pointer mt-2"
                      >
                        Close
                      </button>
                    </div>
                  </div>
                )}

                {/* ── DELETE ACCOUNT CONFIRMATION MODAL ── */}
                {showDeleteAccountModal && (
                  <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
                    <div className="w-full max-w-md rounded-2xl border border-destructive/40 bg-card p-6 shadow-2xl space-y-4 animate-in zoom-in-95 duration-200">
                      <div className="flex items-center justify-between border-b border-border pb-3">
                        <div className="flex items-center gap-2 text-destructive">
                          <Trash2 className="size-5" />
                          <h3 className="font-display text-base font-bold">Delete Account?</h3>
                        </div>
                        <button
                          type="button"
                          onClick={() => setShowDeleteAccountModal(false)}
                          className="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:text-foreground hover:bg-muted/50 cursor-pointer"
                        >
                          <X className="size-4" />
                        </button>
                      </div>
                      <p className="text-xs text-muted-foreground leading-relaxed">
                        Are you sure you want to delete your VEXA profile? This action will permanently remove all your order history, delivery addresses, wallet credits, and VIP status. This cannot be undone.
                      </p>
                      <div className="flex gap-2.5 pt-2">
                        <button
                          type="button"
                          onClick={() => setShowDeleteAccountModal(false)}
                          className="flex-1 rounded-lg border border-border bg-muted/30 py-2.5 text-xs font-bold text-muted-foreground hover:text-foreground transition-all cursor-pointer"
                        >
                          Cancel
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setShowDeleteAccountModal(false);
                            logout();
                            navigate("/");
                          }}
                          className="flex-1 rounded-lg bg-destructive py-2.5 text-xs font-bold uppercase tracking-wider text-destructive-foreground hover:bg-destructive/90 transition-all cursor-pointer shadow-sm"
                        >
                          Yes, Delete
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* 2. MY ORDERS TAB */}
            {activeTab === "orders" && (
              <div className="w-full">
                {/* ── MOBILE VIEW (< sm): 1:1 PIXEL-PERFECT REPLICA OF FLUTTER MY ORDERS SCREEN ── */}
                <div className="block sm:hidden -mx-4 -mt-4 pb-20">
                  {/* 1. SEARCH BAR & FILTERS BUTTON (SIDE-BY-SIDE) - Hides when scrolling in mobile responsive view */}
                  <div
                    className={`px-4 bg-background transition-all duration-300 ease-in-out overflow-hidden ${
                      hideMobileOrderSearch
                        ? "max-h-0 py-0 opacity-0 pointer-events-none -translate-y-3"
                        : "max-h-24 py-3 opacity-100 translate-y-0"
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      {/* Pill Search Input */}
                      <div className="flex-1 h-11 rounded-full border border-slate-200 dark:border-border bg-white dark:bg-card px-3.5 flex items-center gap-2 shadow-[0_2px_8px_rgba(0,0,0,0.03)]">
                        <Search className="size-4.5 text-slate-400 shrink-0" />
                        <input
                          type="text"
                          value={orderSearchQuery}
                          onChange={(e) => setOrderSearchQuery(e.target.value)}
                          placeholder="Search your order here"
                          className="w-full bg-transparent text-xs text-foreground placeholder:text-slate-400 outline-none"
                        />
                        {orderSearchQuery && (
                          <button
                            type="button"
                            onClick={() => setOrderSearchQuery("")}
                            className="text-slate-400 hover:text-foreground p-0.5 shrink-0"
                          >
                            <X className="size-3.5" />
                          </button>
                        )}
                      </div>

                      {/* Filters Pill Button with Dropdown Popup */}
                      <div className="relative shrink-0">
                        <button
                          type="button"
                          onClick={() => setShowOrderFilterMenu((o) => !o)}
                          className="h-11 px-4 rounded-full border border-slate-200 dark:border-border bg-white dark:bg-card flex items-center gap-1.5 shadow-[0_2px_8px_rgba(0,0,0,0.03)] text-xs font-semibold text-slate-700 dark:text-foreground cursor-pointer active:scale-95 transition-transform"
                        >
                          <SlidersHorizontal className="size-3.5 text-slate-600 dark:text-foreground shrink-0" />
                          <span>{selectedMobileOrderFilter !== "All" ? selectedMobileOrderFilter : "Filters"}</span>
                        </button>

                        {/* Filter Options Menu */}
                        {showOrderFilterMenu && (
                          <>
                            <div
                              className="fixed inset-0 z-30"
                              onClick={() => setShowOrderFilterMenu(false)}
                            />
                            <div className="absolute right-0 top-12 z-40 w-44 rounded-2xl border border-border bg-card p-1.5 shadow-xl animate-in fade-in zoom-in-95 duration-150 space-y-0.5">
                              {[
                                { label: "All Orders", value: "All" },
                                { label: "Expected / Shipped", value: "Shipped" },
                                { label: "Delivered", value: "Delivered" },
                                { label: "Cancelled", value: "Cancelled" },
                              ].map((opt) => (
                                <button
                                  key={opt.value}
                                  type="button"
                                  onClick={() => {
                                    setSelectedMobileOrderFilter(opt.value as any);
                                    setShowOrderFilterMenu(false);
                                  }}
                                  className={`flex w-full items-center justify-between px-3 py-2 text-xs font-medium rounded-xl transition-colors ${
                                    selectedMobileOrderFilter === opt.value
                                      ? "bg-gold/15 text-gold font-bold"
                                      : "text-foreground hover:bg-muted/50"
                                  }`}
                                >
                                  <span>{opt.label}</span>
                                  {selectedMobileOrderFilter === opt.value && (
                                    <Check className="size-3.5 text-gold shrink-0" />
                                  )}
                                </button>
                              ))}
                            </div>
                          </>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* 2. ORDERS LIST */}
                  {filteredMobileOrders.length === 0 ? (
                    <div className="mx-4 my-8 p-8 rounded-2xl border border-border bg-card text-center space-y-3">
                      <div className="size-16 rounded-full bg-gold/15 text-gold flex items-center justify-center mx-auto">
                        <Truck className="size-8" />
                      </div>
                      <h4 className="font-display text-base font-bold text-foreground">
                        {orderSearchQuery || selectedMobileOrderFilter !== "All"
                          ? "No Matching Orders"
                          : "No Orders Placed Yet"}
                      </h4>
                      <p className="text-xs text-muted-foreground leading-relaxed max-w-xs mx-auto">
                        {orderSearchQuery || selectedMobileOrderFilter !== "All"
                          ? "Try changing your filter settings or search query to view other purchases."
                          : "Explore our luxury garment collection and place your first order."}
                      </p>
                    </div>
                  ) : (
                    <div className="bg-card divide-y divide-slate-100 dark:divide-border/60">
                      {filteredMobileOrders.map((ord, idx) => {
                        const firstItem = ord.items && ord.items.length > 0 ? ord.items[0] : null;
                        const status = (ord.status || "").toLowerCase();
                        const isDelivered = status.includes("deliver");
                        const isCancelled = status.includes("cancel");
                        const isShipped = status.includes("ship") || status.includes("transit");
                        const isCOD = ord.paymentMethod?.toLowerCase().includes("cod") || ord.paymentMethod?.toLowerCase().includes("cash");
                        const isUnpaidOrActive = isCOD && !isDelivered && !isCancelled;

                        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                        const orderDate = ord.createdAt ? new Date(ord.createdAt) : new Date();

                        let headerText = "";
                        if (isCancelled) {
                          const m = months[orderDate.getMonth()];
                          const d = String(orderDate.getDate()).padStart(2, "0");
                          headerText = `Cancelled on ${m} ${d}, ${orderDate.getFullYear()}`;
                        } else if (isDelivered) {
                          const delDate = new Date(orderDate.getTime() + 2 * 24 * 3600 * 1000);
                          const m = months[delDate.getMonth()];
                          const d = String(delDate.getDate()).padStart(2, "0");
                          headerText = `Delivered on ${m} ${d}`;
                        } else {
                          const expDate = new Date(orderDate.getTime() + 3 * 24 * 3600 * 1000);
                          const m = months[expDate.getMonth()];
                          const d = String(expDate.getDate()).padStart(2, "0");
                          headerText = `Delivery expected by ${m} ${d}`;
                        }

                        let subtitleText = "";
                        if (isCancelled) {
                          subtitleText = ord.cancelReason || "Changed my mind / Placed by mistake";
                        } else if (isDelivered) {
                          subtitleText = firstItem
                            ? `Item delivered at doorstep · ${firstItem.name}`
                            : "Package delivered to customer successfully";
                        } else if (isShipped) {
                          subtitleText = "In Transit via VEXA Express Courier...";
                        } else if (status.includes("qc") || status.includes("quality")) {
                          subtitleText = "Quality Check Active at Central QC Hub...";
                        } else {
                          subtitleText = "Warehouse Dispatch Active · Packing Garment...";
                        }

                        return (
                          <div key={ord._id || ord.id || idx}>
                            <div
                              onClick={() => setSelectedOrderDetailsModal(ord)}
                              className="px-4 py-3.5 flex items-start gap-3.5 hover:bg-muted/20 active:bg-muted/40 transition-colors cursor-pointer"
                            >
                              {/* Thumbnail Box */}
                              <div className="size-16 rounded-[10px] bg-slate-100 dark:bg-muted border border-slate-200 dark:border-border overflow-hidden shrink-0 flex items-center justify-center">
                                {firstItem ? (
                                  <img
                                    src={getProductImage(firstItem)}
                                    alt={firstItem.name}
                                    className="size-full object-cover"
                                  />
                                ) : (
                                  <Package className="size-6 text-muted-foreground" />
                                )}
                              </div>

                              {/* Details Stack */}
                              <div className="flex-1 min-w-0 pt-0.5">
                                <h3 className="font-bold text-[14px] text-[#0F172A] dark:text-foreground leading-snug truncate">
                                  {headerText}
                                </h3>
                                <p className="text-[12px] text-slate-500 dark:text-muted-foreground leading-snug line-clamp-2 mt-0.5 font-normal">
                                  {subtitleText}
                                </p>
                              </div>

                              {/* Chevron Right */}
                              <ChevronRight className="size-5 text-[#0F172A] dark:text-foreground shrink-0 mt-2 ml-1" />
                            </div>

                            {/* COD Payment Banner (Matches Screenshot 1:1) */}
                            {isUnpaidOrActive && (
                              <div className="mx-4 mb-3.5 p-3 rounded-[10px] bg-[#FFFBEB] dark:bg-amber-950/20 border border-[#FDE68A] dark:border-amber-900/40 flex items-center justify-between gap-3 shadow-xs">
                                <p className="text-xs text-[#92400E] dark:text-amber-200 font-medium leading-snug">
                                  Pay right now and save the COD fee
                                </p>
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setMyOrders((prev) =>
                                      prev.map((o) =>
                                        (o._id === ord._id || o.id === ord.id)
                                          ? { ...o, paymentMethod: "Razorpay Instant UPI", status: "Processing" }
                                          : o
                                      )
                                    );
                                    setProfileSavedMsg("Payment of ₹" + (ord.totalAmount || 2241) + " received! COD fee saved.");
                                    setTimeout(() => setProfileSavedMsg(""), 3500);
                                  }}
                                  className="rounded-lg border border-[#D4AF37] bg-white dark:bg-card px-3.5 py-1.5 text-xs font-bold text-[#92400E] dark:text-gold hover:bg-gold/10 transition-colors shrink-0 shadow-xs active:scale-95 cursor-pointer"
                                >
                                  Pay ₹{(ord.totalAmount || 2241).toFixed(0)}
                                </button>
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>

                {/* ── DESKTOP VIEW (>= sm): KEEP COMPLETE FULL CAPABILITY DESKTOP ORDER VIEW ── */}
                <div className="hidden sm:block space-y-6 min-w-0 pt-0">
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
                  <div className="rounded-xl border border-border bg-card p-3 sm:p-4 shadow-sm min-w-0 space-y-3">
                    {/* Status Filter Chips */}
                    <div className="flex items-center gap-1.5 sm:gap-2 overflow-x-auto no-scrollbar py-0.5 min-w-0">
                      {["All", "Processing", "Shipped", "Delivered", "Cancelled"].map((st) => (
                        <button
                          key={st}
                          type="button"
                          onClick={() => setOrderStatusFilter(st)}
                          className={`rounded-full px-2.5 sm:px-3.5 py-1 sm:py-1.5 text-[11px] sm:text-xs font-semibold transition-all cursor-pointer whitespace-nowrap shrink-0 ${
                            orderStatusFilter === st
                              ? "bg-gold text-primary-foreground shadow-sm font-bold"
                              : "border border-border bg-background text-muted-foreground hover:border-gold/50 hover:text-gold"
                          }`}
                        >
                          {st}
                        </button>
                      ))}
                    </div>

                    {/* Divider between Filter and Sort */}
                    <div className="h-px w-full bg-border/60" />

                    {/* Sort & Count Row - cleanly aligned */}
                    <div className="flex items-center justify-between gap-3">
                      <span className="text-[11px] sm:text-xs font-medium text-muted-foreground">
                        Showing <span className="font-bold text-foreground">{sortedOrders.length}</span> {sortedOrders.length === 1 ? "order" : "orders"}
                      </span>

                      <div className="flex items-center gap-2 shrink-0">
                        <span className="text-[11px] sm:text-xs font-semibold text-muted-foreground whitespace-nowrap">Sort by:</span>
                        <select
                          value={orderSortBy}
                          onChange={(e) => setOrderSortBy(e.target.value as any)}
                          className="rounded-lg border border-border bg-background px-2.5 sm:px-3 py-1 sm:py-1.5 text-xs font-semibold text-gold outline-none focus:border-gold cursor-pointer"
                        >
                          <option value="newest">Newest First</option>
                          <option value="oldest">Oldest First</option>
                          <option value="price-high">Price: High to Low</option>
                          <option value="price-low">Price: Low to High</option>
                        </select>
                      </div>
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
                                src={getProductImage(item)}
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

              {/* ── ORDER DETAILS BOTTOM SHEET / MODAL ON MOBILE ── */}
              {selectedOrderDetailsModal && (
                <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60 backdrop-blur-xs p-0 sm:p-4 animate-in fade-in duration-200">
                  <div className="w-full sm:max-w-md rounded-t-[24px] sm:rounded-2xl border border-gold/40 bg-card p-5 sm:p-6 shadow-2xl max-h-[88vh] overflow-y-auto space-y-4 animate-in slide-in-from-bottom-4 sm:zoom-in-95 duration-200">
                    <div className="flex items-center justify-between border-b border-border pb-3">
                      <div>
                        <span className="text-[10px] uppercase tracking-widest text-gold font-bold">Order Details</span>
                        <h3 className="font-display text-base font-bold text-foreground">
                          #{String(selectedOrderDetailsModal._id || selectedOrderDetailsModal.id || "ORD").slice(-8).toUpperCase()}
                        </h3>
                      </div>
                      <button
                        type="button"
                        onClick={() => setSelectedOrderDetailsModal(null)}
                        className="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:text-foreground hover:bg-muted/50 cursor-pointer"
                      >
                        <X className="size-4" />
                      </button>
                    </div>

                    {/* Status Badge & Total */}
                    <div className="flex items-center justify-between bg-muted/40 p-3 rounded-xl border border-border/70">
                      <div>
                        <span className="text-[10px] text-muted-foreground block">Current Status</span>
                        <span className="font-bold text-xs uppercase text-gold">
                          {selectedOrderDetailsModal.status || "Processing"}
                        </span>
                      </div>
                      <div className="text-right">
                        <span className="text-[10px] text-muted-foreground block">Total Amount</span>
                        <span className="font-display font-bold text-sm text-foreground">
                          ₹{(selectedOrderDetailsModal.totalAmount || 0).toLocaleString("en-IN")}
                        </span>
                      </div>
                    </div>

                    {/* Items List */}
                    <div className="space-y-2.5">
                      <span className="text-[11px] uppercase tracking-wider font-bold text-muted-foreground block">
                        Ordered Garments ({selectedOrderDetailsModal.items?.length || 0})
                      </span>
                      {(selectedOrderDetailsModal.items || []).map((item, i) => (
                        <div key={i} className="flex items-center gap-3 p-2 rounded-xl bg-surface/50 border border-border/60">
                          <img
                            src={getProductImage(item)}
                            alt={item.name}
                            className="size-12 rounded-lg object-cover border border-border/60 shrink-0"
                          />
                          <div className="flex-1 min-w-0">
                            <p className="text-xs font-bold text-foreground truncate">{item.name}</p>
                            <p className="text-[10px] text-muted-foreground">
                              Size: {item.size} · Color: {item.color} · Qty: {item.quantity}
                            </p>
                          </div>
                          <span className="text-xs font-bold text-gold shrink-0">
                            ₹{(item.price * item.quantity).toLocaleString("en-IN")}
                          </span>
                        </div>
                      ))}
                    </div>

                    {/* Delivery Address */}
                    <div className="p-3 rounded-xl bg-surface/40 border border-border/60 space-y-1">
                      <span className="text-[10px] uppercase tracking-wider font-bold text-muted-foreground flex items-center gap-1">
                        <MapPin className="size-3 text-gold" /> Delivery Destination
                      </span>
                      <p className="text-xs text-foreground font-medium">
                        {selectedOrderDetailsModal.shippingAddress || "Plot 42, Jubilee Hills, Hyderabad"}
                      </p>
                    </div>

                    {/* Actions */}
                    <div className="pt-2 flex gap-2">
                      {selectedOrderDetailsModal.status !== "Cancelled" && selectedOrderDetailsModal.status !== "Delivered" && (
                        <button
                          type="button"
                          onClick={() => {
                            setCancellingOrderUser({
                              id: selectedOrderDetailsModal._id || selectedOrderDetailsModal.id || "",
                              bookingIdStr: String(selectedOrderDetailsModal._id || selectedOrderDetailsModal.id || "").slice(-8).toUpperCase(),
                            });
                            setSelectedOrderDetailsModal(null);
                          }}
                          className="flex-1 rounded-xl border border-destructive/40 bg-destructive/10 py-2.5 text-xs font-bold text-destructive hover:bg-destructive hover:text-white transition-all cursor-pointer"
                        >
                          Cancel Order
                        </button>
                      )}
                      <button
                        type="button"
                        onClick={() => setSelectedOrderDetailsModal(null)}
                        className="flex-1 rounded-xl bg-gold py-2.5 text-xs font-bold text-primary-foreground uppercase tracking-wider shadow-goldy cursor-pointer"
                      >
                        Close
                      </button>
                    </div>
                  </div>
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
                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                            Select Payment Method
                          </label>
                        </div>

                        <div className="grid gap-2.5 sm:grid-cols-2">
                          {[
                            { id: "Razorpay Online Payment (UPI, Cards, NetBanking, Wallets)", label: "Razorpay Online Payment", desc: "Official Razorpay (UPI, Cards, Wallets, NetBanking)" },
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
                <div className="hidden sm:flex sm:flex-row sm:items-center justify-between border-b border-border pb-4 gap-3">
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

            {/* Dashboard Aligned Footer */}
            <div className="hidden sm:block w-full mt-auto pt-8">
              <Footer />
            </div>
          </main>
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
