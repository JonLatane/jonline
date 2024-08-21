import { XStack, standardFadeAnimation } from "@jonline/ui";
import React, { PropsWithChildren } from "react";
import { DimensionValue, ViewStyle } from "react-native";

export type FadeInViewProps = PropsWithChildren<{
  style?: ViewStyle;
  w?: DimensionValue;
  h?: DimensionValue;
}>;

export const FadeInView: React.FC<FadeInViewProps> = props => {
  return <XStack animation='standard' {...standardFadeAnimation} width={props.w} height={props.h}>
    {props.children}
  </XStack>;
  // return <YStack {...standardFadeAnimation}>
  //   {props.children}
  // </YStack>;
  // if (isWeb) {
  //   return <div style={{ animation: 'animation: fadeIn 5s' }}>
  //     {props.children}
  //   </div>;
  // }


  // const fadeAnim = React.useRef(new Animated.Value(0)).current; // Initial value for opacity: 0

  // useEffect(() => {
  //   Animated.timing(fadeAnim, {
  //     toValue: 1,
  //     duration: 1500,
  //     useNativeDriver: true,
  //   }).start();
  // }, [fadeAnim]);

  // return (
  //   <Animated.View // Special animatable View
  //     style={{
  //       ...props.style,
  //       opacity: fadeAnim, // Bind opacity to animated value
  //     }}>
  //     {props.children}
  //   </Animated.View>
  // );
};
