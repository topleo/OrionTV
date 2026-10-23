import { Platform } from 'react-native';
export const isAppleTV = Platform.OS === 'ios' && Platform.isTV;

// A quiet, content-first palette for a cinematic television interface.
// Custom colors are named by purpose; the player remains a dark viewing surface.
export const TVTheme = {
  background: '#101014',
  surface: '#202026',
  raised: '#303038',
  text: '#F5F5F7',
  secondaryText: '#B6B6C2',
  focus: '#F5F5F7',
  onFocus: '#141418',
  separator: '#41414B',
  accent: '#79B8FF',
  danger: '#FF9B93',
  radius: 16,
  gutter: 64,
};
