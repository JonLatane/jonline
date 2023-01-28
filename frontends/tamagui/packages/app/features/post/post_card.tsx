import React from "react";
import { StyleSheet, View, Text as NativeText, Platform } from "react-native";
import store, { RootState, useCredentialDispatch, useTypedDispatch, useTypedSelector } from "../../store/store";
import { JonlineServer, removeServer, selectServer } from "../../store/modules/servers";
import { AlertDialog, Button, Card, Heading, Image, Paragraph, Text, Post, Theme, XStack, YStack, useTheme, Anchor, Tooltip, useMedia } from "@jonline/ui";
import { Lock, Trash, Unlock } from "@tamagui/lucide-icons";
import Accounts, { removeAccount, selectAccount, selectAllAccounts } from "app/store/modules/accounts";
import ReactMarkdown from 'react-markdown'
import { useLink } from "solito/link";
import moment from 'moment';
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
  isPreview?: boolean;
}

const PostCard: React.FC<Props> = ({ post, isPreview }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);
  const media = useMedia();

  let theme = useTheme();
  let textColor: string = theme.color.val;
  const server = useTypedSelector((state: RootState) => state.servers.server);
  let navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  let preview: string | undefined = useTypedSelector((state: RootState) => state.posts.previews[post.id]);
  if (!preview && !loadingPreview) {
    setLoadingPreview(true);
    setTimeout(() =>
      dispatch(loadPostPreview({ ...post, ...accountOrServer })), 100);
  }

  const postLink = useLink({
    href: `/post/${post.id}`,
  });
  const authorLink = useLink({
    href: `/user/${post.author?.userId}`,
  });
  const postLinkProps = isPreview ? postLink : {};
  const authorLinkProps = post.author ? authorLink : undefined;
  const showDetailsShadow = isPreview && post.content && post.content.length > 1000;
  const detailsMargins = showDetailsShadow ? 20 : 0;
  const detailsProps = showDetailsShadow ? {
    marginHorizontal:-detailsMargins,
    shadowOpacity:0.3,
    shadowOffset:{width:-5, height:-5},
    shadowRadius:10
  } : {};

  let cleanedContent = post.content?.replace(
    /((?!  ).)\n([^\n*])/g,
    (_, b, c) => {
      if (b[1] != ' ') b = `${b} `
      return `${b}${c}`;
    }
  );

  return (
    <Theme inverse={false}>
      <Card theme="dark" elevate size="$4" bordered
        margin='$0'
        marginBottom='$3'
        padding='$0'
        f={isPreview ? undefined : 1}
        animation="bouncy"
        pressStyle={{ scale: 0.990 }}
        {...postLinkProps}>
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
              <YStack maxHeight={isPreview ? 300 : undefined} overflow='hidden'>
              {(!isPreview && preview && preview != '') ?
                <Image
                  // pos="absolute"
                  // width={400}
                  // opacity={0.25}
                  // height={400}
                  // minWidth={300}
                  // minHeight={300}
                  // width='100%'
                  // height='100%'
                  mb='$3'
                  width={media.sm ? 300 : 400}
                  height={media.sm ? 300 : 400}
                  resizeMode="contain"
                  als="center"
                  src={preview}
                  borderRadius={10}
                  // borderBottomRightRadius={5}
                /> : undefined}
                {
                  post.content && post.content != '' ? Platform.select({
                    web: // web/cross-platform-ish
                      <NativeText style={{ color: textColor }}>
                        <ReactMarkdown className="postMarkdown" children={cleanedContent!}
                          components={{
                            // li: ({ node, ordered, ...props }) => <li }} {...props} />,
                            p: ({ node, ...props }) => <p style={{ display: 'inline-block', marginBottom: 10 }} {...props} />,
                            a: ({ node, ...props }) => isPreview ? <span style={{ color: navColor }} children={props.children} /> : <a style={{ color: navColor }} target='_blank' {...props} />,
                          }}
                        />
                      </NativeText>,
                    // default: post.content ? <Markdown /> : undefined
                    default: <Heading size='$1'>Native Markdown support pending!</Heading>
                  }) : undefined
                }
              </YStack>

              <XStack pt={10} {...detailsProps}>
                <YStack mr='auto' marginLeft={detailsMargins}>
                  <Heading size="$1">
                    {post.author
                      ? <>by{' '}<Anchor {...authorLinkProps} zIndex={1000}>{post.author?.username}</Anchor></>
                      : 'by anonymous'}
                  </Heading>
                  <Tooltip placement="bottom-start">
                    <Tooltip.Trigger>
                      <Heading size="$1">
                        {moment.utc(post.createdAt).local().startOf('seconds').fromNow()}
                      </Heading>
                    </Tooltip.Trigger>
                    <Tooltip.Content>
                      <Heading size='$2'>{moment.utc(post.createdAt).local().format("ddd, MMM Do YYYY, h:mm:ss a")}</Heading>
                    </Tooltip.Content>
                  </Tooltip>
                </YStack>
                <XStack f={1} />
                <Anchor {...postLinkProps} marginRight={detailsMargins}>
                  <Heading size="$1" style={{ marginRight: 'auto' }}>{post.responseCount} response{post.responseCount == 1 ? '' : 's'}</Heading>
                </Anchor>
              </XStack>
            </YStack>
          </XStack>
        </Card.Footer>
        <Card.Background>
          {(isPreview && preview && preview != '') ?
            <Image
              pos="absolute"
              width={300}
              opacity={0.25}
              height={300}
              resizeMode="contain"
              als="flex-start"
              src={preview}
              blurRadius={1.5}
              // borderRadius={5}
              borderBottomRightRadius={5}
            /> : undefined}
        </Card.Background>
      </Card>
    </Theme>
  );
};

export default PostCard;
