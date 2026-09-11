import black from "@/assets/tee-black.jpg";
import white from "@/assets/tee-white.jpg";
import navy from "@/assets/tee-navy.jpg";
import beige from "@/assets/tee-beige.jpg";
import charcoal from "@/assets/tee-charcoal.jpg";
import olive from "@/assets/tee-olive.jpg";
import luxuryGold from "@/assets/hero_luxury_tshirt.png";
import rust from "@/assets/tee-rust.png";
import emerald from "@/assets/tee-emerald.png";
import lavender from "@/assets/tee-lavender.png";

export type Product = {
  id: string;
  name: string;
  price: number;
  oldPrice: number;
  image: string;
  category: "Oversized" | "Classic" | "Limited";
  color: string;
  colors?: string[];
  description?: string;
  rating: number;
  stock: number;
  isNewDrop?: boolean;
};

export const SIZES = ["XS", "S", "M", "L", "XL", "XXL"] as const;

export function getVariantStock(
  productId: string,
  color: string,
  size: string,
  baseStock: number = 25
): number {
  if (baseStock === 0) return 0;

  if (typeof window !== "undefined") {
    try {
      const stored = localStorage.getItem("vexa_variant_stocks");
      if (stored) {
        const stocksMap = JSON.parse(stored);
        const key = `${productId}_${color}_${size}`.toLowerCase().replace(/[^a-z0-9]/g, "_");
        if (typeof stocksMap[key] === "number") {
          return stocksMap[key];
        }
      }
    } catch (e) {
      console.warn("Failed reading variant stocks:", e);
    }
  }

  // Deterministic calculation based on product ID, color name, and size
  const str = `${productId}-${color}-${size}`.toLowerCase();
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (hash << 5) - hash + str.charCodeAt(i);
    hash |= 0;
  }
  const absHash = Math.abs(hash);

  // Specific combinations marked as out of stock (0) for demonstration & realistic inventory
  if (size === "XXL" && absHash % 3 === 0) return 0;
  if (size === "XS" && absHash % 4 === 0) return 0;
  if (color.toLowerCase().includes("gold") && size === "S") return 0;
  if (color.toLowerCase().includes("rust") && size === "L") return 0;
  if (absHash % 9 === 0) return 0;

  return Math.max(1, (absHash % (baseStock || 20)) + 3);
}

// 10 Mobile App Products matching Flutter App 1:1
export const products: Product[] = [
  {
    id: "vx-08",
    name: "Emerald Acid Wash Boxy Tee",
    price: 1899,
    oldPrice: 2699,
    image: emerald,
    category: "Limited",
    color: "Emerald Green",
    colors: ["Emerald Green"],
    description: "240 GSM heavyweight cotton with custom emerald acid wash texture and drop-shoulder silhouette.",
    rating: 5.0,
    stock: 14,
    isNewDrop: true,
  },
  {
    id: "vx-12",
    name: "Lavender Lilac Drop-Shoulder Tee",
    price: 1699,
    oldPrice: 2399,
    image: lavender,
    category: "Oversized",
    color: "Pastel Lavender",
    colors: ["Pastel Lavender"],
    description: "240 GSM combed cotton in pastel lilac tone with luxury heavy rib collar.",
    rating: 4.9,
    stock: 18,
    isNewDrop: true,
  },
  {
    id: "vx-00",
    name: "Gold-Embroidered Luxe Tee",
    price: 1799,
    oldPrice: 2499,
    image: luxuryGold,
    category: "Limited",
    color: "Luxury Cream & Gold",
    colors: ["Luxury Cream & Gold"],
    description: "High-density 240 GSM luxury cream cotton featuring metallic gold chest embroidery.",
    rating: 5.0,
    stock: 12,
  },
  {
    id: "vx-07",
    name: "Vintage Rust Heavyweight Tee",
    price: 1699,
    oldPrice: 2399,
    image: rust,
    category: "Oversized",
    color: "Vintage Rust",
    colors: ["Vintage Rust"],
    description: "Heavyweight vintage rust vintage-wash finish, boxy oversized drop-shoulder cut.",
    rating: 4.9,
    stock: 15,
  },
  {
    id: "vx-01",
    name: "Obsidian Stealth Oversized Tee",
    price: 1499,
    oldPrice: 2199,
    image: black,
    category: "Oversized",
    color: "Jet Black",
    colors: ["Jet Black"],
    description: "Deep obsidian black 240 GSM pre-shrunk cotton with subtle tone-on-tone silicone branding.",
    rating: 4.9,
    stock: 42,
  },
  {
    id: "vx-02",
    name: "Ivory Signature Drop-Shoulder Tee",
    price: 1399,
    oldPrice: 1999,
    image: white,
    category: "Classic",
    color: "Ivory White",
    colors: ["Ivory White"],
    description: "Classic ivory white 240 GSM drop-shoulder silhouette with signature rib collar.",
    rating: 4.8,
    stock: 27,
  },
  {
    id: "vx-03",
    name: "Midnight Indigo Heavyweight Tee",
    price: 1599,
    oldPrice: 2299,
    image: navy,
    category: "Oversized",
    color: "Midnight Navy",
    colors: ["Midnight Navy"],
    description: "Rich midnight navy 240 GSM heavyweight tee with double-stitched collar.",
    rating: 4.7,
    stock: 18,
  },
  {
    id: "vx-04",
    name: "Desert Sand Minimalist Tee",
    price: 1549,
    oldPrice: 2149,
    image: beige,
    category: "Limited",
    color: "Desert Sand",
    colors: ["Desert Sand"],
    description: "Clean desert sand 240 GSM minimalist silhouette, bio-washed for lasting softness.",
    rating: 5.0,
    stock: 9,
  },
  {
    id: "vx-05",
    name: "Charcoal Luxe Distressed Tee",
    price: 1449,
    oldPrice: 2099,
    image: charcoal,
    category: "Classic",
    color: "Charcoal Grey",
    colors: ["Charcoal Grey"],
    description: "Charcoal grey 240 GSM distressed-finish luxury tee with relaxed boxy cut.",
    rating: 4.6,
    stock: 33,
  },
  {
    id: "vx-06",
    name: "Olive Military Heritage Tee",
    price: 1649,
    oldPrice: 2399,
    image: olive,
    category: "Limited",
    color: "Military Olive",
    colors: ["Military Olive"],
    description: "Military olive 240 GSM heritage tee with garment-washed finish and relaxed oversized fit.",
    rating: 4.9,
    stock: 6,
  },
];

import { useState, useEffect } from "react";
import { API_URL } from "@/lib/auth";

const localImageById: Record<string, string> = {
  "vx-08": emerald,
  "vx-12": lavender,
  "vx-00": luxuryGold,
  "vx-07": rust,
  "vx-01": black,
  "vx-02": white,
  "vx-03": navy,
  "vx-04": beige,
  "vx-05": charcoal,
  "vx-06": olive,
};

export function getProductImage(item: any): string {
  if (!item) return luxuryGold;
  const itemId = (item.id || item._id || "").toString().trim();
  if (localImageById[itemId]) return localImageById[itemId];

  const nameStr = (item.name || "").toLowerCase().trim();
  if (nameStr.includes("emerald")) return emerald;
  if (nameStr.includes("lavender") || nameStr.includes("lilac")) return lavender;
  if (nameStr.includes("rust")) return rust;
  if (nameStr.includes("sand") || nameStr.includes("desert") || nameStr.includes("beige")) return beige;
  if (nameStr.includes("olive")) return olive;
  if (nameStr.includes("gold") || nameStr.includes("embroidered")) return luxuryGold;
  if (nameStr.includes("obsidian") || nameStr.includes("stealth") || nameStr.includes("black")) return black;
  if (nameStr.includes("ivory") || nameStr.includes("white")) return white;
  if (nameStr.includes("indigo") || nameStr.includes("midnight") || nameStr.includes("navy")) return navy;
  if (nameStr.includes("charcoal")) return charcoal;

  const imgStr = (item.image || "").toLowerCase().trim();
  if (imgStr.includes("emerald")) return emerald;
  if (imgStr.includes("lavender")) return lavender;
  if (imgStr.includes("rust")) return rust;
  if (imgStr.includes("beige") || imgStr.includes("sand")) return beige;
  if (imgStr.includes("olive")) return olive;
  if (imgStr.includes("gold") || imgStr.includes("luxury")) return luxuryGold;
  if (imgStr.includes("black") || imgStr.includes("obsidian")) return black;
  if (imgStr.includes("white") || imgStr.includes("ivory")) return white;
  if (imgStr.includes("navy") || imgStr.includes("indigo")) return navy;
  if (imgStr.includes("charcoal")) return charcoal;

  if (item.image && typeof item.image === "string" && item.image.trim() && !item.image.includes("unsplash.com") && !item.image.startsWith("assets/")) {
    return item.image;
  }

  return luxuryGold;
}

export function mapDbItemToProduct(item: any): Product {
  let cat = item.category || "Oversized";
  if (cat.toLowerCase().includes("over")) cat = "Oversized";
  else if (cat.toLowerCase().includes("class")) cat = "Classic";
  else if (cat.toLowerCase().includes("limit")) cat = "Limited";

  const sellingPrice = Number(item.price) || 1499;
  const mrpPrice = Number(item.oldPrice || item.mrpPrice || item.mrp) || Math.round(sellingPrice * 1.35);
  const colorList = Array.isArray(item.colors) && item.colors.length > 0
    ? item.colors
    : item.color
    ? [item.color]
    : ["Signature Drop"];

  const itemId = (item._id || item.id || "").toString().trim();
  const resolvedImg = getProductImage(item);

  return {
    id: itemId || `db-${Math.random()}`,
    name: item.name || "Custom Tee",
    price: sellingPrice,
    oldPrice: mrpPrice,
    image: resolvedImg,
    category: cat as any,
    color: item.color || colorList[0] || "Signature Drop",
    colors: colorList,
    description: item.description || "",
    rating: Number(item.rating) || 5.0,
    stock: item.inStock !== false ? 25 : 0,
  };
}

function deduplicateProductKeys(list: Product[]): Product[] {
  const seenIds = new Set<string>();
  return list.map((item, idx) => {
    let uniqueId = item.id || `prod-${idx}`;
    if (seenIds.has(uniqueId)) {
      uniqueId = `${item.id}-dup-${idx}`;
    }
    seenIds.add(uniqueId);
    return { ...item, id: uniqueId };
  });
}

export function useProducts() {
  const [allProducts, setAllProducts] = useState<Product[]>(() => products);
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

    const combinedCustom = [...apiProducts];
    const apiNames = new Set(apiProducts.map((p) => p.name.toLowerCase().trim()));
    for (const loc of localCustom) {
      if (!apiNames.has(loc.name.toLowerCase().trim())) {
        combinedCustom.push(loc);
      }
    }

    // 10 Mobile App Products ALWAYS take top priority and lock their images/details
    const defaultSlugs = new Set(products.map((p) => p.name.toLowerCase().trim()));
    const defaultIds = new Set(products.map((p) => p.id.toLowerCase().trim()));

    // Filter out DB or localStorage custom items that duplicate default mobile products or use legacy test names
    const extraCustomItems = combinedCustom.filter((p) => {
      const pId = p.id.toLowerCase().trim();
      const pName = p.name.toLowerCase().trim();
      if (pName.includes("emerald silk") || pName.includes("old product")) return false;
      return !defaultIds.has(pId) && !defaultSlugs.has(pName);
    });

    setAllProducts(deduplicateProductKeys([...products, ...extraCustomItems]));
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



