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
    },
    {
      tag: "BESPOKE CUSTOMISATION",
      title: "BOOK YOUR CUSTOM TEE",
      subtitle: "PERSONALIZED EMBROIDERY & BULK ORDERS",
      text: "Personalize colorways, custom embroidery & bulk orders directly from your user dashboard with live tracking and concierge support.",
      ctaText: "BOOK CUSTOM TEE",
      ctaLink: "/dashboard",
      image: banner2ImgState,
    },
    {
      tag: "VEXA SIGNATURE ESSENTIALS",
      title: "240 GSM HEAVYWEIGHT FIT",
      subtitle: "COMFORT MEETS LUXURY STREETWEAR",
      text: "Engineered for lasting quality, zero color bleeding, and pre-shrunk combed long-staple luxury cotton.",
      ctaText: "SHOP CATALOG",
      ctaLink: "/products",
      image: heroImgState,
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

  const newArrivals = useMemo(() => {
    return products.slice(0, 4);
  }, [products]);

  const newArrivalIds = useMemo(() => {
    return new Set(newArrivals.map((n) => n.id));
  }, [newArrivals]);

  const filteredProducts = useMemo(() => {
    // Exclude New Arrivals items so Featured Collection shows distinct, non-duplicate tees
    return products.filter((p) => !newArrivalIds.has(p.id));
  }, [products, newArrivalIds]);

  return (
    <div className="home-page-root no-scrollbar w-full overflow-x-hidden">
      {/* HERO */}
      <section className="relative overflow-hidden">
        <div className="pointer-events-none absolute inset-0">
          <img
            src={heroImg}
            alt="VEXA premium oversized t-shirts on pedestals"
            loading="lazy"
            decoding="async"
            width={1600}
            height={1104}
            className="h-full w-full object-cover opacity-25 mix-blend-multiply blur-md scale-105 transition-all duration-700"
          />
          <div className="absolute inset-0 bg-gradient-to-b from-background/90 via-background/70 to-background" />
        </div>

        <div className="relative mx-auto max-w-7xl px-5 py-16 lg:py-24">
          <div className="grid gap-10 lg:grid-cols-2 items-center">
            <div className="animate-fade-up">
              <h1 className="mt-4 font-display text-3xl xs:text-4xl leading-[1.08] sm:text-6xl lg:text-7xl font-bold text-foreground">
                PREMIUM
                <br />
                T-SHIRT
                <br />
                <span className="text-gold-gradient">COLLECTION</span>
              </h1>
              <p className="mt-5 max-w-md text-xs sm:text-base leading-relaxed text-muted-foreground">
                Engineered in 240 GSM heavyweight cotton, finished by hand, and cut for the modern oversized silhouette. This is VEXA — wear confidence, wear style.
              </p>

              <div className="mt-8 flex flex-col sm:flex-row gap-3 sm:gap-4 w-full sm:w-auto">
                <Link
                  to="/products"
                  className="btn-gold hover:btn-gold-hover inline-flex items-center justify-center gap-2 rounded-sm px-7 py-3.5 sm:px-8 sm:py-4 text-xs font-bold uppercase tracking-wider shadow-sm text-center"
                >
                  SHOP THE DROP <ArrowRight className="size-4" />
                </Link>
                <Link
                  to="/about"
                  className="btn-outline-gold inline-flex items-center justify-center rounded-sm px-7 py-3.5 sm:px-8 sm:py-4 text-xs font-bold uppercase tracking-wider hover:bg-gold hover:text-primary-foreground shadow-sm text-center"
                >
                  OUR STORY
                </Link>
              </div>
            </div>

            <div className="relative flex items-center justify-center">
              <div className="group relative w-full max-w-lg overflow-hidden rounded-2xl sm:rounded-3xl border border-gold/50 bg-card p-2.5 sm:p-3 shadow-goldy transition-all duration-700 hover:border-gold hover:shadow-2xl">
                <div className="relative w-full overflow-hidden rounded-xl sm:rounded-2xl">
                  <img
                    src={heroImgState}
                    alt="VEXA Premium Luxury Oversized T-Shirt"
                    loading="eager"
                    decoding="async"
                    width={1200}
                    height={1400}
                    className="h-[360px] xs:h-[440px] sm:h-[580px] w-full object-cover object-center transition-transform duration-700 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent pointer-events-none" />

                  <span className="absolute left-3.5 top-3.5 sm:left-5 sm:top-5 rounded-full border border-gold/60 bg-[#f4efe6] px-3 py-1.5 sm:px-4 sm:py-2 text-[10px] sm:text-[11px] font-extrabold uppercase tracking-[0.2em] text-[#1c1917] shadow-md">
                    {heroBanners[heroIndex]?.badgeText || "Signature Drop"}
                  </span>

                  <div className="animate-float absolute right-5 top-5 flex size-18 items-center justify-center rounded-full border-2 border-gold/70 bg-black/90 shadow-goldy">
                    <div className="text-center">
                      <p className="font-display text-base sm:text-lg font-bold text-gold-gradient leading-tight">
                        {heroBanners[heroIndex]?.discount || "30% Off"}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>



        {/* marquee */}
        <div className="relative overflow-hidden border-b border-border py-4">
          <div className="animate-marquee flex w-max gap-12 whitespace-nowrap">
            {Array.from({ length: 2 }).map((_, r) => (
              <div key={r} className="flex gap-12">
                {[
                  "FREE SHIPPING OVER ₹1999",
                  "PREMIUM COTTON",
                  "OVERSIZED FIT",
                  "CASH ON DELIVERY",
                  "30-DAY RETURNS",
                  "LIMITED DROPS",
                ].map((t) => (
                  <span
                    key={t + r}
                    className="text-xs uppercase tracking-[0.3em] text-muted-foreground"
                  >
                    ✦ {t}
                  </span>
                ))}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* SIMPLE FEATURES CAROUSEL */}
      <section className="mx-auto max-w-7xl px-5 py-16">
        <Reveal className="text-center">
          <p className="text-[10px] uppercase tracking-[0.3em] text-gold font-bold">Engineered Excellence</p>
          <h2 className="mt-2 font-display text-3xl sm:text-4xl">
            Crafted to the <span className="text-gold-gradient">last stitch</span>
          </h2>
          <div className="hairline mx-auto mt-4 w-48" />
        </Reveal>

        {/* 2x2 Grid Features Section (2 in line 1, 2 in line 2) */}
        <div className="mt-10 grid grid-cols-2 gap-3.5 sm:gap-6 lg:grid-cols-4 items-stretch">
          {features.map((f, i) => {
            const Icon = f.icon;
            return (
              <Reveal key={f.title} delay={i * 90} className="h-full w-full flex flex-col">
                <div className="group flex h-full w-full flex-col items-center justify-center rounded-2xl border border-gold/40 bg-card p-5 sm:p-8 text-center shadow-goldy transition-all duration-300 hover:-translate-y-1 hover:border-gold">
                  <div className="mx-auto flex size-12 sm:size-14 items-center justify-center rounded-2xl border border-gold/50 bg-gold/15 text-gold shadow-sm transition-transform group-hover:scale-110">
                    <Icon className="size-6 sm:size-7 text-gold" />
                  </div>
                  <h3 className="mt-4 sm:mt-6 font-display text-xs sm:text-lg font-bold text-foreground uppercase tracking-wider">
                    {f.title}
                  </h3>
                  <p className="mt-2 text-[11px] sm:text-sm text-muted-foreground leading-relaxed">
                    {f.text}
                  </p>
                </div>
              </Reveal>
            );
          })}
        </div>
      </section>

      {/* LUXURY PROMO BANNER CAROUSEL SLIDER */}
      <section className="mx-auto max-w-7xl px-5 pb-16 pt-8">
        <Reveal className="mb-6 text-center">
          <p className="text-[10px] font-bold uppercase tracking-[0.3em] text-gold">Featured Highlights</p>
          <h2 className="mt-1 font-display text-2xl sm:text-3xl font-bold">
            Promotional <span className="text-gold-gradient">Showcase</span>
          </h2>
        </Reveal>

        <div className="relative overflow-hidden rounded-3xl border border-gold/50 bg-card shadow-goldy transition-all hover:border-gold">
          {/* Active Banner Image Slide */}
          <div className="relative min-h-[360px] sm:min-h-[420px] lg:min-h-[460px] w-full overflow-hidden">
            <img
              src={activePromoBanners[bannerIndex].image}
              alt={activePromoBanners[bannerIndex].title}
              className="absolute inset-0 h-full w-full object-cover object-center transition-all duration-700"
            />
            <div className="absolute inset-0 bg-gradient-to-r from-background/95 via-background/80 to-transparent" />

            {/* Banner Text Overlay */}
            <div className="relative z-10 flex h-full min-h-[360px] sm:min-h-[420px] lg:min-h-[460px] max-w-2xl flex-col justify-center p-6 sm:p-12 lg:p-16">
              <span className="inline-block w-fit rounded-full border border-gold/60 bg-[#f4efe6] px-3.5 py-1 text-[10px] font-extrabold uppercase tracking-[0.25em] text-[#1c1917] shadow-md">
                {activePromoBanners[bannerIndex].tag}
              </span>

              <h3 className="mt-4 font-display text-2xl sm:text-4xl lg:text-5xl font-bold leading-tight text-foreground">
                {activePromoBanners[bannerIndex].title}
              </h3>

              <p className="mt-2 text-xs sm:text-sm font-bold uppercase tracking-wider text-gold">
                ✨ {activePromoBanners[bannerIndex].subtitle} ✨
              </p>

              <p className="mt-3 text-xs sm:text-sm leading-relaxed text-muted-foreground">
                {activePromoBanners[bannerIndex].text}
              </p>

              <div className="mt-6">
                <Link
                  to={activePromoBanners[bannerIndex].ctaLink}
                  className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2 rounded-sm px-8 py-3.5 text-xs font-bold uppercase tracking-wider shadow-sm"
                >
                  {activePromoBanners[bannerIndex].ctaText} <ArrowRight className="size-4" />
                </Link>
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* NEW ARRIVALS */}
      <section className="mx-auto max-w-7xl px-5 py-12 border-t border-border/40">
        <div className="flex flex-col sm:flex-row sm:items-end justify-between mb-6 gap-4">
          <div>
            <p className="text-[10px] sm:text-xs font-bold uppercase tracking-[0.3em] text-gold">LATEST DROPS</p>
            <h2 className="mt-1 font-display text-3xl sm:text-4xl font-bold text-foreground">
              New Arrivals
            </h2>
            <Link
              to="/products"
              className="mt-2 inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-[0.2em] text-gold hover:underline transition-transform hover:translate-x-1"
            >
              Explore All ({products.length}) <ArrowRight className="size-3.5" />
            </Link>
          </div>
        </div>

        {/* New Arrivals Side Scrolling Container */}
        <div
          ref={newArrivalsRef}
          className="mt-4 flex gap-5 overflow-x-auto pb-6 pt-2 snap-x snap-mandatory scroll-smooth no-scrollbar"
        >
          {newArrivals.map((p, i) => (
            <div
              key={`new-${p.id}`}
              className="w-[280px] xs:w-[300px] sm:w-[320px] shrink-0 snap-start flex flex-col h-full"
            >
              <Reveal delay={i * 90} className="h-full w-full flex flex-col">
                <ProductCard product={p} />
              </Reveal>
            </div>
          ))}
        </div>
      </section>

      {/* COLLECTION */}
      <section className="mx-auto max-w-7xl px-5 pb-24">
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-6">
          <div>
            <p className="text-[10px] uppercase tracking-[0.3em] text-gold">Explore the catalog</p>
            <h2 className="mt-1 font-display text-3xl sm:text-4xl font-bold">Featured Collection</h2>
            <Link
              to="/products"
              className="mt-2 inline-flex items-center gap-2 text-xs uppercase tracking-[0.2em] text-gold hover:underline transition-transform hover:translate-x-1"
            >
              View all ({products.length}) <ArrowRight className="size-4" />
            </Link>
          </div>
        </div>

        {/* Featured Collection Side Scrolling Container */}
        <div
          ref={featuredRef}
          className="mt-4 flex gap-5 overflow-x-auto pb-6 pt-2 snap-x snap-mandatory scroll-smooth no-scrollbar"
        >
          {filteredProducts.map((p, i) => (
            <div
              key={p.id}
              className="w-[280px] xs:w-[300px] sm:w-[320px] shrink-0 snap-start flex flex-col h-full"
            >
              <Reveal delay={(i % 4) * 90} className="h-full w-full flex flex-col">
                <ProductCard product={p} />
              </Reveal>
            </div>
          ))}
        </div>
      </section>

      {/* SERVICE BAR */}
      <section className="border-y border-border bg-surface/40">
        <div className="mx-auto grid max-w-7xl gap-8 px-5 py-14 sm:grid-cols-2 lg:grid-cols-4">
          {services.map((s, i) => (
            <Reveal key={s.title} delay={i * 90}>
              <div className="flex items-center gap-4">
                <div className="flex size-12 shrink-0 items-center justify-center rounded-full border border-gold/50 text-gold">
                  <s.icon className="size-5" />
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.2em] text-foreground">
                    {s.title}
                  </p>
                  <p className="mt-1 text-sm text-muted-foreground">{s.text}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="mx-auto max-w-4xl px-5 py-24 text-center">
        <Reveal>
          <h2 className="font-display text-3xl sm:text-5xl">
            Join the <span className="text-gold-gradient">VEXA</span> circle
          </h2>
          <p className="mx-auto mt-5 max-w-xl text-muted-foreground">
            Create an account for early access to limited drops, member pricing and
            free express shipping.
          </p>
          <div className="mt-9 flex flex-wrap justify-center gap-4">
            <Link
              to="/register"
              className="btn-gold hover:btn-gold-hover rounded-sm px-8 py-4 text-xs"
            >
              Create account
            </Link>
            <Link
              to="/contact"
              className="btn-outline-gold rounded-sm px-8 py-4 text-xs hover:bg-gold hover:text-primary-foreground"
            >
              Talk to us
            </Link>
          </div>
        </Reveal>
      </section>
    </div>
  );
}
