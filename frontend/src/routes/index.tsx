import { Link, useNavigate } from "react-router-dom";
import { useState, useMemo, useEffect, useRef } from "react";
import {
  ArrowRight,
  ChevronLeft,
  ChevronRight,
  Search,
  X,
  LayoutGrid,
  Palette,
  Lock,
  Truck,
  ShoppingBag,
} from "lucide-react";
import heroImg from "@/assets/hero.jpg";
import heroLuxuryImg from "@/assets/hero_luxury_tshirt.png";
import promoBanner1 from "@/assets/promo_banner_1.png";
import promoBanner2 from "@/assets/promo_banner_2.png";
import { products as defaultProducts, SIZES, useProducts } from "@/lib/products";
import { ProductCard } from "@/components/ProductCard";
import { Reveal } from "@/components/Reveal";
import { useAuth } from "@/lib/auth";



const heroBanners = [
  {
    tag: "Elevate your everyday style",
    title: "Premium T-Shirt Collection",
    highlight: "Collection",
    description: "Engineered in 240 GSM heavyweight cotton, finished by hand, and cut for the modern oversized silhouette. This is VEXA — wear confidence, wear style.",
    ctaText: "Shop the drop",
    ctaLink: "/products",
    secondaryText: "Our story",
    secondaryLink: "/about",
    image: heroLuxuryImg,
    badgeText: "Signature Drop",
    discount: "30% Off",
  },
  {
    tag: "New Streetwear Edition",
    title: "Heavyweight Oversized Fit",
    highlight: "Oversized Fit",
    description: "Bio-washed combed cotton with double-stitched collar reinforcement. Sculpted drape designed for lasting luxury and everyday comfort.",
    ctaText: "Explore Catalog",
    ctaLink: "/products",
    secondaryText: "Learn More",
    secondaryLink: "/about",
    image: heroLuxuryImg,
    badgeText: "240 GSM Heavy",
    discount: "Free Ship",
  },
  {
    tag: "Bespoke Streetwear Essentials",
    title: "Signature Heavyweight Edition",
    highlight: "Heavyweight",
    description: "Experience handcrafted luxury with 240 GSM combed cotton, custom boxy drape, and premium drop-shoulder construction.",
    ctaText: "Shop Collection",
    ctaLink: "/products",
    secondaryText: "Customer Support",
    secondaryLink: "/dashboard?tab=support",
    image: heroLuxuryImg,
    badgeText: "Signature Fit",
    discount: "Express",
  },
];

const promoCarouselBanners = [
  {
    tag: "LIMITED EDITION DROP",
    title: "URBAN SILHOUETTE COLLECTION",
    subtitle: "FLAT 30% OFF STOREWIDE",
    text: "Sculpted from 240 GSM bio-washed heavy cotton with double-stitched collar reinforcement. Engineered for superior drape and longevity.",
    ctaText: "EXPLORE COLLECTION",
    ctaLink: "/products",
    image: promoBanner1,
  },
  {
    tag: "EXCLUSIVE STREETWEAR DROP",
    title: "HEAVYWEIGHT BOX-FIT TEES",
    subtitle: "240 GSM COMBED COTTON ESSENTIALS",
    text: "Engineered for superior structure, premium drop-shoulder aesthetic, and zero shrinkage with long-staple combed cotton.",
    ctaText: "EXPLORE COLLECTION",
    ctaLink: "/products",
    image: promoBanner2,
  },
  {
    tag: "VEXA SIGNATURE ESSENTIALS",
    title: "240 GSM HEAVYWEIGHT FIT",
    subtitle: "COMFORT MEETS LUXURY STREETWEAR",
    text: "Engineered for lasting quality, zero color bleeding, and pre-shrunk combed long-staple luxury cotton.",
    ctaText: "SHOP CATALOG",
    ctaLink: "/products",
    image: heroLuxuryImg,
  },
];

export function Home() {
  const navigate = useNavigate();
  const { products } = useProducts();

  // Immediate Product URL redirect for WhatsApp & external shared links
  useEffect(() => {
    if (typeof window !== "undefined") {
      const searchParams = new URLSearchParams(window.location.search);
      const productId = searchParams.get("id") || searchParams.get("product");
      if (productId) {
        navigate(`/product/${productId}`, { replace: true });
      }
    }
  }, [navigate]);

  const hasProductIdInUrl =
    typeof window !== "undefined" &&
    (new URLSearchParams(window.location.search).has("id") ||
      new URLSearchParams(window.location.search).has("product"));

  const { user, isLoggedIn } = useAuth();

  const greeting = useMemo(() => {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 12) return "GOOD MORNING";
    if (hour >= 12 && hour < 17) return "GOOD AFTERNOON";
    if (hour >= 17 && hour < 21) return "GOOD EVENING";
    return "GOOD NIGHT";
  }, []);

  const cleanDisplayName = useMemo(() => {
    let name = user?.name?.trim();
    if (!name || name.toLowerCase() === "collector" || name.toLowerCase().includes("guest")) {
      return "TATUKULA EDUKONDALU";
    }
    return name.toUpperCase();
  }, [user]);

  const [selectedCategory, setSelectedCategory] = useState<string>("All");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [heroIndex, setHeroIndex] = useState(0);
  const [bannerIndex, setBannerIndex] = useState(0);
  const newArrivalsRef = useRef<HTMLDivElement>(null);
  const featuredRef = useRef<HTMLDivElement>(null);

  const scrollContainer = (ref: React.RefObject<HTMLDivElement>, direction: "left" | "right") => {
    if (ref.current) {
      const scrollAmount = direction === "left" ? -300 : 300;
      ref.current.scrollBy({ left: scrollAmount, behavior: "smooth" });
    }
  };

  // Dynamic Media State managed by Admin Portal
  const [heroImgState, setHeroImgState] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("vexa_home_hero_img") || heroLuxuryImg;
    }
    return heroLuxuryImg;
  });
  const [banner1ImgState, setBanner1ImgState] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("vexa_home_banner1_img") || promoBanner1;
    }
    return promoBanner1;
  });
  const [banner2ImgState, setBanner2ImgState] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("vexa_home_banner2_img") || promoBanner2;
    }
    return promoBanner2;
  });

  useEffect(() => {
    if (typeof window === "undefined") return;
    const updateMedia = () => {
      setHeroImgState(localStorage.getItem("vexa_home_hero_img") || heroLuxuryImg);
      setBanner1ImgState(localStorage.getItem("vexa_home_banner1_img") || promoBanner1);
      setBanner2ImgState(localStorage.getItem("vexa_home_banner2_img") || promoBanner2);
    };
    window.addEventListener("vexa_media_updated", updateMedia);
    return () => window.removeEventListener("vexa_media_updated", updateMedia);
  }, []);

  const activePromoBanners = useMemo(() => [
    {
      tag: "LIMITED EDITION DROP",
      title: "URBAN SILHOUETTE COLLECTION",
      subtitle: "FLAT 30% OFF STOREWIDE",
      text: "Sculpted from 240 GSM bio-washed heavy cotton with double-stitched collar reinforcement. Engineered for superior drape and longevity.",
      ctaText: "EXPLORE COLLECTION",
      ctaLink: "/products",
      image: banner1ImgState,
      imgPosition: "object-top md:object-right",
    },
    {
      tag: "EXCLUSIVE STREETWEAR DROP",
      title: "HEAVYWEIGHT BOX-FIT TEES",
      subtitle: "240 GSM COMBED COTTON ESSENTIALS",
      text: "Engineered for superior structure, premium drop-shoulder aesthetic, and zero shrinkage with long-staple combed cotton.",
      ctaText: "EXPLORE COLLECTION",
      ctaLink: "/products",
      image: banner2ImgState,
      imgPosition: "object-top md:object-right",
    },
    {
      tag: "VEXA SIGNATURE ESSENTIALS",
      title: "240 GSM HEAVYWEIGHT FIT",
      subtitle: "COMFORT MEETS LUXURY STREETWEAR",
      text: "Engineered for lasting quality, zero color bleeding, and pre-shrunk combed long-staple luxury cotton.",
      ctaText: "SHOP CATALOG",
      ctaLink: "/products",
      image: heroImgState,
      imgPosition: "object-top md:object-[15%_center]",
    },
  ], [banner1ImgState, banner2ImgState, heroImgState]);




  useEffect(() => {
    const heroTimer = setInterval(() => {
      setHeroIndex((prev) => (prev + 1) % heroBanners.length);
    }, 5000);
    return () => clearInterval(heroTimer);
  }, []);

  // Exact 5 New Arrivals items matching Mobile Flutter App 1:1
  const newArrivals = useMemo(() => {
    const targetNewArrivalIds = new Set(["vx-08", "vx-12", "vx-07", "vx-04", "vx-06"]);
    const arrivals = products.filter((p) => targetNewArrivalIds.has(p.id.toLowerCase().trim()) || p.isNewDrop);
    if (arrivals.length > 0) return arrivals;
    return products.slice(0, 5);
  }, [products]);

  // Exact 5 Featured Collection items matching Mobile Flutter App 1:1 (plus custom products)
  const filteredProducts = useMemo(() => {
    const targetFeaturedIds = new Set(["vx-00", "vx-01", "vx-02", "vx-03", "vx-05"]);
    const newArrivalIds = new Set(newArrivals.map((n) => n.id.toLowerCase().trim()));
    return products.filter((p) => {
      const pid = p.id.toLowerCase().trim();
      return targetFeaturedIds.has(pid) || (!newArrivalIds.has(pid) && !targetFeaturedIds.has(pid));
    });
  }, [products, newArrivals]);

  const searchResults = useMemo(() => {
    if (!searchQuery.trim()) return null;
    const q = searchQuery.toLowerCase().trim();
    return products.filter((p) =>
      p.name.toLowerCase().includes(q) ||
      p.color.toLowerCase().includes(q) ||
      p.category.toLowerCase().includes(q) ||
      (p.description || "").toLowerCase().includes(q)
    );
  }, [products, searchQuery]);

  if (hasProductIdInUrl) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background px-4 py-24">
        <div className="text-center space-y-4">
          <div className="mx-auto size-10 animate-spin rounded-full border-2 border-gold border-t-transparent" />
          <p className="text-xs font-bold uppercase tracking-widest text-gold">
            Opening Product…
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="home-page-root no-scrollbar w-full overflow-x-hidden pt-16 sm:pt-20 md:pt-28">
      {/* 0. MOBILE GREETING HEADER (Matches Flutter Mobile App 1:1) */}
      <div className="block md:hidden px-4 pt-2 pb-2">
        <div className="w-full rounded-2xl border border-[#E5C158]/70 bg-gradient-to-br from-[#FFFDF2] to-[#FFF4D1] dark:from-[#1E1B15] dark:to-[#17140E] px-5 py-4.5 shadow-sm">
          <span className="block font-display text-[13px] font-black uppercase tracking-[0.16em] text-[#B8860B] leading-none mb-2">
            {greeting}
          </span>
          <h2 className="font-display text-lg xs:text-xl font-bold uppercase tracking-[0.05em] text-[#0F172A] dark:text-foreground leading-tight">
            {cleanDisplayName}
          </h2>
        </div>
      </div>

      {/* 0. HERO BANNER SECTION (Desktop & Tablet only; hidden on Mobile) */}
      <section className="hidden md:block mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pt-2 sm:pt-4 pb-8 sm:pb-12 border-b border-border/30">
        <div className="grid grid-cols-1 gap-8 sm:gap-10 lg:grid-cols-2 lg:items-center">
          <Reveal>
            <div className="space-y-4 sm:space-y-6">
              <h1 className="font-display text-3xl xs:text-4xl sm:text-6xl lg:text-7xl font-extrabold uppercase tracking-tight leading-[1.08] sm:leading-[1.05] text-foreground">
                PREMIUM<br />
                T-SHIRT<br />
                <span className="text-[#B8860B]">COLLECTION</span>
              </h1>
              <p className="max-w-xl text-xs xs:text-sm sm:text-base leading-relaxed text-muted-foreground font-normal">
                Engineered in 240 GSM heavyweight cotton, finished by hand, and cut for the modern oversized silhouette. This is VEXA — wear confidence, wear style.
              </p>
              <div className="flex flex-wrap items-center gap-3 sm:gap-4 pt-1 sm:pt-2">
                <Link
                  to="/products"
                  className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2 rounded-sm px-6 py-3 sm:px-8 sm:py-3.5 text-xs font-bold uppercase tracking-wider shadow-md"
                >
                  SHOP THE DROP <ArrowRight className="size-4" />
                </Link>
              </div>
            </div>
          </Reveal>
          <Reveal delay={200}>
            <div className="relative mx-auto max-w-lg overflow-hidden rounded-[28px] sm:rounded-[36px] border-2 border-[#B8860B]/40 bg-card p-2.5 sm:p-3 shadow-2xl">
              <img
                src={heroImgState}
                alt="VEXA Premium T-Shirt Collection"
                className="h-[280px] xs:h-[340px] sm:h-[480px] lg:h-[520px] w-full object-cover rounded-[20px] sm:rounded-[28px]"
              />
              <span className="absolute left-5 sm:left-7 top-5 sm:top-7 rounded-full border border-[#B8860B]/30 bg-[#f4efe6] px-3.5 py-1 sm:px-4 sm:py-1.5 text-[10px] sm:text-[11px] font-extrabold uppercase tracking-[0.2em] text-[#1c1917] shadow-md">
                CUSTOM SERVICE
              </span>
            </div>
          </Reveal>
        </div>
      </section>

      {/* 1. LUXURY PROMO BANNER CAROUSEL SLIDER */}
      <section id="promotional-showcase" className="scroll-mt-28 mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pb-8 pt-3 md:pt-8">
        <Reveal className="mb-3.5 text-left md:text-center">
          <p className="text-[10px] sm:text-xs font-bold uppercase tracking-[0.25em] text-[#B8860B]">
            FEATURED HIGHLIGHTS
          </p>
          <h2 className="mt-1 font-display text-xl sm:text-3xl lg:text-4xl font-bold text-foreground">
            PROMOTIONAL <span className="text-[#B8860B]">SHOWCASE</span>
          </h2>
        </Reveal>

        <div className="relative overflow-hidden rounded-2xl sm:rounded-3xl border border-[#B8860B]/40 bg-card shadow-xl transition-all hover:border-[#B8860B]">
          <div className="relative h-[420px] sm:min-h-[480px] lg:min-h-[520px] w-full overflow-hidden flex flex-col md:flex-row items-stretch">
            {/* Background / Right Side Image Container */}
            <div className="absolute inset-0 md:left-auto md:right-0 md:w-1/2 lg:w-[48%] h-full overflow-hidden">
              <img
                src={activePromoBanners[bannerIndex].image}
                alt={activePromoBanners[bannerIndex].title}
                className="h-full w-full object-cover object-top md:object-center transition-all duration-700"
              />
              {/* Desktop Left-to-Right Blend Gradient */}
              <div className="hidden md:block absolute inset-y-0 left-0 w-28 bg-gradient-to-r from-card via-card/80 to-transparent pointer-events-none" />
            </div>

            {/* Mobile Direct Tap Link */}
            <Link
              to={activePromoBanners[bannerIndex].ctaLink}
              className="md:hidden absolute inset-0 z-10"
              aria-label={activePromoBanners[bannerIndex].title}
            />

            {/* Desktop Left Side Content Container (Hidden on Mobile to keep image clean) */}
            <div className="hidden md:flex relative z-10 flex-col justify-center w-full md:w-1/2 lg:w-[55%] p-6 sm:p-10 lg:p-14 pl-14 sm:pl-20 lg:pl-24 pr-6 sm:pr-8 space-y-3.5 sm:space-y-4.5">
              <h3 className="font-display text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-extrabold uppercase leading-[1.12] text-foreground tracking-tight max-w-xl">
                {activePromoBanners[bannerIndex].title}
              </h3>

              <p className="text-xs sm:text-sm md:text-base leading-relaxed text-muted-foreground font-normal max-w-lg">
                {activePromoBanners[bannerIndex].text}
              </p>

              <div className="pt-2 sm:pt-4">
                <Link
                  to={activePromoBanners[bannerIndex].ctaLink}
                  className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2.5 rounded-sm px-6 py-3 sm:px-8 sm:py-3.5 text-xs sm:text-sm font-bold uppercase tracking-wider shadow-md"
                >
                  {activePromoBanners[bannerIndex].ctaText} <ArrowRight className="size-4 md:size-5" />
                </Link>
              </div>
            </div>

            {/* Left Navigation Arrow Button (Desktop Only) */}
            <button
              type="button"
              onClick={() => setBannerIndex((prev) => (prev - 1 + activePromoBanners.length) % activePromoBanners.length)}
              className="hidden md:flex absolute left-2 sm:left-4 top-1/2 -translate-y-1/2 z-30 items-center justify-center text-[#F5D77F] hover:text-[#D4AF37] hover:scale-125 active:scale-95 transition-all cursor-pointer drop-shadow-[0_2px_8px_rgba(0,0,0,0.85)] bg-transparent border-none p-1.5"
              aria-label="Previous Showcase Banner"
              title="Previous Banner"
            >
              <ChevronLeft className="size-8 sm:size-9 stroke-[2.5]" />
            </button>

            {/* Right Navigation Arrow Button (Desktop Only) */}
            <button
              type="button"
              onClick={() => setBannerIndex((prev) => (prev + 1) % activePromoBanners.length)}
              className="hidden md:flex absolute right-2 sm:right-4 top-1/2 -translate-y-1/2 z-30 items-center justify-center text-[#F5D77F] hover:text-[#D4AF37] hover:scale-125 active:scale-95 transition-all cursor-pointer drop-shadow-[0_2px_8px_rgba(0,0,0,0.85)] bg-transparent border-none p-1.5"
              aria-label="Next Showcase Banner"
              title="Next Banner"
            >
              <ChevronRight className="size-8 sm:size-9 stroke-[2.5]" />
            </button>
          </div>
        </div>

        {/* Showcase Banner Dots Indicator (Hidden on Mobile to match screenshot) */}
        <div className="hidden md:flex items-center justify-center gap-2 pt-4">
          {activePromoBanners.map((_, i) => (
            <button
              key={i}
              type="button"
              onClick={() => setBannerIndex(i)}
              className={`h-1.5 rounded-full transition-all duration-300 cursor-pointer ${
                bannerIndex === i ? "w-6 bg-gold shadow-sm" : "w-2 bg-border hover:bg-gold/50"
              }`}
              aria-label={`Slide ${i + 1}`}
            />
          ))}
        </div>
      </section>

      {/* 2. NEW ARRIVALS */}
      <section className="mx-auto max-w-7xl px-4 sm:px-5 py-6 md:py-8 border-t border-border/40">
        <div className="flex items-center justify-between mb-3.5 gap-4">
          <div>
            <p className="text-[10px] sm:text-xs font-bold uppercase tracking-[0.25em] text-[#B8860B]">
              LATEST DROPS
            </p>
            <h2 className="mt-0.5 font-display text-xl sm:text-3xl font-bold text-foreground">
              NEW ARRIVALS
            </h2>
          </div>
          <Link
            to="/products"
            className="inline-flex items-center gap-1 rounded-full border border-[#B8860B]/40 bg-[#B8860B]/15 px-3 py-1.5 text-[11px] font-bold text-[#B8860B] hover:bg-gold hover:text-primary-foreground transition-all shrink-0"
          >
            <span>Explore All</span>
            <ArrowRight className="size-3.5" />
          </Link>
        </div>

        {/* New Arrivals Horizontal Scroll */}
        <div
          ref={newArrivalsRef}
          className="mt-3 flex gap-3 sm:gap-5 overflow-x-auto pb-4 pt-1 snap-x snap-mandatory scroll-smooth no-scrollbar"
        >
          {newArrivals.map((p, i) => (
            <div
              key={`new-${p.id}`}
              className="w-[180px] xs:w-[190px] sm:w-[260px] md:w-[300px] shrink-0 snap-start flex flex-col h-full"
            >
              <Reveal delay={i * 90} className="h-full w-full flex flex-col">
                <ProductCard product={p} />
              </Reveal>
            </div>
          ))}
        </div>
      </section>



      {/* 4. FEATURED COLLECTION */}
      <section className="mx-auto max-w-7xl px-4 sm:px-5 py-8 border-t border-border/30">
        <div className="flex items-center justify-between gap-4 mb-4">
          <div>
            <p className="text-[10px] sm:text-xs uppercase tracking-[0.3em] text-gold font-bold">Explore the catalog</p>
            <h2 className="mt-0.5 font-display text-2xl sm:text-4xl font-bold text-foreground">Featured Collection</h2>
          </div>
          <Link
            to="/products"
            className="inline-flex items-center gap-1.5 rounded-full border border-gold/40 bg-gold/10 px-3 py-1.5 text-[11px] font-bold uppercase tracking-wider text-gold hover:bg-gold hover:text-primary-foreground transition-all shrink-0"
          >
            View All <ArrowRight className="size-3.5" />
          </Link>
        </div>

        {/* Featured Collection Horizontal Scroll */}
        <div
          ref={featuredRef}
          className="mt-3 flex gap-4 sm:gap-5 overflow-x-auto pb-4 pt-1 snap-x snap-mandatory scroll-smooth no-scrollbar"
        >
          {filteredProducts.map((p, i) => (
            <div
              key={p.id}
              className="w-[240px] xs:w-[270px] sm:w-[300px] shrink-0 snap-start flex flex-col h-full"
            >
              <Reveal delay={(i % 4) * 90} className="h-full w-full flex flex-col">
                <ProductCard product={p} />
              </Reveal>
            </div>
          ))}
        </div>
      </section>






      {/* 5. HOW TO BOOK YOUR VEXA TEE (Exact 1:1 Mobile Responsive Match with Flutter App) */}
      <section className="mx-auto max-w-xl px-4 pt-6 pb-20 sm:pb-24">
        <div className="rounded-[24px] border-[1.5px] border-[#E5C158]/70 bg-gradient-to-br from-[#FFFDF5] to-[#FFF4D8] dark:from-[#1E293B]/90 dark:to-[#0F172A]/90 p-5 sm:p-6 shadow-[0_6px_18px_rgba(184,134,11,0.12)]">
          {/* Title Header */}
          <div className="text-left">
            <h2 className="font-display text-[16.5px] sm:text-[18px] font-black tracking-[0.05em] text-[#0F172A] dark:text-foreground uppercase">
              HOW TO BOOK YOUR VEXA TEE
            </h2>
            <p className="mt-1 text-[13px] text-slate-500 dark:text-muted-foreground leading-snug">
              4 easy steps from catalog selection to custom doorstep delivery.
            </p>
          </div>

          {/* 4 Step Cards */}
          <div className="mt-5 space-y-3.5">
            {[
              {
                stepNum: "01",
                tag: "STEP 01",
                title: "Browse Luxury Catalog Drops",
                subtitle: "Explore 240 GSM luxury catalog drops and handpicked oversized streetwear silhouettes.",
                icon: LayoutGrid,
              },
              {
                stepNum: "02",
                tag: "STEP 02",
                title: "Choose Fit & Colorway",
                subtitle: "Select long-staple combed cotton colorways, drop-shoulder fits, and preferred sizes.",
                icon: Palette,
              },
              {
                stepNum: "03",
                tag: "STEP 03",
                title: "Instant Secure Checkout",
                subtitle: "Complete order seamlessly using Razorpay, UPI, NetBanking, Credit Cards, or COD.",
                icon: Lock,
              },
              {
                stepNum: "04",
                tag: "STEP 04",
                title: "Doorstep Luxury Delivery",
                subtitle: "Track your shipment live from VEXA master tailors to your doorstep with luxury packaging.",
                icon: Truck,
              },
            ].map((item, idx) => {
              const StepIcon = item.icon;
              return (
                <div
                  key={idx}
                  className="rounded-[16px] border border-[#E5C158]/50 bg-white dark:bg-[#0F172A] p-4 shadow-[0_2px_10px_rgba(0,0,0,0.03)] flex items-start gap-3.5 transition-all duration-200 hover:border-[#D4AF37]"
                >
                  {/* Icon Badge Circle */}
                  <div className="size-11 rounded-full bg-[#FFF4D1] dark:bg-amber-950/40 border-[1.2px] border-[#D4AF37]/60 flex items-center justify-center shrink-0 mt-0.5 shadow-xs">
                    <StepIcon className="size-5 text-[#A67C00] dark:text-gold" strokeWidth={2.2} />
                  </div>

                  {/* Title & Description Content */}
                  <div className="flex-1 min-w-0">
                    <div className="inline-block px-1.5 py-0.5 rounded-[4px] bg-[#E5BF4E]/20 text-[#A67C00] dark:text-gold text-[9.5px] font-black tracking-[0.08em] uppercase">
                      {item.tag}
                    </div>
                    <h3 className="mt-1 font-bold text-[14.5px] text-[#0F172A] dark:text-foreground leading-tight">
                      {item.title}
                    </h3>
                    <p className="mt-1 text-[12px] text-slate-500 dark:text-muted-foreground leading-[1.38]">
                      {item.subtitle}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Radiant VEXA Gold Action CTA Button */}
          <Link
            to="/products"
            className="mt-4 flex h-[50px] w-full items-center justify-center gap-2 rounded-[24px] border border-white/80 bg-gradient-to-b from-[#FBE89C] via-[#F2D370] to-[#E5BF4E] text-[#0F172A] shadow-[0_4px_12px_rgba(242,211,112,0.4)] transition-transform duration-200 hover:scale-[1.01] active:scale-[0.99] cursor-pointer"
          >
            <ShoppingBag className="size-5 text-[#0F172A]" strokeWidth={2.2} />
            <span className="font-display text-[13.5px] font-black tracking-[0.09em] uppercase text-[#0F172A]">
              EXPLORE CATALOG NOW
            </span>
          </Link>
        </div>
      </section>
    </div>
  );
}
