import black from "@/assets/tee-black.jpg";
import white from "@/assets/tee-white.jpg";
import navy from "@/assets/tee-navy.jpg";
import beige from "@/assets/tee-beige.jpg";
import charcoal from "@/assets/tee-charcoal.jpg";
import olive from "@/assets/tee-olive.jpg";
import luxuryGold from "@/assets/hero_luxury_tshirt.png";
import rust from "@/assets/tee-rust.png";

export type Product = {
  id: string;
  name: string;
  price: number;
  oldPrice: number;
  image: string;
  category: "Oversized" | "Classic" | "Limited";
  color: string;
  rating: number;
  stock: number;
};

export const SIZES = ["XS", "S", "M", "L", "XL", "XXL"] as const;

export const products: Product[] = [
  {
    id: "vx-00",
    name: "Gold-Embroidered Luxe Tee",
    price: 1799,
    oldPrice: 2499,
    image: luxuryGold,
    category: "Limited",
    color: "Luxury Cream & Gold",
    rating: 5.0,
    stock: 12,
  },
  {
    id: "vx-07",
    name: "Vintage Rust Oversized Tee",
    price: 1699,
    oldPrice: 2399,
    image: rust,
    category: "Oversized",
    color: "Vintage Rust",
    rating: 4.9,
    stock: 15,
  },
  {
    id: "vx-01",
    name: "Obsidian Oversized Tee",
    price: 1499,
    oldPrice: 2199,
    image: black,
    category: "Oversized",
    color: "Jet Black",
    rating: 4.9,
    stock: 42,
  },
  {
    id: "vx-02",
    name: "Ivory Signature Tee",
    price: 1399,
    oldPrice: 1999,
    image: white,
    category: "Classic",
    color: "Ivory",
    rating: 4.8,
    stock: 27,
  },
  {
    id: "vx-03",
    name: "Midnight Navy Tee",
    price: 1599,
    oldPrice: 2299,
    image: navy,
    category: "Oversized",
    color: "Navy",
    rating: 4.7,
    stock: 18,
  },
  {
    id: "vx-04",
    name: "Desert Sand Tee",
    price: 1549,
    oldPrice: 2149,
    image: beige,
    category: "Limited",
    color: "Sand",
    rating: 5.0,
    stock: 9,
  },
  {
    id: "vx-05",
    name: "Charcoal Luxe Tee",
    price: 1449,
    oldPrice: 2099,
    image: charcoal,
    category: "Classic",
    color: "Charcoal",
    rating: 4.6,
    stock: 33,
  },
  {
    id: "vx-06",
    name: "Olive Heritage Tee",
    price: 1649,
    oldPrice: 2399,
    image: olive,
    category: "Limited",
    color: "Olive",
    rating: 4.9,
    stock: 6,
  },
];

import { useState, useEffect } from "react";
import { API_URL } from "@/lib/auth";

export function mapDbItemToProduct(item: any): Product {
  let cat = item.category || "Oversized";
  if (cat.toLowerCase().includes("over")) cat = "Oversized";
  else if (cat.toLowerCase().includes("class")) cat = "Classic";
  else if (cat.toLowerCase().includes("limit")) cat = "Limited";

  return {
    id: item._id || item.id || `db-${Math.random()}`,
    name: item.name || "Custom Tee",
    price: Number(item.price) || 1499,
    oldPrice: Number(item.oldPrice) || Math.round((Number(item.price) || 1499) * 1.35),
    image: item.image && item.image.trim() ? item.image : luxuryGold,
    category: cat as any,
    color: item.color || "Signature Drop",
    rating: Number(item.rating) || 5.0,
    stock: item.inStock !== false ? 25 : 0,
  };
}

export function useProducts() {
  const [allProducts, setAllProducts] = useState<Product[]>(() => {
    // Initial sync from localStorage custom items
    let localCustom: Product[] = [];
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("vexa_custom_items");
        if (stored) {
          const parsed = JSON.parse(stored);
          if (Array.isArray(parsed)) {
            localCustom = parsed.map(mapDbItemToProduct);
          }
        }
      } catch (err) {
        console.warn("Error parsing local custom items:", err);
      }
    }
    const dbNames = new Set(localCustom.map((p) => p.name.toLowerCase()));
    const filteredDefaults = products.filter(
      (p) => !dbNames.has(p.name.toLowerCase())
    );
    return [...localCustom, ...filteredDefaults];
  });

  const [loading, setLoading] = useState(true);

  const fetchDbProducts = async () => {
    let apiProducts: Product[] = [];
    try {
      const res = await fetch(`${API_URL}/items`);
      if (res.ok) {
        const data = await res.json();
        const dbItems = Array.isArray(data) ? data : data.data || [];
        if (Array.isArray(dbItems) && dbItems.length > 0) {
          apiProducts = dbItems.map(mapDbItemToProduct);
        }
      }
    } catch (err) {
      console.warn("Could not fetch database collection items from API:", err);
    }

    // Merge with localStorage custom items
    let localCustom: Product[] = [];
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("vexa_custom_items");
        if (stored) {
          const parsed = JSON.parse(stored);
          if (Array.isArray(parsed)) {
            localCustom = parsed.map(mapDbItemToProduct);
          }
        }
      } catch (err) {
        console.warn("Error reading local custom items:", err);
      }
    }

    // Merge API products and Local custom items (API products take priority)
    const combinedCustom = [...apiProducts];
    const apiIds = new Set(apiProducts.map((p) => p.name.toLowerCase()));
    for (const loc of localCustom) {
      if (!apiIds.has(loc.name.toLowerCase())) {
        combinedCustom.push(loc);
      }
    }

    const customNames = new Set(combinedCustom.map((p) => p.name.toLowerCase()));
    const filteredDefaults = products.filter(
      (p) => !customNames.has(p.name.toLowerCase())
    );

    setAllProducts([...combinedCustom, ...filteredDefaults]);
    setLoading(false);
  };

  useEffect(() => {
    fetchDbProducts();

    const handleUpdate = () => {
      fetchDbProducts();
    };

    window.addEventListener("vexa_items_updated", handleUpdate);
    window.addEventListener("storage", handleUpdate);
    return () => {
      window.removeEventListener("vexa_items_updated", handleUpdate);
      window.removeEventListener("storage", handleUpdate);
    };
  }, []);

  return { products: allProducts, loading, refreshProducts: fetchDbProducts };
}


