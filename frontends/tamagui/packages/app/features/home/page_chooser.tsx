import { Button, Paragraph, ScrollView, Spinner, TamaguiElement, XStack } from '@jonline/ui';
import { Pagination, maxPagesToRender } from 'app/hooks';
import { useIsVisible } from 'app/hooks/use_is_visible';
import { useServerTheme } from 'app/store';
import { themedButtonBackground, highlightedButtonBackground } from 'app/utils';
import React, { useEffect } from "react";
import FlipMove from 'react-flip-move';

export const PageChooser: React.FC<Pagination<any> & {
  width?: string | number;
  height?: string | number;
}> = ({
  page,
  setPage,
  pageCount,
  loadingPage,
  hasNextPage = true,
  loadNextPage,
  width = '100%',
  height = undefined
}) => {
    // const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
    const ref = React.createRef<TamaguiElement>();
    const isVisible = useIsVisible(ref);
    // console.log(`pagination indication isVisible=${isVisible} loadingPage=${loadingPage} hasNextPage=${hasNextPage} page=${page}`)

    const theme = useServerTheme();
    const { primaryColor, primaryTextColor, navColor, navTextColor } = theme;
    // debugger;
    // const [lastPageLoad, setLastPageLoad] = useState(Date.now());

    // const pagesAreHidden = maxPagesToRender < page + 1;
    // useEffect(() => {
    //   if (isVisible && !loadingPage && hasNextPage && !pagesAreHidden) {
    //     console.log(`loading next page (page=${page})`)
    //     loadNextPage();
    //   }
    // }, [isVisible, loadingPage, page, pagesAreHidden, hasNextPage]);

    const [fgColor, bgColor] = hasNextPage
      ? [navTextColor, navColor] : [undefined, '$backgroundFocus'];

    const renderedPage = page + 1;
    const lowerPage = Math.max(1, page + 2 - maxPagesToRender);
    const upperPage = page + 1;
    const text = lowerPage === upperPage
      ? `Showing page ${lowerPage} of ${pageCount}. ${hasNextPage ? 'Press for more.' : 'No more pages.'}`
      : `Showing pages ${lowerPage} - ${upperPage} of ${pageCount}. ${hasNextPage ? 'Press for more.' : 'No more pages.'}`;

    return <XStack ref={ref} w={width} h={height} ai='center'>
      <ScrollView f={1} horizontal>
        <FlipMove style={{ display: 'flex', alignItems: 'center' }}>
          {/* <XStack gap='$1'> */}
          {[...Array(pageCount).keys()].map((i) =>
            <Button key={i} mr='$1'
              {...highlightedButtonBackground(theme, 'nav', i === page)}
              transparent={i !== page}
              onPress={() => setPage(i)}
            >
              {(i + 1).toString()}
            </Button>
          )}
          {/* </XStack> */}
        </FlipMove>
        {/* {pageCount === 0 ? undefined
          : hasNextPage
            ? <Button w={width} h={height} onPress={loadNextPage} {...themedButtonBackground(bgColor, fgColor)}>
              <XStack py='$5' px='$2' w='100%' ai='center'>
                <Paragraph color={fgColor} size='$2' f={1} my='auto'>
                  {loadingPage
                    ? `Loading...` //`Loading page ${page + 2}...`
                    : text}
                </Paragraph>
                <XStack my='auto' animation='lazy' o={loadingPage ? 1 : hasNextPage ? 0 : 0}>
                  <Spinner color={fgColor} size='small' />
                </XStack>
              </XStack>
            </Button>
            : <XStack backgroundColor={bgColor} ai='center' borderRadius={5} py='$5' px='$2' w={width} h={height}>
              <Paragraph color={fgColor} size='$2' f={1} my='auto'>
                {loadingPage
                  ? `Loading...` //`Loading page ${page + 2}...`
                  : text}
              </Paragraph>
              <XStack my='auto' animation='lazy' o={loadingPage ? 1 : hasNextPage ? 0 : 0}>
                <Spinner color={fgColor} size='small' />
              </XStack>
            </XStack>} */}
      </ScrollView>
      {/* <Paragraph color={fgColor} size='$2' f={1} ml='auto'>
        {loadingPage
          ? `Loading...` //`Loading page ${page + 2}...`
          : `Page ${page + 1} of ${pageCount}`}
      </Paragraph> */}
    </XStack>;
  };
