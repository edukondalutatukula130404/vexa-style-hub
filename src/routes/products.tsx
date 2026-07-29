import { createFileRoute } from "@tanstack/react-router";
import { useMemo, useState } from "react";
import { products } from "@/lib/products";
import { ProductCard } from "@/components/ProductCard";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/products")({
  head: () => ({
    meta: [
      { title: "Shop Premium T-Shirts | VEXA" },
      {
        name: "description",
        content:
          "Browse VEXA oversized, classic and limited-edition premium cotton t-shirts in six colourways.",
      },
      { property: "og:title", content: "Shop Premium T-Shirts | VEXA" },
      {
        property: "og:description",
        content: "Oversized, classic and limited-edition premium cotton tees by VEXA.",
      },
    ],
  }),
  component: Products,
});

const filters = ["All", "Oversized", "Classic", "Limited"] as const;

function Products() {
  const [active, setActive] = useState<(typeof filters)[number]>("All");

  const list = useMemo(
    () => (active === "All" ? products : products.filter((p) => p.category === active)),
    [active],
  );

  return (
    <section className="mx-auto max-w-7xl px-5 py-16">
      <Reveal className="text-center">
        <p className="text-[10px] uppercase tracking-[0.3em] text-gold">The collection</p>
        <h1 className="mt-4 font-display text-4xl sm:text-5xl">Premium T-Shirts</h1>
        <div className="hairline mx-auto mt-6 w-40" />
        <p className="mx-auto mt-6 max-w-xl text-muted-foreground">
          Six colourways. One obsessive standard. Every VEXA tee is cut from 240 GSM
          combed cotton and finished with a reinforced collar.
        </p>
      </Reveal>

      <div className="mt-12 flex flex-wrap justify-center gap-3">
        {filters.map((f) => (
          <button
            key={f}
            onClick={() => setActive(f)}
            className={`rounded-sm px-6 py-2.5 text-[10px] uppercase tracking-[0.22em] transition-all duration-300 ${
              active === f
                ? "btn-gold"
                : "border border-border text-muted-foreground hover:border-gold hover:text-gold"
            }`}
          >
            {f}
          </button>
        ))}
      </div>

      <div className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
        {list.map((p, i) => (
          <Reveal key={p.id} delay={i * 90}>
            <ProductCard product={p} />
          </Reveal>
        ))}
      </div>
    </section>
  );
}
