import { Permission, Post } from '@jonline/api'
import { Button, Heading, ScrollView, TextArea, Tooltip, XStack, YStack, ZStack, isClient, isWeb, useWindowDimensions } from '@jonline/ui'
import { Edit, Eye, Send as SendIcon } from '@tamagui/lucide-icons'
import { RootState, confirmReplySent, replyToPost, selectPostById, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store'
import React, { useEffect, useState } from 'react'
import { TextInput } from 'react-native'
import StickyBox from 'react-sticky-box'
import { AddAccountSheet } from '../accounts/add_account_sheet'
import { TamaguiMarkdown } from './tamagui_markdown'

interface ReplyAreaProps {
  replyingToPath: string[];
  editingPost?: Post;
  onCancelEditing?: () => void;
}

let _replyTextFocused = false;

export const isReplyTextFocused = () => _replyTextFocused;

export const ReplyArea: React.FC<ReplyAreaProps> = ({ replyingToPath, editingPost }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const [replyText, setReplyText] = useState('');
  const [previewReply, setPreviewReply] = useState(false);
  const maxPreviewHeight = useWindowDimensions().height * 0.5;
  // const [isReplying, setIsReplying] = useState(false);
  const [isSendingReply, setIsSendingReply] = useState(false);
  const textAreaRef = React.createRef<TextInput>();// as React.MutableRefObject<HTMLElement | View>;
  const chatUI = useTypedSelector((state: RootState) => state.app.discussionChatUI);
  function sendReply() {
    setIsSendingReply(true);
    dispatch(replyToPost({
      ...accountOrServer,
      postIdPath: replyingToPath,
      content: replyText
    }));
  }
  // const replyingToPost = 
  let pathIndex = 0;
  const rootPost = useTypedSelector((state: RootState) => selectPostById(state.posts, replyingToPath[pathIndex++]!));
  const targetPostId = replyingToPath[replyingToPath.length - 1];
  let targetPost = rootPost;
  while (targetPost != null && targetPost?.id != targetPostId) {
    const replyId = replyingToPath[pathIndex++];
    // debugger;
    targetPost = targetPost?.replies?.find(reply => reply.id == replyId);
    // debugger;
  }
  const replyingToPost = targetPost;
  const sendReplyStatus = useTypedSelector((state: RootState) => state.posts.sendReplyStatus);
  useEffect(() => {
    if (isSendingReply && sendReplyStatus == 'sent') {
      setIsSendingReply(false);
      setReplyText('');
      dispatch(confirmReplySent!());
      if (chatUI && isClient) {
        window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
      }
    }
    if (!isSendingReply && previewReply && replyText == '') {
      setPreviewReply(false);
    }
  });
  const canSend = replyText.length > 0;
  const canComment = (accountOrServer.account?.user?.permissions?.includes(Permission.REPLY_TO_POSTS)
    || accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_POSTS));
  return isWeb ? <StickyBox bottom offsetBottom={0} className='blur' style={{ width: '100%' }}>
    {canComment
      ? <YStack w='100%' pl='$2' opacity={.92} paddingVertical='$2' backgroundColor='$background' alignContent='center'>
        {replyingToPath.length > 1
          ? <Heading size='$1'>Replying to {replyingToPost?.author?.username ?? ''}</Heading>
          : undefined}
        <XStack>
          <ZStack f={1}>
            <TextArea f={1} value={replyText} ref={textAreaRef}
              disabled={isSendingReply} opacity={isSendingReply || !canSend ? 0.5 : 1}
              onChangeText={t => setReplyText(t)}
              onFocus={() => { _replyTextFocused = true; /*window.scrollTo({ top: window.scrollY - _viewportHeight/2, behavior: 'smooth' });*/ }}
              onBlur={() => _replyTextFocused = false}
              placeholder={`Reply to this post. Markdown is supported.`} />
            {previewReply
              ? <YStack p='$3' f={1} backgroundColor='$background'>
                <ScrollView maxHeight={maxPreviewHeight} height={maxPreviewHeight}>
                  <TamaguiMarkdown text={replyText} />
                </ScrollView>
              </YStack>
              : undefined}
          </ZStack>
          <YStack mr='$2' ml='$2' mt='auto' ac='flex-end' >
            <YStack f={1} />
            <Tooltip placement="top-end" key={`preview-button-${previewReply}`}>
              <Tooltip.Trigger>
                <Button circular mb='$2' icon={previewReply ? Edit : Eye}
                  backgroundColor={navColor} color={navTextColor}
                  disabled={!canSend} opacity={!canSend ? 0.5 : 1}
                  onPress={() => {
                    setPreviewReply(!previewReply);
                    if (previewReply) {
                      setTimeout(() => textAreaRef.current?.focus(), 100);
                    }
                  }} />
              </Tooltip.Trigger>
              <Tooltip.Content>
                <Heading size='$2'>{previewReply ? 'Edit reply' : 'Preview reply'}</Heading>
              </Tooltip.Content>
            </Tooltip>
            {/* <YStack f={1}/> */}
            <Button circular icon={SendIcon}
              backgroundColor={primaryColor} color={primaryTextColor}
              disabled={isSendingReply || !canSend}
              opacity={isSendingReply || !canSend ? 0.5 : 1}
              onPress={sendReply} />
          </YStack>
        </XStack>
      </YStack>
      : accountOrServer.account ? <YStack w='100%' opacity={.92} paddingVertical='$2' backgroundColor='$background' alignContent='center'>
        <Heading size='$1'>You do not have permission to {chatUI ? 'chat' : 'comment'}.</Heading>
      </YStack>
        : <YStack w='100%' opacity={.92} p='$3' backgroundColor='$background' alignContent='center'>
          {/* <Button backgroundColor={primaryColor} color={primaryTextColor}>
            Login or Create Account to Comment
          </Button> */}
          <AddAccountSheet operation={chatUI ? 'Chat' : 'Comment'} />
        </YStack>}
  </StickyBox>
    : <Button mt='$3' circular icon={SendIcon} backgroundColor={primaryColor} onPress={() => { }} />

}
// var lastScrollTop = 0;

// // element should be replaced with the actual target element on which you have applied scroll, use window in case of no target element.
// isClient && window.addEventListener("scroll", function(){ // or window.addEventListener("scroll"....
//    var st = window.pageYOffset || document.documentElement.scrollTop; // Credits: "https://github.com/qeremy/so/blob/master/so.dom.js#L426"
//    if (st > lastScrollTop) {
//       // downscroll code
//    } else if (st < lastScrollTop) {
//       // upscroll code
//    } // else was horizontal scroll
//    lastScrollTop = st <= 0 ? 0 : st; // For Mobile or negative scrolling
// }, false);
