import React, { createContext, useMemo, useState } from 'react';

// Each screen owns its native destination. Hidden stack screens must never replace it.
export const TVNavigationFocus = createContext<{
  navigationTarget?: number;
  setNavigationTarget: (target: number | undefined) => void;
}>({ setNavigationTarget: () => {} });
export const TVGridFirstRow = createContext(false);

export function TVFocusScope({ children }: { children: React.ReactNode }) {
  const [navigationTarget, setNavigationTarget] = useState<number>();
  const value = useMemo(() => ({ navigationTarget, setNavigationTarget }), [navigationTarget]);
  return <TVNavigationFocus.Provider value={value}>{children}</TVNavigationFocus.Provider>;
}
