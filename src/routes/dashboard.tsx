import { createFileRoute, Link } from "@tanstack/react-router";
import { Package, Heart, Wallet, Truck, ArrowRight } from "lucide-react";
import { products } from "@/lib/products";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/dashboard")({
  head: () => ({
    meta: [
      { title: "My Account Dashboard | VEXA" },
      {
        name: "description",
        content:
          "Track VEXA orders, manage your wishlist, view reward credit and update your saved sizes.",
      },
      { property: "og:title", content: "My Account Dashboard | VEXA" },
      {
        property: "og:description",
        content: "Orders, wishlist, rewards and saved sizes in one place.",
      },
    ],
  }),
  component: Dashboard,
});

const stats = [
  { icon: Package, label: "Total orders", value: "12" },
  { icon: Truck, label: "In transit", value: "2" },
  { icon: Heart, label: "Wishlist", value: "5" },
  { icon: Wallet, label: "Reward credit", value: "₹1,240" },
];

const orders = [
  { id: "VX-1043", item: "Obsidian Oversized Tee", date: "26 Jul 2026", status: "In transit", total: "₹1,499" },
  { id: "VX-1031", item: "Ivory Signature Tee", date: "14 Jul 2026", status: "Delivered", total: "₹1,399" },
  { id: "VX-1019", item: "Desert Sand Tee", date: "02 Jul 2026", status: "Delivered", total: "₹1,549" },
  { id: "VX-1004", item: "Charcoal Luxe Tee", date: "21 Jun 2026", status: "Returned", total: "₹1,449" },
];

const statusStyle: Record<string, string> = {
  "In transit": "border-gold/60 text-gold",
  Delivered: "border-border text-muted-foreground",
  Returned: "border-destructive/50 text-destructive",
};

function Dashboard() {
  return (
    <section className="mx-auto max-w-7xl px-5 py-16">
      <Reveal className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-[10px] uppercase tracking-[0.3em] text-gold">Customer dashboard</p>
          <h1 className="mt-3 font-display text-4xl">Hello, Aarav</h1>
        </div>
        <Link
          to="/admin"
          className="btn-outline-gold inline-flex items-center gap-2 rounded-sm px-6 py-3 text-[10px] hover:bg-gold hover:text-primary-foreground"
        >
          Admin dashboard <ArrowRight className="size-3.5" />
        </Link>
      </Reveal>

      <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((s, i) => (
          <Reveal key={s.label} delay={i * 100}>
            <div className="rounded-sm border border-border bg-card p-7 transition-all duration-500 hover:-translate-y-2 hover:border-gold hover:shadow-goldy">
              <s.icon className="size-6 text-gold" />
              <p className="mt-5 font-display text-3xl text-gold-gradient">{s.value}</p>
              <p className="mt-2 text-[10px] uppercase tracking-[0.22em] text-muted-foreground">
                {s.label}
              </p>
            </div>
          </Reveal>
        ))}
      </div>

      <div className="mt-12 grid gap-8 lg:grid-cols-[1.6fr_1fr]">
        <Reveal>
          <div className="rounded-sm border border-border bg-card p-7">
            <h2 className="font-display text-xl">Recent orders</h2>
            <div className="mt-6 overflow-x-auto">
              <table className="w-full min-w-[520px] text-left text-sm">
                <thead>
                  <tr className="text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
                    <th className="pb-3">Order</th>
                    <th className="pb-3">Item</th>
                    <th className="pb-3">Date</th>
                    <th className="pb-3">Status</th>
                    <th className="pb-3 text-right">Total</th>
                  </tr>
                </thead>
                <tbody>
                  {orders.map((o) => (
                    <tr
                      key={o.id}
                      className="border-t border-border transition-colors duration-300 hover:bg-surface/60"
                    >
                      <td className="py-4 text-gold">{o.id}</td>
                      <td className="py-4">{o.item}</td>
                      <td className="py-4 text-muted-foreground">{o.date}</td>
                      <td className="py-4">
                        <span
                          className={`rounded-full border px-3 py-1 text-[10px] uppercase tracking-[0.15em] ${statusStyle[o.status]}`}
                        >
                          {o.status}
                        </span>
                      </td>
                      <td className="py-4 text-right">{o.total}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </Reveal>

        <Reveal delay={140}>
          <div className="rounded-sm border border-border bg-card p-7">
            <h2 className="font-display text-xl">Your wishlist</h2>
            <div className="mt-6 space-y-4">
              {products.slice(0, 3).map((p) => (
                <div key={p.id} className="group flex items-center gap-4">
                  <img
                    src={p.image}
                    alt={p.name}
                    loading="lazy"
                    width={900}
                    height={1100}
                    className="size-16 rounded-sm object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <div className="flex-1">
                    <p className="text-sm">{p.name}</p>
                    <p className="text-xs text-muted-foreground">₹{p.price}</p>
                  </div>
                  <button className="btn-outline-gold rounded-sm px-3 py-2 text-[9px] hover:bg-gold hover:text-primary-foreground">
                    Add
                  </button>
                </div>
              ))}
            </div>
            <Link
              to="/products"
              className="btn-gold hover:btn-gold-hover mt-7 block rounded-sm py-3 text-center text-[10px]"
            >
              Continue shopping
            </Link>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
