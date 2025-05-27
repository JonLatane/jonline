import { useServerTheme } from "app/store";
import React, { useMemo } from "react";

import { Anchor, Heading, Paragraph, Text, XStack, YStack, useTheme } from "@jonline/ui";
import ReactMarkdown, { Components } from 'react-markdown';
import { useProvidedDispatch } from "app/hooks";
import SyntaxHighlighter from 'react-syntax-highlighter';
import { atomOneDark as darkCodeStyle, atomOneLight as lightCodeStyle } from 'react-syntax-highlighter/dist/cjs/styles/hljs';
import remarkGfm from 'remark-gfm'

export type MarkdownProps = {
  text?: string;
  disableLinks?: boolean;
  cleanContent?: boolean;
  shrink?: boolean;
}
export const TamaguiMarkdown = ({ text = '', disableLinks, cleanContent = false, shrink }: MarkdownProps) => {
  const server = useProvidedDispatch().accountOrServer.server;
  const { primaryColor, navAnchorColor: navColor, darkMode } = useServerTheme(server);

  const cleanedText = useMemo(() => cleanContent ? text.replace(
    /((?!  ).)\n([^\n*])/g,
    (_, b, c) => {
      if (b[1] != ' ') b = `${b} `
      return `${b}${c}`;
    }
  ) : text, [cleanContent, text]);

  const components: Components = useMemo(() => ({
    // li: ({ node, ordered, ...props }) => <li }} {...props} />,
    h1: ({ children, id }) => <Heading size={shrink ? '$6' : '$9'} {...{ children, id }} />,
    h2: ({ children, id }) => <Heading size={shrink ? '$5' : '$8'} {...{ children, id }} />,
    h3: ({ children, id }) => <Heading size={shrink ? '$4' : '$7'} {...{ children, id }} />,
    h4: ({ children, id }) => <Heading size={shrink ? '$3' : '$6'} {...{ children, id }} />,
    h5: ({ children, id }) => <Heading size={shrink ? '$2' : '$5'} {...{ children, id }} />,
    h6: ({ children, id }) => <Heading size={shrink ? '$1' : '$4'} {...{ children, id }} />,
    // li: ({ children, id }) => <li id={id}><Text fontSize={shrink ? '$1' : '$3'} >
    //   {children instanceof Array
    //     ? children.map((child, index) => {
    //       // console.log('TamaguiMarkdown li child', { child, index });
    //       return typeof child === 'string'
    //         ? <Text key={index} fontFamily='$body' fontSize={shrink ? '$1' : '$3'}>{child}</Text>
    //         : // If the child is a React element, render it directly
    //         // (this is useful for nested lists or other complex structures)
    //         React.isValidElement(child)
    //           ? child
    //           : <Text key={index} fontFamily='$body' fontSize={shrink ? '$1' : '$3'}>{String(child)}</Text>
    //     })
    //     : <Text fontFamily='$body' fontSize={shrink ? '$1' : '$3'}>{children}</Text>}
    // </Text>
    // </li>,
    // li: ({ /*ordered, index, */children, ...rest }) => {
    //   console.log('TamaguiMarkdown li', { rest });
    //   return <XStack ml={shrink ? '$2' : '$3'} mb='$2'>
    //     {/* <Text fontFamily='$body' fontSize={shrink ? '$1' : '$3'} mr='$4'>{ordered ? `${index + 1}.` : '• '}</Text> */}
    //     <Text fontFamily='$body' fontSize={shrink ? '$1' : '$3'} {...{ children }} />
    //   </XStack>
    // },

    p: ({ children }) => <Paragraph size={shrink ? '$1' : '$3'}  {...{ children }} w='100%' />,
    // a: ({ children, href }) => <Anchor color={navColor} target='_blank' {...{ href, children }} />,
    a: ({ children, href }) => disableLinks
      ? <Text fontFamily='$body' color={navColor} {...{ href, children }} />
      : <Anchor fontSize={shrink ? '$1' : '$3'} color={navColor} target='_blank' {...{ href, children }} />,

    code: ({ children, className, node, ...rest }) => {
      // const  = props
      const match = /language-(\w+)/.exec(className || '')
      // console.log('TamaguiMarkdown code match', match)
      return match ? (
        <XStack>
          <SyntaxHighlighter
            {...rest}
            ref={undefined}
            PreTag="div"
            children={String(children).replace(/\n$/, '')}
            language={match[1]}
            // style={{}}
            style={darkMode ? darkCodeStyle : lightCodeStyle}
          />
        </XStack>
      ) : (
        <code {...rest} className={className}>
          {children}
        </code>
      )
    }
  }), [shrink, disableLinks, darkMode, navColor]);

  return <YStack gap={shrink ? '$1' : '$2'} className={shrink ? 'tamagui-markdown shrink' : 'tamagui-markdown'}>
    <ReactMarkdown

      remarkPlugins={[remarkGfm]}
      components={components}>
      {cleanedText}
    </ReactMarkdown>
  </YStack>

  // return <Text whiteSpace="pre-wrap" className="tamagui-markdown" fontFamily="$body" fontSize={shrink ? '$1' : '$3'} lineHeight={shrink ? '$2' : '$4'} >
  //   <ReactMarkdown children={cleanedText}
  //     remarkPlugins={[remarkGfm]}
  //     components={components} />
  // </Text>
}
