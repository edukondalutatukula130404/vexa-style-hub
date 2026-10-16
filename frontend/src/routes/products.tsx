import { useMemo, useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { ChevronLeft, Search, SlidersHorizontal, Heart, X, Check } from "lucide-react";
import { useProducts, getProductImage } from "@/lib/products";
import { ProductCard } from "@/components/ProductCard";
import { Reveal } from "@/components/Reveal";
import { useWishlist, toggleWishlist } from "@/lib/wishlist";
import { useCart, addToCart } from "@/lib/cart";
import { useAuth } from "@/lib/auth";

const filters = ["All", "Oversized", "Classic", "Limited"] as const;

export function Products() {
  const navigate = useNavigate();
  const { products } = useProducts();
  const { isInWishlist } = useWishlist();
  const { cartItems } = useCart();
  const { isLoggedIn } = useAuth();
  const [active, setActive] = useState<(typeof filters)[number]>("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [sortBy, setSortBy] = useState<"featured" | "price-asc" | "price-desc" | "rating">("featured");
  const [priceRange, setPriceRange] = useState<"All" | "under-1500" | "1500-1700" | "above-1700">("All");
  const [isFilterModalOpen, setIsFilterModalOpen] = useState(false);
  const [showSizeGuide, setShowSizeGuide] = useState(false);

  // Lock body scroll completely when mobile filter card is open to prevent background scrolling
  useEffect(() => {
    if (isFilterModalOpen) {
      const scrollY = window.scrollY;
      const originalPosition = document.body.style.position;
      const originalTop = document.body.style.top;
      const originalWidth = document.body.style.width;
      const originalOverflow = document.body.style.overflow;
      const docOverflow = document.documentElement.style.overflow;

      document.body.style.position = "fixed";
      document.body.style.top = `-${scrollY}px`;
      document.body.style.width = "100%";
      document.body.style.overflow = "hidden";
      document.documentElement.style.overflow = "hidden";

      return () => {
        document.body.style.position = originalPosition;
        document.body.style.top = originalTop;
        document.body.style.width = originalWidth;
        document.body.style.overflow = originalOverflow;
        document.documentElement.style.overflow = docOverflow;
        window.scrollTo(0, scrollY);
      };
    }
  }, [isFilterModalOpen]);

  const activeFilterCount = useMemo(() => {
    let count = 0;
    if (sortBy !== "featured") count++;
    if (active !== "All") count++;
    if (priceRange !== "All") count++;
    return count;
  }, [sortBy, active, priceRange]);

  const isInCart = (productId: string | number) => {
    return (cartItems || []).some((item) => String(item.product.id) === String(productId));
  };

  const list = useMemo(() => {
    let result = active === "All" ? products : products.filter((p) => p.category === active);

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        (p) => p.name.toLowerCase().includes(q) || p.color.toLowerCase().includes(q)
      );
    }

    if (priceRange === "under-1500") {
      result = result.filter((p) => p.price < 1500);
    } else if (priceRange === "1500-1700") {
      result = result.filter((p) => p.price >= 1500 && p.price <= 1700);
    } else if (priceRange === "above-1700") {
      result = result.filter((p) => p.price > 1700);
    }

    if (sortBy === "price-asc") {
      result = [...result].sort((a, b) => a.price - b.price);
    } else if (sortBy === "price-desc") {
      result = [...result].sort((a, b) => b.price - a.price);
    } else if (sortBy === "rating") {
      result = [...result].sort((a, b) => b.rating - a.rating);
    }

    return result;
  }, [products, active, searchQuery, sortBy, priceRange]);

  return (
    <>
      {/* =========================================================================
          MOBILE RESPONSIVE VIEW ONLY (< md)
          Matches Flutter Mobile App All Products Screen 1:1
          ========================================================================= */}
      <div className="block md:hidden px-3.5 pt-3 pb-24">
        {/* Mobile Header: Back Button + Title (Count) */}
        <div className="flex items-center gap-3 py-1">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1"
            aria-label="Go Back"
          >
            <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
          </button>
          <h1 className="font-serif text-lg font-bold uppercase tracking-wider text-foreground">
            ALL PRODUCTS ({list.length})
          </h1>
        </div>

        {/* Mobile Search & Filter Row */}
        <div className="mt-3 flex items-center gap-2.5">
          <div className="relative flex-1">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search products..."
              className="w-full rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-card py-2.5 pl-10 pr-9 text-xs font-medium placeholder:text-neutral-400 outline-none focus:border-[#B8860B] transition-colors shadow-2xs"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery("")}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-foreground"
                aria-label="Clear search"
              >
                <X className="size-3.5" />
              </button>
            )}
          </div>

          {/* Filter / Sort Button (Opens Bottom Sheet Modal) */}
          <button
            type="button"
            onClick={() => setIsFilterModalOpen(true)}
            className="relative flex size-10.5 items-center justify-center rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-card shadow-2xs shrink-0 cursor-pointer active:scale-95 transition-transform"
            aria-label="Filter and Sort Products"
            title="Filter & Sort"
          >
            <SlidersHorizontal className="size-4 text-neutral-700 dark:text-neutral-300" />
            {activeFilterCount > 0 && (
              <span className="absolute -top-1 -right-1 flex size-4.5 items-center justify-center rounded-full bg-[#8B6508] dark:bg-[#E5BF4E] text-white dark:text-[#0F172A] text-[9.5px] font-black border-2 border-white dark:border-card shadow-xs">
                {activeFilterCount}
              </span>
            )}
          </button>
        </div>

        {/* Mobile 2-Column Product Grid */}
        {list.length > 0 ? (
          <div className="mt-4 grid grid-cols-2 gap-3">
            {list.map((p) => {
              const wishlisted = isInWishlist(p.id);
              return (
                <div
                  key={p.id}
                  onClick={() => navigate(`/product/${p.id}`)}
                  className="relative overflow-hidden rounded-2xl border border-neutral-200/90 dark:border-neutral-800 bg-white dark:bg-card shadow-xs flex flex-col justify-between cursor-pointer transition-transform active:scale-[0.99]"
                >
                  {/* Product Image Area */}
                  <div className="relative aspect-[4/5] w-full overflow-hidden bg-neutral-900">
                    <img
                      src={getProductImage(p)}
                      alt={p.name}
                      loading="lazy"
                      className="h-full w-full object-cover object-top"
                    />

                    {/* Category Badge Pill on Bottom-Left */}
                    <span className="absolute left-2.5 bottom-2.5 rounded-md bg-black/75 px-2 py-0.5 text-[10px] font-semibold text-white capitalize backdrop-blur-xs shadow-xs">
                      {p.category}
                    </span>

                    {/* Heart Button on Top-Right */}
                    <button
                      type="button"
                      onClick={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        toggleWishlist(p);
                      }}
                      className="absolute right-2.5 top-2.5 flex size-7 items-center justify-center rounded-full bg-black/50 text-white backdrop-blur-xs transition-transform active:scale-85 shadow-sm"
                      title={wishlisted ? "Remove from Wishlist" : "Add to Wishlist"}
                    >
                      <Heart
                        className={`size-3.5 transition-colors ${
                          wishlisted ? "fill-red-500 text-red-500" : "text-white"
                        }`}
                      />
                    </button>
                  </div>

                  {/* Product Info & Action Buttons */}
                  <div className="p-2.5 sm:p-3 flex-1 flex flex-col justify-between space-y-2.5">
                    <div>
                      <h3 className="font-bold text-xs text-foreground truncate">
                        {p.name}
                      </h3>
                      <div className="mt-1 flex items-baseline gap-1.5">
                        <span className="text-sm font-extrabold text-[#B8860B]">
                          ₹{p.price.toLocaleString("en-IN")}
                        </span>
                        {p.oldPrice > p.price && (
                          <span className="text-[10px] text-neutral-400 line-through">
                            ₹{p.oldPrice.toLocaleString("en-IN")}
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Dual Buttons: Add to Cart / Cart Symbol and Buy Now */}
                    <div className="grid grid-cols-2 gap-1.5 pt-0.5">
                      {isInCart(p.id) ? (
                        <button
                          type="button"
                          onClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            navigate("/dashboard?tab=cart");
                          }}
                          className="py-1.5 px-1 rounded-lg border border-[#8B6508] bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] font-bold text-[10px] text-center shadow-2xs active:scale-95 transition-all flex items-center justify-center gap-1 cursor-pointer"
                          title="Open Cart Page"
                          aria-label="Open Cart Page"
                        >
                          <svg
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2.1"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            className="size-3.5 text-[#8B6508] dark:text-[#E5BF4E] shrink-0"
                          >
                            <rect x="5" y="8" width="14" height="13" rx="2" />
                            <path d="M9 10V6a3 3 0 0 1 6 0v4" />
                          </svg>
                          <span className="truncate">In Cart</span>
                        </button>
                      ) : (
                        <button
                          type="button"
                          onClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            addToCart(p, "M", 1);
                          }}
                          className="py-1.5 px-1 rounded-lg border border-neutral-300 dark:border-neutral-700 bg-white dark:bg-card text-foreground font-bold text-[10px] text-center shadow-2xs active:scale-95 transition-transform cursor-pointer hover:border-[#8B6508]"
                        >
                          Add to Cart
                        </button>
                      )}
                      <button
                        type="button"
                        onClick={(e) => {
                          e.preventDefault();
                          e.stopPropagation();
                          addToCart(p, "M", 1);
                          navigate(isLoggedIn ? "/dashboard?tab=cart" : "/login");
                        }}
                        className="py-1.5 px-1 rounded-lg bg-[#8B6508] text-white font-bold text-[10px] text-center shadow-2xs active:scale-95 transition-transform hover:bg-[#7A5807] cursor-pointer"
                      >
                        Buy Now
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="mt-12 text-center text-muted-foreground py-10 border border-dashed border-border rounded-xl">
            <p className="text-sm font-semibold">No matching tees found</p>
            <p className="mt-1 text-xs">Try adjusting your search query.</p>
          </div>
        )}
      </div>

      {/* =========================================================================
          MOBILE FILTER & SORT BOTTOM SHEET MODAL (< md)
          Matches Flutter Mobile App Filter Modal 1:1
          ========================================================================= */}
      {isFilterModalOpen && (
        <div
          className="md:hidden fixed inset-0 z-50 flex items-end justify-center bg-black/60 backdrop-blur-xs animate-in fade-in duration-200 overscroll-none touch-none"
          onClick={() => setIsFilterModalOpen(false)}
          onTouchMove={(e) => {
            if (e.target === e.currentTarget) {
              e.preventDefault();
            }
          }}
        >
          <div
            className="w-full max-w-md bg-white dark:bg-[#0F172A] rounded-t-[28px] border-t border-neutral-200 dark:border-neutral-800 shadow-2xl flex flex-col max-h-[82vh] overflow-hidden animate-in slide-in-from-bottom duration-250 overscroll-contain touch-auto"
            onClick={(e) => e.stopPropagation()}
            onWheel={(e) => e.stopPropagation()}
            onTouchMove={(e) => e.stopPropagation()}
          >
            {/* Top Drag Handle Indicator */}
            <div className="pt-3 pb-1 flex justify-center shrink-0">
              <div className="w-11 h-1 rounded-full bg-neutral-300 dark:bg-neutral-700" />
            </div>

            {/* Header: Title + Reset All + Close */}
            <div className="flex items-center justify-between px-5 py-3 border-b border-neutral-200/80 dark:border-neutral-800 shrink-0">
              <div className="flex items-center gap-2">
                <SlidersHorizontal className="size-4.5 text-[#8B6508] dark:text-[#E5BF4E]" />
                <h3 className="font-serif text-base font-bold text-foreground tracking-wide">
                  Filter & Sort
                </h3>
              </div>
              <div className="flex items-center gap-2">
                {activeFilterCount > 0 && (
                  <button
                    type="button"
                    onClick={() => {
                      setSortBy("featured");
                      setActive("All");
                      setPriceRange("All");
                    }}
                    className="text-xs font-semibold text-[#8B6508] dark:text-[#E5BF4E] hover:underline px-2 py-1 transition-colors cursor-pointer"
                  >
                    Reset All
                  </button>
                )}
                <button
                  type="button"
                  onClick={() => setIsFilterModalOpen(false)}
                  className="p-1 rounded-full text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
                  aria-label="Close"
                >
                  <X className="size-5" />
                </button>
              </div>
            </div>

            {/* Scrollable Filter Sections */}
            <div className="flex-1 overflow-y-auto px-5 py-4 space-y-5 overscroll-contain">
              {/* 1. Sort By */}
              <div>
                <label className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground block mb-2.5">
                  Sort By
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {[
                    { id: "featured", label: "Featured" },
                    { id: "price-asc", label: "Price: Low to High" },
                    { id: "price-desc", label: "Price: High to Low" },
                    { id: "rating", label: "Top Rated" },
                  ].map((s) => {
                    const isSelected = sortBy === s.id;
                    return (
                      <button
                        key={s.id}
                        type="button"
                        onClick={() => setSortBy(s.id as any)}
                        className={`py-2 px-3 rounded-xl text-xs font-semibold tracking-wide border transition-all text-left flex items-center justify-between cursor-pointer ${
                          isSelected
                            ? "bg-[#FAF6EE] dark:bg-amber-950/30 border-[#8B6508] dark:border-gold text-[#8B6508] dark:text-[#E5BF4E] font-bold"
                            : "bg-neutral-50 dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800 text-neutral-700 dark:text-neutral-300"
                        }`}
                      >
                        <span className="truncate">{s.label}</span>
                        {isSelected && (
                          <div className="size-2 rounded-full bg-[#8B6508] dark:bg-[#E5BF4E] shrink-0 ml-1.5" />
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* 2. Category */}
              <div>
                <label className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground block mb-2.5">
                  Category
                </label>
                <div className="flex flex-wrap gap-2">
                  {filters.map((f) => {
                    const isSelected = active === f;
                    return (
                      <button
                        key={f}
                        type="button"
                        onClick={() => setActive(f)}
                        className={`py-2 px-4 rounded-xl text-xs font-semibold tracking-wide border transition-all cursor-pointer ${
                          isSelected
                            ? "bg-[#8B6508] text-white border-[#8B6508] font-bold shadow-xs"
                            : "bg-neutral-50 dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800 text-neutral-700 dark:text-neutral-300"
                        }`}
                      >
                        {f}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* 3. Price Range */}
              <div>
                <label className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground block mb-2.5">
                  Price Range
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {[
                    { id: "All", label: "All Prices" },
                    { id: "under-1500", label: "Under ₹1,500" },
                    { id: "1500-1700", label: "₹1,500 - ₹1,700" },
                    { id: "above-1700", label: "Above ₹1,700" },
                  ].map((p) => {
                    const isSelected = priceRange === p.id;
                    return (
                      <button
                        key={p.id}
                        type="button"
                        onClick={() => setPriceRange(p.id as any)}
                        className={`py-2 px-3 rounded-xl text-xs font-semibold tracking-wide border transition-all text-left flex items-center justify-between cursor-pointer ${
                          isSelected
                            ? "bg-[#FAF6EE] dark:bg-amber-950/30 border-[#8B6508] dark:border-gold text-[#8B6508] dark:text-[#E5BF4E] font-bold"
                            : "bg-neutral-50 dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800 text-neutral-700 dark:text-neutral-300"
                        }`}
                      >
                        <span className="truncate">{p.label}</span>
                        {isSelected && (
                          <div className="size-2 rounded-full bg-[#8B6508] dark:bg-[#E5BF4E] shrink-0 ml-1.5" />
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Bottom Sticky Action: Apply Filters */}
            <div className="p-4 border-t border-neutral-200 dark:border-neutral-800 bg-white dark:bg-[#0F172A] shrink-0">
              <button
                type="button"
                onClick={() => setIsFilterModalOpen(false)}
                className="w-full py-3.5 rounded-xl bg-[#8B6508] hover:bg-[#725206] text-white font-bold text-xs uppercase tracking-wider shadow-md active:scale-98 transition-all flex items-center justify-center gap-2 cursor-pointer"
              >
                <span>Apply Filters</span>
                <span className="opacity-90 font-medium">({list.length} Products)</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================================
          DESKTOP VIEW (>= md) - Left Untouched
          ========================================================================= */}
      <section className="hidden md:block mx-auto max-w-7xl px-4 sm:px-5 pt-18 sm:pt-24 pb-16">
        {/* Desktop Header */}
        <Reveal className="text-center">
          <p className="text-[10px] uppercase tracking-[0.3em] text-gold">The complete collection</p>
          <h1 className="mt-4 font-display text-4xl sm:text-5xl">Engineered Essentials</h1>
          <div className="hairline mx-auto mt-6 w-40" />
          <p className="mx-auto mt-6 max-w-2xl text-muted-foreground leading-relaxed">
            Crafted from 240 GSM long-staple combed cotton, finished with bio-wash processing
            and double-stitched reinforced collars. Designed for lasting drape and everyday confidence.
          </p>
        </Reveal>

        {/* Control Bar: Search, Category Filters & Sort */}
        <div className="mt-3 sm:mt-12 flex flex-col gap-4 sm:gap-6 lg:flex-row lg:items-center lg:justify-between">
          {/* Category Filters */}
          <div className="flex w-auto items-center gap-2">
            {filters.map((f) => (
              <button
                key={f}
                onClick={() => setActive(f)}
                className={`rounded-full py-2 px-5 text-[10px] font-semibold uppercase tracking-[0.2em] transition-all duration-300 text-center ${
                  active === f
                    ? "bg-gold text-primary-foreground shadow-goldy font-bold"
                    : "border border-border bg-card text-muted-foreground hover:border-gold hover:text-gold"
                }`}
              >
                {f}
              </button>
            ))}
          </div>

          {/* Search & Sort Controls */}
          <div className="flex w-full sm:w-auto items-center gap-3">
            <div className="relative flex-1 sm:w-64">
              <Search className="absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search by title or color..."
                className="w-full rounded-lg border border-border bg-card py-2.5 pl-10 pr-4 text-xs outline-none transition-colors focus:border-gold placeholder:text-muted-foreground/60"
              />
            </div>

            {/* Filter / Sort Symbol Button */}
            <div className="relative flex size-10 items-center justify-center rounded-lg border border-border bg-card hover:border-gold transition-colors shrink-0 shadow-sm cursor-pointer" title="Sort & Filter Products">
              <SlidersHorizontal className="size-4 text-gold shrink-0 pointer-events-none" />
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as any)}
                className="absolute inset-0 opacity-0 w-full h-full cursor-pointer"
                title="Sort Products"
              >
                <option value="featured">Sort: Featured</option>
                <option value="price-asc">Price: Low to High</option>
                <option value="price-desc">Price: High to Low</option>
                <option value="rating">Top Rated</option>
              </select>
            </div>
          </div>
        </div>

        {/* Desktop Products Grid */}
        {list.length > 0 ? (
          <div className="mt-8 grid grid-cols-2 gap-3 sm:gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {list.map((p, i) => (
              <Reveal key={p.id} delay={(i % 4) * 90} className="h-full w-full flex flex-col">
                <ProductCard product={p} />
              </Reveal>
            ))}
          </div>
        ) : (
          <div className="mt-16 text-center text-muted-foreground py-12 border border-dashed border-border rounded-xl">
            <p className="text-base font-display">No matching tees found</p>
            <p className="mt-1 text-xs">Try adjusting your search or category filters.</p>
          </div>
        )}

        {/* Size Guide Modal */}
        {showSizeGuide && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 overflow-y-auto">
            <div className="w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-xl border border-gold/40 bg-card p-6 shadow-2xl">
              <div className="flex items-center justify-between border-b border-border pb-4">
                <h3 className="font-display text-xl font-semibold text-foreground">VEXA Size Guide</h3>
                <button
                  onClick={() => setShowSizeGuide(false)}
                  className="text-xs uppercase tracking-widest text-gold hover:underline"
                >
                  Close
                </button>
              </div>
              <div className="mt-5 space-y-3 text-xs text-muted-foreground">
                <p>All VEXA tees feature a Signature Oversized Silhouette. Order your normal size for an intended relaxed drop-shoulder drape.</p>
                <table className="mt-4 w-full text-left text-xs">
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
    </>
  );
}
