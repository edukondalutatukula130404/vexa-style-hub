import React, { useState } from "react";
import {
  X,
  Link,
  MessageCircle,
  Users,
  Rss,
  Camera,
  Mail,
  MessageSquare,
  Lock,
  FileText,
  Bluetooth,
  Globe,
  HardDrive,
  Download,
  ArrowLeftRight,
  Bookmark,
  Volume2,
  FolderSync,
  Repeat,
  QrCode,
  Ticket,
  Send,
  AtSign,
  UserCheck,
  PlayCircle,
  Sparkles,
  Zap,
  Smile,
  PhoneCall,
  ShoppingBag,
  Wallet,
  Check,
  Share2,
} from "lucide-react";
import { type Product } from "@/lib/products";

interface ShareProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  product: Product;
}

export const ShareProductModal: React.FC<ShareProductModalProps> = ({
  isOpen,
  onClose,
  product,
}) => {
  const [copiedApp, setCopiedApp] = useState<string | null>(null);

  if (!isOpen || !product) return null;

  const productUrl = `https://vexa.style/p/${product.id || "vx-00"}`;
  const shareText = `Check out ${product.name} (₹${product.price}) on VEXA Style Hub!`;

  const encodedUrl = encodeURIComponent(productUrl);
  const encodedText = encodeURIComponent(shareText);
  const encodedCombined = encodeURIComponent(`${shareText}\n${productUrl}`);

  const handleNativeShare = async () => {
    onClose();
    if (typeof window !== "undefined" && (navigator as any).share) {
      try {
        await (navigator as any).share({
          title: product.name,
          text: shareText,
          url: productUrl,
        });
      } catch (_) {
        // Fallback to clipboard if share cancelled
      }
    } else if (typeof window !== "undefined" && navigator.clipboard) {
      await navigator.clipboard.writeText(`${shareText}\n${productUrl}`);
    }
  };

  const shareApps = [
    {
      name: "Copy Link",
      icon: Link,
      badgeBg: "bg-[#2563EB]",
      iconColor: "text-white",
      isCopy: true,
    },
    {
      name: "WhatsApp",
      icon: MessageCircle,
      badgeBg: "bg-[#25D366]",
      iconColor: "text-white",
      url: `https://api.whatsapp.com/send?text=${encodedCombined}`,
    },
    {
      name: "Your groups",
      icon: Users,
      badgeBg: "bg-[#1877F2]",
      iconColor: "text-white",
      url: `https://www.facebook.com/groups/`,
    },
    {
      name: "Feed",
      icon: Rss,
      badgeBg: "bg-[#1877F2]",
      iconColor: "text-white",
      url: `https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`,
    },
    {
      name: "Your story",
      icon: Camera,
      badgeBg: "bg-[#1877F2]",
      iconColor: "text-white",
      url: `https://www.facebook.com/`,
    },
    {
      name: "Gmail",
      icon: Mail,
      badgeBg: "bg-[#F1F5F9]",
      iconColor: "text-[#EA4335]",
      url: `mailto:?subject=${encodedText}&body=${encodedUrl}`,
    },
    {
      name: "Messages",
      icon: MessageSquare,
      badgeBg: "bg-[#1A73E8]",
      iconColor: "text-white",
      url: `sms:?body=${encodedCombined}`,
    },
    {
      name: "Private message",
      icon: Lock,
      badgeBg: "bg-[#0A66C2]",
      iconColor: "text-white",
      url: `https://www.linkedin.com/messaging/`,
    },
    {
      name: "Share in a post",
      icon: FileText,
      badgeBg: "bg-[#0A66C2]",
      iconColor: "text-white",
      url: `https://www.linkedin.com/sharing/share-offsite/?url=${encodedUrl}`,
    },
    {
      name: "Bluetooth",
      icon: Bluetooth,
      badgeBg: "bg-[#E8F0FE]",
      iconColor: "text-[#1A73E8]",
      useNative: true,
    },
    {
      name: "Chrome",
      icon: Globe,
      badgeBg: "bg-[#FEF3C7]",
      iconColor: "text-[#4285F4]",
      url: productUrl,
    },
    {
      name: "Drive",
      icon: HardDrive,
      badgeBg: "bg-[#DCFCE7]",
      iconColor: "text-[#16A34A]",
      url: `https://drive.google.com/`,
    },
    {
      name: "Download",
      icon: Download,
      badgeBg: "bg-[#3B82F6]",
      iconColor: "text-white",
      useNative: true,
    },
    {
      name: "Quick Share",
      icon: ArrowLeftRight,
      badgeBg: "bg-[#2563EB]",
      iconColor: "text-white",
      useNative: true,
    },
    {
      name: "Save",
      icon: Bookmark,
      badgeBg: "bg-[#F1F5F9]",
      iconColor: "text-[#4285F4]",
      isCopy: true,
    },
    {
      name: "Read aloud",
      icon: Volume2,
      badgeBg: "bg-[#3B82F6]",
      iconColor: "text-white",
      useNative: true,
    },
    {
      name: "File share",
      icon: FolderSync,
      badgeBg: "bg-[#0F172A]",
      iconColor: "text-[#38BDF8]",
      useNative: true,
    },
    {
      name: "Share hub",
      icon: Repeat,
      badgeBg: "bg-[#F1F5F9]",
      iconColor: "text-[#0F172A]",
      useNative: true,
    },
    {
      name: "Share via barcode",
      icon: QrCode,
      badgeBg: "bg-[#EF4444]",
      iconColor: "text-white",
      isCopy: true,
    },
    {
      name: "District",
      icon: Ticket,
      badgeBg: "bg-[#7C3AED]",
      iconColor: "text-white",
      useNative: true,
    },
    {
      name: "Messages",
      icon: Send,
      badgeBg: "bg-[#E4405F]",
      iconColor: "text-white",
      url: `https://www.instagram.com/direct/inbox/`,
    },
    {
      name: "Threads",
      icon: AtSign,
      badgeBg: "bg-[#000000]",
      iconColor: "text-white",
      url: `https://www.threads.net/`,
    },
    {
      name: "Teams",
      icon: UserCheck,
      badgeBg: "bg-[#5B5FC7]",
      iconColor: "text-white",
      url: `https://teams.microsoft.com/`,
    },
    {
      name: "Share Nearby\n(data-free)",
      icon: PlayCircle,
      badgeBg: "bg-[#1A73E8]",
      iconColor: "text-white",
      useNative: true,
    },
    {
      name: "ChatGPT",
      icon: Sparkles,
      badgeBg: "bg-[#10A37F]",
      iconColor: "text-white",
      url: `https://chatgpt.com/`,
    },
    {
      name: "Rapido",
      icon: Zap,
      badgeBg: "bg-[#FFCC00]",
      iconColor: "text-[#0F172A]",
      useNative: true,
    },
    {
      name: "Snapchat",
      icon: Smile,
      badgeBg: "bg-[#FFFC00]",
      iconColor: "text-black",
      url: `https://www.snapchat.com/`,
    },
    {
      name: "Truecaller",
      icon: PhoneCall,
      badgeBg: "bg-[#0088FF]",
      iconColor: "text-white",
      useNative: true,
    },
    {
      name: "Products",
      icon: ShoppingBag,
      badgeBg: "bg-[#FEF3C7]",
      iconColor: "text-[#D97706]",
      url: productUrl,
    },
    {
      name: "Paytm",
      icon: Wallet,
      badgeBg: "bg-[#00BAF2]",
      iconColor: "text-white",
      useNative: true,
    },
  ];

  const handleAppClick = (app: (typeof shareApps)[0]) => {
    if (app.useNative && typeof window !== "undefined" && (navigator as any).share) {
      handleNativeShare();
      return;
    }

    if (app.url) {
      window.open(app.url, "_blank", "noopener,noreferrer");
      onClose();
    } else {
      navigator.clipboard.writeText(`${shareText}\n${productUrl}`);
      setCopiedApp(app.name);
      setTimeout(() => {
        setCopiedApp(null);
        onClose();
      }, 1200);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60 backdrop-blur-xs p-0 sm:p-4 animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md rounded-t-3xl sm:rounded-2xl bg-white text-slate-900 shadow-2xl overflow-hidden animate-in slide-in-from-bottom duration-300 border border-slate-200"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header (X on left, "Share" next to it + Installed Apps Native Button) */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100">
          <div className="flex items-center gap-3">
            <button
              onClick={onClose}
              className="p-1 rounded-full text-slate-700 hover:bg-slate-100 transition-colors"
              title="Close"
            >
              <X className="size-6" />
            </button>
            <h2 className="text-lg font-bold text-slate-900 tracking-tight">
              Share
            </h2>
          </div>

          <button
            onClick={handleNativeShare}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold shadow-xs transition-colors cursor-pointer"
          >
            <Share2 className="size-3.5" />
            <span>Installed Apps</span>
          </button>
        </div>

        {/* Product Preview Card */}
        <div className="mx-4 my-2.5 p-2.5 rounded-xl bg-slate-50 border border-slate-200/70 flex items-center gap-3">
          <img
            src={product.image}
            alt={product.name}
            className="size-13 rounded-lg object-cover border border-slate-200/50 shrink-0"
          />
          <div className="min-w-0 flex-1 space-y-0.5">
            <p className="text-xs font-semibold text-slate-900 truncate">
              {product.name} - Buy {product.name} Online at Best Price
            </p>
            <p className="text-[11px] text-slate-500 truncate">
              Check out {product.name} on VEXA Style Hub - {productUrl}
            </p>
          </div>
        </div>

        {/* 4-Column Grid */}
        <div className="p-4 max-h-[70vh] overflow-y-auto">
          <div className="grid grid-cols-4 gap-y-5 gap-x-2">
            {shareApps.map((app, index) => {
              const IconComp = app.icon;
              const isJustCopied = copiedApp === app.name;

              return (
                <button
                  key={`${app.name}-${index}`}
                  onClick={() => handleAppClick(app)}
                  className="flex flex-col items-center group cursor-pointer focus:outline-hidden"
                >
                  <div
                    className={`size-13 rounded-full ${app.badgeBg} flex items-center justify-center transition-transform group-hover:scale-105 group-active:scale-95 shadow-xs`}
                  >
                    {isJustCopied ? (
                      <Check className="size-6 text-emerald-600 animate-in zoom-in" />
                    ) : (
                      <IconComp className={`size-6 ${app.iconColor}`} />
                    )}
                  </div>
                  <span className="text-[11px] font-medium text-slate-700 text-center leading-tight line-clamp-2 mt-1.5 px-0.5 whitespace-pre-line">
                    {app.name}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Toast / Snackbar banner when link copied */}
        {copiedApp && (
          <div className="bg-slate-900 text-white text-xs font-semibold px-4 py-2.5 flex items-center justify-center gap-2 animate-in fade-in">
            <Check className="size-4 text-emerald-400" />
            <span>Link copied to clipboard for {copiedApp}!</span>
          </div>
        )}
      </div>
    </div>
  );
};


