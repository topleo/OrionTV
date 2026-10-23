import { isAppleTV } from '@/constants/TVTheme';
import {Platform, useWindowDimensions} from 'react-native';

export function useScale(): number {
  const {width} = useWindowDimensions();
  return isAppleTV ? Math.max(0.85, Math.min(1.25, width / 1920)) : Platform.isTV ? width / 1000 : 1;
}
