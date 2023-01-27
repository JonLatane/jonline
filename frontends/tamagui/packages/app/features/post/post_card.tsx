import React from "react";
import { StyleSheet, View, Text as NativeText } from "react-native";
import store, { RootState, useCredentialDispatch, useTypedDispatch, useTypedSelector } from "../../store/store";
import { JonlineServer, removeServer, selectServer } from "../../store/modules/servers";
import { AlertDialog, Button, Card, Heading, Image, Paragraph,Text, Post, Theme, XStack, YStack, useTheme, Anchor } from "@jonline/ui";
import { Lock, Trash, Unlock } from "@tamagui/lucide-icons";
import Accounts, { removeAccount, selectAccount, selectAllAccounts } from "app/store/modules/accounts";
import ReactMarkdown from 'react-markdown'
import { useLink } from "solito/link";
import { loadPostPreview } from "app/store/modules/posts";

interface Props {
  post: Post;
}

const PostCard: React.FC<Props> = ({ post }) => {
  const { dispatch, account_or_server } = useCredentialDispatch();

  let theme = useTheme();
  let textColor: string = theme.color.val;
  const server = useTypedSelector((state: RootState) => state.servers.server);
  let navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  let preview = post.previewImage 
  ?  URL.createObjectURL(
    new Blob([post.previewImage!], { type: 'image/png' })
  ) : undefined;
  // if(!preview) {
  //   dispatch(loadPostPreview({...post, ...account_or_server}));
  // }

  const postLinkProps = useLink({
    href: `/post/${post.id}`,
  });
  const postLinkOnPress = postLinkProps.onPress;
  postLinkProps.onPress = (e: React.MouseEvent<HTMLAnchorElement, MouseEvent>) => {
    e.stopPropagation();
    // postLinkOnPress();
  };
  const authorLinkProps = post.author && useLink({
    href: `/user/${post.author!.userId}`,
  }) || {};
  // const authorLinkOnPress = authorLinkProps.onPress;
  // authorLinkProps.onPress = (e: React.MouseEvent<HTMLAnchorElement, MouseEvent>) => {
  //   e.stopPropagation();
  //   authorLinkOnPress();
  // };

  // function doRemoveServer() {
  //   accounts.forEach(account => {
  //     if (account.server.host == server.host) {
  //       dispatch(removeAccount(account.id));
  //     }
  //   });
  //   dispatch(removeServer(server.host));
  // }

  let cleanedContent = post.content?.replace(
      /((?!  ).)\n([^\n*])/g,
      (_, b, c) =>  {
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
        // scale={0.9}
        // width={260}
        // hoverStyle={{ scale: 0.925 }}
        pressStyle={{ scale: 0.990 }}
        onPress={postLinkProps.onPress}
        // {...postLinkProps}
        >
        <Card.Header>
          <XStack>
            <View style={{ flex: 1 }}>
              {post.link 
              ? <Anchor href={post.link} target="_blank" rel='noopener noreferrer'
              color={navColor}
              ><Heading size="$7" marginRight='auto' color={navColor}>{post.title && post.title}</Heading></Anchor>
              :<Heading size="$7" marginRight='auto'>{post.title && post.title}</Heading>
}
            </View>
            {/* {server.secure ? <Lock /> : <Unlock />} */}
          </XStack>
        </Card.Header>
        <Card.Footer>
          <XStack width='100%' >
            <YStack style={{ flex: 10 }}>
            {/* <Heading size="$1" style={{marginRight: 'auto'}}>{accounts.length || "No"} account{ accounts.length == 1 ? '' : 's'}</Heading> */}
            {/* <Heading size="$1" style={{marginRight: 'auto'}}>{server.serviceVersion!.version}</Heading> */}
            <NativeText style={{color: textColor}}>
            {/* <Text fontFamily={"$body"} space='$3'> */}
            {post.content && <ReactMarkdown children={cleanedContent!}
              components={{
                li: ({node, ordered, ...props}) => <li style={{ listStyleType: ordered ? 'number' : 'disc', marginLeft: 20 }} {...props} />,
                p: ({node, ...props}) => <p style={{ display: 'inline-block', marginBottom: 10 }} {...props} />,
                a: ({node, ...props}) => <a style={{ color:navColor }} target='_blank' {...props} />,
                // ul: ({node, ...props}) => <ul style={{ listStyleType: 'disc', marginLeft: 20 }} {...props} />,
              }}
            />}
            {/* </Text> */}
            </NativeText>

            <XStack marginTop={10}>
              <Heading size="$1" style={{ marginRight: 'auto' }}>
                {post.author 
                  ? <>by{' '}<Anchor {...authorLinkProps}>{post.author?.username}</Anchor></> 
                  : 'by anonymous'}
              </Heading>
              <XStack f={1} />
              <Heading size="$1" style={{ marginRight: 'auto' }}>{post.responseCount} response{post.responseCount == 1 ? '' : 's'}</Heading>
            </XStack>
            </YStack>
          </XStack>
        </Card.Footer>
        {/* <Card.Background backgroundColor={selected ? '#424242' : undefined} /> */}
      <Card.Background>
        {preview && <Image
          pos="absolute"
          width={300}
          height={300}
          resizeMode="contain"
          als="center"
          src={preview}
        />}
      </Card.Background>
      </Card>
    </Theme>
  );
};

export default PostCard;
