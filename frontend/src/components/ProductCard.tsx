import { useState, useEffect } from "react";
import { createPortal } from "react-dom";
import { Star, ShoppingBag, Eye, X, Check, ArrowRight, Minus, Plus, Heart } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { SIZES, getVariantStock, type Product, getProductImage } from "@/lib/products";
import heroLuxuryImg from "@/assets/hero_luxury_tshirt.png";
import { useAuth } from "@/lib/auth";
import { addToCart } from "@/lib/cart";
import { useWishlist, toggleWishlist } from "@/lib/wishlist";

export function ProductCard({ product }: { product: Product }) {
  const { isLoggedIn } = useAuth();
  const { isInWishlist } = useWishlist();
  const isWishlisted = isInWishlist(product.id);
  const navigate = useNavigate();
  const [selectedSize, setSelectedSize] = useState("M");
  const [quantity, setQuantity] = useState(1);
  const [showQuickView, setShowQuickView] = useState(false);
  const [addedMsg, setAddedMsg] = useState("");

  const off = Math.round((1 - product.price / product.oldPrice) * 100);

  useEffect(() => {
    if (showQuickView) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [showQuickView]);

  const handleCardClick = () => {
    navigate(`/product/${product.id}`);
  };

  const handleAddToCart = (e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    addToCart(product, selectedSize, quantity);
    setAddedMsg(`Added ${quantity} × ${product.name} (${selectedSize}) to Cart!`);
    setTimeout(() => setAddedMsg(""), 3000);

    window.scrollTo({ top: 0, left: 0, behavior: "instant" });

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
        className="group relative cursor-pointer overflow-hidden rounded-2xl border border-border bg-card transition-all duration-500 hover:-translate-y-1.5 hover:border-gold hover:shadow-goldy flex flex-col justify-between h-full w-full shadow-sm"
      >
        <div className="relative overflow-hidden shrink-0 aspect-[4/5] w-full bg-surface">
          <img
            src={getProductImage(product)}
            alt={`${product.name} in ${product.color}`}
            loading="lazy"
            decoding="async"
            width={900}
            height={1100}
            onError={(e) => {
              (e.target as HTMLImageElement).src = heroLuxuryImg;
            }}
            className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
          />

          {/* Category Pill Badge (Bottom-Left on Image, matching mobile app) */}
          <span className="absolute left-2.5 bottom-2.5 z-10 rounded-md border border-white/20 bg-black/75 px-2.5 py-0.5 text-[9px] uppercase tracking-[0.16em] text-white font-extrabold shadow-sm backdrop-blur-xs">
            {product.category}
          </span>

          {/* Top-Right Badges & Favorite Heart Icon */}
          <div className="absolute right-2.5 top-2.5 z-20 flex items-center gap-1.5">
            {off > 0 && (
              <span className="btn-gold rounded-full px-2 py-0.5 text-[9px] font-extrabold shadow-sm">
                {off}% OFF
              </span>
            )}
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                toggleWishlist(product);
              }}
              className={`flex size-7.5 items-center justify-center rounded-full border transition-all cursor-pointer shadow-md active:scale-90 ${
                isWishlisted
                  ? "border-red-500/80 bg-black/90 text-red-500 shadow-red-500/20"
                  : "border-gold/50 bg-black/70 text-gold hover:bg-gold hover:text-primary-foreground"
              }`}
              title={isWishlisted ? "Remove from Wishlist" : "Save to Wishlist"}
            >
              <Heart className={`size-3.5 transition-all ${isWishlisted ? "fill-red-500 text-red-500 scale-110" : ""}`} />
            </button>
          </div>

          {/* Desktop Hover Action Options Bar (Only visible on >= lg desktop hover) */}
          <div className="hidden lg:flex absolute inset-x-0 bottom-0 z-20 gap-2 bg-black/95 p-3 border-t border-gold/30 transition-all duration-300 ease-out opacity-0 translate-y-full pointer-events-none group-hover:opacity-100 group-hover:translate-y-0 group-hover:pointer-events-auto">
            <button
              onClick={handleAddToCart}
              className="btn-gold hover:btn-gold-hover flex-1 flex items-center justify-center gap-1.5 rounded-sm py-2 text-[10px] uppercase tracking-wider font-bold cursor-pointer shadow-goldy transition-transform active:scale-95"
            >
              <ShoppingBag className="size-3.5" /> Add to Cart
            </button>
            <button
              onClick={(e) => {
                e.stopPropagation();
                setShowQuickView(true);
              }}
              className="btn-outline-gold flex items-center justify-center rounded-sm px-2.5 py-2 text-[10px] font-bold text-gold hover:bg-gold hover:text-primary-foreground cursor-pointer transition-transform active:scale-95"
              title="Quick View Product Details"
            >
              <Eye className="size-3.5" />
            </button>
          </div>
        </div>

        {/* Card Body Info */}
        <div className="space-y-2 p-3.5 flex-1 flex flex-col justify-between">
          <div className="space-y-1">
            <h3 className="font-display text-xs sm:text-sm font-bold text-foreground group-hover:text-gold transition-colors line-clamp-1">
              {product.name}
            </h3>
            <p className="text-[10px] uppercase tracking-[0.16em] text-muted-foreground line-clamp-1">
              {product.color}
            </p>
          </div>

          <div className="flex items-baseline justify-between pt-1.5 border-t border-border/30 mt-auto">
            <div className="flex items-baseline gap-1.5">
              <span className="text-sm sm:text-base font-extrabold text-[#B8860B]">₹{product.price.toLocaleString("en-IN")}</span>
              {product.oldPrice > product.price && (
                <span className="text-[11px] text-muted-foreground line-through">
                  ₹{product.oldPrice.toLocaleString("en-IN")}
                </span>
              )}
            </div>
            <span className="flex items-center gap-0.5 text-[10px] text-gold font-bold">
              <Star className="size-3 fill-current text-gold" />
              {product.rating}
            </span>
          </div>
        </div>
      </article>

      {/* QUICKVIEW MODAL POPUP (Portaled to document.body for 100% DOM isolation) */}
      {showQuickView && typeof document !== "undefined" &&
        createPortal(
          <div
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              setShowQuickView(false);
            }}
            className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 p-4 backdrop-blur-md animate-in fade-in duration-200 overflow-y-auto"
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="relative w-full max-w-3xl overflow-hidden rounded-xl border border-gold/40 bg-card p-6 shadow-goldy sm:p-8 animate-in zoom-in-95 duration-200 my-auto z-[10000]"
            >
              {/* Close Button */}
              <button
                type="button"
                onClick={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  setShowQuickView(false);
                }}
                className="absolute right-3 top-3 z-[10001] flex size-9 items-center justify-center rounded-full border-2 border-gold/60 bg-black/90 text-gold shadow-lg transition-all hover:bg-gold hover:text-primary-foreground active:scale-95 cursor-pointer"
                title="Close Quick View"
              >
                <X className="size-5" />
              </button>

              <div className="grid gap-6 md:grid-cols-2">
                {/* Product Image */}
                <div className="relative overflow-hidden rounded-lg border border-border">
                  <img
                    src={getProductImage(product)}
                    alt={product.name}
                    onError={(e) => {
                      (e.target as HTMLImageElement).src = heroLuxuryImg;
                    }}
                    className="h-80 sm:h-96 w-full object-cover"
                  />
                  <span className="absolute left-3 top-3 rounded-full border border-gold/60 bg-[#f4efe6] px-3.5 py-1 text-[10px] uppercase tracking-wider text-[#1c1917] font-extrabold shadow-md">
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
                      <span className="text-[10px] uppercase tracking-wider text-gold font-bold block">Select Size</span>
                      <div className="flex flex-wrap gap-2">
                        {SIZES.map((sz) => {
                          const szStock = getVariantStock(product.id, product.color, sz, product.stock);
                          const isSzOut = szStock === 0;
                          const isSelected = selectedSize === sz;

                          return (
                            <button
                              key={sz}
                              type="button"
                              onClick={(e) => {
                                e.stopPropagation();
                                setSelectedSize(sz);
                              }}
                              className={`relative min-w-[42px] rounded-md px-3 py-2 text-xs font-bold transition-all cursor-pointer ${
                                isSelected
                                  ? isSzOut
                                    ? "bg-red-500/20 text-red-300 border border-red-500/60 font-extrabold"
                                    : "bg-gold text-primary-foreground shadow-goldy border border-gold font-extrabold scale-105"
                                  : isSzOut
                                  ? "border border-red-500/30 bg-surface/50 text-muted-foreground/60 line-through hover:border-red-500/60"
                                  : "border border-border bg-surface text-muted-foreground hover:border-gold hover:text-gold"
                              }`}
                            >
                              {sz}
                              {isSzOut && (
                                <span className="absolute -top-1 -right-1 flex size-2 items-center justify-center rounded-full bg-red-500" />
                              )}
                            </button>
                          );
                        })}
                      </div>
                    </div>

                    {/* Stock Status Indicator */}
                    {(() => {
                      const vStock = getVariantStock(product.id, product.color, selectedSize, product.stock);
                      const isInStock = vStock > 0;
                      return (
                        <div className="pt-1">
                          {isInStock ? (
                            <p className="text-[11px] font-bold text-emerald-400 flex items-center gap-1.5">
                              <span className="size-2 rounded-full bg-emerald-500 animate-pulse" />
                              IN STOCK: {vStock} units available ({selectedSize})
                            </p>
                          ) : (
                            <p className="text-[11px] font-bold text-red-400 flex items-center gap-1.5">
                              <span className="size-2 rounded-full bg-red-500" />
                              OUT OF STOCK for Size {selectedSize}
                            </p>
                          )}
                        </div>
                      );
                    })()}

                    {/* Quantity Selector */}
                    <div className="flex items-center gap-4 pt-2">
                      <span className="text-[10px] uppercase tracking-wider text-gold font-bold">Quantity</span>
                      <div className="flex items-center rounded-md border border-gold/40 bg-surface shadow-sm">
                        <button
                          type="button"
                          disabled={getVariantStock(product.id, product.color, selectedSize, product.stock) === 0}
                          onClick={(e) => {
                            e.stopPropagation();
                            setQuantity((q) => Math.max(1, q - 1));
                          }}
                          className="p-2.5 text-gold hover:bg-gold hover:text-primary-foreground transition-colors cursor-pointer rounded-l-md disabled:opacity-40 disabled:cursor-not-allowed"
                          title="Decrease quantity"
                        >
                          <Minus className="size-3.5" />
                        </button>
                        <span className="w-10 text-center text-xs font-bold text-foreground font-mono">{quantity}</span>
                        <button
                          type="button"
                          disabled={getVariantStock(product.id, product.color, selectedSize, product.stock) === 0}
                          onClick={(e) => {
                            e.stopPropagation();
                            setQuantity((q) => q + 1);
                          }}
                          className="p-2.5 text-gold hover:bg-gold hover:text-primary-foreground transition-colors cursor-pointer rounded-r-md disabled:opacity-40 disabled:cursor-not-allowed"
                          title="Increase quantity"
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
                    {(() => {
                      const isInStock = getVariantStock(product.id, product.color, selectedSize, product.stock) > 0;
                      return (
                        <button
                          type="button"
                          disabled={!isInStock}
                          onClick={(e) => {
                            e.stopPropagation();
                            if (!isInStock) return;
                            setShowQuickView(false);
                            handleAddToCart(e);
                          }}
                          className={`w-full rounded-sm py-3.5 text-xs font-bold uppercase tracking-wider flex items-center justify-center gap-2 shadow-goldy transition-all ${
                            isInStock
                              ? "btn-gold hover:btn-gold-hover cursor-pointer active:scale-98"
                              : "bg-muted/40 border border-border text-muted-foreground cursor-not-allowed opacity-60"
                          }`}
                        >
                          <ShoppingBag className="size-4" />
                          {isInStock ? "Add to Cart & Checkout" : "Out of Stock"}
                        </button>
                      );
                    })()}

                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setShowQuickView(false);
                        navigate(`/product/${product.id}`);
                      }}
                      className="w-full text-center text-xs text-gold hover:underline font-bold uppercase tracking-wider py-2 cursor-pointer flex items-center justify-center gap-1.5 transition-all"
                    >
                      View Full Product Details & Reviews <ArrowRight className="size-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>,
          document.body
        )}
    </>
  );
}
