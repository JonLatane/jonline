import { Button, Paragraph, ScrollView, Spinner, TamaguiElement, XStack } from '@jonline/ui';
import { Pagination, maxPagesToRender, useComponentKey } from 'app/hooks';
import { useIsVisible } from 'app/hooks/use_is_visible';
import { useServerTheme } from 'app/store';
import { themedButtonBackground, highlightedButtonBackground } from 'app/utils';
import React, { useEffect } from "react";
import FlipMove from 'react-flip-move';

export const PageChooser: React.FC<Pagination<any> & {
  width?: string | number;
  height?: string | number;
  pageTopId?: string;
}> = ({
  page,
  setPage,
  pageCount,
  loadingPage,
  hasNextPage = true,
  loadNextPage,
  width = '100%',
  height = undefined,
  pageTopId
}) => {
    // const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
    const ref = React.createRef<TamaguiElement>();
    const isVisible = useIsVisible(ref);
    const componentKey = useComponentKey('page-chooser');
    const pageButtonId = (i: number) => `${componentKey}-page-${i}`;

    useEffect(
      () => {
        if (pageTopId) return;

        setTimeout(
          () => document.getElementById(pageButtonId(page))
            ?.scrollIntoView({ block: 'center', inline: 'center', behavior: 'smooth' }),
          300
        );
      },
      [page]
    );
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
          {pageCount > 1 || page > 0
            ? [...Array(pageCount).keys()].map((i) =>
              <Button key={i} mr='$1'
                id={pageButtonId(i)}
                {...highlightedButtonBackground(theme, 'nav', i === page)}
                transparent={i !== page}
                onPress={() => {
                  setPage(i)
                  // onSetPage?.();
                  if (pageTopId) {
                    // setTimeout(() => {
                    const pageTop = document.getElementById(pageTopId);
                    pageTop?.scrollIntoView({ block: 'center', inline: 'center', behavior: 'smooth' });
                    // }, 300);
                  }
                }}
              >
                {(i + 1).toString()}
              </Button>
            )
            : undefined}
        </FlipMove>
      </ScrollView>
    </XStack>;
  };
