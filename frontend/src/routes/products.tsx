import { useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ArrowLeft, Search, SlidersHorizontal } from "lucide-react";
import { useProducts } from "@/lib/products";
import { ProductCard } from "@/components/ProductCard";
import { Reveal } from "@/components/Reveal";

const filters = ["All", "Oversized", "Classic", "Limited"] as const;

export function Products() {
  const navigate = useNavigate();
  const { products } = useProducts();
  const [active, setActive] = useState<(typeof filters)[number]>("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [sortBy, setSortBy] = useState<"featured" | "price-asc" | "price-desc" | "rating">("featured");
  const [showSizeGuide, setShowSizeGuide] = useState(false);

  const list = useMemo(() => {
    let result = active === "All" ? products : products.filter((p) => p.category === active);

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        (p) => p.name.toLowerCase().includes(q) || p.color.toLowerCase().includes(q)
      );
    }

    if (sortBy === "price-asc") {
      result = [...result].sort((a, b) => a.price - b.price);
    } else if (sortBy === "price-desc") {
      result = [...result].sort((a, b) => b.price - a.price);
    } else if (sortBy === "rating") {
      result = [...result].sort((a, b) => b.rating - a.rating);
    }

    return result;
  }, [products, active, searchQuery, sortBy]);

  return (
    <section className="mx-auto max-w-7xl px-5 pt-24 pb-16">
      {/* Back Button */}
      <div className="mb-6 flex items-center justify-start">
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="inline-flex items-center gap-2 rounded-full border border-gold/40 bg-card/80 px-4 py-2 text-xs font-bold uppercase tracking-[0.16em] text-gold transition-all duration-300 hover:border-gold hover:bg-gold hover:text-primary-foreground shadow-sm group cursor-pointer"
        >
          <ArrowLeft className="size-4 transition-transform duration-300 group-hover:-translate-x-1" />
          <span>Back</span>
        </button>
      </div>
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
      <div className="mt-12 flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
        {/* Category Filters (Non-scrolling 4-column grid on mobile) */}
        <div className="grid grid-cols-4 gap-1.5 sm:flex sm:w-auto sm:items-center sm:gap-2">
          {filters.map((f) => (
            <button
              key={f}
              onClick={() => setActive(f)}
              className={`w-full rounded-full py-2 px-1 text-[9px] sm:px-5 sm:text-[10px] font-semibold uppercase tracking-wider sm:tracking-[0.2em] transition-all duration-300 text-center ${
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

          <div className="flex items-center gap-2 rounded-lg border border-border bg-card px-3.5 py-2.5 text-xs shrink-0">
            <SlidersHorizontal className="size-3.5 text-gold shrink-0" />
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as any)}
              className="bg-transparent text-xs font-semibold text-foreground outline-none cursor-pointer"
            >
              <option value="featured">Sort: Featured</option>
              <option value="price-asc">Price: Low to High</option>
              <option value="price-desc">Price: High to Low</option>
              <option value="rating">Top Rated</option>
            </select>
          </div>
        </div>
      </div>

      {/* Products Grid */}
      {list.length > 0 ? (
        <div className="mt-10 grid gap-8 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {list.map((p, i) => (
            <Reveal key={p.id} delay={(i % 4) * 90}>
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
  );
}
