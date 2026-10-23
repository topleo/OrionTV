import React, { forwardRef } from "react";
import { Animated, Pressable, StyleSheet, StyleProp, ViewStyle, PressableProps, TextStyle, View, Platform } from "react-native";
import { TVTheme, isAppleTV } from '@/constants/TVTheme';
import { useReducedMotion } from '@/hooks/useReducedMotion';
import { Text } from 'react-native';
import { ThemedText } from "./ThemedText";
import { Colors } from "@/constants/Colors";
import { useButtonAnimation } from "@/hooks/useAnimation";
import { useResponsiveLayout } from "@/hooks/useResponsiveLayout";

interface StyledButtonProps extends PressableProps {
  children?: React.ReactNode;
  text?: string;
  variant?: "default" | "primary" | "ghost";
  isSelected?: boolean;
  style?: StyleProp<ViewStyle>;
  textStyle?: StyleProp<TextStyle>;
}

const LegacyStyledButton = forwardRef<View, StyledButtonProps>(
  ({ children, text, variant = "default", isSelected = false, style, textStyle, ...rest }, ref) => {
    const colorScheme = "dark";
    const colors = Colors[colorScheme];
    const [isFocused, setIsFocused] = React.useState(false);
    const animationStyle = useButtonAnimation(isFocused);
    const deviceType = useResponsiveLayout().deviceType;

    const variantStyles = {
      default: StyleSheet.create({
        button: {
          backgroundColor: colors.border,
        },
        text: {
          color: colors.text,
        },
        selectedButton: {
          backgroundColor: colors.primary,
        },
        focusedButton: {
          borderColor: colors.primary,
        },
        selectedText: {
          color: Colors.dark.text,
        },
      }),
      primary: StyleSheet.create({
        button: {
          backgroundColor: "transparent",
        },
        text: {
          color: colors.text,
        },
        focusedButton: {
          backgroundColor: colors.primary,
          borderColor: colors.background,
        },
        selectedButton: {
          backgroundColor: colors.primary,
        },
        selectedText: {
          color: colors.link,
        },
      }),
      ghost: StyleSheet.create({
        button: {
          backgroundColor: "transparent",
        },
        text: {
          color: colors.text,
        },
        focusedButton: {
          backgroundColor: "rgba(119, 119, 119, 0.2)",
          borderColor: colors.primary,
        },
        selectedButton: {},
        selectedText: {},
      }),
    };

    const styles = StyleSheet.create({
      button: {
        paddingHorizontal: 16,
        paddingVertical: 10,
        borderRadius: 8,
        borderWidth: 2,
        borderColor: "transparent",
        flexDirection: "row",
        alignItems: "center",
        justifyContent: "center",
      },
      focusedButton: {
        backgroundColor: colors.link,
        borderColor: colors.background,
        elevation: 5,
        shadowColor: colors.link,
        shadowOffset: { width: 0, height: 0 },
        shadowOpacity: 1,
        shadowRadius: 15,
      },
      selectedButton: {
        backgroundColor: colors.tint,
      },
      text: {
        fontSize: 16,
        fontWeight: "500",
        color: colors.text,
      },
      selectedText: {
        color: Colors.dark.text,
      },
    });

    return (
      <Animated.View style={[animationStyle, style]}>
        <Pressable
          android_ripple={Platform.isTV || deviceType !== 'tv'? { color: 'transparent' } : { color: Colors.dark.link }}
          ref={ref}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          style={({ focused }) => [
            styles.button,
            variantStyles[variant].button,
            isSelected && (variantStyles[variant].selectedButton ?? styles.selectedButton),
            focused && (variantStyles[variant].focusedButton ?? styles.focusedButton),
          ]}
          {...rest}
        >
          {text ? (
            <ThemedText
              style={[
                styles.text,
                variantStyles[variant].text,
                isSelected && (variantStyles[variant].selectedText ?? styles.selectedText),
                textStyle,
              ]}
            >
              {text}
            </ThemedText>
          ) : (
            children
          )}
        </Pressable>
      </Animated.View>
    );
  }
);

LegacyStyledButton.displayName = "LegacyStyledButton";

const TVStyledButton = forwardRef<View, StyledButtonProps>(({ text, children, variant = 'default', isSelected = false, disabled, style, textStyle, onFocus, onBlur, accessibilityState, ...rest }, ref) => {
  const [focused, setFocused] = React.useState(false);
  const reducedMotion = useReducedMotion();
  const prominent = focused || variant === 'primary';
  const foreground = prominent ? TVTheme.onFocus : TVTheme.text;
  const content = React.Children.map(children, child => {
    if (!React.isValidElement(child)) return child;
    const element = child as React.ReactElement<any>;
    if (element.type === ThemedText || element.type === Text) return React.cloneElement(element, { style: [element.props.style, { color: foreground }] });
    if ('color' in element.props) return React.cloneElement(element, { color: foreground });
    return element;
  });
  return (
    <View style={[style, { opacity: disabled ? 0.4 : 1 }]}>
      <Pressable {...rest} ref={ref} disabled={disabled} accessibilityRole={rest.accessibilityRole || 'button'}
        accessibilityState={{ ...accessibilityState, selected: isSelected, disabled: !!disabled }}
        tvParallaxProperties={{ enabled: !reducedMotion, magnification: 1.035, pressMagnification: 1.01 }}
        onFocus={event => { setFocused(true); onFocus?.(event); }}
        onBlur={event => { setFocused(false); onBlur?.(event); }}
        style={({ pressed }) => ({ minHeight: 58, paddingHorizontal: text ? 24 : 18, paddingVertical: 12,
          borderRadius: variant === 'ghost' ? 30 : TVTheme.radius, borderWidth: 2,
          borderColor: focused ? TVTheme.focus : 'transparent',
          backgroundColor: prominent ? TVTheme.focus : isSelected ? TVTheme.raised : variant === 'ghost' ? 'transparent' : TVTheme.surface,
          alignItems: 'center', justifyContent: 'center', flexDirection: 'row', gap: 10,
          opacity: pressed ? 0.78 : 1,
          shadowColor: '#000', shadowOffset: { width: 0, height: 10 }, shadowRadius: focused ? 18 : 0, shadowOpacity: focused ? 0.3 : 0,
        })}>
        {text ? <ThemedText style={[{ fontSize: 24, lineHeight: 32, fontWeight: '600' }, textStyle, { color: foreground }]}>{text}</ThemedText> : content}
      </Pressable>
    </View>
  );
});
TVStyledButton.displayName = 'TVStyledButton';
export const StyledButton = forwardRef<View, StyledButtonProps>((props, ref) =>
  isAppleTV ? <TVStyledButton {...props} ref={ref} /> : <LegacyStyledButton {...props} ref={ref} />
);
StyledButton.displayName = 'StyledButton';
