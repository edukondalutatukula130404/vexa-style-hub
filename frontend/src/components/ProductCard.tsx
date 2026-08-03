import { useState } from "react";
import { Star, ShoppingBag, Eye } from "lucide-react";
import { useNavigate } from "@tanstack/react-router";
import type { Product } from "@/lib/products";
import { useAuth } from "@/lib/auth";
import { addToCart } from "@/lib/cart";

export function ProductCard({ product }: { product: Product }) {
  const { isLoggedIn } = useAuth();
  const navigate = useNavigate();
  const [selectedSize] = useState("M");
  const off = Math.round((1 - product.price / product.oldPrice) * 100);

  const handleCardClick = () => {
    navigate({
      to: "/product/$id",
      params: { id: product.id },
    });
  };

  const handleAddToCart = (e: React.MouseEvent) => {
    e.stopPropagation();
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
        <div className="absolute inset-x-0 bottom-0 translate-y-full bg-background/90 p-3.5 backdrop-blur transition-transform duration-500 group-hover:translate-y-0 flex gap-2">
          <button
            onClick={handleAddToCart}
            className="btn-gold hover:btn-gold-hover flex-1 flex items-center justify-center gap-1.5 rounded-sm py-2 text-[10px] uppercase tracking-wider font-bold"
          >
            <ShoppingBag className="size-3.5" /> Add to Cart
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation();
              handleCardClick();
            }}
            className="btn-outline-gold flex items-center justify-center rounded-sm px-3 py-2 text-[10px] font-bold text-gold hover:bg-gold hover:text-primary-foreground"
            title="View Details & Reviews"
          >
            <Eye className="size-3.5" />
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
          <span className="text-[10px] text-gold font-semibold uppercase tracking-wider group-hover:underline">
            View Details & Reviews →
          </span>
        </div>
      </div>
    </article>
  );
}
