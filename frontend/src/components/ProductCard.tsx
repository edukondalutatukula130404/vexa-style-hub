import { useState } from "react";
import { Star, ShoppingBag, Eye, X, Check, ArrowRight, Minus, Plus } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { SIZES, type Product } from "@/lib/products";
import { useAuth } from "@/lib/auth";
import { addToCart } from "@/lib/cart";

export function ProductCard({ product }: { product: Product }) {
  const { isLoggedIn } = useAuth();
  const navigate = useNavigate();
  const [selectedSize, setSelectedSize] = useState("M");
  const [quantity, setQuantity] = useState(1);
  const [showQuickView, setShowQuickView] = useState(false);
  const [addedMsg, setAddedMsg] = useState("");

  const off = Math.round((1 - product.price / product.oldPrice) * 100);

  const handleCardClick = () => {
    navigate(`/product/${product.id}`);
  };

  const handleAddToCart = (e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    addToCart(product, selectedSize, quantity);
    setAddedMsg(`Added ${quantity} × ${product.name} (${selectedSize}) to Cart!`);
    setTimeout(() => setAddedMsg(""), 3000);

    if (isLoggedIn) {
      navigate("/dashboard?tab=cart");
    } else {
      localStorage.setItem("vexa_redirect_after_login", "/dashboard?tab=cart");
      navigate("/login");
    }
  };

  return (
    <>
      <article
        onClick={handleCardClick}
        className="group relative cursor-pointer overflow-hidden rounded-sm border border-border bg-card transition-all duration-500 hover:-translate-y-2 hover:border-gold hover:shadow-goldy flex flex-col justify-between"
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
          <div className="absolute inset-x-0 bottom-0 z-20 flex gap-2 bg-gradient-to-t from-background/95 via-background/90 to-transparent p-3.5 backdrop-blur-md transition-all duration-300 opacity-100 translate-y-0 lg:opacity-0 lg:translate-y-full lg:group-hover:opacity-100 lg:group-hover:translate-y-0">
            <button
              onClick={handleAddToCart}
              className="btn-gold hover:btn-gold-hover flex-1 flex items-center justify-center gap-1.5 rounded-sm py-2.5 text-[10px] uppercase tracking-wider font-bold cursor-pointer shadow-goldy transition-transform active:scale-95"
            >
              <ShoppingBag className="size-3.5" /> Add to Cart
            </button>
            <button
              onClick={(e) => {
                e.stopPropagation();
                setShowQuickView(true);
              }}
              className="btn-outline-gold flex items-center justify-center rounded-sm px-3 py-2.5 text-[10px] font-bold text-gold hover:bg-gold hover:text-primary-foreground cursor-pointer transition-transform active:scale-95"
              title="Quick View Product Details"
            >
              <Eye className="size-4" />
            </button>
          </div>
        </div>

        <div className="space-y-2 p-5">
          <div className="flex items-center justify-between">
            <h3 className="font-display text-base text-foreground group-hover:text-gold transition-colors">
              {product.name}
            </h3>
            <span className="flex items-center gap-1 text-xs text-gold font-bold">
              <Star className="size-3 fill-current text-gold" />
              {product.rating}
            </span>
          </div>
          <p className="text-xs uppercase tracking-[0.18em] text-muted-foreground">
            {product.color}
          </p>
          <div className="flex items-baseline justify-between pt-1">
            <div className="flex items-baseline gap-2">
              <span className="text-lg font-bold text-gold">₹{product.price.toLocaleString("en-IN")}</span>
              <span className="text-sm text-muted-foreground line-through">
                ₹{product.oldPrice.toLocaleString("en-IN")}
              </span>
            </div>
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                setShowQuickView(true);
              }}
              className="text-[10px] text-gold font-semibold uppercase tracking-wider hover:underline cursor-pointer"
            >
              Quick View →
            </button>
          </div>
        </div>
      </article>

      {/* QUICKVIEW MODAL POPUP */}
      {showQuickView && (
        <div
          onClick={() => setShowQuickView(false)}
          className="fixed inset-0 z-[100] flex items-center justify-center bg-background/80 p-4 backdrop-blur-md animate-in fade-in duration-300"
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="relative w-full max-w-3xl overflow-hidden rounded-xl border border-gold/40 bg-card p-6 shadow-goldy sm:p-8 animate-in zoom-in-95 duration-200"
          >
            {/* Close Button */}
            <button
              onClick={() => setShowQuickView(false)}
              className="absolute right-4 top-4 z-10 flex size-9 items-center justify-center rounded-full border border-gold/40 bg-background/80 text-gold transition-colors hover:bg-gold hover:text-primary-foreground cursor-pointer"
              title="Close Quick View"
            >
              <X className="size-5" />
            </button>

            <div className="grid gap-6 md:grid-cols-2">
              {/* Product Image */}
              <div className="relative overflow-hidden rounded-lg border border-border">
                <img
                  src={product.image}
                  alt={product.name}
                  className="h-80 sm:h-96 w-full object-cover"
                />
                <span className="absolute left-3 top-3 rounded-full border border-gold/60 bg-background/70 px-3 py-1 text-[10px] uppercase tracking-wider text-gold backdrop-blur">
                  {product.category}
                </span>
                <span className="btn-gold absolute right-3 top-3 rounded-full px-3 py-1 text-[10px] font-bold">
                  {off}% OFF
                </span>
              </div>

              {/* Product Info */}
              <div className="flex flex-col justify-between space-y-4">
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] uppercase tracking-widest text-gold font-bold">QUICK VIEW</span>
                    <span className="flex items-center gap-1 text-xs text-gold font-bold">
                      <Star className="size-3.5 fill-current text-gold" />
                      {product.rating} (128 Reviews)
                    </span>
                  </div>

                  <h2 className="font-display text-2xl font-bold text-foreground">{product.name}</h2>
                  <p className="text-xs uppercase tracking-wider text-muted-foreground">
                    Color: <span className="text-foreground font-semibold">{product.color}</span>
                  </p>

                  <div className="flex items-baseline gap-3">
                    <span className="font-display text-2xl font-bold text-gold">₹{product.price.toLocaleString("en-IN")}</span>
                    <span className="text-sm text-muted-foreground line-through">₹{product.oldPrice.toLocaleString("en-IN")}</span>
                    <span className="rounded bg-gold/15 px-2 py-0.5 text-[10px] font-bold text-gold border border-gold/30">
                      Save ₹{(product.oldPrice - product.price).toLocaleString("en-IN")}
                    </span>
                  </div>

                  <p className="text-xs text-muted-foreground leading-relaxed">
                    Crafted from 240 GSM 100% Super Combed Luxury Cotton with an oversized aesthetic fit, heavy rib collar, and pre-shrunk fabric for long-lasting drape and comfort.
                  </p>

                  {/* Size Selector */}
                  <div className="space-y-2 pt-2">
                    <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold block">Select Size</span>
                    <div className="flex flex-wrap gap-2">
                      {SIZES.map((sz) => (
                        <button
                          key={sz}
                          type="button"
                          onClick={() => setSelectedSize(sz)}
                          className={`min-w-[42px] rounded-md px-3 py-1.5 text-xs font-bold transition-all cursor-pointer ${
                            selectedSize === sz
                              ? "bg-gold text-primary-foreground shadow-goldy border border-gold"
                              : "border border-border bg-surface text-muted-foreground hover:border-gold hover:text-gold"
                          }`}
                        >
                          {sz}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Quantity Selector */}
                  <div className="flex items-center gap-4 pt-2">
                    <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Quantity</span>
                    <div className="flex items-center rounded-md border border-border bg-surface">
                      <button
                        type="button"
                        onClick={() => setQuantity((q) => Math.max(1, q - 1))}
                        className="p-2 text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
                      >
                        <Minus className="size-3.5" />
                      </button>
                      <span className="w-8 text-center text-xs font-bold text-foreground">{quantity}</span>
                      <button
                        type="button"
                        onClick={() => setQuantity((q) => q + 1)}
                        className="p-2 text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
                      >
                        <Plus className="size-3.5" />
                      </button>
                    </div>
                  </div>
                </div>

                {addedMsg && (
                  <div className="flex items-center gap-2 rounded-lg border border-gold/40 bg-gold/10 p-3 text-xs text-gold font-bold animate-in fade-in duration-300">
                    <Check className="size-4 shrink-0 text-gold" />
                    <span>{addedMsg}</span>
                  </div>
                )}

                {/* QuickView Action Buttons */}
                <div className="space-y-2 pt-4 border-t border-border">
                  <button
                    type="button"
                    onClick={handleAddToCart}
                    className="btn-gold hover:btn-gold-hover w-full rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider flex items-center justify-center gap-2 cursor-pointer shadow-goldy"
                  >
                    <ShoppingBag className="size-4" /> Add to Cart & Checkout
                  </button>

                  <button
                    type="button"
                    onClick={handleCardClick}
                    className="w-full text-center text-xs text-gold hover:underline font-bold uppercase tracking-wider py-1 cursor-pointer flex items-center justify-center gap-1"
                  >
                    View Full Product Details & Reviews <ArrowRight className="size-3.5" />
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
