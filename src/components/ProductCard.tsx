import { Star } from "lucide-react";
import type { Product } from "@/lib/products";

export function ProductCard({ product }: { product: Product }) {
  const off = Math.round((1 - product.price / product.oldPrice) * 100);

  return (
    <article className="group relative overflow-hidden rounded-sm border border-border bg-card transition-all duration-500 hover:-translate-y-2 hover:border-gold hover:shadow-goldy">
      <div className="relative overflow-hidden">
        <img
          src={product.image}
          alt={`${product.name} in ${product.color}`}
          loading="lazy"
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
          <button className="btn-gold hover:btn-gold-hover w-full rounded-sm py-2.5 text-[10px]">
            Add to Cart
          </button>
        </div>
      </div>

      <div className="space-y-2 p-5">
        <div className="flex items-center justify-between">
          <h3 className="font-display text-base text-foreground">{product.name}</h3>
          <span className="flex items-center gap-1 text-xs text-gold">
            <Star className="size-3 fill-current" />
            {product.rating}
          </span>
        </div>
        <p className="text-xs uppercase tracking-[0.18em] text-muted-foreground">
          {product.color}
        </p>
        <div className="flex items-baseline gap-3 pt-1">
          <span className="text-lg text-gold">₹{product.price}</span>
          <span className="text-sm text-muted-foreground line-through">
            ₹{product.oldPrice}
          </span>
        </div>
      </div>
    </article>
  );
}
