import React from "react";
import { StyleSheet, View, Text as NativeText, Platform } from "react-native";
import store, { RootState, useCredentialDispatch, useTypedDispatch, useTypedSelector } from "../../store/store";
import { JonlineServer, removeServer, selectServer } from "../../store/modules/servers";
import { AlertDialog, Button, Card, Heading, Image, Paragraph, Text, Post, Theme, XStack, YStack, useTheme, Anchor } from "@jonline/ui";
import { Lock, Trash, Unlock } from "@tamagui/lucide-icons";
import Accounts, { removeAccount, selectAccount, selectAllAccounts } from "app/store/modules/accounts";
import ReactMarkdown from 'react-markdown'
import { useLink } from "solito/link";
import { loadPostPreview } from "app/store/modules/posts";
import Markdown, {
  AstRenderer,
  getUniqueID,
  PluginContainer,
  renderRules,
  styles,
} from 'react-native-markdown-renderer';

interface Props {
  post: Post;
  maxContentHeight?: number;
  linkToDetails?: boolean;
}

const PostCard: React.FC<Props> = ({ post, maxContentHeight, linkToDetails = false }) => {
  const { dispatch, account_or_server } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);

  let theme = useTheme();
  let textColor: string = theme.color.val;
  const server = useTypedSelector((state: RootState) => state.servers.server);
  let navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  let preview: string | undefined = useTypedSelector((state: RootState) => state.posts.previews[post.id]);
  if (!preview && !loadingPreview) {
    setLoadingPreview(true);
    setTimeout(() =>
      dispatch(loadPostPreview({ ...post, ...account_or_server })), 100);
  }

  const postLink = useLink({
    href: `/post/${post.id}`,
  });
  const authorLink = useLink({
    href: `/user/${post.author?.userId}`,
  });
  const postLinkProps = linkToDetails ? postLink : {};
  const authorLinkProps = post.author ? authorLink : undefined;

  // if (authorLinkProps) {
  //   const authorLinkOnPress = authorLinkProps?.onPress;
  //   authorLinkProps!.onPress = (e: React.MouseEvent<HTMLAnchorElement, MouseEvent>) => {
  //     e.stopPropagation();
  //     authorLinkOnPress!();
  //   };
  // }

  let cleanedContent = post.content?.replace(
    /((?!  ).)\n([^\n*])/g,
    (_, b, c) => {
      if (b[1] != ' ') b = `${b} `
      return `${b}${c}`;
    }
  );
  // debugger;
  return (
    <Theme inverse={false}>
      <Card theme="dark" elevate size="$4" bordered
        margin='$0'
        marginBottom='$3'
        padding='$0'
        animation="bouncy"
        pressStyle={{ scale: 0.990 }}
        {...postLinkProps}
      // onPress={postLinkProps.onPress}
      >
        <Card.Header>
          <XStack>
            <View style={{ flex: 1 }}>
              {post.link
                ? <Anchor href={post.link} onPress={(e) => e.stopPropagation()} target="_blank" rel='noopener noreferrer'
                  color={navColor}
                ><Heading size="$7" marginRight='auto' color={navColor}>{post.title}</Heading></Anchor>
                : <Heading size="$7" marginRight='auto'>{post.title}</Heading>
              }
            </View>
          </XStack>
        </Card.Header>
        <Card.Footer>
          <XStack width='100%' >
            <YStack style={{ flex: 10 }} zi={1000}>
              <YStack maxHeight={maxContentHeight} overflow='hidden'>
                {
                  post.content && post.content != '' ? Platform.select({
                    web: // web/cross-platform-ish
                      <NativeText style={{ color: textColor }}>
                        <ReactMarkdown children={cleanedContent!}
                          components={{
                            li: ({ node, ordered, ...props }) => <li style={{ listStyleType: ordered ? 'number' : 'disc', marginLeft: 20 }} {...props} />,
                            p: ({ node, ...props }) => <p style={{ display: 'inline-block', marginBottom: 10 }} {...props} />,
                            a: ({ node, ...props }) => <a style={{ color: navColor }} target='_blank' {...props} />,
                          }}
                        />
                      </NativeText>,
                    // default: post.content ? <Markdown /> : undefined
                    default: <Heading size='$1'>Native Markdown support pending!</Heading>
                  }) : undefined
                }
              </YStack>

              <XStack marginTop={10}>
                <Heading size="$1" style={{ marginRight: 'auto' }}>
                  {post.author
                    ? <>by{' '}<Anchor {...authorLinkProps} zIndex={1000}>{post.author?.username}</Anchor></>
                    : 'by anonymous'}
                </Heading>
                <XStack f={1} />
                <Anchor {...postLinkProps}>
                  <Heading size="$1" style={{ marginRight: 'auto' }}>{post.responseCount} response{post.responseCount == 1 ? '' : 's'}</Heading>
                </Anchor>
              </XStack>
            </YStack>
          </XStack>
        </Card.Footer>
        <Card.Background>
          {(preview && preview != '') ?
            <Image
              pos="absolute"
              width={300}
              opacity={0.25}
              height={300}
              resizeMode="contain"
              als="flex-start"
              src={preview}
              // borderRadius={5}
              borderBottomRightRadius={5}
            /> : undefined}
        </Card.Background>
      </Card>
    </Theme>
  );
};

export default PostCard;
