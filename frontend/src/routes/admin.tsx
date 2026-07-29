import { createFileRoute, Link } from "@tanstack/react-router";
import { IndianRupee, ShoppingCart, Users, Boxes, ArrowLeft } from "lucide-react";
import { products } from "@/lib/products";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/admin")({
  head: () => ({
    meta: [
      { title: "Admin Dashboard | VEXA Store Control" },
      {
        name: "description",
        content:
          "VEXA admin dashboard: revenue, order volume, customer growth and live inventory levels across the collection.",
      },
      { property: "og:title", content: "Admin Dashboard | VEXA" },
      {
        property: "og:description",
        content: "Revenue, orders, customers and live inventory for the VEXA store.",
      },
    ],
  }),
  component: Admin,
});

const kpis = [
  { icon: IndianRupee, label: "Revenue (30d)", value: "₹8,42,600", delta: "+18.4%" },
  { icon: ShoppingCart, label: "Orders", value: "1,284", delta: "+9.2%" },
  { icon: Users, label: "New customers", value: "376", delta: "+12.7%" },
  { icon: Boxes, label: "Units in stock", value: "135", delta: "-4.1%" },
];

const sales = [42, 58, 51, 74, 66, 88, 79, 96, 84, 108, 97, 124];
const months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];

function Admin() {
  const max = Math.max(...sales);

  return (
    <section className="mx-auto max-w-7xl px-5 py-16">
      <Reveal className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-[10px] uppercase tracking-[0.3em] text-gold">Admin dashboard</p>
          <h1 className="mt-3 font-display text-4xl">Store overview</h1>
        </div>
        <Link
          to="/dashboard"
          className="btn-outline-gold inline-flex items-center gap-2 rounded-sm px-6 py-3 text-[10px] hover:bg-gold hover:text-primary-foreground"
        >
          <ArrowLeft className="size-3.5" /> Customer dashboard
        </Link>
      </Reveal>

      <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {kpis.map((k, i) => (
          <Reveal key={k.label} delay={i * 100}>
            <div className="rounded-sm border border-border bg-card p-7 transition-all duration-500 hover:-translate-y-2 hover:border-gold hover:shadow-goldy">
              <div className="flex items-center justify-between">
                <k.icon className="size-6 text-gold" />
                <span
                  className={`text-xs ${k.delta.startsWith("-") ? "text-destructive" : "text-gold"}`}
                >
                  {k.delta}
                </span>
              </div>
              <p className="mt-5 font-display text-2xl text-gold-gradient">{k.value}</p>
              <p className="mt-2 text-[10px] uppercase tracking-[0.22em] text-muted-foreground">
                {k.label}
              </p>
            </div>
          </Reveal>
        ))}
      </div>

      <div className="mt-12 grid gap-8 lg:grid-cols-[1.4fr_1fr]">
        <Reveal>
          <div className="rounded-sm border border-border bg-card p-7">
            <h2 className="font-display text-xl">Monthly sales</h2>
            <div className="mt-8 flex h-56 items-end gap-2 sm:gap-4">
              {sales.map((v, i) => (
                <div key={i} className="group flex flex-1 flex-col items-center gap-3">
                  <div className="flex w-full flex-1 items-end">
                    <div
                      className="w-full rounded-t-sm transition-all duration-700 group-hover:opacity-100"
                      style={{
                        height: `${(v / max) * 100}%`,
                        background: "var(--gradient-gold)",
                        opacity: 0.75,
                      }}
                    />
                  </div>
                  <span className="text-[10px] text-muted-foreground">{months[i]}</span>
                </div>
              ))}
            </div>
          </div>
        </Reveal>

        <Reveal delay={140}>
          <div className="rounded-sm border border-border bg-card p-7">
            <h2 className="font-display text-xl">Inventory</h2>
            <div className="mt-6 space-y-5">
              {products.map((p) => (
                <div key={p.id}>
                  <div className="flex items-center justify-between text-sm">
                    <span>{p.name}</span>
                    <span className={p.stock < 10 ? "text-destructive" : "text-gold"}>
                      {p.stock}
                    </span>
                  </div>
                  <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-secondary">
                    <div
                      className="h-full rounded-full transition-all duration-1000"
                      style={{
                        width: `${Math.min(100, (p.stock / 50) * 100)}%`,
                        background: "var(--gradient-gold)",
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
