import { Paragraph, Spinner, XStack } from '@jonline/ui';
import { useOnScreen } from "app/hooks/use_on_screen";
import { useServerTheme } from 'app/store';
import React, { useEffect } from "react";
import { View } from 'react-native';

interface Props {
  page: number;
  loadingPage: boolean;
  hasNextPage?: boolean;
  loadNextPage: () => void;
}

export const PaginationIndicator: React.FC<Props> = ({ page, loadingPage, hasNextPage = true, loadNextPage }) => {
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  const onScreen = useOnScreen(ref, "-1px");
  const { primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  useEffect(() => {
    if (onScreen && !loadingPage && hasNextPage) {
      loadNextPage();
    }
  }, [onScreen, loadingPage]);

  const [fgColor, bgColor] = hasNextPage ? [navTextColor, navColor] : [primaryTextColor, primaryColor];

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
    </XStack>
    {/* {loadingPage ? <Spinner color={fgColor} my='auto' size='small' /> : undefined} */}
  </XStack>
};