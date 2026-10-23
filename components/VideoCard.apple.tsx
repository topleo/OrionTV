import { TVNavigationFocus, TVGridFirstRow } from './TVFocusScope';
import { TVGridCardWidth } from './TVGridLayout';
import React, { forwardRef, useState, useContext } from 'react';
import { Alert, Image, Pressable, StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { Play, Star } from 'lucide-react-native';
import { API } from '@/services/api';
import { PlayRecordManager } from '@/services/storage';
import { useResponsiveLayout } from '@/hooks/useResponsiveLayout';
import { useReducedMotion } from '@/hooks/useReducedMotion';
import { TVTheme } from '@/constants/TVTheme';
import { ThemedText } from './ThemedText';

interface Props {
  id: string; source: string; title: string; poster: string; api: API;
  year?: string; rate?: string; sourceName?: string; progress?: number; playTime?: number;
  episodeIndex?: number; totalEpisodes?: number; onFocus?: () => void; onRecordDeleted?: () => void;
}

const AppleVideoCard = forwardRef<View, Props>((props, ref) => {
  const { id, source, title, poster, year, rate, sourceName, progress, episodeIndex, playTime = 0, api, onFocus, onRecordDeleted } = props;
  const router = useRouter();
  const layout = useResponsiveLayout();
  const gridWidth = useContext(TVGridCardWidth);
  const { navigationTarget, markContentFocus } = useContext(TVNavigationFocus);
  const firstRow = useContext(TVGridFirstRow);
  const cardWidth = gridWidth || layout.cardWidth;
  const cardHeight = cardWidth * 1.5;
  const reducedMotion = useReducedMotion();
  const [focused, setFocused] = useState(false);
  const [imageFailed, setImageFailed] = useState(false);
  const continuing = progress !== undefined && progress > 0 && progress < 1;
  const longPressTriggered = React.useRef(false);
  const open = () => {
    if (longPressTriggered.current) { longPressTriggered.current = false; return; }
    if (progress !== undefined && episodeIndex !== undefined) {
      router.push({ pathname: '/play', params: { source, id, episodeIndex: episodeIndex - 1, title, position: playTime * 1000 } });
    } else router.push({ pathname: '/detail', params: { source, q: title } });
  };
  const removeRecord = () => {
    if (progress === undefined) return;
    longPressTriggered.current = true;
    Alert.alert('移除观看记录', `从继续观看中移除“${title}”？`, [
      { text: '取消', style: 'cancel' },
      { text: '移除', style: 'destructive', onPress: async () => {
        try { await PlayRecordManager.remove(source, id); onRecordDeleted?.(); }
        catch { Alert.alert('未能移除', '请检查服务器连接后重试。'); }
      } },
    ]);
  };
  return (
    <Pressable ref={ref} nextFocusUp={firstRow ? navigationTarget : undefined} onPress={open} onLongPress={removeRecord} delayLongPress={1000}
      onFocus={() => { markContentFocus(firstRow); setFocused(true); onFocus?.(); }} onBlur={() => setFocused(false)}
      accessibilityRole="button" accessibilityLabel={`${title}${year ? `，${year}` : ''}${continuing ? '，继续观看' : ''}`}
      accessibilityHint={progress !== undefined ? '按下播放，长按可移除观看记录' : '查看影片详情和播放来源'}
      tvParallaxProperties={{ enabled: !reducedMotion, magnification: 1.045, pressMagnification: 1.015, tiltAngle: 0.025 }}
      style={({ pressed }) => [styles.wrapper, { width: cardWidth, opacity: pressed ? 0.8 : 1, zIndex: focused ? 2 : 1 }]}>
      <View style={[styles.artwork, { height: cardHeight, borderColor: focused ? TVTheme.focus : 'transparent', shadowOpacity: focused ? 0.45 : 0 }]}>
        {imageFailed || !poster ? <View style={styles.placeholder}><Play size={50} color={TVTheme.secondaryText} /></View>
          : <Image source={{ uri: api.getImageProxyUrl(poster) }} style={styles.poster} onError={() => setImageFailed(true)} accessible={false} />}
        {continuing && <View style={styles.progressTrack}><View style={[styles.progress, { width: `${Math.max(0, Math.min(1, progress || 0)) * 100}%` }]} /></View>}
      </View>
      <View style={styles.caption}>
        <ThemedText style={styles.title} numberOfLines={2}>{title}</ThemedText>
        <View style={styles.metadata}>
          {rate ? <View style={styles.rating}><Star size={17} color={TVTheme.secondaryText} /><ThemedText style={styles.detail}>{rate}</ThemedText></View> : null}
          <ThemedText style={styles.detail} numberOfLines={1}>{continuing ? `第 ${episodeIndex} 集 · 已观看 ${Math.round((progress || 0) * 100)}%` : [year, sourceName].filter(Boolean).join(' · ')}</ThemedText>
        </View>
      </View>
    </Pressable>
  );
});
AppleVideoCard.displayName = 'AppleVideoCard';
export default AppleVideoCard;
const styles = StyleSheet.create({
  wrapper: { paddingVertical: 12, overflow: 'visible' },
  artwork: { width: '100%', borderRadius: TVTheme.radius, backgroundColor: TVTheme.surface, borderWidth: 3, shadowColor: '#000', shadowOffset: { width: 0, height: 15 }, shadowRadius: 24, overflow: 'hidden' },
  poster: { width: '100%', height: '100%', resizeMode: 'cover' },
  placeholder: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  caption: { paddingTop: 16, minHeight: 100 },
  title: { color: TVTheme.text, fontSize: 25, lineHeight: 32, fontWeight: '600' },
  metadata: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingTop: 6 },
  detail: { color: TVTheme.secondaryText, fontSize: 21, lineHeight: 28, flexShrink: 1 },
  rating: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  progressTrack: { position: 'absolute', left: 0, right: 0, bottom: 0, height: 5, backgroundColor: 'rgba(0,0,0,0.5)' },
  progress: { height: '100%', backgroundColor: TVTheme.focus },
});
