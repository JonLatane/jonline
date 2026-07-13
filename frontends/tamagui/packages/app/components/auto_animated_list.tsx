// import { J } from '@fullcalendar/core/internal-common';
import { GetThemeValueForKey, Heading, Label, Paragraph, Switch, XStack, YStack } from '@jonline/ui';
import { useAppDispatch } from 'app/hooks';
import React, { useEffect, useRef } from 'react';
import autoAnimate from '@formkit/auto-animate'


export interface AutoAnimatedListProps {
  children: React.ReactNode;
  direction?: AutoAnimatedListDirection;
  style?: React.CSSProperties;

  gap?: number | "unset" | GetThemeValueForKey<"gap"> | undefined;
}

export type AutoAnimatedListDirection = 'horizontal' | 'vertical';
export function AutoAnimatedList({
  direction = 'vertical',
  children,
  style,
  gap = 0,
  /*name, description, value: optionalValue, setter, disabled = false, autoDispatch = false*/
}: AutoAnimatedListProps) {
  const parent = useRef(null)

  useEffect(() => {
    parent.current && autoAnimate(parent.current)
  }, [parent]);

  if (direction === 'vertical') {
    return <YStack ref={parent} gap={gap} ai='center' jc='center' style={style}>
      {children}
    </YStack>;
  } else {
    return <XStack ref={parent} gap={gap} ai='center' style={style}>
      {children}
    </XStack>;
  }

  // const dispatch = useAppDispatch();
  // const nameKey = name.toLowerCase().replace(/[^\w]/g, '_');
  // const value = !!optionalValue;
  // return <XStack gap='$3' o={disabled ? 0.5 : 1} my='$1' ai='center'>
  //   <Label htmlFor={nameKey} my='auto' f={1}>
  //     <YStack w='100%'>
  //       <Paragraph size='$5' my='auto'>
  //         {name}
  //       </Paragraph>
  //       {typeof description === 'string'
  //         ? <Paragraph lineHeight='$1' size='$1' o={value ? 0.7 : 0.25}>
  //           {description}
  //         </Paragraph>
  //         : description}
  //     </YStack>
  //   </Label>
  //   <Switch name={nameKey} size="$5" my='auto'
  //     // defaultChecked={value}
  //     checked={value}
  //     // value={value.toString()}
  //     disabled={false}
  //     onCheckedChange={(checked) => autoDispatch ? dispatch(setter(checked)) : setter(checked)}>
  //     <Switch.Thumb animation='standard' backgroundColor='$background' />
  //   </Switch>
  // </XStack>;
}
