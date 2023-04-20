import { CreatePostRequest, Permission, Post, Visibility } from '@jonline/api';
import { Button, Heading, Input, isClient, isWeb, Sheet, TextArea, useMedia, XStack, YStack } from '@jonline/ui';
import { ChevronDown, Send as SendIcon, Settings } from '@tamagui/lucide-icons';
import { clearPostAlerts, createPost, RootState, selectAllAccounts, selectAllServers, serverUrl, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { Platform, View } from 'react-native';
import StickyBox from 'react-sticky-box';
import { AddAccountSheet } from '../accounts/add_account_sheet';
// import AccountCard from './account_card';
// import ServerCard from './server_card';
import PostCard from '../post/post_card';
import { VisibilityPicker } from '../post/visibility_picker';
import { CreatePostSheet } from '../post/create_post_sheet';
import { CreateEventSheet } from '../event/create_event_sheet';


interface StickyCreateButtonProps {
  // replyingToPath: string[];
}

export const StickyCreateButton: React.FC<StickyCreateButtonProps> = ({ }: StickyCreateButtonProps) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();

  const canPost = (accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_POSTS)
    || accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_POSTS));

  return isWeb ? <StickyBox bottom offsetBottom={0} className='blur' style={{ width: '100%' }}>
    {canPost
      ? <XStack w='100%' p='$2' space='$2' opacity={.92} backgroundColor='$background' alignContent='center'>
        <CreatePostSheet />
        <CreateEventSheet />
      </XStack>
      : accountOrServer.account ? <YStack w='100%' opacity={.92} paddingVertical='$2' backgroundColor='$background' alignContent='center'>
        <Heading size='$1'>You do not have permission to create posts.</Heading>
      </YStack>
        : <YStack w='100%' opacity={.92} p='$3' backgroundColor='$background' alignContent='center'>
          {/* <Button backgroundColor={primaryColor} color={primaryTextColor}>
            Login or Create Account to Comment
          </Button> */}
          <AddAccountSheet operation='Post' />
        </YStack>}
  </StickyBox>
    : <Button mt='$3' circular icon={SendIcon} backgroundColor={primaryColor} onPress={() => { }} />

}
