import { Link, useNavigate } from "react-router-dom";
import { useState, useMemo, useEffect, useRef } from "react";
import {
  Shirt,
  Wind,
  Sparkles,
  ShieldCheck,
  Truck,
  BadgeIndianRupee,
  MessageCircle,
  ArrowRight,
  ChevronLeft,
  ChevronRight,
  Search,
  X,
} from "lucide-react";
import heroImg from "@/assets/hero.jpg";
import heroLuxuryImg from "@/assets/hero_luxury_tshirt.png";
import promoBanner1 from "@/assets/promo_banner_1.png";
import promoBanner2 from "@/assets/promo_banner_2.png";
import { products as defaultProducts, SIZES, useProducts } from "@/lib/products";
import { ProductCard } from "@/components/ProductCard";
import { Reveal } from "@/components/Reveal";
import { useAuth } from "@/lib/auth";

const features = [
  { icon: Shirt, title: "Premium Cotton Fabric", text: "240 GSM combed long-staple cotton." },
  { icon: Sparkles, title: "Oversized Modern Fit", text: "Drop shoulder, sculpted drape." },
  { icon: Wind, title: "Soft & Breathable", text: "Bio-washed for all-day comfort." },
  { icon: ShieldCheck, title: "Wrinkle Resistant", text: "Holds its shape wash after wash." },
];

const services = [
  { icon: MessageCircle, title: "WhatsApp Order", text: "Order in one message" },
  { icon: Truck, title: "Fast Delivery", text: "2–4 day dispatch" },
  { icon: BadgeIndianRupee, title: "Cash on Delivery", text: "Pay when it arrives" },
  { icon: ShieldCheck, title: "Quality Guarantee", text: "30-day easy returns" },
];

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
    tag: "Bespoke Branding & Concierge",
    title: "Custom Tee Booking",
    highlight: "Booking",
    description: "Order personalized colorways, custom logo embroidery, and bulk tee reservations directly from your user dashboard.",
    ctaText: "Book Custom Tee",
    ctaLink: "/dashboard?tab=booking",
    secondaryText: "Customer Support",
    secondaryLink: "/dashboard?tab=support",
    image: heroLuxuryImg,
    badgeText: "Custom Service",
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
    tag: "BESPOKE CUSTOMISATION",
    title: "BOOK YOUR CUSTOM TEE",
    subtitle: "PERSONALIZED EMBROIDERY & BULK ORDERS",
    text: "Personalize colorways, custom embroidery & bulk orders directly from your user dashboard with live tracking and concierge support.",
    ctaText: "BOOK CUSTOM TEE",
    ctaLink: "/dashboard",
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
  const { products } = useProducts();
  const [selectedCategory, setSelectedCategory] = useState<string>("All");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [featureIndex, setFeatureIndex] = useState(0);
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
      imgPosition: "object-right sm:object-[80%_center]",
    },
    {
      tag: "BESPOKE CUSTOMISATION",
      title: "BOOK YOUR CUSTOM TEE",
      subtitle: "PERSONALIZED EMBROIDERY & BULK ORDERS",
      text: "Personalize colorways, custom embroidery & bulk orders directly from your user dashboard with live tracking and concierge support.",
      ctaText: "BOOK CUSTOM TEE",
      ctaLink: "/dashboard",
      image: banner2ImgState,
      imgPosition: "object-right sm:object-[85%_center]",
    },
    {
      tag: "VEXA SIGNATURE ESSENTIALS",
      title: "240 GSM HEAVYWEIGHT FIT",
      subtitle: "COMFORT MEETS LUXURY STREETWEAR",
      text: "Engineered for lasting quality, zero color bleeding, and pre-shrunk combed long-staple luxury cotton.",
      ctaText: "SHOP CATALOG",
      ctaLink: "/products",
      image: heroImgState,
      imgPosition: "object-[15%_center]",
    },
  ], [banner1ImgState, banner2ImgState, heroImgState]);

  useEffect(() => {
    const timer = setInterval(() => {
      setFeatureIndex((prev) => (prev + 1) % features.length);
    }, 3500);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    const bannerTimer = setInterval(() => {
      setBannerIndex((prev) => (prev + 1) % activePromoBanners.length);
    }, 4500);
    return () => clearInterval(bannerTimer);
  }, [activePromoBanners.length]);

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

  return (
    <div className="home-page-root no-scrollbar w-full overflow-x-hidden pt-16 sm:pt-20 md:pt-28">
      {/* 0. HERO BANNER SECTION (Visible on Desktop View >= md) */}
      <section className="hidden md:block mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pt-4 pb-12 border-b border-border/30">
        <div className="grid grid-cols-1 gap-10 lg:grid-cols-2 lg:items-center">
          <Reveal>
            <div className="space-y-6">
              <h1 className="font-display text-5xl sm:text-6xl lg:text-7xl font-extrabold uppercase tracking-tight leading-[1.05] text-foreground">
                PREMIUM<br />
                T-SHIRT<br />
                <span className="text-[#B8860B]">COLLECTION</span>
              </h1>
              <p className="max-w-xl text-sm sm:text-base leading-relaxed text-muted-foreground font-normal">
                Engineered in 240 GSM heavyweight cotton, finished by hand, and cut for the modern oversized silhouette. This is VEXA — wear confidence, wear style.
              </p>
              <div className="flex flex-wrap items-center gap-4 pt-2">
                <Link
                  to="/products"
                  className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2 rounded-sm px-8 py-3.5 text-xs font-bold uppercase tracking-wider shadow-md"
                >
                  SHOP THE DROP <ArrowRight className="size-4" />
                </Link>
                <Link
                  to="/about"
                  className="btn-outline-gold inline-flex items-center gap-2 rounded-sm px-8 py-3.5 text-xs font-bold uppercase tracking-wider hover:bg-gold hover:text-primary-foreground"
                >
                  OUR STORY
                </Link>
              </div>
            </div>
          </Reveal>
          <Reveal delay={200}>
            <div className="relative mx-auto max-w-lg overflow-hidden rounded-[36px] border-2 border-[#B8860B]/40 bg-card p-3 shadow-2xl">
              <img
                src={heroImgState}
                alt="VEXA Premium T-Shirt Collection"
                className="h-[420px] sm:h-[480px] lg:h-[520px] w-full object-cover rounded-[28px]"
              />
              <span className="absolute left-7 top-7 rounded-full border border-[#B8860B]/30 bg-[#f4efe6] px-4 py-1.5 text-[11px] font-extrabold uppercase tracking-[0.2em] text-[#1c1917] shadow-md">
                CUSTOM SERVICE
              </span>
            </div>
          </Reveal>
        </div>
      </section>

      {/* 1. LUXURY PROMO BANNER CAROUSEL SLIDER */}
      <section id="promotional-showcase" className="scroll-mt-28 mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pb-12 pt-8">
        <Reveal className="mb-6 text-center">
          <p className="text-[10px] sm:text-xs font-extrabold uppercase tracking-[0.3em] text-[#B8860B]">Featured Highlights</p>
          <h2 className="mt-1 font-display text-2xl sm:text-3xl lg:text-4xl font-extrabold text-foreground">
            Promotional <span className="text-[#B8860B]">Showcase</span>
          </h2>
        </Reveal>

        <div className="relative overflow-hidden rounded-2xl sm:rounded-3xl border-2 border-[#B8860B]/40 bg-card shadow-2xl transition-all hover:border-[#B8860B]">
          <div className="relative min-h-[340px] xs:min-h-[380px] sm:min-h-[440px] md:min-h-[540px] lg:min-h-[580px] xl:min-h-[620px] w-full overflow-hidden">
            {/* Full Width Background Image Across Entire Card */}
            <img
              src={activePromoBanners[bannerIndex].image}
              alt={activePromoBanners[bannerIndex].title}
              className={`absolute inset-0 h-full w-full object-cover transition-all duration-700 ${
                activePromoBanners[bannerIndex].imgPosition || "object-right"
              }`}
            />
            {/* Soft gradient overlay for text readability on left side */}
            <div className="absolute inset-0 bg-gradient-to-r from-background/95 via-background/65 to-transparent max-w-3xl lg:max-w-4xl" />

            {/* Left Side Content Container */}
            <div className="relative z-10 flex h-full min-h-[340px] xs:min-h-[380px] sm:min-h-[440px] md:min-h-[540px] lg:min-h-[580px] xl:min-h-[620px] max-w-2xl lg:max-w-3xl flex-col justify-center p-6 sm:p-12 lg:p-20 xl:p-24">
              <span className="inline-block w-fit rounded-full border border-[#B8860B]/60 bg-[#f4efe6] px-3.5 py-1 text-[10px] sm:text-xs md:px-5 md:py-1.5 md:text-xs font-extrabold uppercase tracking-[0.25em] text-[#1c1917] shadow-md">
                {activePromoBanners[bannerIndex].tag}
              </span>

              <h3 className="mt-3 sm:mt-5 font-display text-2xl xs:text-3xl sm:text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-extrabold leading-[1.1] text-foreground">
                {activePromoBanners[bannerIndex].title}
              </h3>

              <p className="mt-2.5 sm:mt-3 text-xs sm:text-sm md:text-base lg:text-lg font-extrabold uppercase tracking-wider text-[#B8860B]">
                ✨ {activePromoBanners[bannerIndex].subtitle} ✨
              </p>

              <p className="mt-3 text-xs sm:text-sm md:text-base lg:text-lg leading-relaxed text-muted-foreground hidden xs:block font-normal max-w-xl">
                {activePromoBanners[bannerIndex].text}
              </p>

              <div className="mt-6 sm:mt-8 md:mt-10">
                <Link
                  to={activePromoBanners[bannerIndex].ctaLink}
                  className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2.5 rounded-sm px-7 py-3 sm:px-8 sm:py-3.5 md:px-10 md:py-4 text-xs md:text-sm font-bold uppercase tracking-wider shadow-md"
                >
                  {activePromoBanners[bannerIndex].ctaText} <ArrowRight className="size-4 md:size-5" />
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* Carousel Indicators */}
        <div className="mt-4 flex justify-center gap-2">
          {activePromoBanners.map((_, idx) => (
            <button
              key={idx}
              onClick={() => setBannerIndex(idx)}
              className={`h-2 rounded-full transition-all duration-300 ${
                idx === bannerIndex ? "w-8 bg-[#B8860B]" : "w-2 bg-border hover:bg-[#B8860B]/50"
              }`}
              title={`Go to slide ${idx + 1}`}
            />
          ))}
        </div>
      </section>

      {/* 2. NEW ARRIVALS */}
      <section className="mx-auto max-w-7xl px-4 sm:px-5 py-8 border-t border-border/40">
        <div className="flex items-center justify-between mb-4 gap-4">
          <div>
            <p className="text-[10px] sm:text-xs font-bold uppercase tracking-[0.3em] text-gold">LATEST DROPS</p>
            <h2 className="mt-0.5 font-display text-2xl sm:text-4xl font-bold text-foreground">
              New Arrivals
            </h2>
          </div>
          <Link
            to="/products"
            className="inline-flex items-center gap-1.5 rounded-full border border-gold/40 bg-gold/10 px-3 py-1.5 text-[11px] font-bold uppercase tracking-wider text-gold hover:bg-gold hover:text-primary-foreground transition-all shrink-0"
          >
            Explore All ({products.length}) <ArrowRight className="size-3.5" />
          </Link>
        </div>

        {/* New Arrivals Horizontal Scroll */}
        <div
          ref={newArrivalsRef}
          className="mt-3 flex gap-4 sm:gap-5 overflow-x-auto pb-4 pt-1 snap-x snap-mandatory scroll-smooth no-scrollbar"
        >
          {newArrivals.map((p, i) => (
            <div
              key={`new-${p.id}`}
              className="w-[240px] xs:w-[270px] sm:w-[300px] shrink-0 snap-start flex flex-col h-full"
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
            <p className="text-[10px] uppercase tracking-[0.3em] text-gold font-bold">Explore the catalog</p>
            <h2 className="mt-0.5 font-display text-2xl sm:text-4xl font-bold">Featured Collection</h2>
          </div>
          <span className="text-xs text-muted-foreground font-semibold">{filteredProducts.length} items</span>
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

      {/* 5. ENGINEERED EXCELLENCE (2x2 Grid Features) */}
      <section className="mx-auto max-w-7xl px-4 sm:px-5 py-12 border-t border-border/30">
        <Reveal className="text-center">
          <p className="text-[10px] uppercase tracking-[0.3em] text-gold font-bold">Engineered Excellence</p>
          <h2 className="mt-1 font-display text-2xl sm:text-4xl font-bold">
            Crafted to the <span className="text-gold-gradient">last stitch</span>
          </h2>
          <div className="hairline mx-auto mt-3 w-40" />
        </Reveal>

        <div className="mt-8 grid grid-cols-2 gap-3 sm:gap-6 lg:grid-cols-4 items-stretch">
          {features.map((f, i) => {
            const Icon = f.icon;
            return (
              <Reveal key={f.title} delay={i * 90} className="h-full w-full flex flex-col">
                <div className="group flex h-full w-full flex-col items-center justify-center rounded-2xl border border-gold/40 bg-card p-4 sm:p-8 text-center shadow-goldy transition-all duration-300 hover:-translate-y-1 hover:border-gold">
                  <div className="mx-auto flex size-10 sm:size-14 items-center justify-center rounded-2xl border border-gold/50 bg-gold/15 text-gold shadow-sm transition-transform group-hover:scale-110">
                    <Icon className="size-5 sm:size-7 text-gold" />
                  </div>
                  <h3 className="mt-3 sm:mt-6 font-display text-xs sm:text-lg font-bold text-foreground uppercase tracking-wider">
                    {f.title}
                  </h3>
                  <p className="mt-1.5 text-[10px] sm:text-sm text-muted-foreground leading-relaxed">
                    {f.text}
                  </p>
                </div>
              </Reveal>
            );
          })}
        </div>
      </section>

      {/* 6. SERVICE BAR (WhatsApp Order, Fast Delivery, COD, Quality Guarantee) */}
      <section className="border-y border-border bg-surface/40">
        <div className="mx-auto grid max-w-7xl gap-6 px-4 sm:px-5 py-10 grid-cols-2 lg:grid-cols-4">
          {services.map((s, i) => (
            <Reveal key={s.title} delay={i * 90}>
              <div className="flex items-center gap-3">
                <div className="flex size-10 sm:size-12 shrink-0 items-center justify-center rounded-full border border-gold/50 text-gold">
                  <s.icon className="size-4 sm:size-5" />
                </div>
                <div>
                  <p className="text-[11px] sm:text-xs font-bold uppercase tracking-[0.15em] text-foreground">
                    {s.title}
                  </p>
                  <p className="mt-0.5 text-[10px] sm:text-sm text-muted-foreground">{s.text}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* 7. JOIN VEXA CIRCLE CTA (Last) */}
      <section className="mx-auto max-w-4xl px-4 sm:px-5 py-16 text-center">
        <Reveal>
          <h2 className="font-display text-2xl sm:text-4xl font-bold">
            Join the <span className="text-gold-gradient">VEXA</span> circle
          </h2>
          <p className="mx-auto mt-3 max-w-xl text-xs sm:text-sm text-muted-foreground">
            Create an account for early access to limited drops, member pricing and free express shipping.
          </p>
          <div className="mt-7 flex flex-wrap justify-center gap-3.5">
            <Link
              to="/register"
              className="btn-gold hover:btn-gold-hover rounded-sm px-7 py-3 text-xs font-bold uppercase tracking-wider shadow-goldy"
            >
              Create account
            </Link>
            <Link
              to="/contact"
              className="btn-outline-gold rounded-sm px-7 py-3 text-xs font-bold uppercase tracking-wider hover:bg-gold hover:text-primary-foreground"
            >
              Talk to us
            </Link>
          </div>
        </Reveal>
      </section>
    </div>
  );
}
