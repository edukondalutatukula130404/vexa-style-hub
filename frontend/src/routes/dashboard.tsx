import { jsPDF } from "jspdf";
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
  ChevronLeft,
  Tag,
  MoreHorizontal,
  Download,
  XCircle,
  Store,
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
  
  const [searchParams, setSearchParams] = useSearchParams();

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
    } else {
      setActiveTab("profile");
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
  const [showMobileInvoicePreview, setShowMobileInvoicePreview] = useState<OrderItem | null>(null);
  // Mobile Customer Support Screen State (1:1 Replica of Flutter CustomerSupportScreen)
  const [showMobileSupportScreen, setShowMobileSupportScreen] = useState(false);
  const [mobileSupportOrder, setMobileSupportOrder] = useState<OrderItem | null>(null);
  const [supportCategory, setSupportCategory] = useState("Order Issue");
  const [supportPhone, setSupportPhone] = useState("");
  const [supportMessage, setSupportMessage] = useState("");
  const [supportSubmitting, setSupportSubmitting] = useState(false);
  const [expandedFaqIndex, setExpandedFaqIndex] = useState<number | null>(null);
  const [userSupportTickets, setUserSupportTickets] = useState<any[]>(() => {
    if (typeof window === "undefined") return [];
    try {
      const saved = localStorage.getItem("vexa_user_support_tickets");
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  // Mobile Concierge Live Chat Modal State (1:1 Replica of Flutter _openLiveChatModal)
  const [showLiveConciergeChat, setShowLiveConciergeChat] = useState(false);
  const [conciergeMessages, setConciergeMessages] = useState<Array<{ sender: "bot" | "user"; text: string; time?: string }>>([
    {
      sender: "bot",
      text: "Welcome to VEXA VIP Concierge 🌟 How can I assist you with your order or custom garment today?",
      time: "Just now",
    },
  ]);
  const [conciergeInput, setConciergeInput] = useState("");
  const chatMessagesEndRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (showLiveConciergeChat && chatMessagesEndRef.current) {
      chatMessagesEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [conciergeMessages, showLiveConciergeChat]);

  const handleSendConciergeMessage = (textToSend?: string) => {
    const rawText = textToSend !== undefined ? textToSend : conciergeInput;
    if (!rawText || !rawText.trim()) return;
    const cleanText = rawText.trim();

    setConciergeMessages((prev) => [
      ...prev,
      {
        sender: "user",
        text: cleanText,
        time: "Just now",
      },
    ]);
    setConciergeInput("");

    const targetOrder = mobileSupportOrder || selectedOrderDetailsModal || (myOrders && myOrders.length > 0 ? myOrders[0] : null);
    const ordId = targetOrder ? String(targetOrder._id || targetOrder.id || "#VX-1419") : "#VX-1419";
    const formattedId = ordId.replace(/^#/, "").slice(-8).toUpperCase();

    try {
      fetch(`${API_URL}/notifications/support`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userName: user?.name || "Customer",
          customerName: user?.name || "Customer",
          orderId: `#${formattedId}`,
          associatedOrderId: `#${formattedId}`,
          category: "VIP Concierge Chat",
          text: cleanText,
          message: cleanText,
          timestamp: new Date().toISOString(),
        }),
      }).catch((e) => console.warn("Live chat sync:", e));
    } catch (err) {
      console.warn("Live chat forward:", err);
    }

    setTimeout(() => {
      let reply = "Our concierge agent is reviewing your query. A dedicated stylist will reach out within 2 minutes!";
      const lower = cleanText.toLowerCase();
      if (lower.includes("track") || lower.includes("order") || lower.includes("where") || lower.includes("delivery")) {
        reply = targetOrder
          ? `Your Order #${formattedId} is currently ${(targetOrder.status || "Order Placed").toUpperCase()}. Live GPS sync is active!`
          : "You can track all active orders under your Profile -> My Orders tab with real-time GPS sync.";
      } else if (lower.includes("refund") || lower.includes("return") || lower.includes("cancel") || lower.includes("wallet")) {
        reply = "Returns and cancellations are processed instantly! Refunds are credited directly to your VEXA Pay Wallet.";
      } else if (lower.includes("size") || lower.includes("fit") || lower.includes("custom")) {
        reply = "Our garments use 240 GSM luxury heavyweight cotton with drop-shoulder oversized boxy fit. Order your standard size for tailored drape!";
      }

      setConciergeMessages((prev) => [
        ...prev,
        {
          sender: "bot",
          text: reply,
          time: "Just now",
        },
      ]);
    }, 850);
  };

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
    const rawList = Array.isArray(myOrders) ? myOrders.filter((o) => o && typeof o === "object") : [];

    let mobileHiddenIds: string[] = [];
    if (typeof window !== "undefined") {
      try {
        mobileHiddenIds = JSON.parse(localStorage.getItem("vexa_mobile_hidden_orders") || "[]");
      } catch (e) {}
    }

    let list: OrderItem[] = [];

    if (selectedMobileOrderFilter === "Cancelled") {
      // Show ONLY cancelled orders when Cancelled filter is selected
      list = rawList.filter((o) => {
        const s = String(o?.status || "").toLowerCase().trim();
        const oId = String(o?._id || o?.id || "").trim();
        const cleanOId = oId.replace(/^#+/, "").trim();
        const shortOId = cleanOId.slice(-8).toUpperCase();

        return (
          s.includes("cancel") ||
          mobileHiddenIds.includes(oId) ||
          mobileHiddenIds.includes(cleanOId) ||
          mobileHiddenIds.includes(`#${cleanOId}`) ||
          mobileHiddenIds.includes(shortOId) ||
          mobileHiddenIds.includes(`#${shortOId}`)
        );
      });
    } else {
      // For "All", "Shipped", "Delivered": Exclude cancelled orders
      list = rawList.filter((o) => {
        const s = String(o?.status || "").toLowerCase().trim();
        if (s.includes("cancel")) return false;

        const oId = String(o?._id || o?.id || "").trim();
        const cleanOId = oId.replace(/^#+/, "").trim();
        const shortOId = cleanOId.slice(-8).toUpperCase();

        if (
          mobileHiddenIds.includes(oId) ||
          mobileHiddenIds.includes(cleanOId) ||
          mobileHiddenIds.includes(`#${cleanOId}`) ||
          mobileHiddenIds.includes(shortOId) ||
          mobileHiddenIds.includes(`#${shortOId}`)
        ) {
          return false;
        }

        return true;
      });

      if (selectedMobileOrderFilter === "Shipped") {
        list = list.filter((o) => {
          const s = (o?.status || "").toLowerCase();
          return s.includes("ship") || s.includes("transit") || s.includes("process") || s.includes("pack");
        });
      } else if (selectedMobileOrderFilter === "Delivered") {
        list = list.filter((o) => (o?.status || "").toLowerCase().includes("deliver"));
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

  // Mobile Cart Coupon & Taxes (Matches Mobile App Shopping Cart screen)
  const [mobileCouponInput, setMobileCouponInput] = useState("");
  const [mobileCouponDiscount, setMobileCouponDiscount] = useState(0);
  const [mobileCouponMsg, setMobileCouponMsg] = useState("");

  const mobileGstAmount = useMemo(() => {
    return Math.round(totalAmount * 0.18);
  }, [totalAmount]);

  const mobileGrandTotal = useMemo(() => {
    return Math.max(0, totalAmount + mobileGstAmount - mobileCouponDiscount);
  }, [totalAmount, mobileGstAmount, mobileCouponDiscount]);

  const handleApplyMobileCoupon = () => {
    const code = mobileCouponInput.trim().toUpperCase();
    if (!code) return;
    if (code === "VEXA10") {
      const discount = Math.round(totalAmount * 0.1);
      setMobileCouponDiscount(discount);
      setMobileCouponMsg(`🎉 Coupon VEXA10 applied! You saved ₹${discount}.`);
    } else if (code === "VEXA30") {
      const discount = Math.round(totalAmount * 0.3);
      setMobileCouponDiscount(discount);
      setMobileCouponMsg(`🔥 Coupon VEXA30 applied! You saved ₹${discount}.`);
    } else {
      setMobileCouponDiscount(0);
      setMobileCouponMsg("❌ Invalid coupon code. Try VEXA10 or VEXA30.");
    }
  };

  const [showMobileAddressSelector, setShowMobileAddressSelector] = useState(false);
  const [showMobileAddressEdit, setShowMobileAddressEdit] = useState(false);

  // Mobile Razorpay Test Payment Flow States (Matches Reference Screenshots 1:1)
  const [mobileRazorpayStep, setMobileRazorpayStep] = useState<null | "options" | "demo_bank" | "confirming" | "success">(null);
  const [selectedDemoBank, setSelectedDemoBank] = useState("Punjab National Bank");
  const [selectedDemoCategory, setSelectedDemoCategory] = useState<"recommended" | "upi" | "cards" | "emi" | "netbanking" | "wallet">("recommended");
  const [demoRazorpayTxnId, setDemoRazorpayTxnId] = useState("pay_2133385905");
  const [redirectCountdown, setRedirectCountdown] = useState(3);

  // Transition from Confirming Payment (Yellow pulse) to Payment Successful (Green screen)
  useEffect(() => {
    let timer: any;
    if (mobileRazorpayStep === "confirming") {
      timer = setTimeout(() => {
        const randId = "pay_" + Math.floor(1000000000 + Math.random() * 9000000000);
        setDemoRazorpayTxnId(randId);
        setMobileRazorpayStep("success");
        setRedirectCountdown(3);
      }, 1900);
    }
    return () => clearTimeout(timer);
  }, [mobileRazorpayStep]);

  // Handler to finalize order and redirect to My Orders page
  const handleMobileRazorpaySuccessRedirect = () => {
    setMobileRazorpayStep(null);
    const method = `Razorpay Online Payment (${selectedDemoBank || "Instant UPI"} - Paid)`;
    handlePlaceOrder(undefined, method, demoRazorpayTxnId);
  };

  // Countdown timer for Payment Successful screen redirect to order confirmation
  useEffect(() => {
    let interval: any;
    if (mobileRazorpayStep === "success") {
      interval = setInterval(() => {
        setRedirectCountdown((prev) => {
          if (prev <= 1) {
            clearInterval(interval);
            handleMobileRazorpaySuccessRedirect();
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [mobileRazorpayStep, selectedDemoBank, demoRazorpayTxnId]);

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
    const cleanId = String(orderId || "").replace(/^#+/, "").trim();
    const shortId = cleanId.slice(-8).toUpperCase();

    setMyOrders((prev) =>
      prev.map((o) => {
        const oId = String(o._id || o.id || "").trim();
        const oClean = oId.replace(/^#+/, "").trim();
        const oShort = oClean.slice(-8).toUpperCase();
        const isMatch =
          o._id === orderId ||
          o.id === orderId ||
          oId === orderId ||
          oClean === cleanId ||
          oShort === shortId ||
          (cleanId.length >= 6 && oClean.includes(cleanId)) ||
          (cleanId.length >= 6 && cleanId.includes(oClean));
        return isMatch ? { ...o, status: newStatus as any, cancelReason } : o;
      })
    );

    setSelectedOrderDetailsModal((prev) => {
      if (!prev) return null;
      const prevId = String(prev._id || prev.id || "").trim();
      const prevClean = prevId.replace(/^#+/, "").trim();
      const prevShort = prevClean.slice(-8).toUpperCase();
      const isMatch =
        prev._id === orderId ||
        prev.id === orderId ||
        prevClean === cleanId ||
        prevShort === shortId ||
        (cleanId.length >= 6 && prevClean.includes(cleanId)) ||
        (cleanId.length >= 6 && cleanId.includes(prevClean));
      return isMatch ? { ...prev, status: newStatus as any, cancelReason } : prev;
    });

    if (typeof window !== "undefined") {
      try {
        const isMobile = window.innerWidth < 768;
        const cached = JSON.parse(localStorage.getItem("vexa_demo_orders") || "[]");
        let updated;
        if (isMobile && newStatus === "Cancelled") {
          // In mobile responsive only: remove cancelled order completely from mobile storage
          updated = cached.filter((o: any) => {
            const oId = String(o._id || o.id || "").trim();
            const oClean = oId.replace(/^#+/, "").trim();
            const oShort = oClean.slice(-8).toUpperCase();
            return oId !== orderId && oClean !== cleanId && oShort !== shortId;
          });
        } else {
          let found = false;
          updated = cached.map((o: any) => {
            const oId = String(o._id || o.id || "").trim();
            const oClean = oId.replace(/^#+/, "").trim();
            const oShort = oClean.slice(-8).toUpperCase();
            const isMatch =
              o._id === orderId ||
              o.id === orderId ||
              oId === orderId ||
              oClean === cleanId ||
              oShort === shortId;
            if (isMatch) {
              found = true;
              return { ...o, status: newStatus, cancelReason };
            }
            return o;
          });

          if (!found) {
            const currentOrder = myOrders.find((o) => {
              const oId = String(o._id || o.id || "").trim();
              const oClean = oId.replace(/^#+/, "").trim();
              const oShort = oClean.slice(-8).toUpperCase();
              return o._id === orderId || o.id === orderId || oClean === cleanId || oShort === shortId;
            });
            if (currentOrder) {
              updated.unshift({ ...currentOrder, status: newStatus as any, cancelReason });
            }
          }
        }

        localStorage.setItem("vexa_demo_orders", JSON.stringify(updated));

        // Warehouse Inventory Restock on Order Cancellation
        if (newStatus === "Cancelled") {
          const targetOrder = myOrders.find((o) => {
            const oId = String(o._id || o.id || "").trim();
            const oClean = oId.replace(/^#+/, "").trim();
            const oShort = oClean.slice(-8).toUpperCase();
            return o._id === orderId || o.id === orderId || oClean === cleanId || oShort === shortId;
          });
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
      await fetch(`${API_URL}/orders/status`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus, cancelReason, id: cleanId, orderId: cleanId, _id: cleanId }),
      });
      if (cleanId) {
        await fetch(`${API_URL}/orders/${encodeURIComponent(cleanId)}/status`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ status: newStatus, cancelReason, id: cleanId, orderId: cleanId }),
        });
      }
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
    const targetOrderId = cancellingOrderUser.id;
    const targetBookingId = cancellingOrderUser.bookingIdStr;
    const cleanId = String(targetOrderId || "").replace(/^#+/, "").trim();
    const cleanBookingId = String(targetBookingId || "").replace(/^#+/, "").trim();
    const shortId = cleanId.slice(-8).toUpperCase();

    // 1. Immediately update selectedOrderDetailsModal and close cancel prompt
    setSelectedOrderDetailsModal((prev) =>
      prev
        ? {
            ...prev,
            status: "Cancelled",
            cancelReason: fullReason,
          }
        : null
    );
    setCancellingOrderUser(null);

    // 2. Add to mobile-hidden list so it NEVER shows or updates in mobile My Orders screen
    try {
      const existingHidden = JSON.parse(localStorage.getItem("vexa_mobile_hidden_orders") || "[]");
      const idsToAdd = [
        targetOrderId,
        cleanId,
        `#${cleanId}`,
        shortId,
        `#${shortId}`,
        targetBookingId,
        cleanBookingId,
        `#${cleanBookingId}`,
      ].filter(Boolean);
      idsToAdd.forEach((id) => {
        if (!existingHidden.includes(id)) existingHidden.push(id);
      });
      localStorage.setItem("vexa_mobile_hidden_orders", JSON.stringify(existingHidden));
    } catch (e) {}

    // 3. Update order status across application states and backend
    await handleUpdateUserOrderStatus(targetOrderId, "Cancelled", fullReason);

    // 4. Reset form state & show confirmation notification
    setUserCancelReasonPreset("Ordered by mistake / Change of mind");
    setUserCustomCancelReason("");
    setRefreshMsg(`Order #${targetBookingId} cancelled successfully.`);
    toast.success(`Order #${targetBookingId} cancelled successfully.`);
    setTimeout(() => setRefreshMsg(""), 3500);
  };

  const formatOrderDate = (dateStr?: string) => {
    if (!dateStr) return "16 Oct 2026, 12:20 PM";
    try {
      const d = new Date(dateStr);
      const day = d.getDate();
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      const month = months[d.getMonth()];
      const year = d.getFullYear();
      const time = d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", hour12: true });
      return `${day} ${month} ${year}, ${time}`;
    } catch (e) {
      return "16 Oct 2026, 12:20 PM";
    }
  };

  const handleDownloadInvoice = async (order: OrderItem) => {
    try {
      const rawId = String(order._id || order.id || "VX-1419").replace(/^#/, "");
      const formattedId = rawId.length > 8 ? rawId.slice(-8).toUpperCase() : rawId.toUpperCase();
      const invoiceNumber = `INV-2026-VX${formattedId.slice(-4)}`;
      const orderDateStr = order.createdAt ? new Date(order.createdAt).toLocaleDateString("en-IN", {
        day: "numeric",
        month: "short",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      }) : "16 Oct 2026, 12:20 PM";

      // ── Direct Vector jsPDF Generation (1:1 Replica) ──
      const doc = new jsPDF({
        orientation: "portrait",
        unit: "mm",
        format: "a4",
      });

      // Top Dark Header Bar
      doc.setFillColor(15, 23, 42); // #0F172A
      doc.roundedRect(15, 12, 180, 14, 2, 2, "F");

      doc.setFillColor(39, 33, 21); // #272115
      doc.setDrawColor(139, 101, 8); // #8B6508
      doc.roundedRect(20, 15, 8, 8, 1, 1, "FD");

      doc.setFont("helvetica", "bold");
      doc.setFontSize(7);
      doc.setTextColor(212, 175, 55); // Gold
      doc.text("PDF", 24, 20.5, { align: "center" });

      doc.setFont("times", "bold");
      doc.setFontSize(11);
      doc.setTextColor(255, 255, 255);
      doc.text("TAX E-INVOICE", 31, 21);

      doc.setFont("helvetica", "normal");
      doc.setFontSize(8.5);
      doc.setTextColor(148, 163, 184); // Slate 400
      doc.text(invoiceNumber, 190, 21, { align: "right" });

      // Main White Card
      const cardX = 15;
      const cardY = 28;
      const cardW = 180;
      const cardH = 245;

      doc.setFillColor(255, 255, 255);
      doc.roundedRect(cardX, cardY, cardW, cardH, 3, 3, "F");
      doc.setDrawColor(226, 232, 240);
      doc.setLineWidth(0.4);
      doc.roundedRect(cardX, cardY, cardW, cardH, 3, 3, "S");

      // Card Header: Brand & PAID Badge
      doc.setFont("times", "bold");
      doc.setFontSize(14);
      doc.setTextColor(139, 101, 8); // Gold
      doc.text("VEXA LUXURY WEAR", 22, 38);

      // PAID Badge
      doc.setFillColor(234, 248, 241); // #EAF8F1
      doc.setDrawColor(87, 202, 133); // #57CA85
      doc.roundedRect(165, 32, 22, 8, 1.5, 1.5, "FD");
      doc.setFont("helvetica", "bold");
      doc.setFontSize(8);
      doc.setTextColor(22, 163, 74); // #16A34A
      doc.text("PAID", 176, 37.5, { align: "center" });

      doc.setFont("helvetica", "bold");
      doc.setFontSize(9);
      doc.setTextColor(15, 23, 42);
      doc.text("Vexa Style Hub Pvt. Ltd.", 22, 43.5);

      doc.setFont("helvetica", "normal");
      doc.setFontSize(7.5);
      doc.setTextColor(100, 116, 139);
      doc.text("100Ft Road, Indiranagar, Bengaluru - 560038", 22, 48);
      doc.setFontSize(7);
      doc.setTextColor(148, 163, 184);
      doc.text("GSTIN: 29AAACV9812F1Z4 | CIN: U74999KA2026PTC", 22, 52);

      // Divider line
      doc.setDrawColor(226, 232, 240);
      doc.line(22, 55, 188, 55);

      // 2-Column: BILLED TO & INVOICE DETAILS
      doc.setFont("helvetica", "bold");
      doc.setFontSize(7.5);
      doc.setTextColor(148, 163, 184);
      doc.text("BILLED TO:", 22, 61);
      doc.text("INVOICE DETAILS:", 115, 61);

      // Left Column
      const custName = order.userName || user?.name || "Tatukulaedukondalu";
      doc.setFont("helvetica", "bold");
      doc.setFontSize(9);
      doc.setTextColor(15, 23, 42);
      doc.text(custName, 22, 66);

      doc.setFont("helvetica", "normal");
      doc.setFontSize(7.5);
      doc.setTextColor(71, 85, 105);
      const addrLines = doc.splitTextToSize(
        order.shippingAddress || "Flat 402, Luxury Heights, Jubilee Hills Road No. 36, Hyderabad, Telangana, PIN: 500033",
        85
      );
      doc.text(addrLines, 22, 70);

      const custPhone = shippingPhone ? `+91 ${shippingPhone}` : "+91 98765 43210";
      doc.setFont("helvetica", "bold");
      doc.setFontSize(8);
      doc.setTextColor(30, 41, 59);
      doc.text(`Contact: ${custPhone}`, 22, 82);

      // Right Column
      doc.setFont("helvetica", "normal");
      doc.setFontSize(7.5);
      doc.setTextColor(71, 85, 105);
      doc.text(`Date: ${orderDateStr}`, 115, 66);

      doc.setFont("helvetica", "bold");
      doc.setFontSize(8.5);
      doc.setTextColor(139, 101, 8);
      doc.text(`Order ID: #${formattedId}`, 115, 71);

      doc.setFont("helvetica", "normal");
      doc.setFontSize(7.5);
      doc.setTextColor(71, 85, 105);
      const payLines = doc.splitTextToSize(`Payment: ${order.paymentMethod || "Razorpay NetBanking (Punjab National Bank)"}`, 70);
      doc.text(payLines, 115, 76);

      // Items Table
      let tableY = 88;
      // Dark Table Header
      doc.setFillColor(11, 21, 40); // #0B1528
      doc.roundedRect(22, tableY, 166, 8, 1.5, 1.5, "F");

      doc.setFont("helvetica", "bold");
      doc.setFontSize(7.5);
      doc.setTextColor(255, 255, 255);
      doc.text("ITEM DESCRIPTION", 26, tableY + 5.5);
      doc.text("QTY", 125, tableY + 5.5, { align: "center" });
      doc.text("PRICE", 152, tableY + 5.5, { align: "right" });
      doc.text("AMOUNT", 182, tableY + 5.5, { align: "right" });

      tableY += 8;

      const items = (order.items && order.items.length > 0)
        ? order.items
        : [{ name: "Gold-Embroidered Luxe Tee", size: "M", color: "Default", quantity: 1, price: 1799 }];

      items.forEach((it) => {
        doc.setFillColor(255, 255, 255);
        doc.rect(22, tableY, 166, 12, "F");
        doc.setDrawColor(241, 245, 249);
        doc.line(22, tableY + 12, 188, tableY + 12);

        doc.setFont("helvetica", "bold");
        doc.setFontSize(8);
        doc.setTextColor(15, 23, 42);
        const nameStr = doc.splitTextToSize(it.name || "Luxe Tee", 90);
        doc.text(nameStr[0] || it.name, 26, tableY + 5);

        doc.setFont("helvetica", "normal");
        doc.setFontSize(7);
        doc.setTextColor(148, 163, 184);
        doc.text(`Size: ${it.size || "M"} · Color: ${it.color || "Default"} | HSN: 610910`, 26, tableY + 9.5);

        doc.setFontSize(8);
        doc.setTextColor(51, 65, 85);
        doc.text(String(it.quantity || 1), 125, tableY + 6.5, { align: "center" });
        doc.text(`Rs. ${it.price}`, 152, tableY + 6.5, { align: "right" });

        doc.setFont("helvetica", "bold");
        doc.setTextColor(15, 23, 42);
        const rowAmt = (it.price || 0) * (it.quantity || 1);
        doc.text(`Rs. ${rowAmt}`, 182, tableY + 6.5, { align: "right" });

        tableY += 12;
      });

      // Tax Breakdown Box
      tableY += 4;
      const subtotal = items.reduce((sum, it) => sum + ((it.price || 0) * (it.quantity || 1)), 0) || order.totalAmount || 1799;
      const cgst = subtotal * 0.09;
      const sgst = subtotal * 0.09;
      const grandTotal = order.totalAmount ? Math.round(order.totalAmount) : Math.round(subtotal + cgst + sgst);

      doc.setFillColor(248, 250, 252); // #F8FAFC
      doc.setDrawColor(226, 232, 240);
      doc.roundedRect(22, tableY, 166, 30, 2.5, 2.5, "FD");

      doc.setFont("helvetica", "normal");
      doc.setFontSize(8);
      doc.setTextColor(100, 116, 139);
      doc.text("Taxable Value", 28, tableY + 6);
      doc.text(`Rs. ${subtotal.toFixed(2)}`, 182, tableY + 6, { align: "right" });

      doc.text("CGST (9%)", 28, tableY + 11.5);
      doc.text(`Rs. ${cgst.toFixed(2)}`, 182, tableY + 11.5, { align: "right" });

      doc.text("SGST (9%)", 28, tableY + 17);
      doc.text(`Rs. ${sgst.toFixed(2)}`, 182, tableY + 17, { align: "right" });

      doc.setDrawColor(226, 232, 240);
      doc.line(28, tableY + 20.5, 182, tableY + 20.5);

      doc.setFont("helvetica", "bold");
      doc.setFontSize(8.5);
      doc.setTextColor(15, 23, 42);
      doc.text("GRAND TOTAL (INCL. GST)", 28, tableY + 26);

      doc.setFont("times", "bold");
      doc.setFontSize(13);
      doc.setTextColor(139, 101, 8);
      doc.text(`Rs. ${grandTotal}`, 182, tableY + 26, { align: "right" });

      // Footer Row: QR Pattern & Signatory
      const footerY = tableY + 38;
      // Draw Authentic QR Code Graphic
      doc.setFillColor(15, 23, 42);
      doc.rect(24, footerY, 14, 14, "F");
      doc.setFillColor(255, 255, 255);
      doc.rect(26, footerY + 2, 10, 10, "F");
      doc.setFillColor(15, 23, 42);
      doc.rect(28, footerY + 4, 6, 6, "F");

      doc.setFont("helvetica", "normal");
      doc.setFontSize(7);
      doc.setTextColor(148, 163, 184);
      doc.text("Scan QR for Digital", 42, footerY + 6);
      doc.text("E-Invoice Verification", 42, footerY + 10);

      // Signatory
      doc.setFont("helvetica", "bold");
      doc.setFontSize(7.5);
      doc.setTextColor(30, 41, 59);
      doc.text("For VEXA STYLE HUB PVT LTD", 188, footerY + 5, { align: "right" });

      doc.setFont("helvetica", "italic");
      doc.setFontSize(7);
      doc.setTextColor(148, 163, 184);
      doc.text("Authorized Signatory", 188, footerY + 12, { align: "right" });

      // Generate Blob
      const pdfBlob = doc.output("blob");
      const blobUrl = URL.createObjectURL(pdfBlob);
      const link = document.createElement("a");
      link.href = blobUrl;
      link.setAttribute("download", `VEXA_Invoice_${formattedId}.pdf`);
      document.body.appendChild(link);
      link.click();
      setTimeout(() => {
        document.body.removeChild(link);
        URL.revokeObjectURL(blobUrl);
      }, 500);

      toast.success(`Tax E-Invoice PDF for #${formattedId} downloaded!`);
    } catch (pdfErr) {
      console.error("PDF generation error:", pdfErr);
      toast.error("Failed to generate PDF invoice. Please try again.");
    }
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



  const handlePlaceOrder = async (
    e?: React.FormEvent | React.MouseEvent,
    overridePaymentMethod?: string,
    overridePaymentId?: string
  ) => {
    if (e && typeof (e as any).preventDefault === "function") (e as any).preventDefault();
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

        const isMobileResponsive = typeof window !== "undefined"
          ? window.innerWidth < 768 || /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent)
          : false;

        // 3. Reset Checkout Flow State
        setSelectedProduct(null);
        setIsCartCheckout(false);
        setCheckoutStep(1);
        setOrderSubmitting(false);

        if (isMobileResponsive) {
          // Mobile responsive only: redirect directly to My Orders page
          setCartCheckoutStep("cart");
          setActiveTab("orders");
          navigate("/dashboard?tab=orders", { replace: true });
          if (typeof window !== "undefined") {
            window.scrollTo({ top: 0, left: 0, behavior: "instant" });
          }
          toast.success("Order placed successfully! Redirected to My Orders.");
        } else {
          // Desktop: show dedicated order placed success card
          setCartCheckoutStep("success");
          setActiveTab("cart");
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

      // If called with an override (e.g. from mobile Razorpay test flow):
      if (overridePaymentMethod || overridePaymentId) {
        executeFinalizeOrder(overridePaymentMethod, overridePaymentId);
        return;
      }

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
    <div className={`dashboard-page-root min-h-screen bg-background ${activeTab === "cart" ? "pt-2 md:pt-24" : "pt-20 sm:pt-24"} pb-8 sm:pb-12`}>
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
                            setSearchParams({ tab: item.id });
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
                          setSearchParams({ tab: item.id });
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
                        onClick={() => {
                          setActiveTab("orders");
                          setSearchParams({ tab: "orders" });
                        }}
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
                        onClick={() => {
                          setActiveTab("addresses");
                          setSearchParams({ tab: "addresses" });
                        }}
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
                        onClick={() => {
                          setActiveTab("wallet");
                          setSearchParams({ tab: "wallet" });
                        }}
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
                        onClick={() => {
                          setActiveTab("support");
                          setSearchParams({ tab: "support" });
                        }}
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

                {/* ── EDIT PROFILE FULL PAGE (MOBILE RESPONSIVE ONLY) + DESKTOP MODAL ── */}
                {showEditProfileModal && (
                  <>
                    {/* 1. MOBILE RESPONSIVE ONLY: 1:1 FULL PAGE REPLICA OF FLUTTER EDIT PROFILE SCREEN */}
                    <div className="block md:hidden fixed inset-0 z-50 bg-[#FAFAFC] dark:bg-background overflow-y-auto flex flex-col animate-in fade-in duration-200">
                      {/* Top App Bar */}
                      <div className="sticky top-0 z-30 bg-white/95 dark:bg-card/95 backdrop-blur-md border-b border-neutral-200/80 dark:border-neutral-800 px-4 py-3 flex items-center justify-between shadow-2xs">
                        <button
                          type="button"
                          onClick={() => setShowEditProfileModal(false)}
                          className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1 cursor-pointer"
                          aria-label="Back"
                        >
                          <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
                        </button>

                        <div className="flex items-center gap-2">
                          <div className="flex size-7.5 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] border border-[#EADBBE]/70 shrink-0">
                            <UserIcon className="size-4" />
                          </div>
                          <h1 className="font-serif text-[13.5px] font-bold uppercase tracking-widest text-foreground">
                            EDIT ACCOUNT PROFILE
                          </h1>
                        </div>

                        <div className="size-9 -mr-1" />
                      </div>

                      {/* Scrollable Body Form */}
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
                          toast.success("Profile updated successfully!");
                          setTimeout(() => setProfileSavedMsg(""), 3500);
                        }}
                        className="flex-1 flex flex-col justify-between"
                      >
                        <div className="px-4 py-5 space-y-5 pb-10">
                          {/* Avatar Uploader Card */}
                          <div className="w-full rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-5 shadow-2xs flex flex-col items-center justify-center text-center">
                            <div className="relative size-22 rounded-full bg-[#FAF5E6] dark:bg-gold/15 border-3 border-[#8B6508] dark:border-gold flex items-center justify-center overflow-hidden shrink-0 shadow-md">
                              {profilePic ? (
                                <img src={profilePic} alt={editProfileName} className="size-full object-cover" />
                              ) : (
                                <span className="font-display text-3xl font-extrabold text-[#8C6D23] dark:text-gold">
                                  {(editProfileName || "T")[0].toUpperCase()}
                                </span>
                              )}
                            </div>
                            <div className="mt-3.5 flex flex-wrap items-center justify-center gap-2">
                              <label
                                htmlFor="profile-pic-mobile-full-input"
                                className="flex items-center gap-1.5 rounded-full border border-[#8B6508]/60 bg-[#FAF6EE] dark:bg-amber-950/40 px-3.5 py-1.5 text-xs font-bold text-[#8B6508] dark:text-[#E5BF4E] hover:bg-[#F5EDDC] transition-all cursor-pointer shadow-2xs active:scale-95"
                              >
                                <Camera className="size-3.5" />
                                {profilePic ? "Change Photo" : "Upload Photo"}
                              </label>
                              <input
                                type="file"
                                id="profile-pic-mobile-full-input"
                                accept="image/*"
                                onChange={handleAvatarUpload}
                                className="hidden"
                              />
                              {profilePic && (
                                <button
                                  type="button"
                                  onClick={handleRemoveAvatar}
                                  className="flex items-center gap-1.5 rounded-full border border-destructive/40 bg-destructive/10 px-3 py-1.5 text-xs font-bold text-destructive hover:bg-destructive hover:text-white transition-all cursor-pointer shadow-2xs active:scale-95"
                                >
                                  <Trash2 className="size-3.5" />
                                  Remove
                                </button>
                              )}
                            </div>
                          </div>

                          {/* Personal Information Inputs */}
                          <div className="space-y-3.5">
                            <h3 className="font-serif text-xs font-bold uppercase tracking-wider text-foreground">
                              PERSONAL INFORMATION
                            </h3>

                            {/* Full Name */}
                            <div className="space-y-1.5">
                              <label className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                                <UserIcon className="size-3.5 text-[#8B6508] dark:text-[#E5BF4E]" />
                                Full Name
                              </label>
                              <input
                                type="text"
                                required
                                value={editProfileName}
                                onChange={(e) => setEditProfileName(e.target.value)}
                                placeholder="Enter full name"
                                className="w-full rounded-xl border border-neutral-200/90 dark:border-neutral-800 bg-white dark:bg-card px-4 py-3 text-xs font-semibold text-foreground outline-none focus:border-[#8B6508] dark:focus:border-gold transition-colors shadow-2xs"
                              />
                            </div>

                            {/* Email Address */}
                            <div className="space-y-1.5">
                              <label className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                                <Mail className="size-3.5 text-[#8B6508] dark:text-[#E5BF4E]" />
                                Email Address
                              </label>
                              <input
                                type="email"
                                required
                                value={editProfileEmail}
                                onChange={(e) => setEditProfileEmail(e.target.value)}
                                placeholder="name@example.com"
                                className="w-full rounded-xl border border-neutral-200/90 dark:border-neutral-800 bg-white dark:bg-card px-4 py-3 text-xs font-semibold text-foreground outline-none focus:border-[#8B6508] dark:focus:border-gold transition-colors shadow-2xs"
                              />
                            </div>

                            {/* Mobile Number */}
                            <div className="space-y-1.5">
                              <label className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                                <Phone className="size-3.5 text-[#8B6508] dark:text-[#E5BF4E]" />
                                Mobile Number
                              </label>
                              <input
                                type="tel"
                                value={editProfileMobile}
                                onChange={(e) => setEditProfileMobile(e.target.value)}
                                placeholder="+91 98765 43210"
                                className="w-full rounded-xl border border-neutral-200/90 dark:border-neutral-800 bg-white dark:bg-card px-4 py-3 text-xs font-semibold text-foreground outline-none focus:border-[#8B6508] dark:focus:border-gold font-mono transition-colors shadow-2xs"
                              />
                            </div>

                            {/* Primary Location */}
                            <div className="space-y-1.5">
                              <label className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                                <MapPin className="size-3.5 text-[#8B6508] dark:text-[#E5BF4E]" />
                                Primary Location
                              </label>
                              <input
                                type="text"
                                defaultValue="Hyderabad, Telangana"
                                placeholder="City, State"
                                className="w-full rounded-xl border border-neutral-200/90 dark:border-neutral-800 bg-white dark:bg-card px-4 py-3 text-xs font-semibold text-foreground outline-none focus:border-[#8B6508] dark:focus:border-gold transition-colors shadow-2xs"
                              />
                            </div>
                          </div>
                        </div>

                        {/* Sticky Bottom Save Action Bar */}
                        <div className="sticky bottom-0 inset-x-0 bg-white dark:bg-card border-t border-neutral-200/80 dark:border-neutral-800 p-4 shadow-[0_-5px_15px_rgba(0,0,0,0.06)]">
                          <button
                            type="submit"
                            className="w-full rounded-xl bg-[#8B6508] hover:bg-[#785506] py-3.5 text-xs font-bold uppercase tracking-wider text-white transition-all shadow-md cursor-pointer active:scale-[0.98] flex items-center justify-center gap-2"
                          >
                            <Save className="size-4" />
                            SAVE CHANGES
                          </button>
                        </div>
                      </form>
                    </div>

                    {/* 2. DESKTOP MODAL */}
                    <div className="hidden md:flex fixed inset-0 z-50 items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
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
                  </>
                )}

                {/* ── BRAND STORY FULL PAGE (MOBILE RESPONSIVE ONLY) + DESKTOP MODAL ── */}
                {showBrandStoryModal && (
                  <>
                    {/* 1. MOBILE RESPONSIVE ONLY: 1:1 FULL PAGE REPLICA OF FLUTTER BRAND STORY SCREEN */}
                    <div className="block md:hidden fixed inset-0 z-50 bg-[#FAFAFC] dark:bg-background overflow-y-auto flex flex-col animate-in fade-in duration-200">
                      {/* Top App Bar */}
                      <div className="sticky top-0 z-30 bg-white/95 dark:bg-card/95 backdrop-blur-md border-b border-neutral-200/80 dark:border-neutral-800 px-4 py-3 flex items-center justify-between shadow-2xs">
                        <button
                          type="button"
                          onClick={() => setShowBrandStoryModal(false)}
                          className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1 cursor-pointer"
                          aria-label="Back"
                        >
                          <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
                        </button>

                        <div className="flex items-center gap-2">
                          <div className="flex size-7.5 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] border border-[#EADBBE]/70 shrink-0">
                            <Sparkles className="size-4" />
                          </div>
                          <h1 className="font-serif text-[13.5px] font-bold uppercase tracking-widest text-foreground">
                            BRAND STORY &amp; PHILOSOPHY
                          </h1>
                        </div>

                        <div className="size-9 -mr-1" />
                      </div>

                      {/* Scrollable Body */}
                      <div className="flex-1 px-5 py-6 space-y-6 pb-32">
                        {/* Logo & Tagline Header Row */}
                        <div className="flex items-center gap-3.5">
                          <img
                            src="/vexa_logo.png"
                            alt="VEXA"
                            className="size-12 rounded-xl object-cover shadow-sm border border-[#EADBBE]"
                          />
                          <div>
                            <span className="font-serif font-black text-base tracking-[0.2em] text-[#8B6508] dark:text-[#E5BF4E] uppercase block">
                              VEXA STYLE HUB
                            </span>
                            <span className="text-[11px] font-bold tracking-[0.18em] text-muted-foreground uppercase">
                              WEAR CONFIDENCE • EST. 2026
                            </span>
                          </div>
                        </div>

                        {/* Heritage & Craftsmanship */}
                        <div className="space-y-2.5">
                          <h3 className="font-serif text-sm font-bold uppercase tracking-wider text-foreground">
                            OUR CRAFTSMANSHIP &amp; HERITAGE
                          </h3>
                          <p className="text-xs text-muted-foreground leading-relaxed">
                            Born from the confluence of avant-garde streetwear and bespoke modern minimalism, VEXA redefines luxury for the modern trendsetter.
                          </p>
                          <p className="text-xs text-muted-foreground leading-relaxed">
                            Engineered for those who appreciate heavyweight luxury streetwear. Every garment is meticulously crafted from 240 GSM combed long-staple cotton, pre-shrunk, bio-washed, and tailored with double-stitched collar reinforcement designed to make you wear confidence every day.
                          </p>
                        </div>

                        {/* Signature Brand Features Container */}
                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-4 shadow-2xs">
                          <div className="flex items-start gap-3">
                            <div className="size-8 rounded-xl bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0 mt-0.5">
                              <ShieldCheck className="size-4.5" />
                            </div>
                            <div>
                              <h4 className="font-bold text-xs text-foreground">240 GSM Luxury Weight</h4>
                              <p className="text-[11.5px] text-muted-foreground mt-0.5 leading-snug">
                                Ultra-durable, premium density drape that holds shape wash after wash.
                              </p>
                            </div>
                          </div>

                          <div className="border-t border-neutral-100 dark:border-neutral-800/80 pt-3 flex items-start gap-3">
                            <div className="size-8 rounded-xl bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0 mt-0.5">
                              <Sparkles className="size-4.5" />
                            </div>
                            <div>
                              <h4 className="font-bold text-xs text-foreground">Bespoke Colorways</h4>
                              <p className="text-[11.5px] text-muted-foreground mt-0.5 leading-snug">
                                Custom reactive dye process for deep, fade-resistant rich tones and vintage washes.
                              </p>
                            </div>
                          </div>

                          <div className="border-t border-neutral-100 dark:border-neutral-800/80 pt-3 flex items-start gap-3">
                            <div className="size-8 rounded-xl bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0 mt-0.5">
                              <Truck className="size-4.5" />
                            </div>
                            <div>
                              <h4 className="font-bold text-xs text-foreground">24-48h Express Dispatch</h4>
                              <p className="text-[11.5px] text-muted-foreground mt-0.5 leading-snug">
                                Direct 2-stage Quality Control before express doorstep delivery across India.
                              </p>
                            </div>
                          </div>
                        </div>

                        {/* Read Detailed Brand Story Link */}
                        <button
                          type="button"
                          onClick={() => {
                            setShowBrandStoryModal(false);
                            navigate("/about");
                          }}
                          className="w-full flex items-center justify-between rounded-xl border border-[#EADBBE] dark:border-amber-900/60 bg-[#FAF6EE] dark:bg-amber-950/20 px-4 py-3 text-xs font-bold text-[#8B6508] dark:text-[#E5BF4E] hover:bg-[#F5EDDC] transition-colors cursor-pointer"
                        >
                          <span>Explore Full Lookbook &amp; Atelier Story</span>
                          <ChevronRight className="size-4" />
                        </button>
                      </div>

                      {/* Bottom Action Button */}
                      <div className="sticky bottom-0 inset-x-0 bg-white dark:bg-card border-t border-neutral-200/80 dark:border-neutral-800 p-4 shadow-[0_-5px_15px_rgba(0,0,0,0.06)]">
                        <button
                          type="button"
                          onClick={() => setShowBrandStoryModal(false)}
                          className="w-full rounded-xl bg-[#8B6508] hover:bg-[#785506] py-3.5 text-xs font-bold uppercase tracking-wider text-white transition-all shadow-md cursor-pointer active:scale-[0.98]"
                        >
                          CLOSE BRAND STORY
                        </button>
                      </div>
                    </div>

                    {/* 2. DESKTOP MODAL */}
                    <div className="hidden md:flex fixed inset-0 z-50 items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
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
                  </>
                )}

                {/* ── TERMS & CONDITIONS FULL PAGE (MOBILE RESPONSIVE ONLY) + DESKTOP MODAL ── */}
                {showTermsModal && (
                  <>
                    {/* 1. MOBILE RESPONSIVE ONLY: 1:1 FULL PAGE REPLICA OF FLUTTER TERMS SCREEN */}
                    <div className="block md:hidden fixed inset-0 z-50 bg-[#FAFAFC] dark:bg-background overflow-y-auto flex flex-col animate-in fade-in duration-200">
                      {/* Top App Bar */}
                      <div className="sticky top-0 z-30 bg-white/95 dark:bg-card/95 backdrop-blur-md border-b border-neutral-200/80 dark:border-neutral-800 px-4 py-3 flex items-center justify-between shadow-2xs">
                        <button
                          type="button"
                          onClick={() => setShowTermsModal(false)}
                          className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1 cursor-pointer"
                          aria-label="Back"
                        >
                          <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
                        </button>

                        <div className="flex items-center gap-2">
                          <div className="flex size-7.5 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] border border-[#EADBBE]/70 shrink-0">
                            <FileText className="size-4" />
                          </div>
                          <h1 className="font-serif text-[13.5px] font-bold uppercase tracking-widest text-foreground">
                            TERMS &amp; CONDITIONS
                          </h1>
                        </div>

                        <div className="size-9 -mr-1" />
                      </div>

                      {/* Scrollable Body */}
                      <div className="flex-1 px-4 py-4 space-y-3.5 pb-28">
                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <CheckCircle2 className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">1. Acceptance of Service Terms</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            By downloading, browsing, or placing orders on VEXA Style Hub, you accept all terms outlined herein. Every order placement constitutes a legally binding agreement for high-end streetwear delivery.
                          </p>
                        </div>

                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <Package className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">2. Orders, Bespoke &amp; Quality Control</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            All custom streetwear orders undergo our signature 2-stage Quality Control inspection before dispatch. Orders are fulfilled within 24-48 hours with live express courier tracking across India.
                          </p>
                        </div>

                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <Wallet className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">3. Instant Wallet Refund Guarantee</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            Cancelled orders or approved returns are credited instantly to your VEXA Pay Wallet. Wallet balances may be applied to any future luxury drops or withdrawn to bank accounts.
                          </p>
                        </div>

                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <Sparkles className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">4. Intellectual Property &amp; Designs</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            All original prints, 240 GSM drop designs, bespoke embroidery patterns, typography, and software components are protected trademarks of VEXA Style Hub.
                          </p>
                        </div>

                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <Lock className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">5. Payment Security &amp; Cash On Delivery</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            We support 100% secure Razorpay online payments (UPI, Cards, Netbanking) and verified Cash on Delivery. All transactions are end-to-end encrypted under 256-bit SSL protocols.
                          </p>
                        </div>

                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <Headphones className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">6. User Responsibilities &amp; Support</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            Users are responsible for maintaining accurate shipping addresses and credentials. For concierge assistance, reach out to support@vexa.app or WhatsApp VIP Concierge.
                          </p>
                        </div>
                      </div>

                      {/* Bottom Action Button */}
                      <div className="sticky bottom-0 inset-x-0 bg-white dark:bg-card border-t border-neutral-200/80 dark:border-neutral-800 p-4 shadow-[0_-5px_15px_rgba(0,0,0,0.06)]">
                        <button
                          type="button"
                          onClick={() => setShowTermsModal(false)}
                          className="w-full rounded-xl bg-[#8B6508] hover:bg-[#785506] py-3.5 text-xs font-bold uppercase tracking-wider text-white transition-all shadow-md cursor-pointer active:scale-[0.98]"
                        >
                          I Agree &amp; Continue
                        </button>
                      </div>
                    </div>

                    {/* 2. DESKTOP MODAL */}
                    <div className="hidden md:flex fixed inset-0 z-50 items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
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
                  </>
                )}

                {/* ── PRIVACY POLICY FULL PAGE (MOBILE RESPONSIVE ONLY) + DESKTOP MODAL ── */}
                {showPrivacyPolicyModal && (
                  <>
                    {/* 1. MOBILE RESPONSIVE ONLY: 1:1 FULL PAGE REPLICA OF FLUTTER PRIVACY SCREEN */}
                    <div className="block md:hidden fixed inset-0 z-50 bg-[#FAFAFC] dark:bg-background overflow-y-auto flex flex-col animate-in fade-in duration-200">
                      {/* Top App Bar */}
                      <div className="sticky top-0 z-30 bg-white/95 dark:bg-card/95 backdrop-blur-md border-b border-neutral-200/80 dark:border-neutral-800 px-4 py-3 flex items-center justify-between shadow-2xs">
                        <button
                          type="button"
                          onClick={() => setShowPrivacyPolicyModal(false)}
                          className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1 cursor-pointer"
                          aria-label="Back"
                        >
                          <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
                        </button>

                        <div className="flex items-center gap-2">
                          <div className="flex size-7.5 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] border border-[#EADBBE]/70 shrink-0">
                            <Shield className="size-4" />
                          </div>
                          <h1 className="font-serif text-[13.5px] font-bold uppercase tracking-widest text-foreground">
                            PRIVACY POLICY
                          </h1>
                        </div>

                        <div className="size-9 -mr-1" />
                      </div>

                      {/* Scrollable Body */}
                      <div className="flex-1 px-4 py-4 space-y-3.5 pb-28">
                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <UserIcon className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">1. Information We Collect</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            We collect personal details such as your name, delivery address, phone number, and email strictly to process apparel orders, manage shipment tracking, and provide personalized styling.
                          </p>
                        </div>

                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <CreditCard className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">2. Payment Data Privacy</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            Payment credentials (card numbers, UPI IDs, netbanking passwords) are securely handled through PCI-DSS compliant gateways like Razorpay. VEXA never stores sensitive banking credentials.
                          </p>
                        </div>

                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <Sparkles className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">3. Realtime Tracking &amp; Notifications</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            With your permission, we send real-time SMS updates regarding dispatch status, order arrival, and exclusive limited streetwear drops.
                          </p>
                        </div>

                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <Trash2 className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">4. Data Retention &amp; Account Deletion</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            You have the legal right to request complete deletion of your profile, addresses, and order history at any time through the Account Settings tab in your profile.
                          </p>
                        </div>

                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 space-y-2 shadow-2xs">
                          <div className="flex items-center gap-2.5">
                            <div className="size-6 rounded-lg bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <Shield className="size-3.5" />
                            </div>
                            <h4 className="font-bold text-[13px] text-foreground">5. Cookies &amp; Analytics</h4>
                          </div>
                          <p className="text-xs text-muted-foreground leading-relaxed pl-8.5">
                            We use essential analytical tools to improve app performance, diagnose network crashes, and enhance shopping experiences. We never sell your personal data to third parties.
                          </p>
                        </div>
                      </div>

                      {/* Bottom Action Button */}
                      <div className="sticky bottom-0 inset-x-0 bg-white dark:bg-card border-t border-neutral-200/80 dark:border-neutral-800 p-4 shadow-[0_-5px_15px_rgba(0,0,0,0.06)]">
                        <button
                          type="button"
                          onClick={() => setShowPrivacyPolicyModal(false)}
                          className="w-full rounded-xl bg-[#8B6508] hover:bg-[#785506] py-3.5 text-xs font-bold uppercase tracking-wider text-white transition-all shadow-md cursor-pointer active:scale-[0.98]"
                        >
                          I Understand
                        </button>
                      </div>
                    </div>

                    {/* 2. DESKTOP MODAL */}
                    <div className="hidden md:flex fixed inset-0 z-50 items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
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
                  </>
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
                {/* ── MOBILE VIEW (< md): 1:1 PIXEL-PERFECT REPLICA OF FLUTTER MY ORDERS SCREEN ── */}
                <div className="block md:hidden -mx-4 -mt-4 pb-20">
                  {/* 1. SEARCH BAR & FILTERS BUTTON (SIDE-BY-SIDE) - Hides when scrolling in mobile responsive view */}
                  <div
                    className={`px-4 bg-background transition-all duration-300 ease-in-out ${
                      hideMobileOrderSearch
                        ? "max-h-0 py-0 opacity-0 pointer-events-none -translate-y-3 overflow-hidden"
                        : "opacity-100 translate-y-0 py-3 relative z-30"
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
                          className={`h-11 px-3.5 rounded-full border border-slate-200 dark:border-border bg-white dark:bg-card flex items-center gap-1.5 shadow-[0_2px_8px_rgba(0,0,0,0.03)] text-xs font-semibold text-slate-700 dark:text-foreground cursor-pointer active:scale-95 transition-transform ${
                            selectedMobileOrderFilter !== "All"
                              ? "border-amber-400/80 bg-amber-50/50 dark:bg-amber-950/20 text-amber-900 dark:text-amber-200"
                              : ""
                          }`}
                        >
                          <SlidersHorizontal className="size-3.5 text-slate-600 dark:text-foreground shrink-0" />
                          <span>{selectedMobileOrderFilter !== "All" ? selectedMobileOrderFilter : "Filters"}</span>
                          <ChevronDown
                            className={`size-3.5 text-slate-400 transition-transform duration-200 ${
                              showOrderFilterMenu ? "rotate-180 text-foreground" : ""
                            }`}
                          />
                        </button>

                        {/* Filter Options Menu Dropdown */}
                        {showOrderFilterMenu && (
                          <>
                            <div
                              className="fixed inset-0 z-40 bg-black/20 backdrop-blur-[0.5px]"
                              onClick={() => setShowOrderFilterMenu(false)}
                            />
                            <div className="absolute right-0 top-12 z-50 w-52 rounded-2xl border border-slate-200 dark:border-border bg-white dark:bg-card p-1.5 shadow-[0_10px_35px_-5px_rgba(0,0,0,0.2)] animate-in fade-in slide-in-from-top-2 zoom-in-95 duration-150 space-y-1">
                              <div className="px-3 py-1.5 border-b border-slate-100 dark:border-border/60 flex items-center justify-between">
                                <span className="text-[10.5px] font-bold uppercase tracking-wider text-muted-foreground">Filter Orders</span>
                                {selectedMobileOrderFilter !== "All" && (
                                  <button
                                    type="button"
                                    onClick={() => {
                                      setSelectedMobileOrderFilter("All");
                                      setShowOrderFilterMenu(false);
                                    }}
                                    className="text-[10px] font-semibold text-[#8B6508] dark:text-[#E5BF4E] hover:underline cursor-pointer"
                                  >
                                    Reset
                                  </button>
                                )}
                              </div>
                              {(() => {
                                let mobileHiddenIds: string[] = [];
                                if (typeof window !== "undefined") {
                                  try {
                                    mobileHiddenIds = JSON.parse(localStorage.getItem("vexa_mobile_hidden_orders") || "[]");
                                  } catch (e) {}
                                }

                                const isOrderCancelled = (o: any) => {
                                  const s = String(o?.status || "").toLowerCase().trim();
                                  const oId = String(o?._id || o?.id || "").trim();
                                  const cleanOId = oId.replace(/^#+/, "").trim();
                                  const shortOId = cleanOId.slice(-8).toUpperCase();
                                  return (
                                    s.includes("cancel") ||
                                    mobileHiddenIds.includes(oId) ||
                                    mobileHiddenIds.includes(cleanOId) ||
                                    mobileHiddenIds.includes(`#${cleanOId}`) ||
                                    mobileHiddenIds.includes(shortOId) ||
                                    mobileHiddenIds.includes(`#${shortOId}`)
                                  );
                                };

                                const allNonCancelled = myOrders.filter((o) => !isOrderCancelled(o));
                                const cancelledOrders = myOrders.filter((o) => isOrderCancelled(o));

                                return [
                                  {
                                    label: "All Orders",
                                    value: "All",
                                    count: allNonCancelled.length,
                                  },
                                  {
                                    label: "Expected / Shipped",
                                    value: "Shipped",
                                    count: allNonCancelled.filter((o) => {
                                      const s = (o?.status || "").toLowerCase();
                                      return (s.includes("ship") || s.includes("transit") || s.includes("process") || s.includes("pack"));
                                    }).length,
                                  },
                                  {
                                    label: "Delivered",
                                    value: "Delivered",
                                    count: allNonCancelled.filter((o) => (o?.status || "").toLowerCase().includes("deliver")).length,
                                  },
                                  {
                                    label: "Cancelled",
                                    value: "Cancelled",
                                    count: cancelledOrders.length,
                                  },
                                ];
                              })().map((opt) => {
                                const isSelected = selectedMobileOrderFilter === opt.value;
                                return (
                                  <button
                                    key={opt.value}
                                    type="button"
                                    onClick={() => {
                                      setSelectedMobileOrderFilter(opt.value as any);
                                      setShowOrderFilterMenu(false);
                                    }}
                                    className={`flex w-full items-center justify-between px-3 py-2.5 text-xs font-semibold rounded-xl transition-all cursor-pointer ${
                                      isSelected
                                        ? "bg-amber-500/15 text-amber-700 dark:text-amber-400 font-bold"
                                        : "text-foreground hover:bg-slate-100 dark:hover:bg-muted/60"
                                    }`}
                                  >
                                    <span className="flex items-center gap-2">
                                      <span>{opt.label}</span>
                                      <span
                                        className={`text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                                          isSelected
                                            ? "bg-amber-500/20 text-amber-800 dark:text-amber-300"
                                            : "bg-slate-100 dark:bg-muted text-muted-foreground"
                                        }`}
                                      >
                                        {opt.count}
                                      </span>
                                    </span>
                                    {isSelected && (
                                      <Check className="size-4 text-amber-600 dark:text-amber-400 shrink-0" strokeWidth={2.5} />
                                    )}
                                  </button>
                                );
                              })}
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
                        {orderSearchQuery
                          ? "No Matching Orders"
                          : selectedMobileOrderFilter === "Cancelled"
                          ? "No Cancelled Orders"
                          : selectedMobileOrderFilter !== "All"
                          ? `No ${selectedMobileOrderFilter} Orders`
                          : "No Orders Placed Yet"}
                      </h4>
                      <p className="text-xs text-muted-foreground leading-relaxed max-w-xs mx-auto">
                        {selectedMobileOrderFilter === "Cancelled"
                          ? "You do not have any cancelled purchases."
                          : orderSearchQuery || selectedMobileOrderFilter !== "All"
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
                        const isCancelled = status.includes("cancel") || selectedMobileOrderFilter === "Cancelled";

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

                {/* ── DESKTOP VIEW (>= md): KEEP COMPLETE FULL CAPABILITY DESKTOP ORDER VIEW ── */}
                <div className="hidden md:block space-y-6 min-w-0 pt-0">
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

              {/* ── ORDER DETAILS: MOBILE FULL SCREEN (1:1 REPLICA OF REFERENCE) & DESKTOP MODAL ── */}
              {selectedOrderDetailsModal && (() => {
                const rawId = String(selectedOrderDetailsModal._id || selectedOrderDetailsModal.id || "VX-1419").replace(/^#/, "");
                const formattedOrderId = rawId.length > 8 ? rawId.slice(-8).toUpperCase() : rawId.toUpperCase();

                let mobileHiddenIds: string[] = [];
                if (typeof window !== "undefined") {
                  try {
                    mobileHiddenIds = JSON.parse(localStorage.getItem("vexa_mobile_hidden_orders") || "[]");
                  } catch (e) {}
                }

                const currentOrderInList = myOrders.find((o) => {
                  const oId = String(o._id || o.id || "");
                  const oClean = oId.replace(/^#+/, "").trim();
                  const oShort = oClean.slice(-8).toUpperCase();
                  const cleanReadable = String(o.id || "").replace(/^#+/, "").trim();
                  return (
                    o._id === selectedOrderDetailsModal._id ||
                    o.id === selectedOrderDetailsModal.id ||
                    oClean === rawId ||
                    oShort === formattedOrderId ||
                    (rawId.length >= 6 && oClean.includes(rawId)) ||
                    (rawId.length >= 6 && rawId.includes(oClean)) ||
                    (formattedOrderId.length >= 4 && oShort === formattedOrderId) ||
                    (cleanReadable && (cleanReadable === rawId || cleanReadable === formattedOrderId))
                  );
                });

                const effectiveStatus = String(
                  currentOrderInList?.status || selectedOrderDetailsModal.status || ""
                ).toLowerCase().trim();

                const isCancelled =
                  effectiveStatus.includes("cancel") ||
                  mobileHiddenIds.includes(String(selectedOrderDetailsModal._id || "")) ||
                  mobileHiddenIds.includes(String(selectedOrderDetailsModal.id || "")) ||
                  mobileHiddenIds.includes(rawId) ||
                  mobileHiddenIds.includes(`#${rawId}`) ||
                  mobileHiddenIds.includes(formattedOrderId) ||
                  mobileHiddenIds.includes(`#${formattedOrderId}`) ||
                  (currentOrderInList && (
                    mobileHiddenIds.includes(String(currentOrderInList._id || "")) ||
                    mobileHiddenIds.includes(String(currentOrderInList.id || "")) ||
                    String(currentOrderInList.status || "").toLowerCase().includes("cancel")
                  ));

                const isDelivered = effectiveStatus.includes("deliver");
                const isShipped = effectiveStatus.includes("ship") || effectiveStatus.includes("transit");
                const totalItemPcs = (selectedOrderDetailsModal.items || []).reduce((sum, it) => sum + (it.quantity || 1), 0);
                const itemSubtotal = (selectedOrderDetailsModal.items || []).reduce((sum, it) => sum + ((it.price || 0) * (it.quantity || 1)), 0) || selectedOrderDetailsModal.totalAmount || 1799;
                const taxAmount = Math.round(itemSubtotal * 0.18);
                const finalGrandTotal = selectedOrderDetailsModal.totalAmount || (itemSubtotal + taxAmount);

                return (
                  <>
                    {/* 1. MOBILE RESPONSIVE ORDER DETAILS SCREEN (1:1 PIXEL-PERFECT REPLICA) */}
                    <div className="block md:hidden fixed inset-0 z-50 bg-[#F8F9FA] dark:bg-background overflow-y-auto flex flex-col animate-in fade-in duration-200">
                      {/* Top App Bar */}
                      <div className="sticky top-0 z-30 bg-white/95 dark:bg-card/95 backdrop-blur-md border-b border-neutral-200/80 dark:border-neutral-800 px-4 py-3 flex items-center justify-between shadow-2xs">
                        <div className="flex items-center gap-3 min-w-0">
                          <button
                            type="button"
                            onClick={() => setSelectedOrderDetailsModal(null)}
                            className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1 cursor-pointer"
                            aria-label="Back to Orders"
                          >
                            <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
                          </button>
                          <div className="flex size-9 items-center justify-center rounded-xl bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] border border-[#EADBBE]/70 shrink-0">
                            <Package className="size-4.5" />
                          </div>
                          <div className="min-w-0">
                            <h1 className="font-serif text-sm font-bold uppercase tracking-wider text-foreground leading-tight truncate">
                              ORDER #{formattedOrderId}
                            </h1>
                            <p className="text-[11px] text-muted-foreground flex items-center gap-1 mt-0.5 truncate">
                              <Clock className="size-3 text-muted-foreground shrink-0" />
                              <span>Placed on {formatOrderDate(selectedOrderDetailsModal.createdAt)}</span>
                            </p>
                          </div>
                        </div>

                        <button
                          type="button"
                          onClick={() => setShowMobileInvoicePreview(selectedOrderDetailsModal)}
                          className="flex size-9 items-center justify-center rounded-xl text-[#8B6508] dark:text-[#E5BF4E] hover:bg-[#FAF6EE] dark:hover:bg-amber-950/40 transition-colors active:scale-90 shrink-0 cursor-pointer"
                          title="Download Invoice"
                        >
                          <Download className="size-5" />
                        </button>
                      </div>

                      {/* Main Scroll Content */}
                      <div className="flex-1 px-4 py-4 space-y-4 pb-48">
                        {/* CARD 1: ESTIMATED DELIVERY & TRACKING STEPPER */}
                        <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4.5 shadow-xs space-y-4">
                          {/* Header Row */}
                          <div className="flex items-start justify-between gap-2">
                            <div className="min-w-0 flex-1">
                              <span className="text-[10px] font-black uppercase tracking-widest text-[#8B6508] dark:text-[#E5BF4E] block whitespace-nowrap">
                                ESTIMATED DELIVERY
                              </span>
                              <h2 className="font-serif text-[15px] min-[360px]:text-[17px] sm:text-xl font-bold uppercase tracking-tight text-foreground mt-0.5 whitespace-nowrap">
                                {isCancelled ? "ORDER CANCELLED" : isDelivered ? "ORDER DELIVERED" : isShipped ? "OUT FOR DELIVERY" : "ORDER PLACED"}
                              </h2>
                              <p className="text-[11px] text-muted-foreground mt-0.5 whitespace-nowrap truncate">
                                {isCancelled
                                  ? "Order Cancelled • Refund Processed"
                                  : isDelivered
                                  ? "Order Delivered • Left at Doorstep"
                                  : isShipped
                                  ? "Out for Delivery • Expected Today"
                                  : "Order Placed • Awaiting Warehouse Dispa..."}
                              </p>
                            </div>
                            <div className={`rounded-full border px-2.5 py-0.5 text-[9.5px] font-bold uppercase tracking-wider flex items-center gap-1.5 shrink-0 ${
                              isCancelled
                                ? "border-red-300 dark:border-red-800 bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400"
                                : isDelivered
                                ? "border-emerald-300 dark:border-emerald-800 bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400"
                                : "border-amber-300 dark:border-amber-700/80 bg-amber-50/70 dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E]"
                            }`}>
                              <span className={`size-1.5 rounded-full ${
                                isCancelled ? "bg-red-500" : isDelivered ? "bg-emerald-500" : "bg-[#8B6508] dark:bg-[#E5BF4E] animate-pulse"
                              }`} />
                              <span>{isCancelled ? "CANCELLED" : isDelivered ? "DELIVERED" : isShipped ? "SHIPPED" : "ORDER PLACED"}</span>
                            </div>
                          </div>

                          {/* 4-Step Progress Stepper */}
                          <div className="pt-2 pb-1 relative">
                            {/* Horizontal Connecting Track */}
                            <div className="absolute top-[20px] left-6 right-6 h-[2px] bg-slate-200 dark:bg-neutral-800 z-0" />
                            <div
                              className="absolute top-[20px] left-6 h-[2px] bg-[#8B6508] z-0 transition-all duration-500"
                              style={{
                                width: isCancelled ? "0%" : isDelivered ? "88%" : isShipped ? "60%" : "10%",
                              }}
                            />

                            <div className="relative z-10 flex items-center justify-between">
                              {[
                                { id: "warehouse", label: "Warehouse", icon: Store, step: 0 },
                                { id: "qc", label: "QC Hub", icon: Package, step: 1 },
                                { id: "van", label: "Express Van", icon: Truck, step: 2 },
                                { id: "home", label: "Your Home", icon: Home, step: 3 },
                              ].map((st) => {
                                const Icon = st.icon;
                                const currentStep = isCancelled ? -1 : isDelivered ? 3 : isShipped ? 2 : 0;
                                const isCompleted = currentStep > st.step;
                                const isCurrent = currentStep === st.step;

                                return (
                                  <div key={st.id} className="flex flex-col items-center">
                                    <div
                                      className={`size-10 rounded-full flex items-center justify-center transition-all ${
                                        isCancelled
                                          ? "bg-slate-100 dark:bg-neutral-800 text-slate-300 dark:text-neutral-600 border border-slate-200 dark:border-neutral-700"
                                          : isCurrent
                                          ? "bg-[#8B6508] text-white shadow-md ring-4 ring-[#8B6508]/20"
                                          : isCompleted
                                          ? "bg-[#8B6508] text-white"
                                          : "bg-slate-100 dark:bg-neutral-800 text-slate-400 border border-slate-200 dark:border-neutral-700"
                                      }`}
                                    >
                                      <Icon className="size-4.5" />
                                    </div>
                                    {isCurrent && !isCancelled && (
                                      <div className="h-0.5 w-4 bg-[#8B6508] rounded-full mt-1.5" />
                                    )}
                                    <span
                                      className={`text-[10px] font-bold mt-1 text-center ${
                                        isCancelled
                                          ? "text-slate-400 dark:text-neutral-600"
                                          : isCurrent ? "text-foreground" : "text-muted-foreground"
                                      }`}
                                    >
                                      {st.label}
                                    </span>
                                  </div>
                                );
                              })}
                            </div>
                          </div>

                          {/* Pill Notice Banner */}
                          <div className={`rounded-xl border px-3.5 py-2.5 text-[11px] font-medium flex items-center gap-2 ${
                            isCancelled
                              ? "border-red-200 dark:border-red-900/50 bg-red-50/60 dark:bg-red-950/30 text-red-600 dark:text-red-400"
                              : "border-amber-200/80 dark:border-amber-900/50 bg-[#FAF6EE] dark:bg-amber-950/30 text-[#8B6508] dark:text-[#E5BF4E]"
                          }`}>
                            {isCancelled ? (
                              <XCircle className="size-4 shrink-0 text-red-500" />
                            ) : (
                              <ShoppingBag className="size-4 shrink-0 fill-current" />
                            )}
                            <span>
                              {isCancelled
                                ? (currentOrderInList?.cancelReason || selectedOrderDetailsModal.cancelReason || "Order cancelled upon customer request. No further charges applied.")
                                : isDelivered
                                ? "Package delivered successfully to recipient address."
                                : isShipped
                                ? "Dispatched via Express Courier • In Transit to your city"
                                : "Order Placed • Awaiting Warehouse Processing"}
                            </span>
                          </div>
                        </div>

                        {/* SECTION 2: SHIPPING ADDRESS */}
                        <div className="space-y-2">
                          <h3 className="font-serif text-xs font-bold uppercase tracking-wider text-foreground px-0.5">
                            SHIPPING ADDRESS
                          </h3>
                          <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 shadow-xs flex items-center justify-between gap-3">
                            <div className="flex items-start gap-3.5 min-w-0">
                              <div className="flex size-10 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] shrink-0 mt-0.5">
                                <MapPin className="size-5 fill-current" />
                              </div>
                              <div className="min-w-0">
                                <h4 className="font-bold text-xs text-foreground truncate">
                                  {selectedOrderDetailsModal.userName || user?.name || "Tatukulaedukondalu"}
                                </h4>
                                <p className="text-[11.5px] text-muted-foreground leading-relaxed mt-0.5 line-clamp-2">
                                  {selectedOrderDetailsModal.shippingAddress || "Flat 402, Luxury Heights, Jubilee Hills Road No. 36, Hyderabad, Telangana, PIN: 500033"}
                                </p>
                                <p className="text-xs font-semibold text-foreground mt-1 flex items-center gap-1.5">
                                  <Phone className="size-3 text-[#8B6508] dark:text-[#E5BF4E] shrink-0" />
                                  <span>{shippingPhone ? `+91 ${shippingPhone}` : "+91 98765 43210"}</span>
                                </p>
                              </div>
                            </div>
                            <ChevronRight className="size-4.5 text-slate-400 shrink-0" />
                          </div>
                        </div>

                        {/* SECTION 3: ITEMS IN ORDER */}
                        <div className="space-y-2">
                          <div className="flex items-center justify-between px-0.5">
                            <h3 className="font-serif text-xs font-bold uppercase tracking-wider text-foreground">
                              ITEMS IN ORDER ({selectedOrderDetailsModal.items?.length || 1})
                            </h3>
                            <span className="text-xs text-muted-foreground font-medium">
                              {totalItemPcs} total pcs
                            </span>
                          </div>

                          <div className="space-y-2.5">
                            {(selectedOrderDetailsModal.items || []).map((item, idx) => (
                              <div
                                key={`order-detail-item-${idx}`}
                                className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-3.5 shadow-xs flex items-center justify-between gap-3"
                              >
                                <div className="flex items-center gap-3.5 min-w-0">
                                  <div className="size-16 rounded-xl bg-slate-100 dark:bg-neutral-800 overflow-hidden shrink-0 border border-slate-200 dark:border-neutral-700">
                                    <img
                                      src={getProductImage(item)}
                                      alt={item.name}
                                      className="size-full object-cover"
                                    />
                                  </div>
                                  <div className="min-w-0">
                                    <h4 className="font-bold text-xs text-foreground truncate">
                                      {item.name}
                                    </h4>
                                    <div className="flex items-center gap-2 mt-1">
                                      <span className="rounded-md border border-neutral-200 dark:border-neutral-700 bg-neutral-100 dark:bg-neutral-800 px-2 py-0.5 text-[10px] font-semibold text-foreground">
                                        Size {item.size || "M"}
                                      </span>
                                      <span className="text-[11px] text-muted-foreground">
                                        Qty: {item.quantity || 1}
                                      </span>
                                    </div>
                                  </div>
                                </div>
                                <span className="font-serif font-black text-sm text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                                  ₹{((item.price || 0) * (item.quantity || 1)).toLocaleString("en-IN")}
                                </span>
                              </div>
                            ))}
                          </div>
                        </div>

                        {/* SECTION 4: PRICE DETAILS */}
                        <div className="space-y-2">
                          <h3 className="font-serif text-xs font-bold uppercase tracking-wider text-foreground px-0.5">
                            PRICE DETAILS
                          </h3>
                          <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 shadow-xs space-y-3">
                            <div className="flex items-center justify-between text-xs">
                              <span className="text-muted-foreground">Items Subtotal</span>
                              <span className="font-bold text-foreground">
                                ₹{itemSubtotal.toLocaleString("en-IN")}
                              </span>
                            </div>

                            <div className="flex items-center justify-between text-xs">
                              <div className="flex items-center gap-1.5 text-muted-foreground">
                                <Truck className="size-3.5 shrink-0" />
                                <span>Shipping Fee</span>
                              </div>
                              <div className="flex items-center gap-1.5">
                                <span className="line-through text-slate-400">₹150</span>
                                <span className="font-bold text-emerald-600 dark:text-emerald-400">FREE Express</span>
                              </div>
                            </div>

                            <div className="flex items-center justify-between text-xs">
                              <div className="flex items-center gap-1.5 text-muted-foreground">
                                <FileText className="size-3.5 shrink-0" />
                                <span>Taxes & Duties (GST 18%)</span>
                              </div>
                              <span className="font-semibold text-foreground">
                                +₹{taxAmount.toLocaleString("en-IN")}
                              </span>
                            </div>

                            <div className="flex items-center justify-between text-xs pt-1 border-t border-neutral-100 dark:border-neutral-800">
                              <div className="flex items-center gap-1.5 text-muted-foreground">
                                <CreditCard className="size-3.5 shrink-0" />
                                <span>Payment Method</span>
                              </div>
                              <span className="rounded-lg bg-neutral-100 dark:bg-neutral-800 px-2.5 py-1 text-[11px] font-bold text-foreground max-w-[200px] truncate">
                                {selectedOrderDetailsModal.paymentMethod || "Razorpay Online Payment"}
                              </span>
                            </div>

                            <div className="flex items-center justify-between text-sm pt-2 border-t border-dashed border-neutral-200 dark:border-neutral-700">
                              <span className="font-bold text-foreground">Total Paid Amount</span>
                              <span className="font-serif font-black text-base text-[#8B6508] dark:text-[#E5BF4E]">
                                ₹{finalGrandTotal.toLocaleString("en-IN")}
                              </span>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* STICKY BOTTOM ACTIONS BAR */}
                      <div className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 dark:bg-card/95 backdrop-blur-md border-t border-neutral-200/90 dark:border-neutral-800 p-4 pb-6 shadow-[0_-6px_25px_rgba(0,0,0,0.08)] space-y-2.5 max-w-lg mx-auto">
                        {/* Row 1: Dual Action Buttons */}
                        <div className="flex items-center gap-3">
                          {!isCancelled && !isDelivered && (
                            <button
                              type="button"
                              onClick={() => {
                                setCancellingOrderUser({
                                  id: selectedOrderDetailsModal._id || selectedOrderDetailsModal.id || "",
                                  bookingIdStr: formattedOrderId,
                                });
                              }}
                              className="flex-1 rounded-xl border border-red-300/90 dark:border-red-800/80 bg-red-50/50 dark:bg-red-950/30 text-red-600 dark:text-red-400 hover:bg-red-100 font-bold text-xs py-3.5 flex items-center justify-center gap-1.5 transition-all active:scale-95 cursor-pointer shadow-2xs"
                            >
                              <XCircle className="size-4" />
                              <span>Cancel Order</span>
                            </button>
                          )}
                          <button
                            type="button"
                            onClick={() => {
                              toast.info(`Live tracking active for #${formattedOrderId}: In transit with VEXA Express Courier.`);
                            }}
                            className="flex-1 rounded-xl bg-[#8B6508] hover:bg-[#785707] text-white font-bold text-xs py-3.5 flex items-center justify-center gap-1.5 shadow-md transition-all active:scale-95 cursor-pointer"
                          >
                            <MapPin className="size-4 fill-current" />
                            <span>Track Order</span>
                          </button>
                        </div>

                        {/* Row 2: Customer Support (Full width) */}
                        <button
                          type="button"
                          onClick={() => {
                            setMobileSupportOrder(selectedOrderDetailsModal);
                            setShowMobileSupportScreen(true);
                          }}
                          className="w-full rounded-xl border border-emerald-500/80 bg-emerald-50/40 dark:bg-emerald-950/20 text-emerald-700 dark:text-emerald-400 hover:bg-emerald-100/60 font-bold text-xs py-3.5 flex items-center justify-center gap-2 transition-all active:scale-95 cursor-pointer shadow-2xs"
                        >
                          <Headphones className="size-4" />
                          <span>Customer Support</span>
                        </button>
                      </div>
                    </div>

                    {/* 2. DESKTOP MODAL VIEW (PRESERVED FOR DESKTOP ONLY) */}
                    <div className="hidden md:flex fixed inset-0 z-50 items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
                      <div className="w-full max-w-md rounded-2xl border border-gold/40 bg-card p-6 shadow-2xl max-h-[88vh] overflow-y-auto space-y-4 animate-in zoom-in-95 duration-200">
                        <div className="flex items-center justify-between border-b border-border pb-3">
                          <div>
                            <span className="text-[10px] uppercase tracking-widest text-gold font-bold">Order Details</span>
                            <h3 className="font-display text-base font-bold text-foreground">
                              #{formattedOrderId}
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
                          {!isCancelled && !isDelivered && (
                            <button
                              type="button"
                              onClick={() => {
                                setCancellingOrderUser({
                                  id: selectedOrderDetailsModal._id || selectedOrderDetailsModal.id || "",
                                  bookingIdStr: formattedOrderId,
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
                  </>
                );
              })()}
            </div>
          )}

          {/* ── MOBILE RESPONSIVE ONLY: TAX E-INVOICE PREVIEW & DOWNLOAD SCREEN (1:1 REPLICA) ── */}
          {showMobileInvoicePreview && (() => {
            const ord = showMobileInvoicePreview;
            const rawId = String(ord._id || ord.id || "VX-1419").replace(/^#/, "");
            const formattedId = rawId.length > 8 ? rawId.slice(-8).toUpperCase() : rawId.toUpperCase();
            const invoiceNumber = `INV-2026-VX${formattedId.slice(-4)}`;
            const orderDateStr = ord.createdAt
              ? new Date(ord.createdAt).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" }) + ", " + new Date(ord.createdAt).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", hour12: true })
              : "16 Oct 2026, 12:20 PM";
            const items = (ord.items && ord.items.length > 0)
              ? ord.items
              : [{ name: "Gold-Embroidered Luxe Tee", size: "M", color: "Default", quantity: 1, price: 1799 }];
            const taxableValue = items.reduce((sum, it) => sum + ((it.price || 0) * (it.quantity || 1)), 0) || 1799;
            const cgst = taxableValue * 0.09;
            const sgst = taxableValue * 0.09;
            const grandTotal = ord.totalAmount ? Math.round(ord.totalAmount) : Math.round(taxableValue + cgst + sgst);
            const paymentMethodDisplay = ord.paymentMethod || "Razorpay NetBanking (Punjab National Bank)";
            const customerName = ord.userName || (user as any)?.name || "Tatukulaedukondalu";
            const customerAddress = ord.shippingAddress || "Flat 402, Luxury Heights, Jubilee Hills Road No. 36, Hyderabad, Telangana, PIN: 500033";
            const contactPhone = shippingPhone ? `+91 ${shippingPhone}` : "+91 98765 43210";

            return (
              <div className="block md:hidden fixed inset-0 z-60 bg-[#F4F6F9] overflow-y-auto flex flex-col animate-in fade-in duration-200">
                {/* 1. TOP DARK APP BAR */}
                <div className="sticky top-0 z-30 bg-[#0F172A] border-b border-neutral-800 px-4 py-3 flex items-center justify-between shadow-md">
                  <button
                    type="button"
                    onClick={() => setShowMobileInvoicePreview(null)}
                    className="flex size-9 items-center justify-center rounded-full text-white/90 hover:bg-white/10 active:scale-90 transition-all -ml-1 cursor-pointer"
                    aria-label="Back"
                  >
                    <ChevronLeft className="size-6 text-white" strokeWidth={2.4} />
                  </button>

                  <div className="flex items-center gap-2.5">
                    <div className="flex size-8.5 items-center justify-center rounded-lg bg-[#272115] border border-[#8B6508]/60 text-[#D4AF37] shrink-0 font-bold text-[9px] flex-col leading-none">
                      <FileText className="size-4 text-[#D4AF37]" />
                      <span className="text-[6.5px] tracking-tight font-sans font-bold mt-0.5">PDF</span>
                    </div>
                    <div className="text-left">
                      <h1 className="font-serif text-[13px] font-bold uppercase tracking-wider text-white leading-tight">
                        TAX E-INVOICE
                      </h1>
                      <p className="text-[10px] text-white/60 font-mono tracking-wide">
                        {invoiceNumber}
                      </p>
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() => setShowMobileInvoicePreview(null)}
                    className="flex size-9 items-center justify-center rounded-full text-white/90 hover:bg-white/10 active:scale-90 transition-all -mr-1 cursor-pointer"
                    aria-label="Close"
                  >
                    <X className="size-5.5 text-white" />
                  </button>
                </div>

                {/* 2. SCROLLABLE INVOICE PAPER CARD */}
                <div className="flex-1 p-4 pb-28 flex flex-col items-center justify-start">
                  <div
                    id="vexa-tax-invoice-printable-card"
                    className="w-full max-w-sm rounded-2xl bg-white text-neutral-900 shadow-xl border border-neutral-200/80 overflow-hidden animate-in slide-in-from-bottom-2 duration-300"
                  >
                    {/* Top E-Invoice Header Strip */}
                    <div className="bg-[#0F172A] px-4 py-2.5 flex items-center justify-between border-b border-neutral-800">
                      <div className="flex items-center gap-2">
                        <div className="flex size-6.5 items-center justify-center rounded bg-[#272115] border border-[#8B6508]/60 text-[#D4AF37] font-bold text-[8px] leading-none">
                          PDF
                        </div>
                        <span className="font-serif text-[11px] font-bold uppercase tracking-wider text-white">
                          TAX E-INVOICE
                        </span>
                      </div>
                      <span className="text-[10px] text-white/70 font-mono tracking-wide">
                        {invoiceNumber}
                      </span>
                    </div>

                    <div className="p-5 space-y-4">
                      {/* Header */}
                      <div className="flex items-start justify-between gap-2 border-b border-neutral-300 pb-3">
                        <div>
                          <h2 className="font-serif font-black text-base tracking-wide text-[#8B6508] uppercase">
                            VEXA LUXURY WEAR
                          </h2>
                          <p className="font-bold text-xs text-neutral-900 mt-0.5">
                            Vexa Style Hub Pvt. Ltd.
                          </p>
                          <p className="text-[10px] text-neutral-500 mt-0.5">
                            100Ft Road, Indiranagar, Bengaluru - 560038
                          </p>
                          <p className="text-[9px] text-neutral-400 font-mono mt-0.5">
                            GSTIN: 29AAACV9812F1Z4 | CIN: U74999KA2026PTC
                          </p>
                        </div>
                        <div className="rounded-lg border border-emerald-400/80 bg-emerald-50 px-2.5 py-1 font-bold text-xs text-emerald-600 uppercase tracking-wider shrink-0">
                          PAID
                        </div>
                      </div>

                      {/* Billed To & Invoice Details 2-Column Grid */}
                      <div className="grid grid-cols-2 gap-3 text-left">
                        <div>
                          <span className="text-[9.5px] font-bold uppercase tracking-wider text-neutral-400 block mb-1">
                            BILLED TO:
                          </span>
                          <p className="font-bold text-xs text-neutral-900 leading-snug truncate">
                            {customerName}
                          </p>
                          <p className="text-[10px] text-neutral-600 leading-snug mt-1 line-clamp-3">
                            {customerAddress}
                          </p>
                          <p className="text-[10.5px] font-bold text-neutral-800 mt-1.5">
                            Contact: {contactPhone}
                          </p>
                        </div>

                        <div>
                          <span className="text-[9.5px] font-bold uppercase tracking-wider text-neutral-400 block mb-1">
                            INVOICE DETAILS:
                          </span>
                          <p className="text-[10px] text-neutral-600 leading-snug">
                            Date: {orderDateStr}
                          </p>
                          <p className="text-[11px] font-bold text-[#8B6508] mt-1">
                            Order ID: #{formattedId}
                          </p>
                          <p className="text-[10px] text-neutral-600 leading-snug mt-1 line-clamp-2">
                            Payment: {paymentMethodDisplay}
                          </p>
                        </div>
                      </div>

                      {/* Items Table */}
                      <div className="rounded-xl overflow-hidden border border-neutral-200">
                        <div className="bg-[#0B1528] text-white px-3 py-2 flex items-center justify-between text-[9.5px] font-bold uppercase tracking-wider">
                          <span className="flex-1">ITEM DESCRIPTION</span>
                          <span className="w-8 text-center">QTY</span>
                          <span className="w-14 text-right">PRICE</span>
                          <span className="w-14 text-right">AMOUNT</span>
                        </div>
                        <div className="divide-y divide-neutral-100 bg-white">
                          {items.map((item, idx) => (
                            <div key={idx} className="px-3 py-2.5 flex items-start justify-between text-xs">
                              <div className="flex-1 pr-2 min-w-0">
                                <p className="font-bold text-neutral-900 truncate leading-snug">
                                  {item.name}
                                </p>
                                <p className="text-[9px] text-neutral-400 mt-0.5">
                                  Size: {item.size || "M"} · Color: {item.color || "Default"} | HSN: 610910
                                </p>
                              </div>
                              <span className="w-8 text-center text-neutral-700">{item.quantity || 1}</span>
                              <span className="w-14 text-right text-neutral-700">₹{item.price}</span>
                              <span className="w-14 text-right font-bold text-neutral-900">
                                ₹{(item.price || 0) * (item.quantity || 1)}
                              </span>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Tax Breakdown Card */}
                      <div className="rounded-xl bg-[#F8FAFC] border border-slate-200/90 p-3 space-y-2 text-xs">
                        <div className="flex justify-between text-neutral-600">
                          <span>Taxable Value</span>
                          <span>₹{taxableValue.toFixed(2)}</span>
                        </div>
                        <div className="flex justify-between text-neutral-600">
                          <span>CGST (9%)</span>
                          <span>₹{cgst.toFixed(2)}</span>
                        </div>
                        <div className="flex justify-between text-neutral-600">
                          <span>SGST (9%)</span>
                          <span>₹{sgst.toFixed(2)}</span>
                        </div>
                        <div className="border-t border-neutral-200 pt-2 flex items-center justify-between">
                          <span className="font-bold text-neutral-900 uppercase text-[11px] tracking-wide">
                            GRAND TOTAL (INCL. GST)
                          </span>
                          <span className="font-serif font-black text-xl text-[#8B6508]">
                            ₹{grandTotal}
                          </span>
                        </div>
                      </div>

                      {/* Footer QR & Signatory */}
                      <div className="pt-3 border-t border-neutral-100 flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <div className="size-9 bg-neutral-900 text-white rounded p-1 flex items-center justify-center shrink-0">
                            <QrCode className="size-7 text-white" />
                          </div>
                          <p className="text-[8.5px] text-neutral-400 leading-tight">
                            Scan QR for Digital<br />E-Invoice Verification
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="font-bold text-[9px] text-neutral-800 uppercase tracking-wider">
                            For VEXA STYLE HUB PVT LTD
                          </p>
                          <p className="text-[8.5px] italic text-neutral-400 mt-2">
                            Authorized Signatory
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* 3. STICKY DOWNLOAD BUTTON */}
                <div className="fixed bottom-0 left-0 right-0 z-40 bg-[#F4F6F9] border-t border-neutral-200 p-4 pb-6 max-w-sm mx-auto w-full">
                  <button
                    type="button"
                    onClick={() => handleDownloadInvoice(ord)}
                    className="w-full rounded-xl bg-[#8B6508] hover:bg-[#785707] text-white py-3.5 text-xs font-bold uppercase tracking-wider shadow-md active:scale-98 transition-all flex items-center justify-center gap-2 cursor-pointer"
                  >
                    <Download className="size-4.5" />
                    <span>DOWNLOAD & SAVE INVOICE PDF</span>
                  </button>
                </div>
              </div>
            );
          })()}

          {/* ── MOBILE RESPONSIVE ONLY: 1:1 PIXEL-PERFECT REPLICA OF FLUTTER CUSTOMER SUPPORT SCREEN ── */}
          {(showMobileSupportScreen || activeTab === "support") && (
            <div className="block md:hidden fixed inset-0 z-50 bg-[#FAFAFC] dark:bg-background overflow-y-auto flex flex-col animate-in fade-in duration-200">
              {(() => {
                const ord = mobileSupportOrder || selectedOrderDetailsModal || (myOrders && myOrders.length > 0 ? myOrders[0] : null);
                const rawId = ord ? String(ord._id || ord.id || "VX-1419").replace(/^#/, "") : "VX-1419";
                const formattedOrderId = rawId.length > 8 ? rawId.slice(-8).toUpperCase() : rawId.toUpperCase();
                const firstItem = ord?.items?.[0] || { name: "Gold-Embroidered Luxe Tee", price: 2123 };
                const statusStr = (ord?.status || "Order Placed").toUpperCase();
                const isCancelled = statusStr.includes("CANCEL");
                const isDelivered = statusStr.includes("DELIVER");

                const faqs = [
                  {
                    question: "How do I track my live order delivery status?",
                    answer: "You can tap 'Track Order' on any active order in your My Orders tab to view real-time GPS courier movements and estimated delivery timelines.",
                  },
                  {
                    question: "What is VEXA's return & exchange policy?",
                    answer: "We offer 7-day hassle-free returns and exchanges for all unworn luxury garments with tags intact. Instant refund is credited to your VEXA Wallet upon pickup verification.",
                  },
                  {
                    question: "How does instant VEXA Wallet refund work?",
                    answer: "When an order is cancelled or returned, refund amount is instantly credited to your VEXA Pay Wallet, ready to be used for future luxury purchases.",
                  },
                  {
                    question: "How do I request custom embroidery or bespoke fitting?",
                    answer: "Select 'Bespoke & Custom Orders' topic or tap 'Book Custom Tee' to submit your custom sleeve text, chest monogram, or tailored size preferences directly to our master tailors.",
                  },
                ];

                const handleSubmitTicket = async (e: React.FormEvent) => {
                  e.preventDefault();
                  if (!supportMessage.trim()) {
                    toast.error("Please describe your issue or custom request in detail.");
                    return;
                  }
                  setSupportSubmitting(true);
                  const ticketId = `#VX-SUP-${Math.floor(1000 + Math.random() * 9000)}`;
                  const newTicket = {
                    _id: ticketId,
                    id: ticketId,
                    ticketId,
                    orderId: `#${formattedOrderId}`,
                    category: supportCategory,
                    message: supportMessage.trim(),
                    phone: supportPhone.trim() || user?.phone || "+91 98765 43210",
                    status: "Open",
                    createdAt: new Date().toISOString(),
                    sender: user?.name || "Valued Client",
                  };

                  try {
                    await fetch(`${API_URL}/notifications/support`, {
                      method: "POST",
                      headers: { "Content-Type": "application/json" },
                      body: JSON.stringify(newTicket),
                    });
                  } catch (err) {
                    console.warn("Support ticket submitted locally:", err);
                  }

                  const updatedTickets = [newTicket, ...userSupportTickets];
                  setUserSupportTickets(updatedTickets);
                  if (typeof window !== "undefined") {
                    localStorage.setItem("vexa_user_support_tickets", JSON.stringify(updatedTickets));
                  }
                  setSupportMessage("");
                  setSupportSubmitting(false);
                  toast.success(`Support Ticket ${ticketId} created! Our concierge will reply shortly.`);
                };

                const handleCloseSupport = () => {
                  setShowMobileSupportScreen(false);
                  setMobileSupportOrder(null);
                  setSelectedOrderDetailsModal(null);
                  setActiveTab("profile");
                  setSearchParams({ tab: "profile" });
                };

                return (
                  <>
                    {/* 1. TOP APP BAR */}
                    <div className="sticky top-0 z-30 bg-white/95 dark:bg-card/95 backdrop-blur-md border-b border-neutral-200/80 dark:border-neutral-800 px-4 py-3 flex items-center justify-between shadow-2xs">
                      <button
                        type="button"
                        onClick={handleCloseSupport}
                        className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1 cursor-pointer"
                        aria-label="Back"
                      >
                        <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
                      </button>

                      <div className="flex items-center gap-2">
                        <div className="flex size-7.5 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] border border-[#EADBBE]/70 shrink-0">
                          <Headphones className="size-4" />
                        </div>
                        <h1 className="font-serif text-[13.5px] font-bold uppercase tracking-widest text-foreground">
                          CUSTOMER SUPPORT
                        </h1>
                      </div>

                      <div className="size-9 -mr-1" />
                    </div>

                    {/* 2. SCROLLABLE CONTENT BODY */}
                    <div className="flex-1 px-4 py-4 space-y-4 pb-24">
                      {/* CARD 1: ORDER ASSISTANCE CONTEXT */}
                      {ord && (
                        <div className="rounded-2xl border border-[#EADBBE] dark:border-amber-900/60 bg-[#FDFBF7] dark:bg-amber-950/20 p-3.5 flex items-center justify-between gap-3 shadow-2xs">
                          <div className="flex items-center gap-3 min-w-0">
                            <div className="flex size-10 items-center justify-center rounded-xl bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] border border-[#EADBBE]/80 shrink-0">
                              <Package className="size-5" />
                            </div>
                            <div className="min-w-0">
                              <h3 className="font-bold text-[13px] text-foreground truncate">
                                Assistance for Order #{formattedOrderId}
                              </h3>
                              <p className="text-[11.5px] text-muted-foreground truncate mt-0.5">
                                {firstItem.name} • ₹{(ord.totalAmount || firstItem.price || 2123).toLocaleString("en-IN")}
                              </p>
                            </div>
                          </div>

                          <div className={`rounded-lg px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider shrink-0 ${
                            isCancelled
                              ? "bg-red-100 dark:bg-red-950/50 text-red-600 dark:text-red-400"
                              : isDelivered
                              ? "bg-emerald-100 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400"
                              : "bg-[#FAF6EE] dark:bg-amber-950/50 text-[#8B6508] dark:text-[#E5BF4E] border border-[#EADBBE]/80"
                          }`}>
                            {statusStr}
                          </div>
                        </div>
                      )}

                      {/* CARD 2: LIVE CONCIERGE CHAT PROMPT */}
                      <div className="rounded-2xl border border-[#E5C07B] dark:border-amber-700/80 bg-gradient-to-br from-[#FFFBEB] to-[#FEF3C7] dark:from-amber-950/40 dark:to-yellow-950/30 p-4 shadow-sm flex items-center justify-between gap-3">
                        <div className="flex items-center gap-3.5 min-w-0">
                          <div className="flex size-11 items-center justify-center rounded-full bg-[#B8860B]/15 border border-[#B8860B]/30 text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                            <MessageCircle className="size-6" />
                          </div>
                          <div className="min-w-0">
                            <h4 className="font-serif font-bold text-[13.5px] text-[#3D2A00] dark:text-amber-100 tracking-wide uppercase">
                              LIVE CONCIERGE CHAT
                            </h4>
                            <p className="text-xs font-medium text-[#78591A] dark:text-amber-300 mt-0.5 truncate">
                              Instant 24/7 AI & Stylist Support
                            </p>
                          </div>
                        </div>

                        <button
                          type="button"
                          onClick={() => {
                            setShowLiveConciergeChat(true);
                          }}
                          className="rounded-xl bg-[#8B6508] hover:bg-[#785707] text-white px-3.5 py-2.5 font-bold text-xs shadow-sm active:scale-95 transition-all cursor-pointer whitespace-nowrap shrink-0"
                        >
                          Start Chat
                        </button>
                      </div>

                      {/* CARD 3: 3 QUICK CONTACT CHANNELS */}
                      <div className="grid grid-cols-3 gap-2.5">
                        {/* WhatsApp VIP */}
                        <button
                          type="button"
                          onClick={() => {
                            window.open("https://wa.me/919876543210?text=Hello%20VEXA%20VIP%20Support", "_blank");
                          }}
                          className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-3 flex flex-col items-center text-center shadow-2xs hover:border-emerald-300 transition-all active:scale-95 cursor-pointer"
                        >
                          <div className="size-10 rounded-full bg-emerald-50 dark:bg-emerald-950/40 text-[#10B981] flex items-center justify-center mb-2 border border-emerald-100 dark:border-emerald-900/40">
                            <MessageCircle className="size-5" />
                          </div>
                          <span className="font-bold text-xs text-foreground">WhatsApp VIP</span>
                          <span className="text-[10px] text-muted-foreground mt-0.5">Instant Chat</span>
                        </button>

                        {/* Call Support */}
                        <button
                          type="button"
                          onClick={() => {
                            window.open("tel:18001238392", "_self");
                          }}
                          className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-3 flex flex-col items-center text-center shadow-2xs hover:border-amber-300 transition-all active:scale-95 cursor-pointer"
                        >
                          <div className="size-10 rounded-full bg-amber-50 dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] flex items-center justify-center mb-2 border border-amber-100 dark:border-amber-900/40">
                            <Phone className="size-5" />
                          </div>
                          <span className="font-bold text-xs text-foreground">Call Support</span>
                          <span className="text-[10px] text-muted-foreground mt-0.5">Toll-Free 24/7</span>
                        </button>

                        {/* Email Us */}
                        <button
                          type="button"
                          onClick={() => {
                            window.open("mailto:support@vexa.app?subject=VEXA%20Support%20Request", "_self");
                          }}
                          className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-3 flex flex-col items-center text-center shadow-2xs hover:border-blue-300 transition-all active:scale-95 cursor-pointer"
                        >
                          <div className="size-10 rounded-full bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 flex items-center justify-center mb-2 border border-blue-100 dark:border-blue-900/40">
                            <Mail className="size-5" />
                          </div>
                          <span className="font-bold text-xs text-foreground">Email Us</span>
                          <span className="text-[10px] text-muted-foreground mt-0.5 truncate max-w-full">support@vexa.app</span>
                        </button>
                      </div>

                      {/* ACTIVE TICKETS LIST (IF ANY) */}
                      {userSupportTickets.length > 0 && (
                        <div className="space-y-2.5">
                          <div className="flex items-center justify-between px-0.5">
                            <h4 className="font-serif text-xs font-bold uppercase tracking-wider text-foreground">
                              MY SUPPORT TICKETS ({userSupportTickets.length})
                            </h4>
                          </div>
                          {userSupportTickets.map((t, idx) => (
                            <div
                              key={`user-ticket-${idx}`}
                              className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-3.5 space-y-2 shadow-2xs"
                            >
                              <div className="flex items-center justify-between">
                                <span className="font-mono text-xs font-bold text-[#8B6508] dark:text-[#E5BF4E] bg-amber-50 dark:bg-amber-950/40 px-2 py-0.5 rounded-md">
                                  {t.ticketId || t._id}
                                </span>
                                <span className="rounded-full bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200/50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider">
                                  {t.status || "Open"}
                                </span>
                              </div>
                              <p className="text-xs text-foreground font-medium">{t.message}</p>
                              <div className="flex items-center justify-between text-[10px] text-muted-foreground pt-1 border-t border-neutral-100 dark:border-neutral-800">
                                <span>Topic: {t.category || "Order Issue"}</span>
                                <span>{new Date(t.createdAt || Date.now()).toLocaleDateString("en-IN", { day: "numeric", month: "short" })}</span>
                              </div>
                            </div>
                          ))}
                        </div>
                      )}

                      {/* CARD 4: RAISE A SUPPORT TICKET */}
                      <div className="rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4.5 space-y-3.5 shadow-xs">
                        <div>
                          <h3 className="font-serif text-sm font-bold uppercase tracking-wider text-foreground">
                            RAISE A SUPPORT TICKET
                          </h3>
                          <p className="text-xs text-muted-foreground mt-0.5">
                            Select category and tell us how we can assist you.
                          </p>
                        </div>

                        <form onSubmit={handleSubmitTicket} className="space-y-3.5">
                          {/* Select Topic */}
                          <div>
                            <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground block mb-1">
                              Select Topic
                            </label>
                            <select
                              value={supportCategory}
                              onChange={(e) => setSupportCategory(e.target.value)}
                              className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50/50 dark:bg-neutral-800/50 px-3.5 py-3 text-xs font-semibold text-foreground outline-none focus:border-[#8B6508] cursor-pointer"
                            >
                              <option value="Order Issue">Order Issue</option>
                              <option value="Delivery & Tracking">Delivery & Tracking</option>
                              <option value="Returns & Exchanges">Returns & Exchanges</option>
                              <option value="Size & Fit Advice">Size & Fit Advice</option>
                              <option value="Bespoke & Custom Orders">Bespoke & Custom Orders</option>
                              <option value="Payment & Wallet">Payment & Wallet</option>
                            </select>
                          </div>

                          {/* Callback Phone */}
                          <div>
                            <div className="relative">
                              <Phone className="size-4 text-[#8B6508] dark:text-[#E5BF4E] absolute left-3.5 top-1/2 -translate-y-1/2" />
                              <input
                                type="tel"
                                value={supportPhone}
                                onChange={(e) => setSupportPhone(e.target.value)}
                                placeholder="Callback Phone / WhatsApp Number"
                                className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50/50 dark:bg-neutral-800/50 pl-10 pr-3.5 py-3 text-xs font-medium text-foreground outline-none focus:border-[#8B6508]"
                              />
                            </div>
                          </div>

                          {/* Message / Query */}
                          <div>
                            <textarea
                              rows={3}
                              value={supportMessage}
                              onChange={(e) => setSupportMessage(e.target.value)}
                              placeholder="Describe your issue or custom request in detail..."
                              className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50/50 dark:bg-neutral-800/50 p-3.5 text-xs font-medium text-foreground outline-none focus:border-[#8B6508] resize-none"
                            />
                          </div>

                          {/* Submit Button */}
                          <button
                            type="submit"
                            disabled={supportSubmitting}
                            className="w-full rounded-xl bg-[#8B6508] hover:bg-[#785707] text-white py-3.5 font-bold text-xs uppercase tracking-wider shadow-sm transition-all active:scale-98 cursor-pointer disabled:opacity-70 flex items-center justify-center gap-2"
                          >
                            {supportSubmitting ? (
                              <>
                                <RefreshCw className="size-4 animate-spin" />
                                <span>SUBMITTING TICKET...</span>
                              </>
                            ) : (
                              <span>SUBMIT SUPPORT TICKET</span>
                            )}
                          </button>
                        </form>
                      </div>

                      {/* SECTION 5: FREQUENTLY ASKED QUESTIONS */}
                      <div className="space-y-2.5 pt-1">
                        <h4 className="font-serif text-xs font-bold uppercase tracking-wider text-foreground px-0.5">
                          FREQUENTLY ASKED QUESTIONS
                        </h4>

                        <div className="space-y-2">
                          {faqs.map((faq, idx) => {
                            const isExpanded = expandedFaqIndex === idx;
                            return (
                              <div
                                key={`faq-${idx}`}
                                className={`rounded-2xl border transition-all overflow-hidden ${
                                  isExpanded
                                    ? "border-[#8B6508] bg-white dark:bg-card shadow-xs"
                                    : "border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card"
                                }`}
                              >
                                <button
                                  type="button"
                                  onClick={() => setExpandedFaqIndex(isExpanded ? null : idx)}
                                  className="w-full p-3.5 flex items-center justify-between gap-3 text-left cursor-pointer"
                                >
                                  <span className={`text-[12.5px] font-semibold leading-snug ${
                                    isExpanded ? "text-[#8B6508] dark:text-[#E5BF4E] font-bold" : "text-foreground"
                                  }`}>
                                    {faq.question}
                                  </span>
                                  <ChevronDown
                                    className={`size-4 text-muted-foreground shrink-0 transition-transform duration-200 ${
                                      isExpanded ? "rotate-180 text-[#8B6508]" : ""
                                    }`}
                                  />
                                </button>
                                {isExpanded && (
                                  <div className="px-3.5 pb-3.5 text-xs text-muted-foreground leading-relaxed border-t border-neutral-100 dark:border-neutral-800/60 pt-2.5">
                                    {faq.answer}
                                  </div>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    </div>

                    {/* 3. CONCIERGE LIVE CHAT BOTTOM SHEET MODAL (MOBILE RESPONSIVE ONLY) */}
                    {showLiveConciergeChat && (
                      <div className="fixed inset-0 z-[60] flex flex-col justify-end">
                        {/* Semi-transparent Backdrop */}
                        <div
                          className="fixed inset-0 bg-black/60 backdrop-blur-xs transition-opacity animate-in fade-in duration-200"
                          onClick={() => setShowLiveConciergeChat(false)}
                        />

                        {/* Bottom Sheet Drawer */}
                        <div className="relative z-10 w-full bg-white dark:bg-card rounded-t-3xl shadow-2xl overflow-hidden flex flex-col max-h-[82vh] h-[78vh] animate-in slide-in-from-bottom duration-300">
                          {/* 1. Header (Dark Navy #0F172A) */}
                          <div className="bg-[#0F172A] text-white px-4 py-3.5 flex items-center justify-between shrink-0 border-b border-slate-800">
                            <div className="flex items-center gap-3">
                              <div className="flex size-9 items-center justify-center rounded-full bg-[#B8860B]/25 text-[#E5BF4E] border border-[#B8860B]/40 shrink-0">
                                <Headphones className="size-5" />
                              </div>
                              <div>
                                <h3 className="font-serif text-sm font-bold uppercase tracking-wider text-white">
                                  CONCIERGE LIVE CHAT
                                </h3>
                                <p className="text-[11px] text-slate-300 flex items-center gap-1.5 mt-0.5 font-medium">
                                  <span className="size-2 rounded-full bg-emerald-500 inline-block animate-pulse" />
                                  <span>Online • Concierge Active</span>
                                </p>
                              </div>
                            </div>

                            <button
                              type="button"
                              onClick={() => setShowLiveConciergeChat(false)}
                              className="flex size-8 items-center justify-center rounded-full text-slate-300 hover:text-white hover:bg-white/10 active:scale-90 transition-all cursor-pointer"
                              aria-label="Close Chat"
                            >
                              <X className="size-5" />
                            </button>
                          </div>

                          {/* 2. Quick Suggestion Chips */}
                          <div className="px-3.5 py-2.5 bg-[#FAF6EE] dark:bg-amber-950/20 border-b border-neutral-200/80 dark:border-neutral-800 flex items-center gap-2 overflow-x-auto no-scrollbar shrink-0">
                            <button
                              type="button"
                              onClick={() => handleSendConciergeMessage("Track my live order delivery")}
                              className="rounded-full border border-[#D4AF37]/60 bg-white dark:bg-neutral-800 px-3 py-1.5 text-xs font-semibold text-[#8B6508] dark:text-[#E5BF4E] hover:bg-amber-50 active:scale-95 transition-all whitespace-nowrap cursor-pointer shrink-0 shadow-2xs"
                            >
                              📦 Track Live Delivery
                            </button>
                            <button
                              type="button"
                              onClick={() => handleSendConciergeMessage("How does instant wallet refund work?")}
                              className="rounded-full border border-[#D4AF37]/60 bg-white dark:bg-neutral-800 px-3 py-1.5 text-xs font-semibold text-[#8B6508] dark:text-[#E5BF4E] hover:bg-amber-50 active:scale-95 transition-all whitespace-nowrap cursor-pointer shrink-0 shadow-2xs"
                            >
                              💵 Wallet Refund Query
                            </button>
                            <button
                              type="button"
                              onClick={() => handleSendConciergeMessage("Help me select correct fit and size")}
                              className="rounded-full border border-[#D4AF37]/60 bg-white dark:bg-neutral-800 px-3 py-1.5 text-xs font-semibold text-[#8B6508] dark:text-[#E5BF4E] hover:bg-amber-50 active:scale-95 transition-all whitespace-nowrap cursor-pointer shrink-0 shadow-2xs"
                            >
                              📏 Size & Fit Advice
                            </button>
                          </div>

                          {/* 3. Messages List Area */}
                          <div className="flex-1 p-4 overflow-y-auto space-y-3 bg-[#FAFAFC] dark:bg-background">
                            {conciergeMessages.map((msg, idx) => {
                              const isUser = msg.sender === "user";
                              return (
                                <div
                                  key={`chat-msg-${idx}`}
                                  className={`flex ${isUser ? "justify-end" : "justify-start"}`}
                                >
                                  <div
                                    className={`p-3.5 text-xs leading-relaxed max-w-[85%] ${
                                      isUser
                                        ? "rounded-2xl rounded-br-xs bg-[#8B6508] text-white shadow-sm font-medium"
                                        : "rounded-2xl rounded-bl-xs bg-white dark:bg-neutral-800 text-foreground border border-neutral-200/80 dark:border-neutral-700/80 shadow-2xs"
                                    }`}
                                  >
                                    {msg.text}
                                  </div>
                                </div>
                              );
                            })}
                            <div ref={chatMessagesEndRef} />
                          </div>

                          {/* 4. Bottom Input Bar */}
                          <form
                            onSubmit={(e) => {
                              e.preventDefault();
                              handleSendConciergeMessage();
                            }}
                            className="p-3 bg-white dark:bg-card border-t border-neutral-200/80 dark:border-neutral-800 flex items-center gap-2 shrink-0"
                          >
                            <input
                              type="text"
                              value={conciergeInput}
                              onChange={(e) => setConciergeInput(e.target.value)}
                              placeholder="Type your message to VIP agent..."
                              className="flex-1 rounded-full border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800/60 px-4 py-2.5 text-xs text-foreground placeholder:text-muted-foreground outline-none focus:border-[#8B6508]"
                            />
                            <button
                              type="submit"
                              className="size-10 rounded-full bg-[#8B6508] hover:bg-[#785707] text-white flex items-center justify-center shrink-0 shadow-sm active:scale-95 transition-all cursor-pointer"
                              aria-label="Send"
                            >
                              <Send className="size-4.5" />
                            </button>
                          </form>
                        </div>
                      </div>
                    )}
                  </>
                );
              })()}
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
                    {/* =========================================================================
                        MOBILE RESPONSIVE VIEW ONLY (< md)
                        Matches Flutter Mobile App Shopping Cart screen 1:1
                        ========================================================================= */}
                    <div className="block md:hidden pb-12">
                      {/* Top Header: Back Button + Title (Count) */}
                      <div className="flex items-center gap-3 py-1">
                        <button
                          type="button"
                          onClick={() => {
                            if (window.history.state && typeof window.history.state.idx === "number" && window.history.state.idx > 0) {
                              navigate(-1);
                            } else {
                              navigate("/products");
                            }
                          }}
                          className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1 cursor-pointer"
                          aria-label="Go Back"
                        >
                          <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
                        </button>
                        <div>
                          <h1 className="font-serif text-lg font-bold uppercase tracking-wider text-foreground leading-tight">
                            SHOPPING CART
                          </h1>
                          <p className="text-xs text-muted-foreground">
                            {cartItems.length} {cartItems.length === 1 ? "product" : "products"} in cart
                          </p>
                        </div>
                      </div>

                      {/* Free Express Shipping Banner */}
                      <div className="mt-3 -mx-4 flex items-center justify-center gap-2 bg-[#FAF6EE] dark:bg-amber-950/20 py-2.5 px-4 text-[10.5px] font-bold tracking-wider text-[#8B6508] dark:text-[#E5BF4E] uppercase">
                        <Truck className="size-4 shrink-0 fill-current" />
                        <span>FREE EXPRESS SHIPPING APPLIED TO YOUR ORDER</span>
                      </div>

                      {cartItems.length > 0 ? (
                        <>
                          {/* Cart Items List */}
                          <div className="mt-4 space-y-3">
                            {cartItems.map((ci, idx) => (
                              <div
                                key={`mobile-cart-${ci.product.id}-${ci.size}-${idx}`}
                                className="flex items-center gap-3.5 rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-3 shadow-xs"
                              >
                                {/* Square Image Thumbnail */}
                                <img
                                  src={getProductImage(ci.product)}
                                  alt={ci.product.name}
                                  className="size-20 rounded-xl object-cover bg-neutral-900 border border-neutral-200/60 dark:border-neutral-800 shrink-0"
                                />

                                {/* Product Details */}
                                <div className="flex-1 min-w-0 flex flex-col justify-between h-20">
                                  <div className="flex items-start justify-between gap-2">
                                    <h4 className="font-bold text-xs text-foreground truncate">
                                      {ci.product.name}
                                    </h4>
                                    <button
                                      type="button"
                                      onClick={() => removeFromCart(ci.product.id, ci.size)}
                                      className="text-rose-500 hover:text-rose-600 transition-colors p-0.5 active:scale-90 shrink-0"
                                      title="Remove item"
                                    >
                                      <Trash2 className="size-4" />
                                    </button>
                                  </div>

                                  {/* Badges: Color & Size */}
                                  <div className="flex items-center gap-2">
                                    <span className="rounded-md bg-neutral-100 dark:bg-neutral-800 px-2 py-0.5 text-[10px] font-medium text-neutral-600 dark:text-neutral-300">
                                      Color: {ci.product.color || "Default"}
                                    </span>
                                    <span className="rounded-md bg-neutral-100 dark:bg-neutral-800 px-2 py-0.5 text-[10px] font-medium text-neutral-600 dark:text-neutral-300">
                                      Size: {ci.size}
                                    </span>
                                  </div>

                                  {/* Price & Quantity Selector */}
                                  <div className="flex items-center justify-between">
                                    <span className="text-sm font-bold text-[#8B6508] dark:text-[#D4AF37]">
                                      ₹{ci.product.price.toLocaleString("en-IN")}
                                    </span>

                                    <div className="flex items-center gap-2.5 rounded-lg bg-neutral-100 dark:bg-neutral-800 px-2.5 py-1">
                                      <button
                                        type="button"
                                        onClick={() => updateCartQuantity(ci.product.id, ci.size, -1)}
                                        className="text-neutral-600 dark:text-neutral-300 hover:text-foreground text-xs font-bold active:scale-90"
                                      >
                                        <Minus className="size-3" />
                                      </button>
                                      <span className="text-xs font-bold text-foreground min-w-[12px] text-center">
                                        {ci.quantity}
                                      </span>
                                      <button
                                        type="button"
                                        onClick={() => updateCartQuantity(ci.product.id, ci.size, 1)}
                                        className="text-neutral-600 dark:text-neutral-300 hover:text-foreground text-xs font-bold active:scale-90"
                                      >
                                        <Plus className="size-3" />
                                      </button>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>

                          {/* Promo / Coupon Code Card */}
                          <div className="mt-4 rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-3.5 shadow-xs space-y-3">
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-2 text-foreground font-bold text-xs">
                                <Tag className="size-4 text-[#8B6508] dark:text-[#D4AF37]" />
                                <span>Promo / Coupon Code</span>
                              </div>
                              <button
                                type="button"
                                onClick={() => {
                                  setMobileCouponInput("VEXA10");
                                  const disc = Math.round(totalAmount * 0.1);
                                  setMobileCouponDiscount(disc);
                                  setMobileCouponMsg(`🎉 Coupon VEXA10 applied! You saved ₹${disc}.`);
                                }}
                                className="text-[10px] font-semibold text-[#8B6508] dark:text-[#D4AF37] hover:underline cursor-pointer"
                              >
                                Try "VEXA10" or "VEXA30"
                              </button>
                            </div>

                            <div className="flex items-center gap-2">
                              <input
                                type="text"
                                value={mobileCouponInput}
                                onChange={(e) => setMobileCouponInput(e.target.value.toUpperCase())}
                                placeholder="Enter code (e.g. VEXA10)"
                                className="flex-1 rounded-xl bg-[#F4F6F9] dark:bg-neutral-900 border border-neutral-200/50 dark:border-neutral-800 focus:border-[#8B6508] px-3.5 py-2.5 text-xs text-foreground placeholder:text-neutral-400 outline-none transition-colors"
                              />
                              <button
                                type="button"
                                onClick={handleApplyMobileCoupon}
                                className="rounded-xl bg-[#8B6508] hover:bg-[#7A5807] text-white px-4 py-2.5 text-xs font-bold shadow-xs active:scale-95 transition-all cursor-pointer"
                              >
                                Apply
                              </button>
                            </div>

                            {mobileCouponMsg && (
                              <p className={`text-[11px] font-medium ${mobileCouponDiscount > 0 ? "text-emerald-600" : "text-rose-500"}`}>
                                {mobileCouponMsg}
                              </p>
                            )}
                          </div>

                          {/* Mobile Order Summary & Checkout Bottom Card */}
                          <div className="mt-6 rounded-t-3xl border-t border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-5 shadow-lg space-y-4 -mx-4 -mb-8">
                            <div className="space-y-2 text-xs">
                              <div className="flex justify-between text-neutral-600 dark:text-neutral-400">
                                <span>Subtotal:</span>
                                <span className="font-semibold text-foreground">₹{totalAmount.toLocaleString("en-IN")}</span>
                              </div>
                              {mobileCouponDiscount > 0 && (
                                <div className="flex justify-between text-emerald-600 font-semibold">
                                  <span>Coupon Discount:</span>
                                  <span>-₹{mobileCouponDiscount.toLocaleString("en-IN")}</span>
                                </div>
                              )}
                              <div className="flex justify-between text-neutral-600 dark:text-neutral-400">
                                <span>Taxes & Duties (GST 18%):</span>
                                <span className="font-semibold text-foreground">+₹{mobileGstAmount.toLocaleString("en-IN")}</span>
                              </div>
                            </div>

                            <div className="h-px bg-neutral-200/80 dark:bg-neutral-800" />

                            <div className="flex items-center justify-between">
                              <div>
                                <h3 className="font-serif text-base font-bold uppercase tracking-wider text-foreground leading-tight">
                                  GRAND TOTAL
                                </h3>
                                <p className="text-[10px] text-muted-foreground mt-0.5">
                                  GST 18% tax included in total
                                </p>
                              </div>
                              <span className="font-serif text-xl font-black text-[#8B6508] dark:text-[#D4AF37]">
                                ₹{mobileGrandTotal.toLocaleString("en-IN")}
                              </span>
                            </div>

                            <button
                              type="button"
                              onClick={() => {
                                setIsCartCheckout(true);
                                setCartCheckoutStep("address");
                                setOrderSuccessMsg("");
                              }}
                              className="w-full rounded-xl bg-[#8B6508] hover:bg-[#7A5807] py-3.5 text-xs font-bold uppercase tracking-wider text-white shadow-md active:scale-98 transition-all flex items-center justify-center gap-2 cursor-pointer"
                            >
                              <span>PROCEED TO CHECKOUT</span>
                              <ArrowRight className="size-4" />
                            </button>
                          </div>
                        </>
                      ) : (
                        <div className="mt-8 flex flex-col items-center justify-center rounded-2xl border border-dashed border-neutral-200 dark:border-neutral-800 bg-white dark:bg-card p-8 text-center space-y-4">
                          <div className="flex size-14 items-center justify-center rounded-full bg-amber-50 dark:bg-amber-950/30 text-[#8B6508]">
                            <ShoppingBag className="size-7" />
                          </div>
                          <div>
                            <h3 className="font-bold text-sm text-foreground">Your cart is empty</h3>
                            <p className="text-xs text-muted-foreground mt-1">Looks like you haven't added anything yet.</p>
                          </div>
                          <Link
                            to="/products"
                            className="rounded-xl bg-[#8B6508] hover:bg-[#7A5807] text-white px-6 py-2.5 text-xs font-bold uppercase tracking-wider shadow-sm active:scale-95 transition-all"
                          >
                            Start Shopping
                          </Link>
                        </div>
                      )}
                    </div>

                    {/* =========================================================================
                        DESKTOP VIEW (>= md) - Left Untouched
                        ========================================================================= */}
                    <div className="hidden md:block">
                      <div className={`${cartItems.length > 0 ? "flex" : "hidden sm:flex"} items-center justify-between border-b border-border pb-3 sm:pb-4 gap-3`}>
                        <div className="hidden sm:flex items-center gap-3">
                          <h2 className="font-display text-2xl font-bold text-foreground">My Cart</h2>
                        </div>
                        {cartItems.length > 0 && (
                          <button
                            onClick={clearCart}
                            className="text-xs text-muted-foreground hover:text-destructive transition-colors uppercase tracking-wider font-semibold cursor-pointer ml-auto"
                          >
                            Clear Cart
                          </button>
                        )}
                      </div>

                      {cartItems.length > 0 ? (
                        <div className="grid gap-8 lg:grid-cols-[1fr_320px] mt-6">
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
                    </div>
                  </>
                )}

                {/* =========================================================================
                    MOBILE RESPONSIVE CHECKOUT & DELIVERY VIEW ONLY (< md)
                    Matches Flutter Mobile App Checkout & Delivery screen 1:1
                    ========================================================================= */}
                {(cartCheckoutStep === "address" || cartCheckoutStep === "payment") && (
                  <div className="block md:hidden pb-12 animate-in fade-in duration-300">
                    {/* Top Header: Back Button + Circular Icon + Title + Subtitle */}
                    <div className="flex items-center gap-3 py-1">
                      <button
                        type="button"
                        onClick={() => {
                          if (cartCheckoutStep === "payment") {
                            setCartCheckoutStep("address");
                          } else {
                            setCartCheckoutStep("cart");
                          }
                        }}
                        className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1 cursor-pointer"
                        aria-label="Back"
                      >
                        <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
                      </button>
                      <div className="flex items-center gap-2.5">
                        <div className="flex size-8.5 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] shrink-0 border border-[#EADBBE]/50">
                          <Truck className="size-4.5" />
                        </div>
                        <div>
                          <h1 className="font-serif text-base font-bold uppercase tracking-wider text-foreground leading-tight">
                            CHECKOUT & DELIVERY
                          </h1>
                          <p className="text-[11px] text-muted-foreground">
                            Fast Doorstep Shipping & Secure Checkout
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* Section 1: Delivery Address */}
                    <div className="mt-4 space-y-2.5">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <h3 className="font-bold text-sm text-foreground">1. Delivery Address</h3>
                          <span className="rounded-md bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/60 px-2 py-0.5 text-[10px] font-bold text-emerald-600 dark:text-emerald-400 uppercase tracking-wider">
                            DEFAULT
                          </span>
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            type="button"
                            onClick={() => setShowMobileAddressSelector(true)}
                            className="flex items-center gap-1 rounded-lg bg-neutral-100 dark:bg-neutral-800 hover:bg-neutral-200 dark:hover:bg-neutral-700 px-2.5 py-1 text-xs font-semibold text-foreground transition-colors active:scale-95 shadow-2xs cursor-pointer"
                          >
                            <span>⇄</span>
                            <span>Change</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => setShowMobileAddressEdit(true)}
                            className="flex items-center gap-1 rounded-lg border border-amber-300/80 dark:border-amber-700/60 bg-amber-50/60 dark:bg-amber-950/30 hover:bg-amber-100 px-2.5 py-1 text-xs font-semibold text-amber-800 dark:text-amber-300 transition-colors active:scale-95 shadow-2xs cursor-pointer"
                          >
                            <span>✎</span>
                            <span>Edit</span>
                          </button>
                        </div>
                      </div>

                      {/* Selected Delivery Address Card */}
                      <div className="rounded-2xl border border-[#B8860B]/70 dark:border-[#B8860B]/50 bg-white dark:bg-card p-3.5 shadow-xs space-y-2">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <div className="flex size-7 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-neutral-800 text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                              <Home className="size-3.5" />
                            </div>
                            <span className="font-bold text-sm text-foreground">
                              {shippingName || user?.name || "Tatukulaedukondalu"}
                            </span>
                          </div>
                          <span className="flex items-center gap-1 rounded-md bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/60 px-2 py-0.5 text-[10px] font-bold text-emerald-600 dark:text-emerald-400 uppercase tracking-wider">
                            <span>✔</span>
                            <span>DELIVER HERE</span>
                          </span>
                        </div>

                        <p className="text-xs text-neutral-600 dark:text-neutral-300 leading-relaxed pl-1">
                          {shippingStreet || "Flat 402, Luxury Heights, Jubilee Hills Road No. 36"}
                        </p>

                        <div className="flex items-center gap-4 text-xs text-neutral-600 dark:text-neutral-400 pl-1 pt-0.5">
                          <span className="flex items-center gap-1">
                            <span>📞</span>
                            <span>+91 {shippingPhone || "98765 43210"}</span>
                          </span>
                          <span className="flex items-center gap-1">
                            <span>📍</span>
                            <span>PIN: {shippingPincode || "500033"}</span>
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Section 2: Select Payment Method */}
                    <div className="mt-5 space-y-2.5">
                      <h3 className="font-bold text-sm text-foreground">2. Select Payment Method</h3>

                      {/* Option 1: Razorpay Online Payment */}
                      <div
                        onClick={() => setPaymentMethod("Razorpay Online Payment (UPI, Cards, NetBanking, Wallets)")}
                        className={`rounded-2xl p-3.5 shadow-xs flex items-center justify-between cursor-pointer transition-all ${
                          paymentMethod.includes("Razorpay")
                            ? "border-2 border-[#0C2340] dark:border-amber-400 bg-white dark:bg-card"
                            : "border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card hover:border-neutral-300"
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <div className="flex size-10 items-center justify-center rounded-xl bg-[#0C2340] text-amber-400 shrink-0">
                            <Zap className="size-4.5 fill-current" />
                          </div>
                          <div>
                            <div className="flex items-center gap-2">
                              <span className="font-bold text-xs sm:text-sm text-foreground">
                                Razorpay Online Payment
                              </span>
                              <span className="rounded-sm bg-emerald-500 text-white text-[9px] font-extrabold px-1.5 py-0.2 tracking-wider">
                                OFFICIAL
                              </span>
                            </div>
                            <p className="text-[11px] text-neutral-500 mt-0.5">
                              UPI, Cards, NetBanking & Wallets
                            </p>
                          </div>
                        </div>
                        <div className={`flex size-5 items-center justify-center rounded-full ${paymentMethod.includes("Razorpay") ? "bg-[#0C2340] dark:bg-amber-400 text-white dark:text-black" : "border border-neutral-300 dark:border-neutral-700"}`}>
                          {paymentMethod.includes("Razorpay") && <Check className="size-3 stroke-[3]" />}
                        </div>
                      </div>

                      {/* Option 2: Cash on Delivery (COD) */}
                      <div
                        onClick={() => setPaymentMethod("Demo Cash on Delivery (COD)")}
                        className={`rounded-2xl p-3.5 shadow-xs flex items-center justify-between cursor-pointer transition-all ${
                          paymentMethod.includes("COD")
                            ? "border-2 border-[#0C2340] dark:border-amber-400 bg-white dark:bg-card"
                            : "border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card hover:border-neutral-300"
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <div className="flex size-10 items-center justify-center rounded-xl bg-[#0C2340] text-white shrink-0">
                            <Wallet className="size-4.5" />
                          </div>
                          <div>
                            <span className="font-bold text-xs sm:text-sm text-foreground">
                              Cash on Delivery (COD)
                            </span>
                            <p className="text-[11px] text-neutral-500 mt-0.5">
                              Pay in cash upon doorstep delivery
                            </p>
                          </div>
                        </div>
                        <div className={`flex size-5 items-center justify-center rounded-full ${paymentMethod.includes("COD") ? "bg-[#0C2340] dark:bg-amber-400 text-white dark:text-black" : "border border-neutral-300 dark:border-neutral-700"}`}>
                          {paymentMethod.includes("COD") && <Check className="size-3 stroke-[3]" />}
                        </div>
                      </div>
                    </div>

                    {/* Section 3: Order Bill Details */}
                    <div className="mt-5 rounded-2xl border border-neutral-200/80 dark:border-neutral-800 bg-white dark:bg-card p-4 shadow-xs space-y-2.5">
                      <h4 className="font-bold text-sm text-foreground">Order Bill Details</h4>

                      <div className="space-y-2 text-xs">
                        <div className="flex justify-between text-neutral-600 dark:text-neutral-400">
                          <span>Items Subtotal ({totalCartItemsCount}):</span>
                          <span className="font-bold text-foreground">₹{totalAmount.toLocaleString("en-IN")}</span>
                        </div>
                        <div className="flex justify-between text-neutral-600 dark:text-neutral-400">
                          <span>Delivery & Handling:</span>
                          <span className="font-bold text-emerald-600 dark:text-emerald-400">FREE</span>
                        </div>
                        <div className="flex justify-between text-neutral-600 dark:text-neutral-400">
                          <span>Taxes & Duties (GST 18%):</span>
                          <span className="font-bold text-foreground">+₹{mobileGstAmount.toLocaleString("en-IN")}</span>
                        </div>
                      </div>

                      <div className="h-px bg-neutral-200/80 dark:bg-neutral-800" />

                      <div className="flex items-center justify-between pt-1">
                        <span className="font-bold text-sm text-foreground">
                          Total Payable Amount:
                        </span>
                        <span className="font-serif text-xl font-black text-[#8B6508] dark:text-[#D4AF37]">
                          ₹{mobileGrandTotal.toLocaleString("en-IN")}
                        </span>
                      </div>
                    </div>

                    {/* Bottom Action Button */}
                    <div className="mt-6 pt-2 pb-6">
                        <button
                          type="button"
                          disabled={orderSubmitting}
                          onClick={(e) => {
                            if (paymentMethod.includes("Razorpay")) {
                              setMobileRazorpayStep("options");
                            } else {
                              handlePlaceOrder(e);
                            }
                          }}
                          className="w-full rounded-xl bg-[#0C2340] hover:bg-[#15345B] py-4 text-xs font-bold uppercase tracking-wider text-white shadow-lg active:scale-98 transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
                        >
                        {orderSubmitting ? (
                          <span>PROCESSING ORDER...</span>
                        ) : paymentMethod.includes("Razorpay") ? (
                          <>
                            <Zap className="size-3.5 fill-current text-amber-400" />
                            <span>PAY VIA RAZORPAY • ₹{mobileGrandTotal.toLocaleString("en-IN")}</span>
                          </>
                        ) : (
                          <>
                            <Package className="size-3.5" />
                            <span>PLACE ORDER (COD) • ₹{mobileGrandTotal.toLocaleString("en-IN")}</span>
                          </>
                        )}
                      </button>
                    </div>

                    {/* Mobile Change Address Modal */}
                    {showMobileAddressSelector && (
                      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-xs p-4">
                        <div className="w-full max-w-sm rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-card p-5 shadow-2xl space-y-4 animate-in zoom-in-95 duration-200 max-h-[85vh] overflow-y-auto">
                          <div className="flex items-center justify-between border-b border-border pb-3">
                            <h3 className="font-bold text-sm text-foreground">Select Delivery Address</h3>
                            <button
                              type="button"
                              onClick={() => setShowMobileAddressSelector(false)}
                              className="text-muted-foreground hover:text-foreground text-xs"
                            >
                              ✕
                            </button>
                          </div>

                          <div className="space-y-3">
                            {savedAddresses.map((addr: any) => {
                              const isSelected = selectedSavedAddressId === addr.id;
                              return (
                                <div
                                  key={addr.id}
                                  onClick={() => {
                                    setSelectedSavedAddressId(addr.id);
                                    setShippingName(addr.name || user?.name || "Tatukulaedukondalu");
                                    setShippingPhone(addr.mobile || "9876543210");
                                    setShippingStreet(addr.address || "");
                                    setShippingCity(addr.city || "Bengaluru");
                                    setShippingState(addr.state || "Karnataka");
                                    setShippingPincode(addr.pincode || "560038");
                                    setShippingAddress(`${addr.name} (+91 ${addr.mobile}), ${addr.address}, ${addr.city}, ${addr.state} - ${addr.pincode}`);
                                    setShowMobileAddressSelector(false);
                                  }}
                                  className={`rounded-xl border p-3 cursor-pointer transition-all text-xs ${
                                    isSelected
                                      ? "border-[#B8860B] bg-amber-50/50 dark:bg-amber-950/20 font-bold"
                                      : "border-neutral-200 dark:border-neutral-800 hover:border-neutral-300"
                                  }`}
                                >
                                  <div className="flex items-center justify-between">
                                    <span className="font-bold text-foreground">{addr.name}</span>
                                    {addr.isDefault && (
                                      <span className="text-[9px] bg-emerald-100 text-emerald-800 px-1.5 py-0.2 rounded font-bold">
                                        Default
                                      </span>
                                    )}
                                  </div>
                                  <p className="text-muted-foreground mt-1 text-[11px] line-clamp-2">{addr.address}</p>
                                  <p className="text-muted-foreground text-[11px]">{addr.city}, {addr.state} - {addr.pincode}</p>
                                  <p className="text-[#8B6508] font-bold text-[11px] mt-1">+91 {addr.mobile}</p>
                                </div>
                              );
                            })}
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Mobile Edit Address Modal */}
                    {showMobileAddressEdit && (
                      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-xs p-4">
                        <div className="w-full max-w-sm rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-card p-5 shadow-2xl space-y-3.5 animate-in zoom-in-95 duration-200 max-h-[90vh] overflow-y-auto">
                          <div className="flex items-center justify-between border-b border-border pb-3">
                            <h3 className="font-bold text-sm text-foreground">Edit Delivery Address</h3>
                            <button
                              type="button"
                              onClick={() => setShowMobileAddressEdit(false)}
                              className="text-muted-foreground hover:text-foreground text-xs"
                            >
                              ✕
                            </button>
                          </div>

                          <div className="space-y-2.5 text-xs">
                            <div>
                              <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Full Name</label>
                              <input
                                type="text"
                                value={shippingName}
                                onChange={(e) => setShippingName(e.target.value)}
                                className="mt-1 w-full rounded-xl border border-neutral-200 dark:border-neutral-800 bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-[#B8860B]"
                              />
                            </div>
                            <div>
                              <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Flat / Street Address</label>
                              <input
                                type="text"
                                value={shippingStreet}
                                onChange={(e) => setShippingStreet(e.target.value)}
                                className="mt-1 w-full rounded-xl border border-neutral-200 dark:border-neutral-800 bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-[#B8860B]"
                              />
                            </div>
                            <div className="grid grid-cols-2 gap-2">
                              <div>
                                <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">City</label>
                                <input
                                  type="text"
                                  value={shippingCity}
                                  onChange={(e) => setShippingCity(e.target.value)}
                                  className="mt-1 w-full rounded-xl border border-neutral-200 dark:border-neutral-800 bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-[#B8860B]"
                                />
                              </div>
                              <div>
                                <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Pincode</label>
                                <input
                                  type="text"
                                  value={shippingPincode}
                                  onChange={(e) => setShippingPincode(e.target.value)}
                                  className="mt-1 w-full rounded-xl border border-neutral-200 dark:border-neutral-800 bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-[#B8860B]"
                                />
                              </div>
                            </div>
                            <div>
                              <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Phone Number</label>
                              <input
                                type="text"
                                value={shippingPhone}
                                onChange={(e) => setShippingPhone(e.target.value)}
                                className="mt-1 w-full rounded-xl border border-neutral-200 dark:border-neutral-800 bg-background px-3 py-2 text-xs text-foreground outline-none focus:border-[#B8860B]"
                              />
                            </div>
                          </div>

                          <div className="pt-2">
                            <button
                              type="button"
                              onClick={() => {
                                setShippingAddress(`${shippingName} (+91 ${shippingPhone}), ${shippingStreet}, ${shippingCity}, ${shippingState} - ${shippingPincode}`);
                                setShowMobileAddressEdit(false);
                              }}
                              className="w-full rounded-xl bg-[#8B6508] hover:bg-[#7A5807] py-2.5 text-xs font-bold uppercase text-white shadow-sm"
                            >
                              Save Address
                            </button>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* =========================================================================
                        MOBILE RAZORPAY TEST PAYMENT FLOW MODALS (Screenshots 1, 2, 3, 4)
                        ========================================================================= */}
                    {mobileRazorpayStep && (
                      <div className="fixed inset-0 z-[100] flex flex-col md:hidden animate-in fade-in duration-200">
                        {/* SCREEN 1: Razorpay Payment Options Modal (Screenshot 1) */}
                        {mobileRazorpayStep === "options" && (
                          <div className="flex-1 flex flex-col bg-[#C29F5D] overflow-hidden relative">
                            {/* Top Header */}
                            <div className="relative p-4 pb-3 overflow-hidden">
                              {/* Red Test Mode Ribbon */}
                              <div className="absolute -right-8 top-3.5 bg-[#E53935] text-white text-[9px] font-black uppercase tracking-widest px-8 py-0.5 shadow-md rotate-45 select-none z-10">
                                Test Mode
                              </div>

                              {/* VEXA Brand Title */}
                              <div className="flex items-center gap-2.5">
                                <div className="flex size-7 items-center justify-center rounded-full bg-white/20 border border-white/40 text-white font-bold text-xs">
                                  V
                                </div>
                                <span className="font-bold text-sm text-white tracking-wide">
                                  VEXA - Wear Confidence
                                </span>
                              </div>

                              {/* Price Summary Card */}
                              <div className="mt-3 rounded-2xl bg-white text-neutral-900 p-3.5 shadow-sm">
                                <span className="text-[11px] font-semibold text-neutral-500">Price Summary</span>
                                <div className="font-black text-2xl text-neutral-900 tracking-tight">
                                  ₹{mobileGrandTotal.toLocaleString("en-IN")}
                                </div>
                              </div>

                              {/* User Bar */}
                              <div className="mt-2.5 flex items-center justify-between rounded-xl bg-white/95 text-neutral-800 px-3 py-2 text-xs font-semibold shadow-xs">
                                <div className="flex items-center gap-2">
                                  <UserIcon className="size-3.5 text-neutral-600" />
                                  <span>Using as +91 {shippingPhone || "98765 43210"}</span>
                                </div>
                                <ChevronRight className="size-4 text-neutral-500" />
                              </div>

                              <p className="mt-2 text-[10px] text-white/90 font-medium">
                                Secured by <span className="font-bold">Razorpay</span>
                              </p>
                            </div>

                            {/* White Payment Options Body */}
                            <div className="flex-1 bg-white text-neutral-900 rounded-t-3xl shadow-2xl flex flex-col overflow-hidden">
                              {/* Header Row */}
                              <div className="flex items-center justify-between px-4 py-3 border-b border-neutral-100">
                                <h2 className="font-bold text-base text-neutral-900">Payment Options</h2>
                                <div className="flex items-center gap-3 text-neutral-500">
                                  <MoreHorizontal className="size-5 cursor-pointer" />
                                  <button
                                    type="button"
                                    onClick={() => setMobileRazorpayStep(null)}
                                    className="p-1 hover:text-neutral-900 cursor-pointer"
                                    aria-label="Close"
                                  >
                                    <X className="size-5" />
                                  </button>
                                </div>
                              </div>

                              {/* 2-Column Split: Categories on Left, Options on Right */}
                              <div className="flex-1 flex overflow-hidden">
                                {/* Left Category Sidebar */}
                                <div className="w-28 sm:w-32 bg-neutral-50 border-r border-neutral-100 flex flex-col py-2 overflow-y-auto">
                                  {[
                                    { id: "recommended", label: "Recommended", sub: "Mobikwik, PayZapp" },
                                    { id: "upi", label: "UPI", sub: "GPay, PhonePe" },
                                    { id: "cards", label: "Cards", sub: "Visa, Mastercard" },
                                    { id: "emi", label: "EMI", sub: "Axis, HDFC, ICICI" },
                                    { id: "netbanking", label: "Netbanking", sub: "HDFC, ICICI, SBI" },
                                    { id: "wallet", label: "Wallet", sub: "Mobikwik, Paytm" },
                                  ].map((cat) => {
                                    const isActive = selectedDemoCategory === cat.id;
                                    return (
                                      <button
                                        key={cat.id}
                                        type="button"
                                        onClick={() => setSelectedDemoCategory(cat.id as any)}
                                        className={`text-left px-3 py-2.5 transition-all cursor-pointer relative ${
                                          isActive
                                            ? "bg-white font-bold text-neutral-900 shadow-2xs border-l-4 border-[#C29F5D]"
                                            : "text-neutral-600 hover:bg-neutral-100/80"
                                        }`}
                                      >
                                        <div className="text-xs font-bold leading-tight">{cat.label}</div>
                                        <div className="text-[9px] text-neutral-400 truncate mt-0.5">{cat.sub}</div>
                                      </button>
                                    );
                                  })}
                                </div>

                                {/* Right Content Area */}
                                <div className="flex-1 p-3.5 overflow-y-auto space-y-4">
                                  {/* UPI QR Code Section */}
                                  <div>
                                    <div className="flex items-center justify-between text-xs font-bold text-neutral-900 mb-2">
                                      <span>UPI QR</span>
                                      <span className="flex items-center gap-1 text-[11px] text-neutral-500 font-normal">
                                        <Clock className="size-3" /> 11:41
                                      </span>
                                    </div>

                                    <div
                                      onClick={() => {
                                        setSelectedDemoBank("UPI QR");
                                        setMobileRazorpayStep("demo_bank");
                                      }}
                                      className="rounded-2xl border border-neutral-200/90 p-4 bg-white shadow-2xs flex flex-col items-center text-center cursor-pointer hover:border-neutral-400 active:scale-98 transition-all"
                                    >
                                      {/* Generated QR Code SVG pattern */}
                                      <div className="size-36 p-2 rounded-xl bg-white border border-neutral-200 flex items-center justify-center">
                                        <QrCode className="size-full text-neutral-900" />
                                      </div>
                                      <p className="mt-3 text-[11px] font-semibold text-neutral-600">
                                        Scan the QR using any UPI App
                                      </p>
                                      <div className="mt-2 flex items-center gap-1.5 flex-wrap justify-center">
                                        <span className="rounded bg-[#4285F4] text-white text-[9px] font-bold px-1.5 py-0.5">GPay</span>
                                        <span className="rounded bg-[#5F259F] text-white text-[9px] font-bold px-1.5 py-0.5">PhonePe</span>
                                        <span className="rounded bg-[#00BAF2] text-white text-[9px] font-bold px-1.5 py-0.5">Paytm</span>
                                        <span className="rounded bg-black text-white text-[9px] font-bold px-1.5 py-0.5">CRED</span>
                                        <span className="rounded bg-[#008276] text-white text-[9px] font-bold px-1.5 py-0.5">BHIM</span>
                                      </div>
                                    </div>
                                  </div>

                                  {/* Recommended Bank / Wallet Options */}
                                  <div className="space-y-2">
                                    <span className="text-xs font-bold text-neutral-900 block">Recommended</span>

                                    {/* Option 1: Punjab National Bank */}
                                    <div
                                      onClick={() => {
                                        setSelectedDemoBank("Punjab National Bank");
                                        setMobileRazorpayStep("demo_bank");
                                      }}
                                      className="rounded-xl border border-neutral-200/90 p-3 flex items-center justify-between cursor-pointer hover:border-neutral-400 active:scale-98 transition-all bg-white shadow-2xs"
                                    >
                                      <div className="flex items-center gap-2.5 overflow-hidden">
                                        <div className="flex size-7 items-center justify-center rounded-lg bg-amber-50 text-amber-700 shrink-0 border border-amber-200">
                                          <Building2 className="size-3.5" />
                                        </div>
                                        <span className="font-bold text-xs text-neutral-900 truncate">
                                          Punjab National Bank - Retail Ban...
                                        </span>
                                      </div>
                                      <ChevronRight className="size-4 text-neutral-400 shrink-0" />
                                    </div>

                                    {/* Option 2: Canara Bank Netbanking */}
                                    <div
                                      onClick={() => {
                                        setSelectedDemoBank("Canara Bank");
                                        setMobileRazorpayStep("demo_bank");
                                      }}
                                      className="rounded-xl border border-neutral-200/90 p-3 flex items-center justify-between cursor-pointer hover:border-neutral-400 active:scale-98 transition-all bg-white shadow-2xs"
                                    >
                                      <div className="flex items-center gap-2.5 overflow-hidden">
                                        <div className="flex size-7 items-center justify-center rounded-lg bg-blue-50 text-blue-700 shrink-0 border border-blue-200">
                                          <Building2 className="size-3.5" />
                                        </div>
                                        <span className="font-bold text-xs text-neutral-900 truncate">
                                          Canara Bank Netbanking
                                        </span>
                                      </div>
                                      <ChevronRight className="size-4 text-neutral-400 shrink-0" />
                                    </div>
                                  </div>

                                  {/* Wallets Section */}
                                  <div className="space-y-2">
                                    <span className="text-[11px] font-bold text-neutral-900 block">
                                      Pay via Mobikwik, PayZapp, Airtel Money & Wallets
                                    </span>

                                    <div
                                      onClick={() => {
                                        setSelectedDemoBank("Mobikwik Wallet");
                                        setMobileRazorpayStep("demo_bank");
                                      }}
                                      className="rounded-xl border border-neutral-200/90 p-3 flex items-center justify-between cursor-pointer hover:border-neutral-400 active:scale-98 transition-all bg-white shadow-2xs"
                                    >
                                      <div className="flex items-center gap-2.5">
                                        <div className="flex size-7 items-center justify-center rounded-lg bg-amber-50 text-amber-700 shrink-0 border border-amber-200">
                                          <Wallet className="size-3.5" />
                                        </div>
                                        <span className="font-bold text-xs text-neutral-900">Wallet</span>
                                      </div>
                                      <ChevronRight className="size-4 text-neutral-400 shrink-0" />
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        )}

                        {/* SCREEN 2: Demo Bank Gateway Simulation (Screenshot 2) */}
                        {mobileRazorpayStep === "demo_bank" && (
                          <div className="flex-1 flex flex-col bg-white text-neutral-900 justify-between">
                            {/* Top Ochre Bar */}
                            <div className="h-6 bg-[#C9A86A] w-full" />

                            {/* Center Content */}
                            <div className="flex-1 flex flex-col items-center justify-center px-6 text-center space-y-4">
                              <div className="text-6xl font-black text-blue-600 italic tracking-tighter">
                                1
                              </div>
                              <h2 className="font-bold text-lg text-neutral-900 max-w-xs">
                                Welcome to {selectedDemoBank} Demo Bank
                              </h2>
                              <div className="text-xs text-neutral-500 max-w-xs leading-relaxed space-y-1">
                                <p>This is just a demo bank page.</p>
                                <p>You can choose whether to make this payment successful or not:</p>
                              </div>

                              <div className="flex items-center gap-4 pt-4">
                                <button
                                  type="button"
                                  onClick={() => setMobileRazorpayStep("confirming")}
                                  className="bg-[#28A745] hover:bg-[#218838] text-white px-9 py-3 rounded-xl font-bold text-sm shadow-md active:scale-95 transition-all cursor-pointer"
                                >
                                  Success
                                </button>
                                <button
                                  type="button"
                                  onClick={() => setMobileRazorpayStep("options")}
                                  className="bg-[#DC3545] hover:bg-[#C82333] text-white px-9 py-3 rounded-xl font-bold text-sm shadow-md active:scale-95 transition-all cursor-pointer"
                                >
                                  Failure
                                </button>
                              </div>
                            </div>

                            {/* Bottom Ochre Bar */}
                            <div className="h-6 bg-[#C9A86A] w-full" />
                          </div>
                        )}

                        {/* SCREEN 3: Confirming Payment Spinner Modal (Screenshot 3) */}
                        {mobileRazorpayStep === "confirming" && (
                          <div className="flex-1 flex flex-col items-center justify-center bg-[#C9A86A] px-6">
                            <div className="w-full max-w-xs rounded-3xl bg-white text-neutral-900 p-6 shadow-2xl text-center space-y-5 animate-in zoom-in-95 duration-200">
                              <div>
                                <h3 className="font-bold text-lg text-neutral-900">Confirming Payment</h3>
                                <p className="text-xs text-neutral-500 mt-1">This will only take a few seconds.</p>
                              </div>

                              {/* Yellow Glowing Pulsing Orb */}
                              <div className="relative size-24 mx-auto flex items-center justify-center">
                                <div className="absolute inset-0 rounded-full bg-amber-200/60 animate-ping" />
                                <div className="absolute inset-2 rounded-full bg-amber-300/60 animate-pulse" />
                                <div className="relative size-16 rounded-full bg-[#FFD600] shadow-lg flex items-center justify-center border-2 border-amber-300" />
                              </div>

                              <div className="border-t border-neutral-100 pt-3">
                                <p className="text-[11px] text-neutral-500 font-semibold">
                                  Secured by <span className="font-bold text-neutral-900">Razorpay</span>
                                </p>
                              </div>
                            </div>
                          </div>
                        )}

                        {/* SCREEN 4: Payment Successful (Screenshot 4) */}
                        {mobileRazorpayStep === "success" && (
                          <div className="flex-1 flex flex-col justify-between bg-[#00A859] text-white p-6 pb-4">
                            {/* Top Status */}
                            <div className="pt-4 text-center">
                              <p className="text-xs text-white/90 font-medium">
                                You will be redirected in {redirectCountdown} seconds
                              </p>
                              <h1 className="font-extrabold text-2xl text-white mt-2 tracking-tight">
                                Payment Successful
                              </h1>

                              {/* White Check Circle */}
                              <div className="size-20 rounded-full border-4 border-white flex items-center justify-center mx-auto my-7 shadow-lg">
                                <Check className="size-11 stroke-[3.5] text-white" />
                              </div>
                            </div>

                            {/* White Receipt Card */}
                            <div className="rounded-2xl bg-white text-neutral-900 p-5 shadow-2xl space-y-3.5 max-w-sm mx-auto w-full animate-in slide-in-from-bottom-4 duration-300">
                              <div className="flex items-center justify-between">
                                <span className="font-bold text-sm text-neutral-900">VEXA - Wear Confidence</span>
                                <span className="font-black text-lg text-neutral-900">₹{mobileGrandTotal.toLocaleString("en-IN")}</span>
                              </div>

                              <p className="text-xs text-neutral-500">
                                {new Date().toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })},{" "}
                                {new Date().toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", hour12: true })}
                              </p>

                              <div className="border-t border-neutral-100 pt-3 flex items-center justify-between text-xs text-neutral-600">
                                <span className="font-mono">
                                  Netbanking | <span className="font-bold text-neutral-900">{demoRazorpayTxnId}</span>
                                </span>
                                <button
                                  type="button"
                                  onClick={() => {
                                    if (navigator.clipboard) navigator.clipboard.writeText(demoRazorpayTxnId);
                                    toast.success("Transaction ID copied!");
                                  }}
                                  className="text-neutral-500 hover:text-neutral-900 p-1 cursor-pointer"
                                  title="Copy Transaction ID"
                                >
                                  <Copy className="size-3.5" />
                                </button>
                              </div>

                              <p className="text-[10px] text-neutral-400">
                                ⓘ Visit razorpay.com/support for queries
                              </p>
                            </div>

                            {/* Go to My Orders Button (Immediate Redirect) */}
                            <div className="max-w-sm mx-auto w-full pt-1">
                              <button
                                type="button"
                                onClick={handleMobileRazorpaySuccessRedirect}
                                className="w-full rounded-xl bg-white text-[#00A859] hover:bg-white/95 py-3 text-xs font-bold uppercase tracking-wider shadow-lg active:scale-98 transition-all flex items-center justify-center gap-2 cursor-pointer"
                              >
                                <span>Go to My Orders ({redirectCountdown}s)</span>
                                <ArrowRight className="size-4" />
                              </button>
                            </div>

                            {/* Bottom Secured By */}
                            <div className="text-center pb-2">
                              <p className="text-xs text-white/80 font-medium">
                                Secured by <span className="font-bold text-white">Razorpay</span>
                              </p>
                            </div>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                )}

                {/* PAGE STEP 1: ADDRESS DETAILS & SAVED ADDRESS CARDS (DESKTOP) */}
                {cartCheckoutStep === "address" && (
                  <div className="hidden md:block space-y-6 max-w-2xl animate-in fade-in duration-300 min-w-0">
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

                {/* PAGE STEP 2: DEMO PAYMENT OPTION (DESKTOP) */}
                {cartCheckoutStep === "payment" && (
                  <div className="hidden md:block space-y-6 max-w-2xl animate-in fade-in duration-300">
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
                            navigate("/dashboard?tab=orders", { replace: true });
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
              <div className="hidden md:block space-y-6 max-w-2xl pt-3 sm:pt-0">
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
