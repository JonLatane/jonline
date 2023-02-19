import { useServerTheme } from "app/store";
import React from "react";

import { Anchor, Heading, Paragraph, Text, XStack } from "@jonline/ui";
import ReactMarkdown from 'react-markdown';

export type MarkdownProps = {
  text?: string;
  disableLinks?: boolean;
  cleanContent?: boolean;
}
export const TamaguiMarkdown = ({ text = '', disableLinks, cleanContent = false }: MarkdownProps) => {
  const { server, primaryColor, navAnchorColor: navColor } = useServerTheme();

  const cleanedText = cleanContent ? text.replace(
    /((?!  ).)\n([^\n*])/g,
    (_, b, c) => {
      if (b[1] != ' ') b = `${b} `
      return `${b}${c}`;
    }
  ) : text;

  return <ReactMarkdown children={cleanedText}
    components={{
      // li: ({ node, ordered, ...props }) => <li }} {...props} />,
      h1: ({ children, id }) => <Heading size='$9' {...{ children, id }} />,
      h2: ({ children, id }) => <Heading size='$8' {...{ children, id }} />,
      h3: ({ children, id }) => <Heading size='$7' {...{ children, id }} />,
      h4: ({ children, id }) => <Heading size='$6' {...{ children, id }} />,
      h5: ({ children, id }) => <Heading size='$5' {...{ children, id }} />,
      h6: ({ children, id }) => <Heading size='$4' {...{ children, id }} />,
      li: ({ ordered, index, children }) => <XStack ml='$3' mb='$2'>
        {/* <Paragraph size='$3' mr='$4'>{ordered ? `${index + 1}.` : '• '}</Paragraph>
        <Paragraph size='$3' {...{ children }} /> */}
        <Text fontFamily='$body' fontSize='$3' mr='$4'>{ordered ? `${index + 1}.` : '• '}</Text>
        <Text fontFamily='$body' fontSize='$3' {...{ children }} />
      </XStack>,
      p: ({ children }) => <Paragraph size='$3' marginVertical='$2' {...{ children }} w='100%' />,
      // a: ({ children, href }) => <Anchor color={navColor} target='_blank' {...{ href, children }} />,
      a: ({ children, href }) => disableLinks
        ? <Text fontFamily='$body' color={navColor} {...{ href, children }} />
        : <Anchor color={navColor} target='_blank' {...{ href, children }} />,
    }} />
}
