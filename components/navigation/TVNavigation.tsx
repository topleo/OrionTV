import React from 'react';
import { StyleSheet, View } from 'react-native';
import { usePathname, useRouter } from 'expo-router';
import { Settings } from 'lucide-react-native';
import { StyledButton } from '../StyledButton';
import { ThemedText } from '../ThemedText';
import { TVTheme, isAppleTV } from '@/constants/TVTheme';

const sections = [
  { title: '现在观看', path: '/' },
  { title: '资料库', path: '/favorites' },
  { title: '搜索', path: '/search' },
  { title: '直播', path: '/live' },
] as const;

export function TVNavigation() {
  const router = useRouter();
  const pathname = usePathname();
  if (!isAppleTV) return null;
  return (
    <View style={styles.container}>
      <ThemedText style={styles.brand} accessibilityRole="header">OrionTV</ThemedText>
      <View style={styles.sections}>
        {sections.map(section => (
          <StyledButton key={section.path} text={section.title} variant="ghost"
            accessibilityRole="tab" accessibilityLabel={section.title}
            isSelected={pathname === section.path}
            onPress={() => { if (pathname !== section.path) router.replace(section.path); }}
            style={styles.tab} textStyle={styles.label} />
        ))}
      </View>
      <StyledButton variant="ghost" accessibilityLabel="设置" isSelected={pathname === '/settings'}
        onPress={() => { if (pathname !== '/settings') router.push('/settings'); }}>
        <Settings size={28} color={TVTheme.text} />
      </StyledButton>
    </View>
  );
}
const styles = StyleSheet.create({
  container: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: TVTheme.gutter, paddingTop: 24, paddingBottom: 24, gap: 28 },
  brand: { fontSize: 32, lineHeight: 42, fontWeight: '700', letterSpacing: -0.8 },
  sections: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  tab: { borderRadius: 28 },
  label: { fontSize: 25, lineHeight: 32, fontWeight: '600' },
});
