import { isAppleTV, TVTheme } from './TVTheme';
/**
 * Below are the colors that are used in the app. The colors are defined in the light and dark mode.
 * There are many other ways to style your app. For example, [Nativewind](https://www.nativewind.dev/), [Tamagui](https://tamagui.dev/), [unistyles](https://reactnativeunistyles.vercel.app), etc.
 */

const tintColorLight = "#0a7ea4";
const tintColorDark = "#aaa";

export const Colors = {
  light: {
    text: "#11181C",
    background: "#fff",
    tint: tintColorLight,
    icon: "#687076",
    tabIconDefault: "#687076",
    tabIconSelected: tintColorLight,
    link: "#0a7ea4",
    border: "#E5E5E5",
  },
  dark: {
    text: "#ECEDEE",
    background: isAppleTV ? TVTheme.background : "#151718",
    tint: tintColorDark,
    icon: "#9BA1A6",
    tabIconDefault: "#9BA1A6",
    tabIconSelected: tintColorDark,
    link: isAppleTV ? TVTheme.accent : "#0a7ea4",
    border: isAppleTV ? TVTheme.separator : "#333",
    primary: isAppleTV ? TVTheme.focus : "#00bb5e",
  },
};
