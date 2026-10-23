import React, { createContext, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { BackHandler, View, findNodeHandle, useTVEventHandler } from 'react-native';
import { useIsFocused } from '@react-navigation/native';
import { isAppleTV } from '@/constants/TVTheme';

type NavigationFocus = {
  navigationTarget?: number;
  registerNavigation: (view: View | null) => void;
  markContentFocus: (firstRow: boolean) => void;
  markNavigationFocus: () => void;
};
// Each screen owns its destination; hidden stack screens cannot replace it.
export const TVNavigationFocus = createContext<NavigationFocus>({
  registerNavigation: () => {}, markContentFocus: () => {}, markNavigationFocus: () => {},
});
export const TVGridFirstRow = createContext(false);

export function TVFocusScope({ children }: { children: React.ReactNode }) {
  const [navigationTarget, setNavigationTarget] = useState<number>();
  const navigation = useRef<View | null>(null);
  const region = useRef<'navigation' | 'firstRow' | 'content'>('navigation');
  const pendingFocus = useRef<ReturnType<typeof setTimeout>>();
  const isFocused = useIsFocused();
  const registerNavigation = useCallback((view: View | null) => {
    navigation.current = view;
    setNavigationTarget(view ? findNodeHandle(view) ?? undefined : undefined);
  }, []);
  const markContentFocus = useCallback((firstRow: boolean) => { region.current = firstRow ? 'firstRow' : 'content'; }, []);
  const markNavigationFocus = useCallback(() => { region.current = 'navigation'; }, []);
  const focusNavigation = useCallback(() => {
    if (!navigation.current) return false;
    region.current = 'navigation';
    clearTimeout(pendingFocus.current);
    // Apply after UIKit handles the directional event, so ScrollView cannot retain it.
    pendingFocus.current = setTimeout(() => navigation.current?.requestTVFocus(), 20);
    return true;
  }, []);
  useTVEventHandler(event => {
    if (isAppleTV && isFocused && ['up', 'longUp', 'swipeUp'].includes(event.eventType) && region.current === 'firstRow') {
      focusNavigation();
    }
  });
  useEffect(() => {
    if (!isAppleTV || !isFocused) return;
    const subscription = BackHandler.addEventListener('hardwareBackPress', () =>
      region.current !== 'navigation' && focusNavigation());
    return () => subscription.remove();
  }, [focusNavigation, isFocused]);
  useEffect(() => () => clearTimeout(pendingFocus.current), []);
  const value = useMemo(() => ({ navigationTarget, registerNavigation, markContentFocus, markNavigationFocus }),
    [navigationTarget, registerNavigation, markContentFocus, markNavigationFocus]);
  return <TVNavigationFocus.Provider value={value}>{children}</TVNavigationFocus.Provider>;
}
