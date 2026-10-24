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
// Unlike RN's View wrapper, raw native component refs do not add requestTVFocus.
// Keep the real host ref (for findNodeHandle) and expose the same imperative API.
let focusSequence = 0;
function nativeControl<Props extends ViewProps>(managerName: string) {
  const Control = requireNativeComponent<Props>(managerName);
  return React.forwardRef<View, Props>((props, forwardedRef) => {
    const setRef = React.useCallback((view: View | null) => {
      if (view) {
        view.requestTVFocus = () => {
          // Prop updates reach our UIKit focus system directly, including when
          // a custom manager has no inherited command metadata.
          view.setNativeProps({ focusRequest: ++focusSequence });
        };
      }
      if (typeof forwardedRef === 'function') forwardedRef(view);
      else if (forwardedRef) forwardedRef.current = view;
    }, [forwardedRef]);
    return <Control {...props} ref={setRef} />;
  });
}

// Other upstream platforms never load the tvOS view managers.
export const NativeTVTabBar = isAppleTV ? nativeControl<NativeTabProps>('OrionTVTabBar') : View;
export const NativeTVMenu = isAppleTV ? nativeControl<NativeMenuProps>('OrionTVMenu') : View;
