import { TVTheme, isAppleTV } from '@/constants/TVTheme';
import React, { useState } from "react";
import { StyleSheet, Pressable, Platform } from "react-native";
import { ThemedView } from "@/components/ThemedView";
import { Colors } from "@/constants/Colors";
import { useResponsiveLayout } from "@/hooks/useResponsiveLayout";

interface SettingsSectionProps {
  children: React.ReactNode;
  onFocus?: () => void;
  onBlur?: () => void;
  onPress?: () => void;
  focusable?: boolean;
}

export const SettingsSection: React.FC<SettingsSectionProps> = ({ children, onFocus, onBlur, onPress, focusable = false }) => {
  const [isFocused, setIsFocused] = useState(false);
  const deviceType = useResponsiveLayout().deviceType;

  const handleFocus = () => {
    setIsFocused(true);
    onFocus?.();
  };

  const handleBlur = () => {
    setIsFocused(false);
    onBlur?.();
  };

  const handlePress = () => {
    onPress?.();
  }

  if (!focusable) {
    return <ThemedView style={styles.section}>{children}</ThemedView>;
  }

  return (
    <ThemedView style={[styles.section, isFocused && styles.sectionFocused]}>
      <Pressable
        android_ripple={Platform.isTV||deviceType !=='tv'? {color:'transparent'}:{color:Colors.dark.link}}
        style={styles.sectionPressable}
        // {...(Platform.isTV ? {onFocus: handleFocus, onBlur: handleBlur} : {onPress: onPress})}
        onFocus={handleFocus}
        onBlur={handleBlur}
        onPress={handlePress}
      >
        {children}
      </Pressable>
    </ThemedView>
  );
};

const styles = StyleSheet.create({
  section: {
    padding: isAppleTV ? 32 : 20,
    backgroundColor: isAppleTV ? TVTheme.surface : undefined,
    marginBottom: 16,
    borderRadius: isAppleTV ? 24 : 12,
    borderWidth: isAppleTV ? 2 : 1,
    borderColor: isAppleTV ? "transparent" : "#333",
  },
  sectionFocused: {
    borderColor: Colors.dark.primary,
    backgroundColor: isAppleTV ? TVTheme.raised : "#007AFF10",
  },
  sectionPressable: {
    width: "100%",
  },
});
