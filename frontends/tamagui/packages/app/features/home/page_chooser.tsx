import { Button, Paragraph, ScrollView, XStack, YStack, useTheme } from '@jonline/ui';
import { useAccountOrServerContext } from 'app/contexts';
import { Pagination, maxPagesToRender, useComponentKey, useProvidedAccountOrServer, useProvidedDispatch } from 'app/hooks';
import { useServerTheme } from 'app/store';
import { highlightedButtonBackground } from 'app/utils';
import React, { useEffect } from "react";
import FlipMove from 'react-flip-move';

export type Pluralizable = {
  singular: string;
  plural: string;
}
export function pluralize(
  count: number,
  { singular, plural }: Pluralizable = { singular: "result", plural: "results" }
) {
  return count === 1 ? singular : plural;
}

export const PageChooser: React.FC<Pagination<any> & {
  width?: string | number;
  maxWidth?: string | number;
  height?: string | number;
  pageTopId?: string;
  noAutoScroll?: boolean;
  showResultCounts?: boolean;
  entityName?: Pluralizable;
}> = ({
  page: currentPage,
  setPage,
  pageCount,
  resultCount,
  pageSize,
  loadingPage,
  hasNextPage = true,
  loadNextPage,
  width = '100%',

  maxWidth = undefined,
  height = undefined,
  pageTopId,
  noAutoScroll = false,
  showResultCounts = false,
  entityName
}) => {
    // const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
    // const ref = React.createRef<TamaguiElement>();
    // const isVisible = useIsVisible(ref);
    const componentKey = useComponentKey('page-chooser');
    const pageButtonId = (i: number) => `${componentKey}-page-${i}`;

    useEffect(
      () => {
        if (pageTopId) return;
        if (noAutoScroll) return;

        setTimeout(
          () => document.getElementById(pageButtonId(currentPage))
            ?.scrollIntoView({ block: 'center', inline: 'center', behavior: 'smooth' }),
          300
        );
      },
      [currentPage]
    );
    // console.log(`pagination indication isVisible=${isVisible} loadingPage=${loadingPage} hasNextPage=${hasNextPage} page=${page}`)

    const server = useProvidedAccountOrServer().server;
    const theme = useServerTheme(server);
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

    const renderedPage = currentPage + 1;
    const lowerPage = Math.max(1, currentPage + 2 - maxPagesToRender);
    const upperPage = currentPage + 1;
    const text = lowerPage === upperPage
      ? `Showing page ${lowerPage} of ${pageCount}. ${hasNextPage ? 'Press for more.' : 'No more pages.'}`
      : `Showing pages ${lowerPage} - ${upperPage} of ${pageCount}. ${hasNextPage ? 'Press for more.' : 'No more pages.'}`;

    return <YStack w={width} h={height} maxWidth={maxWidth} ai='center'>
      <ScrollView f={1} w='100%' horizontal>
        <FlipMove style={{ display: 'flex', alignItems: 'center' }}>
          {pageCount > 1 || currentPage > 0
            ? [...Array(pageCount).keys()].map((page) =>
              <Button key={pageButtonId(page)} mr='$1'
                id={pageButtonId(page)}
                {...highlightedButtonBackground(theme, 'nav', page === currentPage)}
                transparent={page !== currentPage}
                onPress={() => {
                  setPage(page)
                  // onSetPage?.();
                  if (pageTopId) {
                    // setTimeout(() => {
                    const pageTop = document.getElementById(pageTopId);
                    pageTop?.scrollIntoView({ block: 'center', inline: 'center', behavior: 'smooth' });
                    // }, 300);
                  }
                }}
              >
                {(page + 1).toString()}
              </Button>
            )
            : undefined}
        </FlipMove>
      </ScrollView>
      {showResultCounts && resultCount > 0
        ? <Paragraph mx='auto' mt='$1' pt='$1' size='$1'>
          {
            Math.min(resultCount, (lowerPage - 1) * pageSize + 1)
          }-{
            Math.min(resultCount, (upperPage) * pageSize)
          } of {resultCount} {pluralize(resultCount, entityName)}
        </Paragraph>
        : undefined}
    </YStack>;
  };
