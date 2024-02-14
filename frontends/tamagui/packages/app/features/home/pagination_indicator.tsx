import { Button, Paragraph, Spinner, TamaguiElement, XStack } from '@jonline/ui';
import { Pagination, maxPagesToRender } from 'app/hooks';
import { useIsVisible } from 'app/hooks/use_is_visible';
import { useServerTheme } from 'app/store';
import { themedButtonBackground } from 'app/utils';
import React, { useEffect } from "react";

export const PaginationIndicator: React.FC<Pagination<any>> = ({
  page,
  pageCount,
  loadingPage,
  hasNextPage = true,
  loadNextPage
}) => {
  // const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  const ref = React.createRef<TamaguiElement>();
  // const isVisible = useIsVisible(ref);
  // console.log(`pagination indication isVisible=${isVisible} loadingPage=${loadingPage} hasNextPage=${hasNextPage} page=${page}`)

  const { primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  // debugger;
  // const [lastPageLoad, setLastPageLoad] = useState(Date.now());

  // useEffect(() => {
  //   if (isVisible && !loadingPage && hasNextPage) {
  //     console.log(`loading next page (page=${page})`)
  //     loadNextPage();
  //     // setLastPageLoad(Date.now());
  //   }
  // }, [isVisible, loadingPage, page]);

  const [fgColor, bgColor] = hasNextPage
    ? [navTextColor, navColor] : [undefined, '$backgroundFocus'];

  const renderedPage = page + 1;
  const pagesAreHidden = maxPagesToRender < page + 1;
  const lowerPage = Math.max(1, page + 2 - maxPagesToRender);
  const upperPage = page + 1;
  const text = lowerPage === upperPage
    ? `Showing page ${lowerPage} of ${pageCount}. ${hasNextPage ? 'Press for more.' : 'No more pages.'}`
    : `Showing pages ${lowerPage} - ${upperPage} of ${pageCount}. ${hasNextPage ? 'Press for more.' : 'No more pages.'}`;

  return hasNextPage
    ? <Button onPress={loadNextPage} {...themedButtonBackground(bgColor, fgColor)} mb='$3'>
      <XStack ref={ref} p='$5' w='100%' ai='center'>
        <Paragraph color={fgColor} size='$2' f={1} my='auto'>
          {loadingPage
            ? `Loading page ${page + 2}...`
            : text}
        </Paragraph>
        <XStack my='auto' animation='lazy' o={loadingPage ? 1 : hasNextPage ? 0 : 0}>
          <Spinner color={fgColor} size='small' />
        </XStack>
      </XStack>
    </Button>
    : <XStack backgroundColor={bgColor} h={80} ai='center' borderRadius={5} ref={ref} p='$5' w='100%' mb='$3'>
      <Paragraph color={fgColor} size='$2' f={1} my='auto'>
        {loadingPage
          ? `Loading page ${page + 2}...`
          : text}
      </Paragraph>
      <XStack my='auto' animation='lazy' o={loadingPage ? 1 : hasNextPage ? 0 : 0}>
        <Spinner color={fgColor} size='small' />
      </XStack>
    </XStack>;

  // return <XStack backgroundColor={bgColor} h={80} borderRadius={5} ref={ref} p='$5' w='100%' mb='$3'>
  //   <Paragraph color={fgColor} size='$2' f={1} my='auto'>
  //     {loadingPage
  //       ? `Loading page ${page + 2}...`
  //       : `${renderedPageCount} page${renderedPageCount === 1 ? '' : 's'} loaded.`}
  //     {hasNextPage ? '' : ' No more pages.'}
  //   </Paragraph>
  //   <XStack my='auto' animation='lazy' o={loadingPage ? 1 : hasNextPage ? 0.5 : 0}>
  //     <Spinner color={fgColor} size='small' />
  //     {/* {loadingPage ? <Spinner color={fgColor} my='auto' size='small' /> : undefined} */}

  //   </XStack>
  // </XStack>
};


export const PaginationResetIndicator: React.FC<Pagination<any>> = ({
  page,
  reset
}) => {
  if (maxPagesToRender < page + 1) {
    return <Button onPress={reset}>
      <Paragraph>
        {page + 1 - maxPagesToRender} {page + 1 - maxPagesToRender === 1 ? 'page' : 'pages'} hidden. Press to reset pagination.
      </Paragraph>
    </Button>
  }
};