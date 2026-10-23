/**
 * Below are text styles used in the app, primarily in the ThemedText component.
 */

import { isAppleTV } from './TVTheme';
import {TextStyle} from 'react-native';

export const textStyles = function (
  scale: number,
  linkColor: string,
): {
  [key: string]: TextStyle & {fontSize: number; lineHeight: number};
} {
  if (isAppleTV) return {
    default: { fontSize: 29 * scale, lineHeight: 38 * scale },
    defaultSemiBold: { fontSize: 29 * scale, lineHeight: 38 * scale, fontWeight: '600' },
    title: { fontSize: 48 * scale, lineHeight: 58 * scale, fontWeight: '700' },
    subtitle: { fontSize: 34 * scale, lineHeight: 44 * scale, fontWeight: '600' },
    link: { fontSize: 26 * scale, lineHeight: 34 * scale, color: linkColor },
  };
  return {
    default: {
      fontSize: 16 * scale,
      lineHeight: 24 * scale,
    },
    defaultSemiBold: {
      fontSize: 16 * scale,
      lineHeight: 24 * scale,
      fontWeight: '600',
    },
    title: {
      fontSize: 32 * scale,
      fontWeight: 'bold',
      lineHeight: 32 * scale,
    },
    subtitle: {
      fontSize: 20 * scale,
      lineHeight: 20 * scale,
      fontWeight: 'bold',
    },
    link: {
      lineHeight: 30 * scale,
      fontSize: 16 * scale,
      color: linkColor,
    },
  };
};
