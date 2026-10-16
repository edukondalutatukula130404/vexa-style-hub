import React, { useState, useEffect } from "react";
import {
  MapPin,
  Compass,
  X,
  Check,
  Search,
  Building2,
  Loader2,
  AlertCircle,
  ChevronLeft,
  ChevronRight,
  Plus,
  Edit3,
  Trash2,
  Radio,
} from "lucide-react";

interface DeliveryLocationModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentLocation: string;
  onSelectLocation: (location: string) => void;
}

interface SavedAddress {
  id: string;
  type?: "Home" | "Work" | "Other" | string;
  name: string;
  address: string;
  city: string;
  state: string;
  pincode: string;
  mobile?: string;
  phone?: string;
}

const DEFAULT_SEED_ADDRESSES: SavedAddress[] = [
  {
    id: "addr_default_1",
    type: "Home",
    name: "Tatukulaedukondalu",
    phone: "+91 98765 43210",
    address: "Flat 402, Luxury Heights, Jubilee Hills Road No. 36",
    city: "Hyderabad",
    state: "Telangana",
    pincode: "500033",
  },
  {
    id: "addr_default_2",
    type: "Work",
    name: "Tatukulaedukondalu",
    phone: "+91 98765 43210",
    address: "Floor 5, Cyber Towers, HITEC City, Phase 2",
    city: "Hyderabad",
    state: "Telangana",
    pincode: "500081",
  },
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
  const [savedAddresses, setSavedAddresses] = useState<SavedAddress[]>(DEFAULT_SEED_ADDRESSES);
  const [selectedAddressId, setSelectedAddressId] = useState<string>("addr_default_1");

  // Add / Edit Modal Drawer State
  const [isAddEditOpen, setIsAddEditOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formType, setFormType] = useState<string>("Home");
  const [formName, setFormName] = useState("Tatukulaedukondalu");
  const [formAddress, setFormAddress] = useState("");
  const [formCity, setFormCity] = useState("Hyderabad");
  const [formState, setFormState] = useState("Telangana");
  const [formPincode, setFormPincode] = useState("500033");
  const [formPhone, setFormPhone] = useState("+91 98765 43210");

  useEffect(() => {
    if (isOpen) {
      setPincode("");
      setDeliveryStatus(null);
      setDetectedLocation(null);
      setIsCheckingPincode(false);
      setIsDetectingGPS(false);
      setIsAddEditOpen(false);

      // Load saved addresses from localStorage or default seed
      try {
        const raw = localStorage.getItem("vexa_saved_addresses");
        if (raw) {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed) && parsed.length > 0) {
            setSavedAddresses(parsed);
            return;
          }
        }
      } catch {}

      setSavedAddresses(DEFAULT_SEED_ADDRESSES);
      try {
        localStorage.setItem("vexa_saved_addresses", JSON.stringify(DEFAULT_SEED_ADDRESSES));
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
      const display = pin
        ? (state ? `${city}, ${state} (${pin})` : `${city} ${pin}`)
        : (state ? `${city}, ${state}` : city);
      onSelectLocation(display);
      setIsDetectingGPS(false);
      onClose();
    };

    // Helper: Reverse geocode lat/lon coordinates to get accurate locality, city, state, and pincode
    const reverseGeocode = async (latitude: number, longitude: number) => {
      try {
        const [osmRes, bdcRes] = await Promise.allSettled([
          fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=18&addressdetails=1`,
            { headers: { Accept: "application/json" } }
          ).then((r) => (r.ok ? r.json() : null)),
          fetch(
            `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=en`
          ).then((r) => (r.ok ? r.json() : null)),
        ]);

        const osmData = osmRes.status === "fulfilled" ? osmRes.value : null;
        const bdcData = bdcRes.status === "fulfilled" ? bdcRes.value : null;

        const osmAddr = osmData?.address || {};
        const city =
          osmAddr.city ||
          osmAddr.town ||
          osmAddr.village ||
          osmAddr.municipality ||
          bdcData?.city ||
          osmAddr.suburb ||
          osmAddr.county ||
          bdcData?.locality ||
          "";
        const state = osmAddr.state || bdcData?.principalSubdivision || "";
        const pin = osmAddr.postcode || bdcData?.postcode || "";

        if (city || state) {
          return { city: city || state, state, pin };
        }
      } catch (err) {
        console.warn("Reverse geocode failed:", err);
      }
      return null;
    };

    try {
      // 1. Primary: Use real device GPS hardware via navigator.geolocation
      if (typeof navigator !== "undefined" && navigator.geolocation) {
        const getGpsPosition = () =>
          new Promise<GeolocationPosition>((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(resolve, reject, {
              enableHighAccuracy: true,
              timeout: 10000,
              maximumAge: 0,
            });
          });

        try {
          const position = await getGpsPosition();
          const { latitude, longitude } = position.coords;
          const geoResult = await reverseGeocode(latitude, longitude);
          if (geoResult && geoResult.city) {
            applyLocation(geoResult.city, geoResult.state, geoResult.pin);
            return;
          }
        } catch (gpsError) {
          console.warn("Device GPS failed or permission denied, falling back to IP detection:", gpsError);
        }
      }

      // 2. Fallback: IP-based detection with high-accuracy services
      try {
        const ipRes = await fetch("https://ipapi.co/json/");
        if (ipRes.ok) {
          const data = await ipRes.json();
          if (data.city && !data.error) {
            applyLocation(data.city, data.region || "Telangana", data.postal || "");
            return;
          }
        }
      } catch {}

      try {
        const res = await fetch("https://freeipapi.com/api/json");
        if (res.ok) {
          const data = await res.json();
          if (data.cityName) {
            applyLocation(data.cityName, data.regionName || "Telangana", data.zipCode || "");
            return;
          }
        }
      } catch {}

      // 3. Fallback to active saved address if available, or default
      const activeAddress = savedAddresses.find((a) => a.isDefault) || savedAddresses[0];
      if (activeAddress) {
        applyLocation(activeAddress.city, activeAddress.state, activeAddress.pincode);
      } else {
        applyLocation("Hyderabad", "Telangana", "500081");
      }
    } catch {
      applyLocation("Hyderabad", "Telangana", "500081");
    } finally {
      setIsDetectingGPS(false);
    }
  };

  const handleSelectAddress = (addr: SavedAddress) => {
    setSelectedAddressId(addr.id);
    const display = `${addr.city} ${addr.pincode}`;
    onSelectLocation(display);
    onClose();
  };

  const handleRemoveAddress = (id: string, e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    const updated = savedAddresses.filter((a) => a.id !== id);
    setSavedAddresses(updated);
    try {
      localStorage.setItem("vexa_saved_addresses", JSON.stringify(updated));
    } catch {}
  };

  const handleOpenAddAddress = () => {
    setEditingId(null);
    setFormType("Home");
    setFormName("Tatukulaedukondalu");
    setFormAddress("");
    setFormCity("Hyderabad");
    setFormState("Telangana");
    setFormPincode("500033");
    setFormPhone("+91 98765 43210");
    setIsAddEditOpen(true);
  };

  const handleOpenEditAddress = (addr: SavedAddress, e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    setEditingId(addr.id);
    setFormType(addr.type || "Home");
    setFormName(addr.name);
    setFormAddress(addr.address);
    setFormCity(addr.city);
    setFormState(addr.state);
    setFormPincode(addr.pincode);
    setFormPhone(addr.phone || addr.mobile || "+91 98765 43210");
    setIsAddEditOpen(true);
  };

  const handleSaveAddress = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formAddress.trim()) return;

    if (editingId) {
      const updated = savedAddresses.map((a) =>
        a.id === editingId
          ? {
              ...a,
              type: formType,
              name: formName,
              address: formAddress.trim(),
              city: formCity.trim(),
              state: formState.trim(),
              pincode: formPincode.trim(),
              phone: formPhone.trim(),
            }
          : a
      );
      setSavedAddresses(updated);
      try {
        localStorage.setItem("vexa_saved_addresses", JSON.stringify(updated));
      } catch {}
    } else {
      const newAddr: SavedAddress = {
        id: `addr_${Date.now()}`,
        type: formType,
        name: formName,
        address: formAddress.trim(),
        city: formCity.trim(),
        state: formState.trim(),
        pincode: formPincode.trim(),
        phone: formPhone.trim(),
      };
      const updated = [newAddr, ...savedAddresses];
      setSavedAddresses(updated);
      setSelectedAddressId(newAddr.id);
      try {
        localStorage.setItem("vexa_saved_addresses", JSON.stringify(updated));
      } catch {}
    }

    setIsAddEditOpen(false);
  };

  return (
    <>
      {/* ── 1. MOBILE RESPONSIVE ONLY: 1:1 PIXEL-PERFECT REPLICA OF FLUTTER DELIVERY LOCATION SCREEN ── */}
      <div className="block md:hidden fixed inset-0 z-50 bg-[#F8FAFC] dark:bg-background overflow-y-auto flex flex-col animate-in fade-in duration-200">
        {/* Top App Bar */}
        <div className="sticky top-0 z-30 bg-white dark:bg-card border-b border-neutral-200/80 dark:border-neutral-800 px-4 py-3 flex items-center justify-between shadow-xs">
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onClose}
              className="flex size-9 items-center justify-center rounded-full text-foreground hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-90 shrink-0 -ml-1 cursor-pointer"
              aria-label="Back"
            >
              <ChevronLeft className="size-6 text-foreground" strokeWidth={2.4} />
            </button>

            <div className="flex items-center gap-2.5">
              <div className="flex size-7.5 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] border border-[#EADBBE]/70 shrink-0">
                <MapPin className="size-4 fill-[#8B6508]/20" />
              </div>
              <h1 className="font-serif text-[14.5px] font-bold uppercase tracking-widest text-foreground">
                DELIVERY LOCATION
              </h1>
            </div>
          </div>

          <button
            type="button"
            onClick={handleOpenAddAddress}
            className="flex items-center gap-1 text-xs font-bold text-[#8B6508] dark:text-[#E5BF4E] hover:opacity-80 active:scale-95 transition-all cursor-pointer -mr-1"
          >
            <Plus className="size-4" />
            <span>Add New</span>
          </button>
        </div>

        {/* Scrollable Content Body */}
        <div className="flex-1 px-4 py-4 space-y-4 pb-24">
          {/* Card 1: Enter Delivery Pincode */}
          <div className="rounded-2xl border border-neutral-200/90 dark:border-neutral-800 bg-white dark:bg-card p-4 shadow-2xs space-y-2.5">
            <h3 className="text-[11px] font-extrabold uppercase tracking-wider text-[#8B6508] dark:text-[#E5BF4E]">
              ENTER DELIVERY PINCODE
            </h3>
            <form
              onSubmit={handleCheckPincode}
              className={`flex items-center rounded-xl border ${
                deliveryStatus === "available"
                  ? "border-[#16A34A]"
                  : deliveryStatus === "unavailable"
                  ? "border-[#EF4444]"
                  : "border-neutral-200"
              } bg-[#F8FAFC] dark:bg-neutral-900/60 pl-3 pr-1.5 py-1.5 transition-colors`}
            >
              <MapPin className={`size-4 ${deliveryStatus === "available" ? "text-[#16A34A]" : deliveryStatus === "unavailable" ? "text-[#EF4444]" : "text-slate-400"} shrink-0`} />
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
                className="flex-1 bg-transparent px-2.5 text-xs font-semibold text-foreground placeholder:text-slate-400 outline-none"
              />
              <button
                type="submit"
                disabled={isCheckingPincode || pincode.length !== 6}
                className="rounded-lg bg-[#8B6508] hover:bg-[#785506] px-4 py-2 text-xs font-bold text-white transition-all disabled:opacity-50 cursor-pointer shrink-0"
              >
                {isCheckingPincode ? <Loader2 className="size-3.5 animate-spin" /> : "Check"}
              </button>
            </form>

            {/* Pincode Availability Indicator */}
            {isCheckingPincode && (
              <div className="flex items-center gap-2 text-xs text-muted-foreground pt-1">
                <Loader2 className="size-3.5 animate-spin text-[#8B6508]" />
                <span>Checking delivery serviceability...</span>
              </div>
            )}

            {/* Seamless 1:1 Flutter Inline Available Row (No Green Box) */}
            {deliveryStatus === "available" && (
              <button
                type="button"
                onClick={() => handleSelectPincode(pincode, detectedLocation || undefined)}
                className="w-full flex items-center justify-between py-1 cursor-pointer hover:opacity-90 active:scale-[0.99] transition-all"
              >
                <div className="flex items-center gap-1.5">
                  <Check className="size-4 text-[#16A34A] stroke-[2.5]" />
                  <span className="text-[13px] font-bold text-[#16A34A]">Delivery available</span>
                </div>
                <div className="flex items-center gap-0.5 text-[#8B6508] dark:text-[#E5BF4E] text-[11.5px] font-bold">
                  <span>Tap to select</span>
                  <ChevronRight className="size-3.5 stroke-[2.5]" />
                </div>
              </button>
            )}

            {deliveryStatus === "unavailable" && (
              <div className="flex items-center gap-1.5 py-1 text-[#DC2626]">
                <AlertCircle className="size-4 shrink-0 stroke-[2.5] text-[#EF4444]" />
                <span className="text-[13px] font-bold text-[#DC2626]">Delivery not available</span>
              </div>
            )}
          </div>

          {/* Card 2: Use Current Location */}
          <button
            type="button"
            onClick={handleUseCurrentLocation}
            disabled={isDetectingGPS}
            className="w-full rounded-2xl border border-neutral-200/90 dark:border-neutral-800 bg-white dark:bg-card p-3.5 shadow-2xs flex items-center justify-between text-left cursor-pointer active:scale-[0.99] transition-transform"
          >
            <div className="flex items-center gap-3 min-w-0">
              <div className="flex size-9 items-center justify-center rounded-full bg-[#FAF6EE] dark:bg-amber-950/40 text-[#8B6508] dark:text-[#E5BF4E] shrink-0">
                {isDetectingGPS ? (
                  <Loader2 className="size-4 animate-spin text-[#8B6508]" />
                ) : (
                  <Compass className="size-4.5 text-[#8B6508] dark:text-[#E5BF4E]" />
                )}
              </div>
              <div className="min-w-0">
                <h4 className="font-bold text-xs text-foreground">Use Current Location</h4>
                <p className="text-[11.5px] text-muted-foreground mt-0.5">
                  {isDetectingGPS ? "Detecting your GPS location..." : "Detect automatically via device GPS"}
                </p>
              </div>
            </div>
            <ChevronRight className="size-4.5 text-slate-400 shrink-0" />
          </button>

          {/* Section 3: SAVED ADDRESSES */}
          <div className="space-y-3">
            <div className="flex items-center justify-between px-0.5">
              <h3 className="text-xs font-extrabold uppercase tracking-wider text-muted-foreground">
                SAVED ADDRESSES ({savedAddresses.length})
              </h3>
              <button
                type="button"
                onClick={handleOpenAddAddress}
                className="text-xs font-bold text-[#8B6508] dark:text-[#E5BF4E] hover:underline cursor-pointer"
              >
                + Add Address
              </button>
            </div>

            {savedAddresses.map((addr, idx) => {
              const isSelected = selectedAddressId
                ? selectedAddressId === addr.id
                : currentLocation.includes(addr.pincode) || idx === 0;

              return (
                <div
                  key={addr.id}
                  className={`rounded-2xl transition-all shadow-2xs ${
                    isSelected
                      ? "bg-[#FFFDF5] dark:bg-amber-950/20 border-1.5 border-[#D4AF37] dark:border-gold"
                      : "bg-white dark:bg-card border border-neutral-200/90 dark:border-neutral-800"
                  } p-4 space-y-3`}
                >
                  <div
                    onClick={() => handleSelectAddress(addr)}
                    className="flex items-start gap-3 cursor-pointer"
                  >
                    {/* Radio Indicator */}
                    <div className="pt-0.5 shrink-0">
                      {isSelected ? (
                        <div className="size-4.5 rounded-full border-2 border-[#8B6508] flex items-center justify-center">
                          <div className="size-2 rounded-full bg-[#8B6508]" />
                        </div>
                      ) : (
                        <div className="size-4.5 rounded-full border-2 border-slate-300 dark:border-slate-600" />
                      )}
                    </div>

                    {/* Address Details */}
                    <div className="flex-1 min-w-0 space-y-1">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="rounded bg-[#D4AF37]/25 dark:bg-amber-900/40 px-2 py-0.5 text-[9.5px] font-black uppercase tracking-wider text-[#8B6508] dark:text-[#E5BF4E]">
                          {addr.type || "Home"}
                        </span>
                        <span className="font-bold text-[13.5px] text-foreground truncate">
                          {addr.name}
                        </span>
                        {isSelected && (
                          <span className="rounded bg-emerald-50 dark:bg-emerald-950/50 border border-emerald-200 dark:border-emerald-800 px-2 py-0.5 text-[9.5px] font-extrabold text-emerald-600 dark:text-emerald-400 uppercase tracking-wider ml-auto">
                            ACTIVE
                          </span>
                        )}
                      </div>

                      <p className="text-xs text-muted-foreground leading-relaxed pt-0.5">
                        {addr.address}, {addr.city}, {addr.state}, Pincode: {addr.pincode}
                      </p>

                      {(addr.mobile || addr.phone) && (
                        <p className="text-xs text-slate-500 dark:text-slate-400 font-medium pt-0.5">
                          Phone: {addr.mobile || addr.phone}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Divider */}
                  <div className="border-t border-neutral-100 dark:border-neutral-800/80 pt-2 flex items-center justify-between">
                    <span
                      onClick={() => handleSelectAddress(addr)}
                      className={`text-xs font-semibold cursor-pointer ${
                        isSelected ? "text-[#8B6508] dark:text-[#E5BF4E] font-bold" : "text-muted-foreground hover:text-foreground"
                      }`}
                    >
                      {isSelected ? "Tap to reselect" : "Tap to select delivery location"}
                    </span>

                    <div className="flex items-center gap-3">
                      <button
                        type="button"
                        onClick={(e) => handleOpenEditAddress(addr, e)}
                        className="flex items-center gap-1 text-xs font-bold text-[#8B6508] dark:text-[#E5BF4E] hover:underline cursor-pointer"
                      >
                        <Edit3 className="size-3.5" />
                        <span>Edit</span>
                      </button>
                      <button
                        type="button"
                        onClick={(e) => handleRemoveAddress(addr.id, e)}
                        className="flex items-center gap-1 text-xs font-bold text-red-500 hover:text-red-600 hover:underline cursor-pointer"
                      >
                        <Trash2 className="size-3.5" />
                        <span>Remove</span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}

            {/* Bottom CTA Button: ADD NEW DELIVERY ADDRESS */}
            <button
              type="button"
              onClick={handleOpenAddAddress}
              className="w-full rounded-2xl border-1.5 border-[#8B6508] dark:border-gold bg-white dark:bg-card py-3.5 text-xs font-bold uppercase tracking-wider text-[#8B6508] dark:text-[#E5BF4E] hover:bg-[#FAF6EE] dark:hover:bg-amber-950/20 transition-all shadow-2xs active:scale-[0.98] flex items-center justify-center gap-2 cursor-pointer mt-3"
            >
              <MapPin className="size-4" />
              <span>ADD NEW DELIVERY ADDRESS</span>
            </button>
          </div>
        </div>

        {/* Add / Edit Address Drawer Modal */}
        {isAddEditOpen && (
          <div className="fixed inset-0 z-60 bg-black/60 backdrop-blur-xs flex flex-col justify-end p-0">
            <div className="w-full bg-white dark:bg-card rounded-t-[28px] p-5 space-y-4 shadow-2xl max-h-[90vh] overflow-y-auto animate-in slide-in-from-bottom duration-200">
              <div className="flex items-center justify-between border-b border-neutral-100 dark:border-neutral-800 pb-3">
                <h3 className="font-serif text-sm font-bold uppercase tracking-wider text-foreground">
                  {editingId ? "Edit Delivery Address" : "Add New Delivery Address"}
                </h3>
                <button
                  type="button"
                  onClick={() => setIsAddEditOpen(false)}
                  className="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:text-foreground cursor-pointer"
                >
                  <X className="size-4" />
                </button>
              </div>

              <form onSubmit={handleSaveAddress} className="space-y-3.5">
                {/* Type pills */}
                <div>
                  <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground block mb-1.5">
                    Address Type
                  </label>
                  <div className="flex gap-2">
                    {["Home", "Work", "Other"].map((t) => (
                      <button
                        key={t}
                        type="button"
                        onClick={() => setFormType(t)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-bold tracking-wider transition-all cursor-pointer ${
                          formType === t
                            ? "bg-[#8B6508] text-white shadow-xs"
                            : "bg-neutral-100 dark:bg-neutral-800 text-muted-foreground"
                        }`}
                      >
                        {t}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground block mb-1">
                    Contact Name
                  </label>
                  <input
                    type="text"
                    required
                    value={formName}
                    onChange={(e) => setFormName(e.target.value)}
                    placeholder="Enter name"
                    className="w-full rounded-xl border border-neutral-200 bg-[#F8FAFC] dark:bg-neutral-900 px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-[#8B6508]"
                  />
                </div>

                <div>
                  <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground block mb-1">
                    Flat / House / Street Address
                  </label>
                  <textarea
                    required
                    rows={2}
                    value={formAddress}
                    onChange={(e) => setFormAddress(e.target.value)}
                    placeholder="Flat 402, Luxury Heights, Road No. 36"
                    className="w-full rounded-xl border border-neutral-200 bg-[#F8FAFC] dark:bg-neutral-900 px-3.5 py-2 text-xs text-foreground outline-none focus:border-[#8B6508]"
                  />
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground block mb-1">
                      City
                    </label>
                    <input
                      type="text"
                      required
                      value={formCity}
                      onChange={(e) => setFormCity(e.target.value)}
                      className="w-full rounded-xl border border-neutral-200 bg-[#F8FAFC] dark:bg-neutral-900 px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-[#8B6508]"
                    />
                  </div>
                  <div>
                    <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground block mb-1">
                      Pincode
                    </label>
                    <input
                      type="text"
                      maxLength={6}
                      required
                      value={formPincode}
                      onChange={(e) => setFormPincode(e.target.value)}
                      className="w-full rounded-xl border border-neutral-200 bg-[#F8FAFC] dark:bg-neutral-900 px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-[#8B6508]"
                    />
                  </div>
                </div>

                <div>
                  <label className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground block mb-1">
                    Phone Number
                  </label>
                  <input
                    type="tel"
                    required
                    value={formPhone}
                    onChange={(e) => setFormPhone(e.target.value)}
                    placeholder="+91 98765 43210"
                    className="w-full rounded-xl border border-neutral-200 bg-[#F8FAFC] dark:bg-neutral-900 px-3.5 py-2.5 text-xs text-foreground outline-none focus:border-[#8B6508]"
                  />
                </div>

                <div className="pt-2 flex gap-2">
                  <button
                    type="button"
                    onClick={() => setIsAddEditOpen(false)}
                    className="flex-1 rounded-xl border border-neutral-200 py-3 text-xs font-bold text-muted-foreground hover:bg-neutral-50 cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="flex-1 rounded-xl bg-[#8B6508] py-3 text-xs font-bold uppercase tracking-wider text-white shadow-md hover:bg-[#785506] cursor-pointer"
                  >
                    Save Address
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>

      {/* ── 2. DESKTOP MODAL VIEW (PRESERVED FOR DESKTOP SCREENS) ── */}
      <div
        className="hidden md:flex fixed inset-0 z-50 items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200"
        onClick={onClose}
      >
        <div
          className="w-full max-w-md bg-white dark:bg-[#0F172A] rounded-2xl shadow-2xl border border-border/80 overflow-hidden flex flex-col max-h-[85vh] animate-in zoom-in-95 duration-200"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-5 py-4 border-b border-border/60 bg-slate-50/70 dark:bg-slate-900/50 shrink-0">
            <div className="flex items-center gap-2">
              <div className="flex size-8 items-center justify-center rounded-full bg-gold/15 text-gold-dark">
                <MapPin className="size-4 text-gold fill-gold/20" />
              </div>
              <h2 className="font-display text-[15px] font-bold tracking-wider text-foreground">
                DELIVERY LOCATION
              </h2>
            </div>
            <button
              onClick={onClose}
              className="p-1.5 rounded-full text-muted-foreground hover:text-foreground hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors cursor-pointer"
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
          </div>
        </div>
      </div>
    </>
  );
}
