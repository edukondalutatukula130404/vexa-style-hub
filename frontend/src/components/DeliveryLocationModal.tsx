import React, { useState, useEffect } from "react";
import { MapPin, Compass, X, Check, Search, Building2, Loader2, AlertCircle } from "lucide-react";

interface DeliveryLocationModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentLocation: string;
  onSelectLocation: (location: string) => void;
}

interface SavedAddress {
  id: string;
  name: string;
  address: string;
  city: string;
  state: string;
  pincode: string;
  mobile?: string;
}

const POPULAR_CITIES = [
  { city: "Hyderabad", pincode: "500081" },
  { city: "Bengaluru", pincode: "560001" },
  { city: "Mumbai", pincode: "400001" },
  { city: "Delhi", pincode: "110001" },
  { city: "Chennai", pincode: "600001" },
  { city: "Pune", pincode: "411001" },
];

export function DeliveryLocationModal({
  isOpen,
  onClose,
  currentLocation,
  onSelectLocation,
}: DeliveryLocationModalProps) {
  const [pincode, setPincode] = useState("");
  const [isCheckingPincode, setIsCheckingPincode] = useState(false);
  const [deliveryStatus, setDeliveryStatus] = useState<"available" | "unavailable" | null>(null);
  const [detectedLocation, setDetectedLocation] = useState<string | null>(null);
  const [isDetectingGPS, setIsDetectingGPS] = useState(false);
  const [savedAddresses, setSavedAddresses] = useState<SavedAddress[]>([]);

  useEffect(() => {
    if (isOpen) {
      setPincode("");
      setDeliveryStatus(null);
      setDetectedLocation(null);
      setIsCheckingPincode(false);
      setIsDetectingGPS(false);

      // Load saved addresses from localStorage
      try {
        const raw = localStorage.getItem("vexa_saved_addresses");
        if (raw) {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed) && parsed.length > 0) {
            setSavedAddresses(parsed);
          }
        }
      } catch {}
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleCheckPincode = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const cleanPin = pincode.trim();

    if (!cleanPin || cleanPin.length !== 6 || !/^[1-9][0-9]{5}$/.test(cleanPin)) {
      setDeliveryStatus("unavailable");
      setDetectedLocation(null);
      return;
    }

    setIsCheckingPincode(true);
    setDeliveryStatus(null);
    setDetectedLocation(null);

    try {
      const res = await fetch(`https://api.postalpincode.in/pincode/${cleanPin}`);
      const data = await res.json();

      if (Array.isArray(data) && data[0]?.Status === "Success" && data[0]?.PostOffice?.length > 0) {
        const po = data[0].PostOffice[0];
        const place = [po.Name, po.District, po.State].filter(Boolean).join(", ");
        setDetectedLocation(place);
        setDeliveryStatus("available");
      } else {
        setDeliveryStatus("unavailable");
      }
    } catch {
      // Fallback check
      if (cleanPin.startsWith("500") || cleanPin.startsWith("560") || cleanPin.startsWith("400") || cleanPin.startsWith("110")) {
        setDetectedLocation(`Region ${cleanPin}`);
        setDeliveryStatus("available");
      } else {
        setDeliveryStatus("unavailable");
      }
    } finally {
      setIsCheckingPincode(false);
    }
  };

  const handleSelectPincode = (pin: string, locationName?: string) => {
    const display = locationName ? `${locationName} (${pin})` : `Pincode ${pin}`;
    onSelectLocation(display);
    onClose();
  };

  const handleUseCurrentLocation = async () => {
    setIsDetectingGPS(true);

    const applyLocation = (city: string, state: string, pin: string) => {
      const display = `${city}, ${state} (${pin})`;
      onSelectLocation(display);
      setIsDetectingGPS(false);
      onClose();
    };

    try {
      // Try freeipapi (HTTPS)
      const res = await fetch("https://freeipapi.com/api/json");
      if (res.ok) {
        const data = await res.json();
        if (data.cityName) {
          applyLocation(data.cityName, data.regionName || "Telangana", data.zipCode || "500081");
          return;
        }
      }
    } catch {}

    // Fallback default
    applyLocation("Hyderabad", "Telangana", "500081");
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
      <div
        className="w-full sm:max-w-md bg-white dark:bg-[#0F172A] rounded-t-[24px] sm:rounded-2xl shadow-2xl border border-border/80 overflow-hidden flex flex-col max-h-[90vh] sm:max-h-[85vh] animate-in slide-in-from-bottom-6 sm:zoom-in-95 duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border/60 bg-slate-50/50 dark:bg-slate-900/40">
          <div className="flex items-center gap-2.5">
            <div className="flex size-8 items-center justify-center rounded-full bg-gold/15 text-gold-dark">
              <MapPin className="size-4 text-gold fill-gold/20" />
            </div>
            <h2 className="font-display text-[15px] font-bold tracking-wider text-foreground">
              DELIVERY LOCATION
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-full text-muted-foreground hover:text-foreground hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors"
            aria-label="Close"
          >
            <X className="size-5" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {/* Card 1: Pincode Check */}
          <div className="p-4 rounded-xl border border-border/80 bg-white dark:bg-slate-900/60 shadow-xs">
            <label className="block text-[11px] font-bold uppercase tracking-wider text-gold-dark mb-2.5">
              Enter Delivery Pincode
            </label>
            <form onSubmit={handleCheckPincode} className="flex gap-2">
              <div className="relative flex-1">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
                <input
                  type="text"
                  maxLength={6}
                  value={pincode}
                  onChange={(e) => {
                    const val = e.target.value.replace(/\D/g, "");
                    setPincode(val);
                    if (deliveryStatus) setDeliveryStatus(null);
                    if (val.length === 6) {
                      setTimeout(() => handleCheckPincode(), 50);
                    }
                  }}
                  placeholder="Enter 6-digit Pincode"
                  className="w-full pl-9 pr-3 py-2 text-sm rounded-lg border border-border bg-slate-50/70 dark:bg-slate-800/60 text-foreground font-semibold placeholder:text-muted-foreground/60 focus:outline-hidden focus:ring-1 focus:ring-gold"
                />
              </div>
              <button
                type="submit"
                disabled={isCheckingPincode || pincode.length !== 6}
                className="px-4 py-2 rounded-lg bg-gold-dark hover:bg-gold text-white font-bold text-xs tracking-wider uppercase transition-colors disabled:opacity-50 shrink-0"
              >
                {isCheckingPincode ? <Loader2 className="size-4 animate-spin" /> : "Check"}
              </button>
            </form>

            {/* Pincode Availability Status */}
            {isCheckingPincode && (
              <div className="mt-2.5 flex items-center gap-1.5 text-xs text-muted-foreground">
                <Loader2 className="size-3.5 animate-spin text-gold" />
                <span>Checking delivery serviceability...</span>
              </div>
            )}

            {deliveryStatus === "available" && (
              <div className="mt-2.5 flex items-center justify-between p-2 rounded-md bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800">
                <div className="flex items-center gap-2">
                  <Check className="size-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                  <div className="flex flex-col">
                    <span className="text-xs font-bold text-emerald-700 dark:text-emerald-400">
                      Delivery available
                    </span>
                    {detectedLocation && (
                      <span className="text-[11px] text-emerald-600/80 dark:text-emerald-500 font-medium truncate max-w-[180px]">
                        {detectedLocation}
                      </span>
                    )}
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => handleSelectPincode(pincode, detectedLocation || undefined)}
                  className="px-2.5 py-1 text-[11px] font-bold bg-emerald-600 hover:bg-emerald-700 text-white rounded shadow-xs transition-colors shrink-0"
                >
                  Apply
                </button>
              </div>
            )}

            {deliveryStatus === "unavailable" && (
              <div className="mt-2.5 flex items-center gap-2 p-2 rounded-md bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-400">
                <AlertCircle className="size-4 shrink-0" />
                <span className="text-xs font-semibold">Delivery not available for this pincode</span>
              </div>
            )}
          </div>

          {/* Card 2: Use Current Location */}
          <button
            type="button"
            onClick={handleUseCurrentLocation}
            disabled={isDetectingGPS}
            className="w-full p-3.5 rounded-xl border border-border/80 bg-white dark:bg-slate-900/60 hover:border-gold/60 transition-all flex items-center justify-between shadow-xs group text-left"
          >
            <div className="flex items-center gap-3">
              <div className="flex size-9 items-center justify-center rounded-full bg-gold/15 text-gold-dark group-hover:scale-105 transition-transform">
                {isDetectingGPS ? (
                  <Loader2 className="size-4.5 animate-spin text-gold" />
                ) : (
                  <Compass className="size-4.5 text-gold" />
                )}
              </div>
              <div>
                <p className="text-sm font-bold text-foreground">Use Current Location</p>
                <p className="text-xs text-muted-foreground">
                  {isDetectingGPS ? "Detecting location via GPS..." : "Detect automatically via device GPS"}
                </p>
              </div>
            </div>
          </button>

          {/* Card 3: Saved Addresses (if any) */}
          {savedAddresses.length > 0 && (
            <div>
              <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-2">
                Saved Addresses
              </h3>
              <div className="space-y-2">
                {savedAddresses.map((addr) => {
                  const display = `${addr.city}, ${addr.state} (${addr.pincode})`;
                  const isSelected = currentLocation.includes(addr.pincode);
                  return (
                    <button
                      key={addr.id}
                      type="button"
                      onClick={() => {
                        onSelectLocation(display);
                        onClose();
                      }}
                      className={`w-full p-3 rounded-xl border text-left transition-all flex items-start gap-3 ${
                        isSelected
                          ? "border-gold bg-gold/5 dark:bg-gold/10"
                          : "border-border/70 hover:border-border bg-white dark:bg-slate-900/40"
                      }`}
                    >
                      <MapPin className={`size-4 mt-0.5 shrink-0 ${isSelected ? "text-gold" : "text-muted-foreground"}`} />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between">
                          <span className="text-xs font-bold text-foreground truncate">{addr.name}</span>
                          {isSelected && (
                            <span className="text-[10px] font-bold text-gold uppercase tracking-wider">Active</span>
                          )}
                        </div>
                        <p className="text-xs text-muted-foreground truncate mt-0.5">{addr.address}</p>
                        <p className="text-xs font-semibold text-foreground mt-0.5">
                          {addr.city}, {addr.state} - {addr.pincode}
                        </p>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Card 4: Quick Select Cities */}
          <div>
            <h3 className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground mb-2">
              Popular Delivery Hubs
            </h3>
            <div className="grid grid-cols-2 gap-2">
              {POPULAR_CITIES.map((c) => {
                const label = `${c.city} ${c.pincode}`;
                const isSelected = currentLocation.includes(c.pincode);
                return (
                  <button
                    key={c.city}
                    type="button"
                    onClick={() => {
                      onSelectLocation(label);
                      onClose();
                    }}
                    className={`py-2 px-3 rounded-lg border text-xs font-semibold text-left transition-all flex items-center justify-between ${
                      isSelected
                        ? "border-gold bg-gold/10 text-gold-dark font-bold"
                        : "border-border/70 hover:border-gold/40 text-foreground bg-slate-50/50 dark:bg-slate-800/40"
                    }`}
                  >
                    <span>{c.city}</span>
                    <span className="text-[10px] text-muted-foreground">{c.pincode}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
