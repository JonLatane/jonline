import { Paragraph, Spinner, TamaguiElement, XStack } from '@jonline/ui';
import { Pagination } from 'app/hooks';
import { useIsVisible } from 'app/hooks/use_is_visible';
import { useServerTheme } from 'app/store';
import React, { useEffect } from "react";

export const PaginationIndicator: React.FC<Pagination<any>> = ({
  page,
  loadingPage,
  hasNextPage = true,
  loadNextPage
}) => {
  // const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  const ref = React.createRef<TamaguiElement>();
  const isVisible = useIsVisible(ref);
  console.log(`pagination indication isVisible=${isVisible} loadingPage=${loadingPage} hasNextPage=${hasNextPage} page=${page}`)

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

  const renderedPageCount = page + 1;//(hasNextPage ? 1 : 0);
  return <XStack backgroundColor={bgColor} h={80} borderRadius={5} ref={ref} p='$5' w='100%' mb='$3'>
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