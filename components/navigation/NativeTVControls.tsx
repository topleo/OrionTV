import React from 'react';
import { requireNativeComponent, View, ViewProps, NativeSyntheticEvent } from 'react-native';
import { isAppleTV } from '@/constants/TVTheme';

type SelectionEvent = NativeSyntheticEvent<{ index: number }>;
type NativeTabProps = ViewProps & {
  selectedIndex: number;
  onTabSelect: (event: SelectionEvent) => void;
  onControlFocus?: () => void;
};
type NativeMenuProps = ViewProps & {
  title: string;
  options: string[];
  selectedIndex: number;
  onSelect: (event: SelectionEvent) => void;
  onControlFocus?: () => void;
};
// Resolve only on tvOS; other upstream platforms never load these view managers.
export const NativeTVTabBar = isAppleTV ? requireNativeComponent<NativeTabProps>('OrionTVTabBar') : View;
export const NativeTVMenu = isAppleTV ? requireNativeComponent<NativeMenuProps>('OrionTVMenu') : View;
