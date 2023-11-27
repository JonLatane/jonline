import { Paragraph, Spinner, TamaguiElement, XStack } from '@jonline/ui';
import { useIsVisible } from 'app/hooks/use_is_visible';
import { useServerTheme } from 'app/store';
import React, { useEffect, useState } from "react";
import { View } from 'react-native';

interface Props {
  page: number;
  loadingPage: boolean;
  hasNextPage?: boolean;
  loadNextPage: () => void;
}

export const PaginationIndicator: React.FC<Props> = ({ page, loadingPage, hasNextPage = true, loadNextPage }) => {
  // const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  const ref = React.createRef<TamaguiElement>();
  const isVisible = useIsVisible(ref);

  const { primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  // debugger;
  // const [lastPageLoad, setLastPageLoad] = useState(Date.now());
  useEffect(() => {
    if (isVisible && !loadingPage && hasNextPage) {
      console.log(`loading next page (page=${page})`)
      loadNextPage();
      // setLastPageLoad(Date.now());
    }
  }, [isVisible, loadingPage, page]);

  const [fgColor, bgColor] = hasNextPage
    ? [navTextColor, navColor] : [undefined, '$backgroundFocus'];

  const renderedPageCount = page + (hasNextPage ? 1 : 0);
  return <XStack backgroundColor={bgColor} h={80} borderRadius={5} ref={ref} p='$5' w='100%'>
    <Paragraph color={fgColor} size='$2' f={1} my='auto'>
      {loadingPage
        ? `Loading page ${page + 2}...`
        : `${renderedPageCount} page${renderedPageCount === 1 ? '' : 's'} loaded.`}
      {hasNextPage ? '' : ' No more pages.'}
    </Paragraph>
    <XStack my='auto' animation='lazy' o={loadingPage ? 1 : hasNextPage ? 0.5 : 0}>
      <Spinner color={fgColor} size='small' />
      {/* {loadingPage ? <Spinner color={fgColor} my='auto' size='small' /> : undefined} */}

    </XStack>
  </XStack>
};