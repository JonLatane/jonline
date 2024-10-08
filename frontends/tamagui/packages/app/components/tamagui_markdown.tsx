import { useServerTheme } from "app/store";
import React from "react";

import { Anchor, Heading, Paragraph, Text, XStack, useTheme } from "@jonline/ui";
import ReactMarkdown from 'react-markdown';
import { useProvidedDispatch } from "app/hooks";
// import SyntaxHighlighter from "react-syntax-highlighter";
// import {dark} from 'react-syntax-highlighter/dist/esm/styles/hljs'
// import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
// import { dark } from 'react-syntax-highlighter/dist/cjs/styles/prism';
import SyntaxHighlighter from 'react-syntax-highlighter';
import { atomOneDark as darkCodeStyle, atomOneLight as lightCodeStyle } from 'react-syntax-highlighter/dist/cjs/styles/hljs';

export type MarkdownProps = {
  text?: string;
  disableLinks?: boolean;
  cleanContent?: boolean;
  shrink?: boolean;
}
export const TamaguiMarkdown = ({ text = '', disableLinks, cleanContent = false, shrink }: MarkdownProps) => {
  const server = useProvidedDispatch().accountOrServer.server;
  const { primaryColor, navAnchorColor: navColor, darkMode } = useServerTheme(server);

  const cleanedText = cleanContent ? text.replace(
    /((?!  ).)\n([^\n*])/g,
    (_, b, c) => {
      if (b[1] != ' ') b = `${b} `
      return `${b}${c}`;
    }
  ) : text;

  return <Text whiteSpace="pre-wrap">
    <ReactMarkdown children={cleanedText}
      components={{
        // li: ({ node, ordered, ...props }) => <li }} {...props} />,
        h1: ({ children, id }) => <Heading size={shrink ? '$6' : '$9'} {...{ children, id }} />,
        h2: ({ children, id }) => <Heading size={shrink ? '$5' : '$8'} {...{ children, id }} />,
        h3: ({ children, id }) => <Heading size={shrink ? '$4' : '$7'} {...{ children, id }} />,
        h4: ({ children, id }) => <Heading size={shrink ? '$3' : '$6'} {...{ children, id }} />,
        h5: ({ children, id }) => <Heading size={shrink ? '$2' : '$5'} {...{ children, id }} />,
        h6: ({ children, id }) => <Heading size={shrink ? '$1' : '$4'} {...{ children, id }} />,
        li: ({ ordered, index, children }) => <XStack ml={shrink ? '$2' : '$3'} mb='$2'>
          {/* <Paragraph size='$3' mr='$4'>{ordered ? `${index + 1}.` : '• '}</Paragraph>
        <Paragraph size='$3' {...{ children }} /> */}
          <Text fontFamily='$body' fontSize={shrink ? '$1' : '$3'} mr='$4'>{ordered ? `${index + 1}.` : '• '}</Text>
          <Text fontFamily='$body' fontSize={shrink ? '$1' : '$3'} {...{ children }} />
        </XStack>,
        p: ({ children }) => <Paragraph size={shrink ? '$1' : '$3'} marginVertical='$2' {...{ children }} w='100%' />,
        // a: ({ children, href }) => <Anchor color={navColor} target='_blank' {...{ href, children }} />,
        a: ({ children, href }) => disableLinks
          ? <Text fontFamily='$body' color={navColor} {...{ href, children }} />
          : <Anchor fontSize={shrink ? '$1' : '$3'} color={navColor} target='_blank' {...{ href, children }} />,

        code: ({ children, className, node, ...rest }) => {
          // const  = props
          const match = /language-(\w+)/.exec(className || '')
          // console.log('TamaguiMarkdown code match', match)
          return match ? (
            <XStack my='$3'>
              <SyntaxHighlighter
                {...rest}
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
      }} />
  </Text>
}
