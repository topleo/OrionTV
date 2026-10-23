import { TVNavigationFocus } from '../TVFocusScope';
import React from 'react';
import { View } from 'react-native';
import { usePathname, useRouter } from 'expo-router';
import { isAppleTV } from '@/constants/TVTheme';
import { NativeTVTabBar } from './NativeTVControls';

const paths = ['/', '/favorites', '/search', '/live', '/settings'] as const;

export function TVNavigation() {
  const { registerNavigation, markNavigationFocus } = React.useContext(TVNavigationFocus);
  const router = useRouter();
  const pathname = usePathname();
  if (!isAppleTV) return null;
  const index = paths.indexOf(pathname as typeof paths[number]);
  return <View style={{ paddingTop: 34, paddingBottom: 24 }}>
    <NativeTVTabBar ref={registerNavigation} style={{ height: 68, width: '100%' }}
      selectedIndex={Math.max(0, index)} onControlFocus={markNavigationFocus}
      onTabSelect={event => {
        const path = paths[event.nativeEvent.index];
        if (path && pathname !== path) router.replace(path);
      }} />
  </View>;
}
