import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect } from "react";

export const Route = createFileRoute("/cart")({
  head: () => ({
    meta: [
      { title: "Shopping Cart | VEXA" },
      { name: "description", content: "View your selected VEXA oversized t-shirts and proceed to order checkout." },
    ],
  }),
  component: CartRedirect,
});

function CartRedirect() {
  const navigate = useNavigate();

  useEffect(() => {
    navigate({ to: "/dashboard", search: { tab: "cart" } });
  }, [navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-6">
      <div className="text-center space-y-3">
        <div className="size-10 rounded-full border-2 border-gold border-t-transparent animate-spin mx-auto" />
        <p className="text-xs uppercase tracking-wider text-muted-foreground font-bold">Loading Your VEXA Cart...</p>
      </div>
    </div>
  );
}
