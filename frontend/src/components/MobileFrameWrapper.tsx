import React from "react";

interface MobileFrameWrapperProps {
  children: React.ReactNode;
}

export function MobileFrameWrapper({ children }: MobileFrameWrapperProps) {
  return (
    <div className="relative min-h-screen w-full">
      {children}
    </div>
  );
}
