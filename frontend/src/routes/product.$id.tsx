import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useState, useMemo, useEffect } from "react";
import {
  Star,
  ShoppingBag,
  ShieldCheck,
  Truck,
  ArrowRight,
  CheckCircle2,
  Sparkles,
  Ruler,
  MessageSquare,
  ThumbsUp,
  X,
  ChevronLeft,
  Share2,
  Minus,
  Plus,
  RotateCcw,
  Check,
} from "lucide-react";
import { useProducts, SIZES, type Product } from "@/lib/products";
import { ProductCard } from "@/components/ProductCard";
import { Reveal } from "@/components/Reveal";
import { addToCart } from "@/lib/cart";
import { useAuth } from "@/lib/auth";

import black from "@/assets/tee-black.jpg";
import white from "@/assets/tee-white.jpg";
import navy from "@/assets/tee-navy.jpg";
import beige from "@/assets/tee-beige.jpg";
import charcoal from "@/assets/tee-charcoal.jpg";
import olive from "@/assets/tee-olive.jpg";
import luxuryGold from "@/assets/hero_luxury_tshirt.png";
import rust from "@/assets/tee-rust.png";

export const Route = createFileRoute("/product/$id")({
  head: () => ({
    meta: [
      { title: "Product Detail | VEXA Account" },
      {
        name: "description",
        content:
          "Explore VEXA 240 GSM luxury heavyweight combed cotton oversized t-shirt details, customer reviews, and related products.",
      },
    ],
  }),
  component: ProductDetailPage,
});

export type ColorOption = {
  name: string;
  hex: string;
  image: string;
  borderColor?: string;
};

export const COLOR_OPTIONS: ColorOption[] = [
  { name: "Luxury Cream & Gold", hex: "#F5F0E6", image: luxuryGold, borderColor: "#D4AF37" },
  { name: "Jet Black", hex: "#18181B", image: black, borderColor: "#3F3F46" },
  { name: "Ivory White", hex: "#FDFDFD", image: white, borderColor: "#E4E4E7" },
  { name: "Midnight Navy", hex: "#1E293B", image: navy, borderColor: "#334155" },
  { name: "Desert Sand", hex: "#D4C3A3", image: beige, borderColor: "#A89878" },
  { name: "Vintage Rust", hex: "#8B3A2B", image: rust, borderColor: "#65281B" },
  { name: "Charcoal Gray", hex: "#3F3F46", image: charcoal, borderColor: "#52525B" },
  { name: "Olive Green", hex: "#4A5D4E", image: olive, borderColor: "#38473B" },
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
      name: "Rahul Verma",
      rating: 5,
      date: "August 1, 2026",
      title: "Unbelievable quality and fit!",
      comment:
        "The 240 GSM weight is incredible. Heavy yet breathable cotton, drape is top notch. Wore it all day in the heat and the collar hasn't lost shape at all.",
      verified: true,
      helpfulCount: 24,
    },
    {
      id: "rev-2",
      name: "Ananya Sharma",
      rating: 5,
      date: "July 28, 2026",
      title: "Fits like high-end luxury streetwear",
      comment:
        "Ordered size M for an oversized look and it fits like a high-end designer brand. Stitching quality and bio-wash finish are super impressive.",
      verified: true,
      helpfulCount: 18,
    },
    {
      id: "rev-3",
      name: "Karan Patel",
      rating: 4,
      date: "July 20, 2026",
      title: "Great colorway & premium feel",
      comment:
        "Great colorway and luxurious heavy feel. Delivery took 2 days to Mumbai. Definitely buying the obsidian color next.",
      verified: true,
      helpfulCount: 9,
    },
    {
      id: "rev-4",
      name: "Vikram Singh",
      rating: 5,
      date: "July 12, 2026",
      title: "Best heavy tee in India",
      comment:
        "Hands down the best heavyweight tee in India right now. Fits true to the oversized aesthetic. Premium gold-tier packaging too!",
      verified: true,
      helpfulCount: 15,
    },
  ],
};

function ProductDetailPage() {
  const { id } = Route.useParams();
  const navigate = useNavigate();
  const { products, loading } = useProducts();
  const { isLoggedIn } = useAuth();

  // Find product by id
  const product = useMemo(() => {
    if (!products || products.length === 0) return null;
    return (
      products.find((p) => p.id === id) ||
      products.find((p) => p.id.toLowerCase() === id.toLowerCase()) ||
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

  // Review state
  const [reviews, setReviews] = useState<Review[]>([]);
  const [showReviewModal, setShowReviewModal] = useState(false);
  const [newRating, setNewRating] = useState(5);
  const [newName, setNewName] = useState("");
  const [newTitle, setNewTitle] = useState("");
  const [newComment, setNewComment] = useState("");
  const [helpfulClicked, setHelpfulClicked] = useState<Record<string, boolean>>({});

  // Sync color & image whenever current product changes
  useEffect(() => {
    if (product) {
      const match = COLOR_OPTIONS.find((c) =>
        c.name.toLowerCase().includes(product.color.toLowerCase()) ||
        product.color.toLowerCase().includes(c.name.toLowerCase())
      );
      if (match) {
        setSelectedColor(match);
        setSelectedImage(match.image);
      } else {
        const fallbackCol: ColorOption = {
          name: product.color || "Signature Drop",
          hex: "#C5A880",
          image: product.image || luxuryGold,
          borderColor: "#D4AF37",
        };
        setSelectedColor(fallbackCol);
        setSelectedImage(product.image || luxuryGold);
      }
    }
  }, [product]);

  // Scroll to top on ID change
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [id]);

  // Load reviews from localStorage or defaults
  useEffect(() => {
    if (!product) return;
    const storageKey = `vexa_reviews_${product.id}`;
    const saved = localStorage.getItem(storageKey);
    if (saved) {
      try {
        setReviews(JSON.parse(saved));
      } catch {
        setReviews(defaultReviewsMap.default);
      }
    } else {
      setReviews(defaultReviewsMap.default);
    }
  }, [product]);

  // Handle color swatch pick
  const handleSelectColor = (col: ColorOption) => {
    setSelectedColor(col);
    setSelectedImage(col.image);
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
    return [...sameCat, ...others].slice(0, 4);
  }, [products, product]);

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

  const discountOff = Math.round((1 - product.price / product.oldPrice) * 100);

  const getProductWithColor = () => ({
    ...product,
    color: selectedColor.name,
    image: selectedImage,
  });

  const handleAddToCart = () => {
    addToCart(getProductWithColor(), selectedSize, quantity);
    setAddedToast(true);
    setTimeout(() => setAddedToast(false), 3000);
  };

  const handleBuyNow = () => {
    addToCart(getProductWithColor(), selectedSize, quantity);
    if (isLoggedIn) {
      navigate({ to: "/dashboard", search: { tab: "cart" } });
    } else {
      localStorage.setItem("vexa_redirect_after_login", "/dashboard?tab=cart");
      navigate({ to: "/login" });
    }
  };

  // Average review calculation
  const avgRating =
    reviews.length > 0
      ? (reviews.reduce((acc, r) => acc + r.rating, 0) / reviews.length).toFixed(1)
      : product.rating.toFixed(1);

  return (
    <section className="mx-auto max-w-7xl px-5 py-12">
      {/* Toast Notification */}
      {addedToast && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 rounded-lg border border-gold/50 bg-card p-4 text-xs shadow-2xl animate-in slide-in-from-bottom duration-300">
          <CheckCircle2 className="size-5 text-gold shrink-0" />
          <div>
            <p className="font-bold text-foreground">Added to Bag</p>
            <p className="text-muted-foreground">
              {quantity}x {product.name} ({selectedColor.name}, Size {selectedSize})
            </p>
          </div>
          <Link
            to="/dashboard"
            search={{ tab: "cart" }}
            className="ml-3 rounded-sm bg-gold px-3 py-1.5 text-[10px] font-bold uppercase text-primary-foreground hover:opacity-90"
          >
            View Bag
          </Link>
        </div>
      )}


      {/* Main Product Grid */}
      <div className="grid gap-12 lg:grid-cols-12 items-start">
        {/* Left Column: Product Image Gallery */}
        <div className="lg:col-span-7 space-y-4">
          <Reveal>
            <div className="group relative overflow-hidden rounded-2xl border border-gold/40 bg-card shadow-goldy transition-all duration-500">
              <img
                key={selectedImage}
                src={selectedImage}
                alt={`${product.name} in ${selectedColor.name}`}
                className="h-[480px] sm:h-[580px] w-full object-cover object-center transition-all duration-700 group-hover:scale-105 animate-in fade-in duration-300"
              />
              <span className="absolute left-5 top-5 rounded-full border border-gold/50 bg-background/80 px-4 py-1.5 text-[10px] font-bold uppercase tracking-[0.25em] text-gold backdrop-blur-md">
                {product.category} Collection
              </span>
              <span className="btn-gold absolute right-5 top-5 rounded-full px-3.5 py-1.5 text-[10px] font-bold uppercase tracking-wider">
                {discountOff}% OFF
              </span>
              <span className="absolute bottom-5 left-5 rounded-full border border-gold/40 bg-black/80 px-4 py-1.5 text-[10px] font-semibold text-gold backdrop-blur-md">
                240 GSM Heavyweight Cotton
              </span>
            </div>
          </Reveal>

          {/* Colorway Image Thumbnails (Hidden on mobile responsive) */}
          <div className="hidden sm:block pt-2 space-y-2">
            <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
              Available Color Previews
            </p>
            <div className="grid grid-cols-4 sm:grid-cols-8 gap-2.5">
              {COLOR_OPTIONS.map((col) => (
                <button
                  key={col.name}
                  onClick={() => handleSelectColor(col)}
                  className={`group relative overflow-hidden rounded-xl border transition-all duration-300 cursor-pointer ${
                    selectedColor.name === col.name
                      ? "border-gold ring-2 ring-gold/60 scale-105 shadow-goldy"
                      : "border-border opacity-70 hover:opacity-100 hover:border-gold/50"
                  }`}
                  title={col.name}
                >
                  <img
                    src={col.image}
                    alt={col.name}
                    className="h-16 w-full object-cover"
                  />
                  <div className="absolute inset-0 bg-black/20 group-hover:bg-transparent transition-colors" />
                  {selectedColor.name === col.name && (
                    <div className="absolute inset-0 flex items-center justify-center bg-gold/20 backdrop-blur-[1px]">
                      <Check className="size-4 text-gold drop-shadow-md stroke-[3]" />
                    </div>
                  )}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Right Column: Product Details & Purchase Form */}
        <div className="lg:col-span-5 space-y-7">
          <Reveal>
            <div className="space-y-3">
              <span className="text-[10px] uppercase tracking-[0.3em] text-gold font-bold">
                VEXA Signature Series
              </span>
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

              {/* Price Row */}
              <div className="flex items-baseline gap-4 pt-3">
                <span className="font-display text-3xl sm:text-4xl font-bold text-gold">
                  ₹{product.price.toLocaleString("en-IN")}
                </span>
                <span className="text-base text-muted-foreground line-through">
                  ₹{product.oldPrice.toLocaleString("en-IN")}
                </span>
                <span className="rounded-full bg-gold/15 border border-gold/40 px-3 py-1 text-[10px] font-bold text-gold">
                  Save ₹{(product.oldPrice - product.price).toLocaleString("en-IN")} ({discountOff}%)
                </span>
              </div>
              <p className="text-[11px] text-muted-foreground">
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
                {COLOR_OPTIONS.map((col) => {
                  const isActive = selectedColor.name === col.name;
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
                {SIZES.map((sz) => (
                  <button
                    key={sz}
                    onClick={() => setSelectedSize(sz)}
                    className={`rounded-md border py-3 text-xs font-bold transition-all cursor-pointer ${
                      selectedSize === sz
                        ? "border-gold bg-gold text-primary-foreground shadow-goldy font-extrabold"
                        : "border-border bg-card text-foreground hover:border-gold/60"
                    }`}
                  >
                    {sz}
                  </button>
                ))}
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
                  onClick={() => setQuantity((q) => Math.max(1, q - 1))}
                  className="flex size-8 items-center justify-center rounded-md text-muted-foreground hover:text-gold hover:bg-surface cursor-pointer"
                >
                  <Minus className="size-3.5" />
                </button>
                <span className="w-8 text-center text-xs font-bold text-foreground">
                  {quantity}
                </span>
                <button
                  type="button"
                  onClick={() => setQuantity((q) => q + 1)}
                  className="flex size-8 items-center justify-center rounded-md text-muted-foreground hover:text-gold hover:bg-surface cursor-pointer"
                >
                  <Plus className="size-3.5" />
                </button>
              </div>
            </div>

            {/* CTA Action Buttons */}
            <div className="mt-8 grid grid-cols-1 sm:grid-cols-2 gap-4">
              <button
                onClick={handleAddToCart}
                className="btn-gold hover:btn-gold-hover flex items-center justify-center gap-2 rounded-sm py-4 text-xs font-bold uppercase tracking-widest cursor-pointer shadow-goldy"
              >
                <ShoppingBag className="size-4" /> Add to Cart
              </button>
              <button
                onClick={handleBuyNow}
                className="btn-outline-gold flex items-center justify-center gap-2 rounded-sm py-4 text-xs font-bold uppercase tracking-widest hover:bg-gold hover:text-primary-foreground cursor-pointer shadow-sm"
              >
                Buy Now
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
            onClick={() => setShowReviewModal(true)}
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

        {/* Reviews List */}
        <div className="space-y-6">
          {reviews.map((rev) => (
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
                  className={`flex items-center gap-1.5 hover:text-gold transition-colors ${
                    helpfulClicked[rev.id] ? "text-gold font-bold" : ""
                  }`}
                >
                  <ThumbsUp className="size-3.5" /> Helpful ({rev.helpfulCount})
                </button>
                <span>VEXA Verified Review</span>
              </div>
            </div>
          ))}
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

      {/* WRITE A REVIEW MODAL */}
      {showReviewModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4 overflow-y-auto animate-in fade-in duration-200">
          <div className="relative w-full max-w-lg rounded-2xl border border-gold/50 bg-card p-6 sm:p-8 shadow-2xl space-y-5">
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
    </section>
  );
}
