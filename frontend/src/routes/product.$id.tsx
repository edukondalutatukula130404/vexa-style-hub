import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useState, useMemo, useEffect } from "react";
import {
  Star,
  ShoppingBag,
  ShieldCheck,
  Truck,
  ArrowRight,
  ArrowLeft,
  CheckCircle2,
  Sparkles,
  Ruler,
  MessageSquare,
  ThumbsUp,
  X,
  ChevronLeft,
  ChevronRight,
  ChevronDown,
  Edit3,
  MapPin,
  Share2,
  Minus,
  Plus,
  RotateCcw,
  Check,
  AlertCircle,
  PackageX,
  Heart,
  Send,
} from "lucide-react";
import { useProducts, SIZES, getVariantStock, type Product } from "@/lib/products";
import { ProductCard } from "@/components/ProductCard";
import { Reveal } from "@/components/Reveal";
import { addToCart } from "@/lib/cart";
import { useAuth } from "@/lib/auth";
import { useWishlist, toggleWishlist } from "@/lib/wishlist";
import { DeliveryLocationModal } from "@/components/DeliveryLocationModal";
import { toast } from "sonner";

import black from "@/assets/tee-black.jpg";
import white from "@/assets/tee-white.jpg";
import navy from "@/assets/tee-navy.jpg";
import beige from "@/assets/tee-beige.jpg";
import charcoal from "@/assets/tee-charcoal.jpg";
import olive from "@/assets/tee-olive.jpg";
import luxuryGold from "@/assets/hero_luxury_tshirt.png";
import heroLuxuryImg from "@/assets/hero_luxury_tshirt.png";
import promoBanner1 from "@/assets/promo_banner_1.png";
import promoBanner2 from "@/assets/promo_banner_2.png";
import rust from "@/assets/tee-rust.png";
import lavender from "@/assets/tee-lavender.png";
import emerald from "@/assets/tee-emerald.png";

export type ColorOption = {
  name: string;
  hex: string;
  image: string;
  borderColor?: string;
};

export const COLOR_OPTIONS: ColorOption[] = [
  { name: "Pastel Lavender", hex: "#B8A5D6", image: lavender, borderColor: "#9C87BD" },
  { name: "Emerald Green", hex: "#1B4D3E", image: emerald, borderColor: "#13382D" },
  { name: "Jet Black", hex: "#18181B", image: black, borderColor: "#3F3F46" },
  { name: "Vintage Rust", hex: "#8B3A2B", image: rust, borderColor: "#65281B" },
  { name: "Desert Sand", hex: "#D4C3A3", image: beige, borderColor: "#A89878" },
  { name: "Military Olive", hex: "#4B5320", image: olive, borderColor: "#3B4219" },
  { name: "Ivory White", hex: "#FDFDFD", image: white, borderColor: "#E4E4E7" },
  { name: "Midnight Navy", hex: "#1E293B", image: navy, borderColor: "#334155" },
  { name: "Charcoal Gray", hex: "#3F3F46", image: charcoal, borderColor: "#52525B" },
  { name: "Luxury Cream & Gold", hex: "#F5F0E6", image: luxuryGold, borderColor: "#D4AF37" },
];

export type Review = {
  id: string;
  name: string;
  rating: number;
  date: string;
  title: string;
  comment: string;
  verified: boolean;
  helpfulCount: number;
};

// Initial default customer reviews for products
const defaultReviewsMap: Record<string, Review[]> = {
  default: [
    {
      id: "rev-1",
      name: "Rohan V.",
      rating: 5,
      date: "2 days ago",
      title: "The 240 GSM heavy cotton feel is insane!",
      comment:
        "The 240 GSM heavy cotton feel is insane! Fits perfectly oversized without looking boxy. Color fastness after washing is top notch.",
      verified: true,
      helpfulCount: 24,
    },
    {
      id: "rev-2",
      name: "Ananya I.",
      rating: 5,
      date: "5 days ago",
      title: "Pure luxury aesthetic",
      comment:
        "Pure luxury aesthetic. Stitching detail and drop shoulder cut is premium quality.",
      verified: true,
      helpfulCount: 18,
    },
    {
      id: "rev-3",
      name: "Karan P.",
      rating: 4,
      date: "1 week ago",
      title: "Great colorway & premium feel",
      comment:
        "Great colorway and luxurious heavy feel. Delivery took 2 days. Definitely buying the obsidian color next.",
      verified: true,
      helpfulCount: 9,
    },
    {
      id: "rev-4",
      name: "Vikram S.",
      rating: 5,
      date: "2 weeks ago",
      title: "Best heavy tee in India",
      comment:
        "Hands down the best heavyweight tee in India right now. Fits true to the oversized aesthetic. Premium gold-tier packaging too!",
      verified: true,
      helpfulCount: 15,
    },
  ],
};

export function ProductDetailPage() {
  const { id: pathId } = useParams();
  const [searchParams] = useSearchParams();
  const queryId = searchParams.get("id") || searchParams.get("product");
  const id = pathId || queryId;
  const navigate = useNavigate();
  const { products, loading } = useProducts();
  const { isLoggedIn, user } = useAuth();

  // Find product by id
  const product = useMemo(() => {
    if (!products || products.length === 0) return null;
    return (
      products.find((p) => p.id === id) ||
      products.find((p) => p.id && id && p.id.toLowerCase() === id.toLowerCase()) ||
      products[0]
    );
  }, [products, id]);

  // Dynamic Color & Image state
  const [selectedColor, setSelectedColor] = useState<ColorOption>(COLOR_OPTIONS[0]);
  const [selectedImage, setSelectedImage] = useState<string>(luxuryGold);

  // Selected state
  const [selectedSize, setSelectedSize] = useState("M");
  const [quantity, setQuantity] = useState(1);
  const [activeTab, setActiveTab] = useState<"specs" | "care" | "shipping">("specs");
  const [addedToast, setAddedToast] = useState(false);
  const [showSizeGuide, setShowSizeGuide] = useState(false);
  const { isInWishlist } = useWishlist();
  const isWishlisted = product ? isInWishlist(product.id) : false;

  // Delivery details state
  const [isLocationModalOpen, setIsLocationModalOpen] = useState(false);
  const [selectedLocation, setSelectedLocation] = useState(() => {
    if (typeof window !== "undefined") {
      return (
        localStorage.getItem("vexa_delivery_location") ||
        "Floor 5, Cyber Towers, HITEC City, Phase 2, Hyderabad 500081"
      );
    }
    return "Floor 5, Cyber Towers, HITEC City, Phase 2, Hyderabad 500081";
  });

  const deliveryDateString = useMemo(() => {
    const d = new Date();
    d.setDate(d.getDate() + 2);
    const weekday = d.toLocaleDateString("en-US", { weekday: "long" });
    const day = d.getDate();
    const month = d.toLocaleDateString("en-US", { month: "short" });
    return `${weekday}, ${day} ${month}`;
  }, []);

  const handleSelectLocation = (loc: string) => {
    setSelectedLocation(loc);
    if (typeof window !== "undefined") {
      localStorage.setItem("vexa_delivery_location", loc);
    }
    setIsLocationModalOpen(false);
  };

  // Review state
  const [reviews, setReviews] = useState<Review[]>([]);
  const [showReviewModal, setShowReviewModal] = useState(false);
  const [showAllMobileReviews, setShowAllMobileReviews] = useState(false);
  const [newRating, setNewRating] = useState(5);
  const [newName, setNewName] = useState("");
  const [newTitle, setNewTitle] = useState("");
  const [newComment, setNewComment] = useState("");
  const [helpfulClicked, setHelpfulClicked] = useState<Record<string, boolean>>({});

  // Compute active colors and variant images for the current product (1-to-1 swatch & thumbnail sync)
  const availableColorsForProduct = useMemo(() => {
    if (!product) return COLOR_OPTIONS;

    let customColorMap: Record<string, string> = {};
    if (typeof window !== "undefined") {
      try {
        customColorMap = JSON.parse(localStorage.getItem(`vexa_color_images_${product.id}`) || "{}");
      } catch (e) {}
    }

    return COLOR_OPTIONS.map((c) => {
      const customImg = (product as any)?.colorImages?.[c.name] || customColorMap[c.name];

      // If this color matches the product's primary color, use product.image as default unless customImg is set
      const isPrimaryColor =
        product.color &&
        (c.name.toLowerCase().includes(product.color.toLowerCase()) ||
          product.color.toLowerCase().includes(c.name.toLowerCase()));

      const finalImg = customImg || (isPrimaryColor && product.image ? product.image : c.image);

      return {
        ...c,
        image: finalImg,
      };
    });
  }, [product]);

  // Sync color & image whenever current product changes
  useEffect(() => {
    if (product && availableColorsForProduct.length > 0) {
      const match = availableColorsForProduct.find(
        (c) =>
          product.color &&
          (c.name.toLowerCase().includes(product.color.toLowerCase()) ||
            product.color.toLowerCase().includes(c.name.toLowerCase()))
      );
      const initialCol = match || availableColorsForProduct[0];
      setSelectedColor(initialCol);
      setSelectedImage(initialCol.image || product.image || luxuryGold);
    }
  }, [product, availableColorsForProduct]);

  // Scroll to top on ID change
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [id]);

  // Scroll to top on ID change
  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: "instant" as any });
    if (typeof document !== "undefined") {
      document.documentElement.scrollTop = 0;
      document.body.scrollTop = 0;
    }
  }, [id]);

  // Dynamic Review Filter & Sort state
  const [reviewFilter, setReviewFilter] = useState<"all" | "5" | "4" | "verified">("all");
  const [reviewSort, setReviewSort] = useState<"recent" | "rating" | "helpful">("recent");

  // Load reviews from localStorage, product data, or default seed reviews
  useEffect(() => {
    if (!product) return;
    const storageKey = `vexa_reviews_${product.id}`;
    const saved = localStorage.getItem(storageKey);
    if (saved) {
      try {
        setReviews(JSON.parse(saved));
        return;
      } catch {}
    }
    if ((product as any)?.reviews && Array.isArray((product as any).reviews) && (product as any).reviews.length > 0) {
      setReviews((product as any).reviews);
    } else {
      setReviews(defaultReviewsMap.default);
    }
  }, [product]);

  // Dynamic Filtered & Sorted Reviews list
  const filteredReviews = useMemo(() => {
    let result = [...reviews];

    if (reviewFilter === "5") {
      result = result.filter((r) => r.rating === 5);
    } else if (reviewFilter === "4") {
      result = result.filter((r) => r.rating === 4);
    } else if (reviewFilter === "verified") {
      result = result.filter((r) => r.verified);
    }

    if (reviewSort === "recent") {
      result.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
    } else if (reviewSort === "rating") {
      result.sort((a, b) => b.rating - a.rating);
    } else if (reviewSort === "helpful") {
      result.sort((a, b) => b.helpfulCount - a.helpfulCount);
    }

    return result;
  }, [reviews, reviewFilter, reviewSort]);

  // Per-color 4-angle views (Front Side, Back Side, Right Side, Left Side)
  const COLOR_ANGLE_VIEWS: Record<string, { label: string; image: string }[]> = useMemo(() => ({
    "Luxury Cream & Gold": [
      { label: "Front Side", image: luxuryGold },
      { label: "Back Side", image: white },
      { label: "Right Side", image: beige },
      { label: "Left Side", image: heroLuxuryImg },
    ],
    "Jet Black": [
      { label: "Front Side", image: black },
      { label: "Back Side", image: charcoal },
      { label: "Right Side", image: navy },
      { label: "Left Side", image: black },
    ],
    "Ivory White": [
      { label: "Front Side", image: white },
      { label: "Back Side", image: luxuryGold },
      { label: "Right Side", image: beige },
      { label: "Left Side", image: white },
    ],
    "Midnight Navy": [
      { label: "Front Side", image: navy },
      { label: "Back Side", image: charcoal },
      { label: "Right Side", image: black },
      { label: "Left Side", image: navy },
    ],
    "Desert Sand": [
      { label: "Front Side", image: beige },
      { label: "Back Side", image: luxuryGold },
      { label: "Right Side", image: rust },
      { label: "Left Side", image: beige },
    ],
    "Vintage Rust": [
      { label: "Front Side", image: rust },
      { label: "Back Side", image: beige },
      { label: "Right Side", image: charcoal },
      { label: "Left Side", image: rust },
    ],
    "Charcoal Gray": [
      { label: "Front Side", image: charcoal },
      { label: "Back Side", image: black },
      { label: "Right Side", image: navy },
      { label: "Left Side", image: charcoal },
    ],
  }), []);

  // Compute 4-angle preview photos (Front, Back, Right, Left) for selected colorway
  const colorGalleryAngles = useMemo(() => {
    if (!selectedColor) return [];

    let customImg = (product as any)?.colorImages?.[selectedColor.name];
    if (!customImg && typeof window !== "undefined" && product) {
      try {
        const storedMap = JSON.parse(localStorage.getItem(`vexa_color_images_${product.id}`) || "{}");
        if (storedMap[selectedColor.name]) customImg = storedMap[selectedColor.name];
      } catch (e) {}
    }

    const mainColorImg = customImg || selectedColor.image || product?.image || luxuryGold;
    const defaultAngles = COLOR_ANGLE_VIEWS[selectedColor.name] || [
      { label: "Front Side", image: mainColorImg },
      { label: "Back Side", image: mainColorImg },
      { label: "Right Side", image: mainColorImg },
      { label: "Left Side", image: mainColorImg },
    ];

    return defaultAngles.map((item, idx) =>
      idx === 0 ? { ...item, image: mainColorImg } : item
    );
  }, [selectedColor, product, COLOR_ANGLE_VIEWS]);

  // Handle color swatch pick & global variant photo sync
  const handleSelectColor = (col: ColorOption) => {
    setSelectedColor(col);

    let variantImg = col.image || (product as any)?.colorImages?.[col.name];

    if (!variantImg && typeof window !== "undefined" && product) {
      try {
        const storedMap = JSON.parse(localStorage.getItem(`vexa_color_images_${product.id}`) || "{}");
        if (storedMap[col.name]) variantImg = storedMap[col.name];
      } catch (e) {}
    }

    const finalImage = variantImg || product?.image || luxuryGold;
    setSelectedImage(finalImage);

    // Auto-select first available size for newly selected color if current size is out of stock
    if (product) {
      const currentStock = getVariantStock(product.id, col.name, selectedSize, product.stock);
      if (currentStock <= 0) {
        const firstAvail = SIZES.find(
          (sz) => getVariantStock(product.id, col.name, sz, product.stock) > 0
        );
        if (firstAvail) setSelectedSize(firstAvail);
      }
    }
  };

  // Open Write Review Modal (Requires Login)
  const handleOpenReviewModal = () => {
    if (!isLoggedIn) {
      if (typeof window !== "undefined" && product) {
        localStorage.setItem("vexa_redirect_after_login", `/product/${product.id}`);
      }
      navigate("/login");
      return;
    }
    if (user?.name && !newName) {
      setNewName(user.name);
    }
    setShowReviewModal(true);
  };

  // Handle new review submission
  const handleAddReview = (e: React.FormEvent) => {
    e.preventDefault();
    if (!product || !newName.trim() || !newComment.trim()) return;

    const newRev: Review = {
      id: `rev-user-${Date.now()}`,
      name: newName.trim(),
      rating: newRating,
      date: new Date().toLocaleDateString("en-US", {
        month: "long",
        day: "numeric",
        year: "numeric",
      }),
      title: newTitle.trim() || "Verified Experience",
      comment: newComment.trim(),
      verified: true,
      helpfulCount: 0,
    };

    const updated = [newRev, ...reviews];
    setReviews(updated);
    if (product) {
      localStorage.setItem(`vexa_reviews_${product.id}`, JSON.stringify(updated));
    }

    // Reset form
    setNewName("");
    setNewTitle("");
    setNewComment("");
    setNewRating(5);
    setShowReviewModal(false);
  };

  const handleHelpfulClick = (revId: string) => {
    if (helpfulClicked[revId]) return;
    const updated = reviews.map((r) =>
      r.id === revId ? { ...r, helpfulCount: r.helpfulCount + 1 } : r
    );
    setReviews(updated);
    setHelpfulClicked((prev) => ({ ...prev, [revId]: true }));
    if (product) {
      localStorage.setItem(`vexa_reviews_${product.id}`, JSON.stringify(updated));
    }
  };

  // Related products (excluding current)


  const relatedProducts = useMemo(() => {
    if (!product) return [];
    const sameCat = products.filter(
      (p) => p.id !== product.id && p.category === product.category
    );
    const others = products.filter(
      (p) => p.id !== product.id && p.category !== product.category
    );
    return [...sameCat, ...others].slice(0, 10);
  }, [products, product]);

  const currentVariantStock = useMemo(() => {
    if (!product || !selectedColor) return 0;
    return getVariantStock(product.id, selectedColor.name || "Standard", selectedSize || "M", product.stock || 25);
  }, [product, selectedColor, selectedSize]);

  const isVariantInStock = currentVariantStock > 0;

  if (loading) {
    return (
      <div className="mx-auto max-w-7xl px-5 py-24 text-center">
        <div className="mx-auto size-10 animate-spin rounded-full border-2 border-gold border-t-transparent" />
        <p className="mt-4 text-xs font-semibold uppercase tracking-widest text-muted-foreground">
          Loading VEXA Signature Piece…
        </p>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="mx-auto max-w-7xl px-5 py-24 text-center space-y-6">
        <h1 className="font-display text-3xl font-bold text-foreground">Product Not Found</h1>
        <p className="text-sm text-muted-foreground">
          The requested VEXA piece could not be located in our catalog.
        </p>
        <Link
          to="/products"
          className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2 rounded-sm px-6 py-3 text-xs font-bold uppercase tracking-wider"
        >
          <ChevronLeft className="size-4" /> Back to All Products
        </Link>


      </div>
    );
  }

  const getColorPriceOffset = (colorName: string) => {
    switch ((colorName || "").toLowerCase().trim()) {
      case "default":
      case "original":
      case "pastel lavender":
      case "lavender":
      case "lavender lilac":
        return 0;
      case "emerald green":
      case "green":
        return 50;
      case "jet black":
      case "black":
        return 100;
      case "vintage rust":
      case "rust":
      case "brown":
        return 150;
      case "ivory white":
      case "white":
        return 30;
      case "military olive":
      case "olive":
        return 80;
      case "midnight navy":
      case "navy":
      case "blue":
        return 120;
      case "desert sand":
      case "sand":
      case "beige":
        return 60;
      case "charcoal grey":
      case "charcoal":
      case "grey":
      case "gray":
        return 90;
      case "luxury cream & gold":
      case "cream & gold":
      case "gold":
        return 200;
      default:
        return 0;
    }
  };

  const getSizePriceOffset = (size: string) => {
    switch ((size || "").toUpperCase().trim()) {
      case "S":
        return -50;
      case "M":
        return 0;
      case "L":
        return 100;
      case "XL":
        return 200;
      case "XXL":
        return 300;
      default:
        return 0;
    }
  };

  const currentPrice = useMemo(() => {
    if (!product) return 0;
    const colorOffset = getColorPriceOffset(selectedColor?.name || "");
    const sizeOffset = getSizePriceOffset(selectedSize || "M");
    return Math.max(1, product.price + colorOffset + sizeOffset);
  }, [product, selectedColor, selectedSize]);

  const currentOldPrice = useMemo(() => {
    if (!product || !product.oldPrice) return 0;
    const colorOffset = getColorPriceOffset(selectedColor?.name || "");
    const sizeOffset = getSizePriceOffset(selectedSize || "M");
    return Math.max(1, product.oldPrice + colorOffset + sizeOffset);
  }, [product, selectedColor, selectedSize]);

  const discountOff = Math.round(
    (1 - currentPrice / (currentOldPrice || product.oldPrice || currentPrice)) * 100
  );

  const getProductWithColor = () => ({
    ...product,
    price: currentPrice,
    oldPrice: currentOldPrice,
    color: selectedColor.name,
    image: selectedImage,
  });

  const handleAddToCart = () => {
    addToCart(getProductWithColor(), selectedSize, quantity);
    setAddedToast(true);
    setTimeout(() => setAddedToast(false), 3000);
  };

  const handleShare = async () => {
    const url = window.location.href;
    const shareData = {
      title: product?.name || "VEXA Style Hub",
      text: `Take a look at this ${product?.name || "item"} on VEXA!`,
      url: url,
    };
    if (navigator.share) {
      try {
        await navigator.share(shareData);
        return;
      } catch (err: any) {
        if (err.name === "AbortError") return;
      }
    }
    try {
      await navigator.clipboard.writeText(url);
      toast.success("Product link copied to clipboard!");
    } catch {
      toast("Link: " + url);
    }
  };

  const handleBuyNow = () => {
    addToCart(getProductWithColor(), selectedSize, quantity);
    if (isLoggedIn) {
      navigate("/dashboard?tab=cart");
    } else {
      localStorage.setItem("vexa_redirect_after_login", "/dashboard?tab=cart");
      navigate("/login");
    }
  };

  // Average review calculation
  const avgRating =
    reviews.length > 0
      ? (reviews.reduce((acc, r) => acc + r.rating, 0) / reviews.length).toFixed(1)
      : product.rating.toFixed(1);

  return (
    <>
      {/* Toast Notification */}
      {addedToast && (
        <div className="fixed bottom-20 md:bottom-6 right-6 z-50 flex items-center gap-3 rounded-lg border border-gold/50 bg-card p-4 text-xs shadow-2xl animate-in slide-in-from-bottom duration-300">
          <CheckCircle2 className="size-5 text-gold shrink-0" />
          <div>
            <p className="font-bold text-foreground">Added to Bag</p>
            <p className="text-muted-foreground">
              {quantity}x {product.name} ({selectedColor.name}, Size {selectedSize})
            </p>
          </div>
          <Link
            to="/dashboard?tab=cart"
            className="ml-3 rounded-sm bg-gold px-3 py-1.5 text-[10px] font-bold uppercase text-primary-foreground hover:opacity-90"
          >
            View Bag
          </Link>
        </div>
      )}

      {/* ============================================================== */}
      {/* 1. MOBILE RESPONSIVE ONLY VIEW (< md)                          */}
      {/* ============================================================== */}
      <div className="block md:hidden min-h-screen bg-background pb-32">
        {/* Edge-to-Edge Hero Image */}
        <div className="relative w-full aspect-[4/5] sm:aspect-square overflow-hidden bg-neutral-900">
          <img
            key={selectedImage}
            src={selectedImage}
            alt={`${product.name} in ${selectedColor.name}`}
            className="h-full w-full object-cover object-top"
          />

          {/* Floating Back Button (Top Left) */}
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="absolute top-4 left-4 z-20 flex size-10 items-center justify-center rounded-full bg-white text-black shadow-lg transition-transform active:scale-90 cursor-pointer"
            aria-label="Go Back"
          >
            <ChevronLeft className="size-6 text-black -ml-0.5" strokeWidth={2.4} />
          </button>

          {/* Floating Action Buttons (Top Right) */}
          <div className="absolute top-4 right-4 z-20 flex flex-col gap-2.5">
            <button
              type="button"
              onClick={() => toggleWishlist(product)}
              className="flex size-10 items-center justify-center rounded-full bg-white text-black shadow-lg transition-transform active:scale-90 cursor-pointer"
              aria-label="Wishlist"
            >
              <Heart className={`size-5 transition-colors ${isWishlisted ? "fill-red-500 text-red-500" : "text-black"}`} />
            </button>
            <button
              type="button"
              onClick={handleShare}
              className="flex size-10 items-center justify-center rounded-full bg-white text-black shadow-lg transition-transform active:scale-90 cursor-pointer"
              aria-label="Share"
            >
              <Send className="size-4.5 text-black -ml-0.5" />
            </button>
          </div>

          {/* Floating Rating Pill (Bottom Left) */}
          <div className="absolute bottom-3.5 left-3.5 z-20 flex items-center gap-1.5 rounded-lg bg-white/95 px-2.5 py-1 text-xs font-bold text-black shadow-md backdrop-blur-xs">
            <span className="font-extrabold">{avgRating}</span>
            <Star className="size-3.5 fill-emerald-600 text-emerald-600" />
            <span className="text-neutral-300 font-light">|</span>
            <span className="text-neutral-600 font-semibold">{reviews.length || 96}</span>
          </div>
        </div>

        {/* Slide Progress Indicator Bar */}
        <div className="w-full h-1 bg-neutral-200 dark:bg-neutral-800 relative">
          <div className="h-full bg-[#D4AF37] w-1/3" />
        </div>

        {/* Main Details Body */}
        <div className="px-4 pt-4 space-y-5">
          {/* Brand Tag & Title */}
          <div>
            <p className="text-xs font-semibold text-neutral-500 dark:text-neutral-400 tracking-wide">
              {product.category ? `${product.category} Collection` : "VEXA Fashion"}
            </p>
            <h1 className="mt-1 font-display text-lg font-bold text-foreground leading-snug">
              {product.name}
            </h1>

            {/* Price Row */}
            <div className="mt-2 flex items-baseline gap-2.5">
              <span className="text-2xl font-black text-foreground">
                ₹{currentPrice.toLocaleString("en-IN")}
              </span>
              {currentOldPrice > currentPrice && (
                <span className="text-sm text-neutral-400 line-through">
                  ₹{currentOldPrice.toLocaleString("en-IN")}
                </span>
              )}
              {discountOff > 0 && (
                <span className="text-sm font-extrabold text-emerald-500">
                  {discountOff}% OFF
                </span>
              )}
            </div>
          </div>

          {/* Selected Color Section with Image Thumbnails */}
          <div>
            <p className="text-xs font-bold text-foreground">
              Selected Color:{" "}
              <span className="font-normal text-neutral-500 dark:text-neutral-400">
                {selectedColor.name}
              </span>
            </p>
            <div className="mt-2.5 flex gap-2.5 overflow-x-auto pb-1 no-scrollbar">
              {availableColorsForProduct.map((col) => {
                const isSelected = selectedColor.name.toLowerCase().trim() === col.name.toLowerCase().trim();
                return (
                  <button
                    key={col.name}
                    type="button"
                    onClick={() => handleSelectColor(col)}
                    className={`relative shrink-0 w-14 h-18 rounded-xl overflow-hidden border-2 transition-all bg-card cursor-pointer ${
                      isSelected
                        ? "border-foreground dark:border-white ring-2 ring-[#D4AF37]/50 shadow-md scale-102"
                        : "border-border/70 opacity-80 hover:opacity-100"
                    }`}
                    title={col.name}
                  >
                    <img
                      src={col.image}
                      alt={col.name}
                      className="w-full h-full object-cover object-top"
                    />
                  </button>
                );
              })}
            </div>
          </div>

          {/* Select Size Section */}
          <div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-foreground">Select Size</span>
                <button
                  type="button"
                  onClick={() => setShowSizeGuide(true)}
                  className="text-xs font-semibold text-blue-500 hover:underline cursor-pointer"
                >
                  Size Chart
                </button>
              </div>
              <span className={`text-xs font-semibold ${isVariantInStock ? "text-emerald-500" : "text-red-500"}`}>
                {isVariantInStock ? `Size ${selectedSize} (In Stock)` : `Size ${selectedSize} (Out of Stock)`}
              </span>
            </div>

            <div className="mt-3 flex gap-2.5">
              {SIZES.filter((sz) => sz !== "XS" && sz !== "XXL").map((sz) => {
                const szStock = product ? getVariantStock(product.id, selectedColor.name, sz, product.stock) : 0;
                const isSzOut = szStock <= 0;
                const isSelected = selectedSize === sz;

                return (
                  <button
                    key={sz}
                    type="button"
                    disabled={isSzOut}
                    onClick={() => !isSzOut && setSelectedSize(sz)}
                    className={`relative flex size-11 items-center justify-center rounded-xl font-bold text-sm transition-all cursor-pointer ${
                      isSelected
                        ? "bg-[#D4AF37] text-white shadow-sm font-black border-none"
                        : isSzOut
                        ? "border border-neutral-200 dark:border-neutral-800 bg-muted/20 text-neutral-400 cursor-not-allowed opacity-50"
                        : "border border-neutral-300 dark:border-neutral-700 bg-white dark:bg-card text-foreground hover:border-[#D4AF37]"
                    }`}
                  >
                    <span>{sz}</span>
                    {isSzOut && (
                      <span className="absolute -top-1.5 -right-1.5 rounded-full bg-red-500 px-1 py-0.2 text-[8px] font-black text-white shadow-xs">
                        OOS
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Quantity Selector */}
          <div className="flex items-center justify-between pt-1">
            <span className="text-sm font-bold text-foreground">Quantity:</span>
            <div className="flex items-center rounded-xl border border-neutral-300 dark:border-neutral-700 bg-white dark:bg-card px-3 py-1.5 shadow-xs">
              <button
                type="button"
                disabled={!isVariantInStock}
                onClick={() => setQuantity((q) => Math.max(1, q - 1))}
                className="p-1 text-neutral-600 dark:text-neutral-300 hover:text-foreground cursor-pointer disabled:opacity-40"
              >
                <Minus className="size-4" />
              </button>
              <span className="w-8 text-center text-sm font-bold text-foreground">
                {quantity}
              </span>
              <button
                type="button"
                disabled={!isVariantInStock}
                onClick={() => setQuantity((q) => q + 1)}
                className="p-1 text-neutral-600 dark:text-neutral-300 hover:text-foreground cursor-pointer disabled:opacity-40"
              >
                <Plus className="size-4" />
              </button>
            </div>
          </div>

          {/* Delivery Details */}
          <div className="space-y-2.5 pt-1">
            <h2 className="text-base font-bold text-foreground">Delivery details</h2>

            {/* Address Row */}
            <div
              onClick={() => setIsLocationModalOpen(true)}
              className="flex items-center justify-between rounded-2xl bg-[#F0F6FF] dark:bg-blue-950/25 border border-blue-100 dark:border-blue-900/40 p-3.5 cursor-pointer active:scale-99 transition-all"
            >
              <div className="flex items-center gap-2.5 min-w-0 pr-2">
                <MapPin className="size-4.5 text-blue-600 shrink-0" />
                <span className="text-xs font-semibold text-neutral-800 dark:text-neutral-200 truncate">
                  {selectedLocation}
                </span>
              </div>
              <ChevronRight className="size-4 text-neutral-400 shrink-0" />
            </div>

            {/* Delivery Time Row */}
            <div className="flex items-center justify-between rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-card p-3.5 shadow-xs">
              <div className="flex items-center gap-2.5">
                <Truck className="size-4.5 text-neutral-600 dark:text-neutral-300" />
                <span className="text-xs text-neutral-600 dark:text-neutral-300">
                  Delivery by <strong className="font-bold text-foreground">{deliveryDateString}</strong>
                </span>
              </div>
              <span className="rounded-md bg-emerald-100 dark:bg-emerald-950/50 px-2 py-0.5 text-[10px] font-black text-emerald-700 dark:text-emerald-400 uppercase tracking-wider">
                FASTEST
              </span>
            </div>
          </div>

          {/* Description */}
          <div className="pt-1">
            <h2 className="text-sm font-bold text-foreground">Description:</h2>
            <p className="mt-1 text-xs text-neutral-600 dark:text-neutral-400 leading-relaxed">
              {product.description || "240 GSM combed cotton in pastel lilac tone with luxury heavy rib collar."}
            </p>
          </div>

          {/* Similar Products */}
          {relatedProducts.length > 0 && (
            <div className="pt-2">
              <div className="flex items-center justify-between mb-3">
                <h2 className="text-base font-bold text-foreground">Similar Products</h2>
                <Link
                  to="/products"
                  className="inline-flex items-center gap-1 rounded-full border border-[#D4AF37]/50 bg-[#FFFDF5] dark:bg-card px-2.5 py-1 text-[11px] font-bold text-[#8B6508] dark:text-[#E5C158] hover:bg-[#D4AF37] hover:text-white transition-all shadow-xs shrink-0"
                >
                  <span>See All</span>
                  <ArrowRight className="size-3" />
                </Link>
              </div>

              <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
                {relatedProducts.map((rel) => {
                  const relOff = Math.round((1 - rel.price / rel.oldPrice) * 100);
                  const isRelWish = isInWishlist(rel.id);
                  return (
                    <div
                      key={rel.id}
                      onClick={() => {
                        navigate(`/product/${rel.id}`);
                        window.scrollTo({ top: 0, behavior: "instant" });
                      }}
                      className="relative w-[180px] xs:w-[190px] shrink-0 overflow-hidden rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-card shadow-xs cursor-pointer flex flex-col justify-between"
                    >
                      {/* Product Image */}
                      <div className="relative aspect-[4/5] w-full overflow-hidden bg-neutral-900">
                        <img
                          src={rel.image || luxuryGold}
                          alt={rel.name}
                          className="h-full w-full object-cover object-top"
                        />
                        {/* Discount Badge */}
                        {relOff > 0 && (
                          <span className="absolute left-2.5 top-2.5 rounded-md bg-[#E5C158] px-2 py-0.5 text-[9px] font-black uppercase text-black shadow-xs">
                            {relOff}% OFF
                          </span>
                        )}
                        {/* Heart */}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            toggleWishlist(rel);
                          }}
                          className="absolute right-2.5 top-2.5 flex size-7 items-center justify-center rounded-full bg-black/60 text-white backdrop-blur-xs transition-transform active:scale-90"
                        >
                          <Heart className={`size-3.5 ${isRelWish ? "fill-red-500 text-red-500" : "text-white"}`} />
                        </button>
                      </div>

                      {/* Card Info */}
                      <div className="p-3 flex-1 flex flex-col justify-between">
                        <div>
                          <p className="text-[10px] font-bold uppercase tracking-wider text-[#D4AF37]">
                            {rel.category || "OVERSIZED"}
                          </p>
                          <h3 className="mt-0.5 font-bold text-xs text-foreground line-clamp-1">
                            {rel.name}
                          </h3>
                        </div>

                        <div className="mt-2.5 flex items-center justify-between pt-1">
                          <div>
                            {rel.oldPrice > rel.price && (
                              <p className="text-[10px] text-neutral-400 line-through">
                                ₹{rel.oldPrice.toLocaleString("en-IN")}
                              </p>
                            )}
                            <p className="text-sm font-extrabold text-foreground">
                              ₹{rel.price.toLocaleString("en-IN")}
                            </p>
                          </div>

                          <div className="flex size-7 items-center justify-center rounded-full bg-[#FFF4D1] dark:bg-neutral-800 text-[#8B6508] dark:text-[#E5C158]">
                            <ArrowRight className="size-3.5" />
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}

                {/* See All End Card */}
                <Link
                  to="/products"
                  className="relative w-[140px] shrink-0 overflow-hidden rounded-2xl border-2 border-dashed border-[#D4AF37]/50 bg-[#FFFDF5] dark:bg-card/40 flex flex-col items-center justify-center p-4 text-center cursor-pointer transition-all hover:border-[#D4AF37] active:scale-95 shadow-xs"
                >
                  <div className="flex size-10 items-center justify-center rounded-full bg-[#D4AF37]/15 text-[#8B6508] dark:text-[#E5C158] mb-2 shadow-xs">
                    <ArrowRight className="size-5" />
                  </div>
                  <span className="text-xs font-bold text-foreground">See All</span>
                  <span className="text-[10px] text-muted-foreground mt-0.5 font-medium">
                    View Catalog
                  </span>
                </Link>
              </div>
            </div>
          )}

          {/* Customer Reviews on Mobile */}
          <div className="pt-2 border-t border-border/40 space-y-3.5">
            <div className="flex items-center justify-between">
              <h2 className="text-base font-bold text-foreground">Customer Reviews</h2>
              <button
                type="button"
                onClick={handleOpenReviewModal}
                className="inline-flex items-center gap-1.5 rounded-xl border border-[#D4AF37] bg-white dark:bg-card px-3 py-1.5 text-xs font-bold text-[#8B6508] dark:text-[#E5C158] shadow-xs cursor-pointer active:scale-95"
              >
                <Edit3 className="size-3.5" />
                <span>Write Review</span>
              </button>
            </div>

            {/* Rating Breakdown Card */}
            <div className="rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-card p-4 shadow-xs flex items-center gap-4">
              {/* Left Column: Big score */}
              <div className="text-center shrink-0 pr-2">
                <div className="text-4xl font-black text-foreground tracking-tight">4.6</div>
                <div className="flex justify-center text-amber-400 gap-0.5 mt-1">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Star key={i} className="size-3.5 fill-amber-400 text-amber-400" />
                  ))}
                </div>
                <p className="text-[11px] text-neutral-400 mt-1">175 ratings</p>
              </div>

              {/* Vertical Divider */}
              <div className="w-px h-18 bg-neutral-200 dark:bg-neutral-800 shrink-0" />

              {/* Right Column: Rating progress bars */}
              <div className="flex-1 space-y-1">
                {[
                  { star: 5, pct: 75, count: 3 },
                  { star: 4, pct: 25, count: 1 },
                  { star: 3, pct: 0, count: 0 },
                  { star: 2, pct: 0, count: 0 },
                  { star: 1, pct: 0, count: 0 },
                ].map(({ star, pct, count }) => (
                  <div key={star} className="flex items-center gap-1.5 text-[10px]">
                    <span className="font-semibold text-neutral-500 w-2.5 text-right">{star}</span>
                    <Star className="size-2.5 fill-amber-400 text-amber-400 shrink-0" />
                    <div className="flex-1 h-1.5 rounded-full bg-neutral-100 dark:bg-neutral-800 overflow-hidden">
                      <div
                        className="h-full bg-[#D4AF37] rounded-full"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                    <span className="text-neutral-400 w-3 text-right">{count}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Individual Review Cards */}
            <div className="space-y-3 pt-1">
              {(showAllMobileReviews ? reviews : reviews.slice(0, 2)).map((rev) => (
                <div
                  key={rev.id}
                  className="rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-card p-4 shadow-xs space-y-2.5"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-2.5">
                      <div className="flex size-9 items-center justify-center rounded-full bg-[#FFF4D1] dark:bg-neutral-800 font-bold text-xs text-[#8B6508] dark:text-[#E5C158] shrink-0">
                        {rev.name.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <div className="flex items-center gap-1.5">
                          <span className="font-bold text-xs text-foreground">{rev.name}</span>
                          {rev.verified && (
                            <span className="flex items-center gap-1 rounded-full bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 px-1.5 py-0.2 text-[9px] font-semibold text-emerald-600 dark:text-emerald-400">
                              <Check className="size-2.5 stroke-[3]" /> Verified Buyer
                            </span>
                          )}
                        </div>
                        <p className="text-[10px] text-neutral-400">{rev.date}</p>
                      </div>
                    </div>

                    {/* Star Rating */}
                    <div className="flex text-amber-400 gap-0.5">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star
                          key={i}
                          className={`size-3 ${i < rev.rating ? "fill-amber-400 text-amber-400" : "text-neutral-200 dark:text-neutral-700"}`}
                        />
                      ))}
                    </div>
                  </div>

                  <p className="text-xs text-neutral-600 dark:text-neutral-300 leading-relaxed font-normal">
                    {rev.comment}
                  </p>
                </div>
              ))}
            </div>

            {/* View All Reviews Button */}
            {reviews.length > 2 && (
              <button
                type="button"
                onClick={() => setShowAllMobileReviews((prev) => !prev)}
                className="w-full rounded-xl border border-[#E5C158] bg-[#FFFDF5] dark:bg-neutral-900 py-3 flex items-center justify-center gap-1.5 text-xs font-bold text-[#8B6508] dark:text-[#E5C158] shadow-xs active:scale-98 transition-all cursor-pointer"
              >
                <ChevronDown className={`size-4 transition-transform duration-300 ${showAllMobileReviews ? "rotate-180" : ""}`} />
                <span>
                  {showAllMobileReviews ? "Hide Reviews" : `View All Reviews (${reviews.length})`}
                </span>
              </button>
            )}
          </div>
        </div>

        {/* Sticky Mobile Bottom Bar (Fixed at bottom on Mobile) */}
        <div className="fixed inset-x-0 bottom-0 z-40 flex items-center gap-3 border-t border-border/60 bg-white dark:bg-[#14120E] p-3.5 pb-safe shadow-[0_-4px_20px_rgba(0,0,0,0.08)]">
          <button
            type="button"
            disabled={!isVariantInStock}
            onClick={handleAddToCart}
            className="flex-1 py-3 px-4 rounded-xl border border-neutral-300 dark:border-neutral-600 bg-white dark:bg-neutral-800 text-foreground font-bold text-sm shadow-xs active:scale-95 transition-all text-center disabled:opacity-50 cursor-pointer"
          >
            Add to cart
          </button>
          <button
            type="button"
            disabled={!isVariantInStock}
            onClick={handleBuyNow}
            className="flex-1 py-3 px-4 rounded-xl bg-[#D4AF37] hover:bg-[#C29D2F] text-white font-extrabold text-sm shadow-md active:scale-95 transition-all text-center disabled:opacity-50 cursor-pointer"
          >
            Buy now
          </button>
        </div>
      </div>

      {/* ============================================================== */}
      {/* 2. DESKTOP VIEW (>= md)                                        */}
      {/* ============================================================== */}
      <section className="hidden md:block mx-auto max-w-7xl px-5 pt-28 pb-12">




      {/* Main Product Grid */}
      <div className="grid gap-12 lg:grid-cols-12 items-start">
        {/* Left Column: Product Image Gallery */}
        <div className="lg:col-span-7 space-y-4">
          <Reveal>
            <div className="group relative overflow-hidden rounded-2xl border border-gold/40 bg-card/40 shadow-goldy transition-all duration-500">
              <img
                key={selectedImage}
                src={selectedImage}
                alt={`${product.name} in ${selectedColor.name}`}
                className="h-[480px] sm:h-[580px] w-full object-cover object-top transition-all duration-700 group-hover:scale-105 animate-in fade-in duration-300"
              />
              <span className="absolute left-5 top-5 rounded-full border border-gold/60 bg-[#f4efe6] px-4 py-1.5 text-[10px] font-extrabold uppercase tracking-[0.25em] text-[#1c1917] shadow-md z-10">
                {product.category} Collection
              </span>
              <span className="btn-gold absolute right-5 top-5 rounded-full px-3.5 py-1.5 text-[10px] font-bold uppercase tracking-wider z-10">
                {discountOff}% OFF
              </span>

            </div>
          </Reveal>

          {/* 4-Angle Gallery Previews */}
          {colorGalleryAngles.length > 0 && (
            <div className="pt-2">
              <div className="grid grid-cols-4 gap-2.5">
                {colorGalleryAngles.map((angle, idx) => {
                  const isActive = selectedImage === angle.image;
                  return (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setSelectedImage(angle.image)}
                      className={`group relative overflow-hidden rounded-xl border transition-all duration-300 h-20 sm:h-24 cursor-pointer bg-card ${
                        isActive
                          ? "border-gold ring-2 ring-gold/60 scale-105 shadow-goldy"
                          : "border-border opacity-70 hover:opacity-100 hover:border-gold/50"
                      }`}
                      title={`${selectedColor.name} - ${angle.label}`}
                    >
                      <img
                        src={angle.image}
                        alt={`${selectedColor.name} ${angle.label}`}
                        className="h-full w-full object-cover object-top"
                      />
                      <div className="absolute inset-0 bg-black/20 group-hover:bg-transparent transition-colors" />
                    </button>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {/* Right Column: Product Details & Purchase Form */}
        <div className="lg:col-span-5 space-y-7">
          <Reveal>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-[10px] uppercase tracking-[0.3em] text-gold font-bold">
                  VEXA Signature Series
                </span>
                <button
                  type="button"
                  onClick={handleShare}
                  className="inline-flex items-center gap-1.5 rounded-full border border-gold/40 bg-card/80 px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-gold backdrop-blur transition-all duration-300 hover:border-gold hover:bg-gold hover:text-primary-foreground shadow-xs cursor-pointer active:scale-95"
                >
                  <Share2 className="size-3.5" />
                  <span>Share</span>
                </button>
              </div>
              <h1 className="font-display text-3xl sm:text-4xl font-bold text-foreground">
                {product.name}
              </h1>

              {/* Rating Summary Link */}
              <div className="flex items-center gap-3 pt-1">
                <a
                  href="#reviews-section"
                  className="flex items-center gap-1.5 text-xs text-gold font-bold hover:underline"
                >
                  <div className="flex text-gold">
                    {Array.from({ length: 5 }).map((_, i) => (
                      <Star key={i} className="size-3.5 fill-current" />
                    ))}
                  </div>
                  <span>{avgRating}</span>
                  <span className="text-muted-foreground font-normal">
                    ({reviews.length} Customer Reviews)
                  </span>
                </a>
              </div>

              {/* Dynamic Price Row (Updates live with selected Quantity & MRP) */}
              <div className="space-y-1.5 pt-3">
                <div className="flex flex-wrap items-baseline gap-3 sm:gap-4">
                  <span className="font-display text-3xl sm:text-4xl font-extrabold text-gold">
                    ₹{(currentPrice * quantity).toLocaleString("en-IN")}
                  </span>
                  {currentOldPrice > currentPrice && (
                    <span className="text-base sm:text-lg text-muted-foreground/75 line-through">
                      ₹{(currentOldPrice * quantity).toLocaleString("en-IN")}
                    </span>
                  )}
                  {currentOldPrice > currentPrice && (
                    <span className="rounded-full bg-gold/15 border border-gold/40 px-3 py-1 text-[10px] font-bold text-gold shadow-xs">
                      Save ₹{((currentOldPrice - currentPrice) * quantity).toLocaleString("en-IN")} ({discountOff}%)
                    </span>
                  )}
                </div>
                {quantity > 1 && (
                  <p className="text-[11px] text-gold/80 font-bold tracking-wide">
                    ₹{currentPrice.toLocaleString("en-IN")} per piece × {quantity} items
                  </p>
                )}
              </div>
              <p className="text-[11px] text-muted-foreground pt-1">
                Inclusive of all taxes. Free express shipping nationwide.
              </p>
            </div>

            <div className="hairline my-6" />

            {/* Description Highlights */}
            <p className="text-xs text-muted-foreground leading-relaxed">
              Crafted from 240 GSM long-staple combed cotton with specialized bio-wash treatment.
              Features VEXA's signature drop-shoulder silhouette, pre-shrunk anti-fade fabric weave,
              and double-stitched reinforced collar for lasting structure.
            </p>

            {/* INTERACTIVE COLORWAY SELECTOR */}
            <div className="mt-7 space-y-3 rounded-xl border border-gold/30 bg-card p-4 shadow-sm">
              <div className="flex items-center justify-between">
                <label className="text-[10px] uppercase tracking-[0.2em] text-muted-foreground font-bold">
                  Select Colorway:
                </label>
                <span className="text-xs font-bold text-gold flex items-center gap-1.5">
                  <span
                    className="size-3.5 rounded-full border border-gold/40 inline-block shadow-sm"
                    style={{ backgroundColor: selectedColor.hex }}
                  />
                  {selectedColor.name}
                </span>
              </div>

              {/* Color Swatch Circles (Single Line Row Layout) */}
              <div className="grid grid-cols-8 gap-1 sm:gap-2.5 pt-1 items-center justify-items-center">
                {availableColorsForProduct.map((col) => {
                  const isActive = selectedColor.name.toLowerCase().trim() === col.name.toLowerCase().trim();
                  return (
                    <button
                      key={col.name}
                      type="button"
                      onClick={() => handleSelectColor(col)}
                      className={`group relative flex items-center justify-center size-7 sm:size-9 rounded-full transition-all duration-300 cursor-pointer ${
                        isActive
                          ? "ring-2 ring-gold ring-offset-1 sm:ring-offset-2 ring-offset-background scale-110 shadow-goldy"
                          : "hover:scale-105 opacity-85 hover:opacity-100"
                      }`}
                      style={{
                        backgroundColor: col.hex,
                        border: `1.5px solid ${col.borderColor || "#C5A880"}`,
                      }}
                      title={col.name}
                    >
                      {isActive && (
                        <Check
                          className={`size-3 sm:size-4 stroke-[3] ${
                            col.name.includes("White") || col.name.includes("Cream")
                              ? "text-black"
                              : "text-white"
                          }`}
                        />
                      )}
                      {/* Tooltip on Hover */}
                      <span className="pointer-events-none absolute -bottom-8 left-1/2 -translate-x-1/2 whitespace-nowrap rounded bg-black/90 px-2 py-1 text-[9px] font-bold text-gold opacity-0 transition-opacity group-hover:opacity-100 border border-gold/30 z-20">
                        {col.name}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Size Selection */}
            <div className="mt-6 space-y-3">
              <div className="flex items-center justify-between">
                <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                  Select Size
                </label>
                <button
                  type="button"
                  onClick={() => setShowSizeGuide(true)}
                  className="flex items-center gap-1 text-[11px] text-gold hover:underline font-bold"
                >
                  <Ruler className="size-3.5" /> Size Guide
                </button>
              </div>
              <div className="grid grid-cols-6 gap-2">
                {SIZES.map((sz) => {
                  const szStock = product ? getVariantStock(product.id, selectedColor.name, sz, product.stock) : 0;
                  const isSzOut = szStock <= 0;
                  const isSelected = selectedSize === sz;

                  return (
                    <button
                      key={sz}
                      type="button"
                      disabled={isSzOut}
                      onClick={() => !isSzOut && setSelectedSize(sz)}
                      className={`relative overflow-hidden rounded-md border py-3 text-xs font-bold transition-all ${
                        isSzOut
                          ? "opacity-50 cursor-not-allowed border-border/60 bg-muted/20 text-muted-foreground select-none"
                          : isSelected
                          ? "border-gold bg-gold text-primary-foreground shadow-goldy font-extrabold scale-105 cursor-pointer"
                          : "border-border bg-card text-foreground hover:border-gold/60 cursor-pointer"
                      }`}
                    >
                      <span>{sz}</span>
                      {/* Diagonal strike-through cross line for unavailable sizes */}
                      {isSzOut && (
                        <div className="absolute inset-0 flex items-center justify-center pointer-events-none overflow-hidden rounded-md">
                          <div className="w-[140%] h-[1.5px] bg-foreground/60 transform -rotate-45" />
                        </div>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Quantity Selector */}
            <div className="mt-6 space-y-2">
              <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                Quantity
              </label>
              <div className="flex items-center gap-3 w-fit rounded-lg border border-border bg-card p-1">
                <button
                  type="button"
                  disabled={!isVariantInStock}
                  onClick={() => setQuantity((q) => Math.max(1, q - 1))}
                  className="flex size-8 items-center justify-center rounded-md text-muted-foreground hover:text-gold hover:bg-surface cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  <Minus className="size-3.5" />
                </button>
                <span className="w-8 text-center text-xs font-bold text-foreground">
                  {quantity}
                </span>
                <button
                  type="button"
                  disabled={!isVariantInStock}
                  onClick={() => setQuantity((q) => q + 1)}
                  className="flex size-8 items-center justify-center rounded-md text-muted-foreground hover:text-gold hover:bg-surface cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  <Plus className="size-3.5" />
                </button>
              </div>
            </div>

            {/* CTA Action Buttons */}
            <div className="mt-8 grid grid-cols-1 sm:grid-cols-2 gap-4">
              <button
                disabled={!isVariantInStock}
                onClick={handleAddToCart}
                className={`flex items-center justify-center gap-2 rounded-sm py-4 text-xs font-bold uppercase tracking-widest transition-all ${
                  isVariantInStock
                    ? "btn-gold hover:btn-gold-hover cursor-pointer shadow-goldy active:scale-98"
                    : "border border-border bg-muted/40 text-muted-foreground cursor-not-allowed opacity-60"
                }`}
              >
                <ShoppingBag className="size-4" />
                {isVariantInStock ? "Add to Cart" : "Out of Stock"}
              </button>
              <button
                disabled={!isVariantInStock}
                onClick={handleBuyNow}
                className={`flex items-center justify-center gap-2 rounded-sm py-4 text-xs font-bold uppercase tracking-widest transition-all ${
                  isVariantInStock
                    ? "btn-outline-gold hover:bg-gold hover:text-primary-foreground cursor-pointer shadow-sm active:scale-98"
                    : "border border-border bg-card/20 text-muted-foreground cursor-not-allowed opacity-60"
                }`}
              >
                {isVariantInStock ? "Buy Now" : "Variant Unavailable"}
              </button>
            </div>

            {/* Trust Badges */}
            <div className="mt-8 grid grid-cols-3 gap-3 border-t border-border pt-6 text-center text-[10px] text-muted-foreground">
              <div className="space-y-1.5">
                <Truck className="mx-auto size-5 text-gold" />
                <p className="font-semibold text-foreground">Fast Dispatch</p>
                <p>2-4 Business Days</p>
              </div>
              <div className="space-y-1.5">
                <ShieldCheck className="mx-auto size-5 text-gold" />
                <p className="font-semibold text-foreground">100% Combed Cotton</p>
                <p>Pre-shrunk 240 GSM</p>
              </div>
              <div className="space-y-1.5">
                <RotateCcw className="mx-auto size-5 text-gold" />
                <p className="font-semibold text-foreground">7-Day Returns</p>
                <p>Hassle-Free Exchange</p>
              </div>
            </div>
          </Reveal>
        </div>
      </div>

      {/* Tabs: Specifications & Instructions */}
      <div className="mt-20">
        <div className="flex border-b border-border gap-8 overflow-x-auto">
          {[
            { id: "specs", label: "Fabric & Craftsmanship" },
            { id: "care", label: "Washing & Care Guide" },
            { id: "shipping", label: "Shipping & Returns" },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`pb-4 text-xs font-bold uppercase tracking-wider transition-all cursor-pointer ${
                activeTab === tab.id
                  ? "border-b-2 border-gold text-gold"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div className="py-8 text-xs text-muted-foreground leading-relaxed">
          {activeTab === "specs" && (
            <div className="grid sm:grid-cols-2 gap-6 bg-card p-6 rounded-xl border border-border">
              <div className="space-y-2">
                <p className="font-bold text-foreground uppercase tracking-wider">Construction</p>
                <p>• Fabric: 100% Combed Long-Staple Luxury Cotton</p>
                <p>• Weight: 240 GSM (Grams per Square Meter) Heavyweight</p>
                <p>• Fit: Modern Signature Oversized Drop Shoulder</p>
              </div>
              <div className="space-y-2">
                <p className="font-bold text-foreground uppercase tracking-wider">Features</p>
                <p>• Finish: Enzyme & Bio-Washed for silk-like handfeel</p>
                <p>• Collar: Reinforced Lycra double-stitched rib collar</p>
                <p>• Colorfastness: Reactive dyes engineered to prevent fading</p>
              </div>
            </div>
          )}

          {activeTab === "care" && (
            <div className="space-y-3 bg-card p-6 rounded-xl border border-border">
              <p className="font-bold text-foreground uppercase tracking-wider">Garment Care Instructions</p>
              <p>• Machine wash cold (below 30°C) with like colors inside out.</p>
              <p>• Use mild detergent; do not use chlorine bleach or fabric softeners.</p>
              <p>• Line dry in shade to preserve rich fabric color and structural shape.</p>
              <p>• Cool iron inside out if needed. Do not iron directly over high-density prints or embroidery.</p>
            </div>
          )}

          {activeTab === "shipping" && (
            <div className="space-y-3 bg-card p-6 rounded-xl border border-border">
              <p className="font-bold text-foreground uppercase tracking-wider">Nationwide Logistics</p>
              <p>• Free Express Pan-India Delivery on orders over ₹1,999.</p>
              <p>• Orders dispatched within 24–48 hours from our central warehouse.</p>
              <p>• Live SMS & Email tracking provided upon shipment dispatch.</p>
              <p>• 7-Day Easy Exchange Policy: If the size isn't perfect, initiate a replacement in 1-click from your dashboard.</p>
            </div>
          )}
        </div>
      </div>

      {/* Customer Reviews Section */}
      <div id="reviews-section" className="mt-16 pt-8 border-t border-border space-y-10">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
          <div>
            <p className="text-[10px] uppercase tracking-[0.3em] text-gold font-bold">
              Verified Buyer Feedback
            </p>
            <h2 className="mt-1 font-display text-3xl font-bold text-foreground">
              Customer Reviews
            </h2>
          </div>
          <button
            onClick={handleOpenReviewModal}
            className="btn-gold hover:btn-gold-hover flex items-center justify-center gap-2 rounded-sm px-6 py-3 text-xs font-bold uppercase tracking-wider cursor-pointer"
          >
            <MessageSquare className="size-4" /> Write a Review
          </button>
        </div>

        {/* Rating Breakdown Card */}
        <div className="grid lg:grid-cols-12 gap-8 rounded-2xl border border-gold/40 bg-card p-6 sm:p-8 shadow-goldy items-center">
          <div className="lg:col-span-4 text-center border-b lg:border-b-0 lg:border-r border-border pb-6 lg:pb-0 lg:pr-8">
            <span className="font-display text-5xl font-extrabold text-gold">{avgRating}</span>
            <div className="flex justify-center text-gold my-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <Star key={i} className="size-5 fill-current" />
              ))}
            </div>
            <p className="text-xs text-muted-foreground font-semibold">
              Based on {reviews.length} Verified Customer Reviews
            </p>
          </div>

          <div className="lg:col-span-8 space-y-2">
            {[5, 4, 3, 2, 1].map((ratingVal) => {
              const count = reviews.filter((r) => r.rating === ratingVal).length;
              const pct = reviews.length > 0 ? Math.round((count / reviews.length) * 100) : 0;
              return (
                <div key={ratingVal} className="flex items-center gap-3 text-xs">
                  <span className="w-12 text-right font-bold text-gold">{ratingVal} Stars</span>
                  <div className="h-2 flex-1 rounded-full bg-surface overflow-hidden border border-border">
                    <div
                      className="h-full bg-gold transition-all duration-500"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <span className="w-10 text-muted-foreground text-right">{pct}%</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Dynamic Interactive Filter & Sort Toolbar */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 rounded-xl border border-border bg-card p-4 shadow-xs">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-bold mr-1">
              Filter:
            </span>
            <button
              type="button"
              onClick={() => setReviewFilter("all")}
              className={`rounded-full px-3 py-1 text-[11px] font-bold transition-all cursor-pointer ${
                reviewFilter === "all"
                  ? "bg-gold text-primary-foreground shadow-xs"
                  : "bg-surface text-muted-foreground hover:text-foreground border border-border"
              }`}
            >
              All ({reviews.length})
            </button>
            <button
              type="button"
              onClick={() => setReviewFilter("5")}
              className={`rounded-full px-3 py-1 text-[11px] font-bold transition-all cursor-pointer ${
                reviewFilter === "5"
                  ? "bg-gold text-primary-foreground shadow-xs"
                  : "bg-surface text-muted-foreground hover:text-foreground border border-border"
              }`}
            >
              ★ 5 Stars ({reviews.filter((r) => r.rating === 5).length})
            </button>
            <button
              type="button"
              onClick={() => setReviewFilter("4")}
              className={`rounded-full px-3 py-1 text-[11px] font-bold transition-all cursor-pointer ${
                reviewFilter === "4"
                  ? "bg-gold text-primary-foreground shadow-xs"
                  : "bg-surface text-muted-foreground hover:text-foreground border border-border"
              }`}
            >
              ★ 4 Stars ({reviews.filter((r) => r.rating === 4).length})
            </button>
            <button
              type="button"
              onClick={() => setReviewFilter("verified")}
              className={`rounded-full px-3 py-1 text-[11px] font-bold transition-all cursor-pointer ${
                reviewFilter === "verified"
                  ? "bg-gold text-primary-foreground shadow-xs"
                  : "bg-surface text-muted-foreground hover:text-foreground border border-border"
              }`}
            >
              Verified Buyers ({reviews.filter((r) => r.verified).length})
            </button>
          </div>

          <div className="flex items-center gap-2 self-end sm:self-auto">
            <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-bold">
              Sort By:
            </span>
            <select
              value={reviewSort}
              onChange={(e) => setReviewSort(e.target.value as any)}
              className="rounded-lg border border-border bg-background px-3 py-1.5 text-xs text-foreground font-semibold outline-none focus:border-gold cursor-pointer"
            >
              <option value="recent">Most Recent</option>
              <option value="rating">Highest Rating</option>
              <option value="helpful">Most Helpful</option>
            </select>
          </div>
        </div>

        {/* Dynamic Reviews List */}
        <div className="space-y-6">
          {filteredReviews.length === 0 ? (
            <div className="rounded-xl border border-border bg-card p-8 text-center space-y-2">
              <p className="text-sm font-bold text-foreground">No customer reviews match the selected filter.</p>
              <button
                type="button"
                onClick={() => setReviewFilter("all")}
                className="text-xs text-gold underline font-semibold cursor-pointer"
              >
                Clear filters to view all {reviews.length} customer reviews
              </button>
            </div>
          ) : (
            filteredReviews.map((rev) => (
              <div
                key={rev.id}
                className="rounded-xl border border-border bg-card p-6 space-y-3 transition-all hover:border-gold/50"
              >
                <div className="flex items-center justify-between flex-wrap gap-2">
                  <div className="flex items-center gap-3">
                    <div className="flex size-10 items-center justify-center rounded-full bg-gold/20 font-bold text-gold text-sm border border-gold/40">
                      {rev.name.charAt(0)}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h4 className="font-bold text-foreground text-sm">{rev.name}</h4>
                        {rev.verified && (
                          <span className="flex items-center gap-1 rounded-full bg-gold/10 px-2 py-0.5 text-[9px] font-bold text-gold border border-gold/30">
                            <CheckCircle2 className="size-3 text-gold" /> Verified Buyer
                          </span>
                        )}
                      </div>
                      <p className="text-[10px] text-muted-foreground">{rev.date}</p>
                    </div>
                  </div>

                  <div className="flex text-gold">
                    {Array.from({ length: 5 }).map((_, i) => (
                      <Star
                        key={i}
                        className={`size-4 ${i < rev.rating ? "fill-current" : "text-border"}`}
                      />
                    ))}
                  </div>
                </div>

                <h5 className="font-bold text-foreground text-sm">{rev.title}</h5>
                <p className="text-xs text-muted-foreground leading-relaxed">{rev.comment}</p>

                <div className="pt-2 flex items-center justify-between text-[11px] text-muted-foreground border-t border-border/50">
                  <button
                    onClick={() => handleHelpfulClick(rev.id)}
                    disabled={helpfulClicked[rev.id]}
                    className={`flex items-center gap-1.5 hover:text-gold transition-colors cursor-pointer ${
                      helpfulClicked[rev.id] ? "text-gold font-bold" : ""
                    }`}
                  >
                    <ThumbsUp className="size-3.5" /> Helpful ({rev.helpfulCount})
                  </button>
                  <span>VEXA Verified Review</span>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

        {/* Related Products Section ("You May Also Like") - Side Scrolling */}
      {relatedProducts.length > 0 && (
        <div className="mt-24 pt-12 border-t border-border">
          <Reveal className="flex flex-wrap items-end justify-between gap-4 mb-8">
            <div>
              <p className="text-[10px] uppercase tracking-[0.3em] text-gold font-bold">
                You May Also Like
              </p>
              <h2 className="mt-1 font-display text-3xl font-bold">Related Products</h2>
            </div>
            <Link
              to="/products"
              className="inline-flex items-center gap-2 text-xs uppercase tracking-[0.2em] text-gold transition-transform hover:translate-x-1"
            >
              Explore Full Collection ({products.length}) <ArrowRight className="size-4" />
            </Link>
          </Reveal>

          {/* Horizontal Side-Scrolling Carousel */}
          <div className="flex gap-5 sm:gap-6 overflow-x-auto pb-6 pt-2 snap-x snap-mandatory scroll-smooth no-scrollbar -mx-5 px-5 sm:mx-0 sm:px-0">
            {relatedProducts.map((relProduct, i) => (
              <div key={relProduct.id} className="w-[280px] sm:w-[300px] lg:w-[310px] shrink-0 snap-start">
                <Reveal delay={i * 90}>
                  <ProductCard product={relProduct} />
                </Reveal>
              </div>
            ))}
          </div>
        </div>
      )}
    </section>

      {/* WRITE A REVIEW MODAL (Available on Mobile & Desktop) */}
      {showReviewModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4 overflow-y-auto animate-in fade-in duration-200">
          <div className="relative w-full max-w-lg rounded-2xl border border-gold/50 bg-card p-5 sm:p-8 shadow-2xl space-y-5 my-auto max-h-[90vh] overflow-y-auto">
            <button
              onClick={() => setShowReviewModal(false)}
              className="absolute right-5 top-5 rounded-full border border-border bg-background p-2 text-muted-foreground hover:border-gold hover:text-gold"
            >
              <X className="size-4" />
            </button>

            <div className="text-center space-y-2 border-b border-border pb-4">
              <h3 className="font-display text-2xl font-bold text-foreground">Write a Review</h3>
              <p className="text-xs text-muted-foreground">
                Share your experience for <strong className="text-gold">{product.name}</strong>
              </p>
            </div>

            <form onSubmit={handleAddReview} className="space-y-4">
              {/* Star Rating Pick */}
              <div>
                <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground font-semibold">
                  Your Rating
                </label>
                <div className="flex items-center gap-2 mt-2">
                  {[1, 2, 3, 4, 5].map((starVal) => (
                    <button
                      key={starVal}
                      type="button"
                      onClick={() => setNewRating(starVal)}
                      className="p-1 text-gold cursor-pointer transition-transform hover:scale-125"
                    >
                      <Star
                        className={`size-7 ${starVal <= newRating ? "fill-current text-gold" : "text-border"}`}
                      />
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground font-semibold">
                  Your Name
                </label>
                <input
                  required
                  type="text"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="e.g. Rahul V."
                  className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs outline-none focus:border-gold"
                />
              </div>

              <div>
                <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground font-semibold">
                  Review Headline / Title
                </label>
                <input
                  type="text"
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="e.g. Perfect fit and amazing fabric weight!"
                  className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs outline-none focus:border-gold"
                />
              </div>

              <div>
                <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground font-semibold">
                  Detailed Review
                </label>
                <textarea
                  required
                  rows={4}
                  value={newComment}
                  onChange={(e) => setNewComment(e.target.value)}
                  placeholder="Tell us about the drape, fabric feel, sizing, and overall quality..."
                  className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs outline-none focus:border-gold resize-none"
                />
              </div>

              <div className="pt-2 flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setShowReviewModal(false)}
                  className="flex-1 rounded-sm border border-border py-3 text-xs font-bold uppercase tracking-wider text-muted-foreground hover:bg-surface cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-gold hover:btn-gold-hover flex-1 rounded-sm py-3 text-xs font-bold uppercase tracking-wider cursor-pointer"
                >
                  Submit Review
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* SIZE GUIDE MODAL */}
      {showSizeGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-sm p-4">
          <div className="w-full max-w-lg rounded-2xl border border-gold/40 bg-card p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-border pb-3">
              <h3 className="font-display text-xl font-bold text-foreground">VEXA Size Chart</h3>
              <button
                onClick={() => setShowSizeGuide(false)}
                className="text-xs uppercase tracking-widest text-gold hover:underline"
              >
                Close
              </button>
            </div>
            <div className="space-y-3 text-xs text-muted-foreground">
              <p>All VEXA tees feature a Signature Oversized Silhouette. Order your normal size for an intended relaxed drop-shoulder drape.</p>
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-border text-foreground uppercase tracking-wider text-[10px]">
                    <th className="py-2">Size</th>
                    <th className="py-2">Chest (Inches)</th>
                    <th className="py-2">Length (Inches)</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  <tr><td className="py-2 font-bold text-gold">XS</td><td className="py-2">40"</td><td className="py-2">27"</td></tr>
                  <tr><td className="py-2 font-bold text-gold">S</td><td className="py-2">42"</td><td className="py-2">28"</td></tr>
                  <tr><td className="py-2 font-bold text-gold">M</td><td className="py-2">44"</td><td className="py-2">29"</td></tr>
                  <tr><td className="py-2 font-bold text-gold">L</td><td className="py-2">46"</td><td className="py-2">30"</td></tr>
                  <tr><td className="py-2 font-bold text-gold">XL</td><td className="py-2">48"</td><td className="py-2">31"</td></tr>
                  <tr><td className="py-2 font-bold text-gold">XXL</td><td className="py-2">50"</td><td className="py-2">32"</td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* DELIVERY LOCATION MODAL */}
      <DeliveryLocationModal
        isOpen={isLocationModalOpen}
        onClose={() => setIsLocationModalOpen(false)}
        currentLocation={selectedLocation}
        onSelectLocation={handleSelectLocation}
      />
    </>
  );
}
