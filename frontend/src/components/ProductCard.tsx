import { useState } from "react";
import { Star, ShoppingBag, X, Sparkles, ShieldCheck, Ruler, CheckCircle2 } from "lucide-react";
import { useNavigate } from "@tanstack/react-router";
import type { Product } from "@/lib/products";
import { SIZES } from "@/lib/products";
import { useAuth } from "@/lib/auth";
import { addToCart } from "@/lib/cart";

export function ProductCard({ product }: { product: Product }) {
  const { isLoggedIn } = useAuth();
  const navigate = useNavigate();
  const [showModal, setShowModal] = useState(false);
  const [selectedSize, setSelectedSize] = useState("M");
  const off = Math.round((1 - product.price / product.oldPrice) * 100);

  const handleOrder = (e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    addToCart(product, selectedSize, 1);
    if (isLoggedIn) {
      navigate({
        to: "/dashboard",
        search: { tab: "cart" },
      });
    } else {
      localStorage.setItem("vexa_redirect_after_login", "/dashboard?tab=cart");
      navigate({ to: "/login" });
    }
  };

  return (
    <>
      <article
        onClick={() => setShowModal(true)}
        className="group relative cursor-pointer overflow-hidden rounded-sm border border-border bg-card transition-all duration-500 hover:-translate-y-2 hover:border-gold hover:shadow-goldy"
      >
        <div className="relative overflow-hidden">
          <img
            src={product.image}
            alt={`${product.name} in ${product.color}`}
            loading="lazy"
            decoding="async"
            width={900}
            height={1100}
            className="h-[360px] w-full object-cover transition-transform duration-700 group-hover:scale-105"
          />
          <span className="absolute left-4 top-4 rounded-full border border-gold/60 bg-background/70 px-3 py-1 text-[10px] uppercase tracking-[0.18em] text-gold backdrop-blur">
            {product.category}
          </span>
          <span className="btn-gold absolute right-4 top-4 rounded-full px-3 py-1 text-[10px]">
            {off}% Off
          </span>
          <div className="absolute inset-x-0 bottom-0 translate-y-full bg-background/85 p-4 backdrop-blur transition-transform duration-500 group-hover:translate-y-0">
            <button
              onClick={handleOrder}
              className="btn-gold hover:btn-gold-hover flex w-full items-center justify-center gap-2 rounded-sm py-2.5 text-[10px] uppercase tracking-wider font-bold"
            >
              <ShoppingBag className="size-3.5" /> Add to Cart
            </button>
          </div>
        </div>

        <div className="space-y-2 p-5">
          <div className="flex items-center justify-between">
            <h3 className="font-display text-base text-foreground group-hover:text-gold transition-colors">
              {product.name}
            </h3>
            <span className="flex items-center gap-1 text-xs text-gold">
              <Star className="size-3 fill-current" />
              {product.rating}
            </span>
          </div>
          <p className="text-xs uppercase tracking-[0.18em] text-muted-foreground">
            {product.color}
          </p>
          <div className="flex items-baseline gap-3 pt-1">
            <span className="text-lg text-gold">₹{product.price.toLocaleString("en-IN")}</span>
            <span className="text-sm text-muted-foreground line-through">
              ₹{product.oldPrice.toLocaleString("en-IN")}
            </span>
          </div>
        </div>
      </article>

      {/* PRODUCT DETAIL VIEW MODAL */}
      {showModal && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-md p-4 overflow-y-auto animate-in fade-in duration-300"
          onClick={() => setShowModal(false)}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="relative w-full max-w-3xl max-h-[90vh] overflow-y-auto rounded-2xl border border-gold/40 bg-card p-6 sm:p-8 shadow-2xl space-y-6"
          >
            {/* Close Button */}
            <button
              onClick={() => setShowModal(false)}
              className="absolute right-5 top-5 rounded-full border border-border bg-background p-2 text-muted-foreground transition-colors hover:border-gold hover:text-gold"
            >
              <X className="size-5" />
            </button>

            <div className="grid gap-8 md:grid-cols-2">
              {/* Product Image Preview */}
              <div className="relative overflow-hidden rounded-xl border border-border bg-surface">
                <img
                  src={product.image}
                  alt={product.name}
                  className="h-[380px] w-full object-cover"
                />
                <span className="absolute top-4 left-4 rounded-full bg-gold/90 text-primary-foreground px-3 py-1 text-[10px] font-bold uppercase tracking-wider">
                  {product.category} Collection
                </span>
                <span className="absolute bottom-4 right-4 rounded-full bg-black/70 px-3.5 py-1 text-[10px] text-gold font-semibold border border-gold/40 backdrop-blur-md">
                  240 GSM Heavyweight
                </span>
              </div>

              {/* Product Info & Specifications */}
              <div className="flex flex-col justify-between space-y-5">
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] uppercase tracking-[0.25em] text-gold font-semibold">
                      VEXA Signature Series
                    </span>
                    <span className="flex items-center gap-1 text-xs text-gold font-bold">
                      <Star className="size-3.5 fill-current" />
                      {product.rating} / 5.0
                    </span>
                  </div>

                  <h2 className="font-display text-2xl font-bold text-foreground">
                    {product.name}
                  </h2>

                  <p className="text-xs uppercase tracking-[0.2em] text-muted-foreground">
                    Color: <span className="text-foreground font-semibold">{product.color}</span>
                  </p>

                  <div className="flex items-baseline gap-4 pt-1">
                    <span className="font-display text-3xl font-bold text-gold">
                      ₹{product.price.toLocaleString("en-IN")}
                    </span>
                    <span className="text-base text-muted-foreground line-through">
                      ₹{product.oldPrice.toLocaleString("en-IN")}
                    </span>
                    <span className="rounded-full bg-gold/15 border border-gold/40 px-3 py-1 text-[10px] font-bold text-gold">
                      Save {off}%
                    </span>
                  </div>

                  <p className="text-xs text-muted-foreground leading-relaxed pt-2">
                    Engineered from 240 GSM luxury heavyweight combed cotton with bio-wash finish.
                    Features a signature drop-shoulder silhouette, pre-shrunk anti-fade weave, and double-stitched reinforced collar.
                  </p>

                  {/* Size Selector */}
                  <div className="pt-2 space-y-2">
                    <label className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
                      Select Size
                    </label>
                    <div className="flex flex-wrap gap-2">
                      {SIZES.map((sz) => (
                        <button
                          key={sz}
                          onClick={() => setSelectedSize(sz)}
                          className={`min-w-[42px] rounded-md border py-2 text-xs font-bold transition-all ${
                            selectedSize === sz
                              ? "border-gold bg-gold text-primary-foreground shadow-goldy"
                              : "border-border bg-background text-foreground hover:border-gold/60"
                          }`}
                        >
                          {sz}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Key Fabric Highlights */}
                <div className="space-y-2 border-t border-border pt-4 text-[11px] text-muted-foreground">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="size-3.5 text-gold shrink-0" />
                    <span>240 GSM 100% Combed Cotton Craftsmanship</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <ShieldCheck className="size-3.5 text-gold shrink-0" />
                    <span>Pre-Shrunk Bio-Washed Fabric</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Sparkles className="size-3.5 text-gold shrink-0" />
                    <span>Free Pan-India Express Delivery & Easy Returns</span>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="pt-2 flex gap-3">
                  <button
                    onClick={(e) => {
                      setShowModal(false);
                      handleOrder(e);
                    }}
                    className="btn-gold hover:btn-gold-hover flex-1 flex items-center justify-center gap-2 rounded-sm py-3 text-xs uppercase tracking-wider font-bold"
                  >
                    <ShoppingBag className="size-4" /> Add to Cart
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
