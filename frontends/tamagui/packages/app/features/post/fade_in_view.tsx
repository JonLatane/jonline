import React, { PropsWithChildren, useEffect } from "react";
import { Animated, ViewStyle } from "react-native";


export type FadeInViewProps = PropsWithChildren<{ style?: ViewStyle }>;

export const FadeInView: React.FC<FadeInViewProps> = props => {
  const fadeAnim = React.useRef(new Animated.Value(0)).current; // Initial value for opacity: 0

  useEffect(() => {
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 1500,
      useNativeDriver: true,
    }).start();
  }, [fadeAnim]);

  return (
    <Animated.View // Special animatable View
      style={{
        ...props.style,
        opacity: fadeAnim, // Bind opacity to animated value
      }}>
      {props.children}
    </Animated.View>
  );
};
