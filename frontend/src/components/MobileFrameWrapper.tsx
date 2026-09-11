import React, { useState, useEffect } from "react";
import {
  Smartphone,
  Monitor,
  ChevronLeft,
  ChevronRight,
  Share,
  BookOpen,
  Copy,
  RotateCw,
  Lock,
  Wifi,
  Battery,
} from "lucide-react";

interface MobileFrameWrapperProps {
  children: React.ReactNode;
}

export function MobileFrameWrapper({ children }: MobileFrameWrapperProps) {
  const [isMobileFrame, setIsMobileFrame] = useState<boolean>(false);
  const [isMobileScreen, setIsMobileScreen] = useState<boolean>(false);
  const [currentTime, setCurrentTime] = useState<string>("4:48 PM");

  useEffect(() => {
    const checkScreen = () => {
      setIsMobileScreen(window.innerWidth < 768);
    };
    checkScreen();
    window.addEventListener("resize", checkScreen);
    return () => window.removeEventListener("resize", checkScreen);
  }, []);

  useEffect(() => {
    const updateClock = () => {
      const now = new Date();
      let hours = now.getHours();
      const minutes = now.getMinutes().toString().padStart(2, "0");
      const ampm = hours >= 12 ? "PM" : "AM";
      hours = hours % 12 || 12;
      setCurrentTime(`${hours}:${minutes} ${ampm}`);
    };
    updateClock();
    const interval = setInterval(updateClock, 30000);
    return () => clearInterval(interval);
  }, []);

  // On mobile screens (<768px) or when mobile frame is off, render full responsive app directly
  if (!isMobileFrame || isMobileScreen) {
    return (
      <div className="relative min-h-screen w-full">
        {/* Floating View Switcher Button (Desktop only) */}
        {!isMobileScreen && (
          <div className="fixed bottom-6 right-6 z-[99999]">
            <button
              onClick={() => setIsMobileFrame(true)}
              className="flex items-center gap-2 rounded-full border border-gold/60 bg-[#1c1917] px-4 py-2.5 text-xs font-bold uppercase tracking-wider text-gold shadow-2xl backdrop-blur-md transition-all hover:scale-105 active:scale-95 cursor-pointer"
            >
              <Smartphone className="size-4" />
              <span>📱 Mobile Simulator</span>
            </button>
          </div>
        )}
        {children}
      </div>
    );
  }

  return (
    <div className="relative min-h-screen w-full bg-[#222224] flex items-center justify-center py-6 sm:py-10 px-2 sm:px-4 select-none">
      {/* Floating Desktop Switcher Toggle */}
      <div className="fixed top-4 right-4 z-[99999]">
        <button
          onClick={() => setIsMobileFrame(false)}
          className="flex items-center gap-1.5 rounded-full border border-gold/40 bg-[#141414]/90 px-3.5 py-2 text-[11px] font-extrabold uppercase tracking-wider text-gold shadow-xl backdrop-blur-md transition-all hover:bg-gold hover:text-black cursor-pointer"
          title="Switch to Full Desktop View"
        >
          <Monitor className="size-3.5" />
          <span>Full Desktop View</span>
        </button>
      </div>

      {/* iPhone 15 Pro Device Mockup Frame Container */}
      <div className="relative w-full max-w-[395px] xs:max-w-[420px] rounded-[52px] border-[12px] border-[#2b2826] bg-[#121110] shadow-[0_30px_70px_rgba(0,0,0,0.95)] ring-1 ring-white/10 flex flex-col overflow-hidden transition-all duration-300">
        
        {/* iOS Top Status Bar */}
        <div className="relative z-[9999] flex items-center justify-between bg-[#141414] px-7 pt-3.5 pb-2 text-white">
          <span className="text-[13px] font-extrabold tracking-tight text-white/90">{currentTime}</span>
          
          {/* Dynamic Island Notch */}
          <div className="absolute left-1/2 top-2.5 -translate-x-1/2 flex items-center gap-2 rounded-full bg-black px-3 py-1 shadow-inner">
            <div className="size-2.5 rounded-full bg-[#101010]" />
            <div className="size-2 rounded-full bg-[#181818]" />
          </div>

          <div className="flex items-center gap-1.5 text-white/90">
            <span className="text-[10px] font-extrabold tracking-tighter">5G</span>
            <Wifi className="size-3.5" />
            <Battery className="size-4" />
          </div>
        </div>

        {/* Scrollable Mobile Viewport Content Container */}
        <div className="relative flex-1 overflow-y-auto no-scrollbar max-h-[700px] xs:max-h-[740px] min-h-[640px] bg-background">
          {children}
        </div>

        {/* Safari Bottom Address Bar & Browser Controls */}
        <div className="relative z-[9999] border-t border-white/10 bg-[#1c1c1e] p-3 text-white">
          {/* URL Address Input Bar */}
          <div className="mx-auto flex items-center justify-between rounded-xl bg-[#2c2c2e] px-4 py-2 text-xs text-white/90 shadow-inner">
            <div className="flex items-center gap-2 text-xs">
              <span className="font-semibold text-white/70">Aa</span>
              <Lock className="size-3 text-emerald-400" />
              <span className="font-medium tracking-tight text-white/90">clothing.speshway.site</span>
            </div>
            <RotateCw className="size-3.5 text-white/60 hover:text-white cursor-pointer" />
          </div>

          {/* Safari Footer Navigation Toolbar */}
          <div className="mt-2.5 flex items-center justify-around px-2 text-white/70">
            <button title="Back" className="p-1 hover:text-white transition-colors cursor-pointer">
              <ChevronLeft className="size-5" />
            </button>
            <button title="Forward" className="p-1 hover:text-white transition-colors cursor-pointer">
              <ChevronRight className="size-5" />
            </button>
            <button title="Share" className="p-1 hover:text-white transition-colors cursor-pointer">
              <Share className="size-4.5" />
            </button>
            <button title="Bookmarks" className="p-1 hover:text-white transition-colors cursor-pointer">
              <BookOpen className="size-4.5" />
            </button>
            <button title="Tabs" className="p-1 hover:text-white transition-colors cursor-pointer">
              <Copy className="size-4.5" />
            </button>
          </div>

          {/* iOS Home Indicator Bar */}
          <div className="mx-auto mt-2 h-1 w-32 rounded-full bg-white/40" />
        </div>
      </div>
    </div>
  );
}
