import { Anchor, Button, H1, Input, Paragraph, Separator, Sheet, XStack, YStack } from '@jonline/ui'
import { ChevronDown, ChevronUp } from '@tamagui/lucide-icons'
import { RootState, useCredentialDispatch, useTypedDispatch, useTypedSelector } from 'app/store/store';
import React, { useState } from 'react'
import { useLink } from 'solito/link'
import { upsertServer, selectAllServers } from "../../store/modules/servers";
import { selectAllAccounts } from "../../store/modules/accounts";
import { AccountsSheet } from '../accounts/accounts_sheet';

export function HomeScreen() {
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const linkProps = useLink({
    href: '/user/nate',
  })
  const postLinkProps = useLink({
    href: '/post/asdf123',
  })
  const flutterLinkProps = useLink({
    href: '/flutter',
  })
  // const { dispatch, account_or_server } = useCredentialDispatch();

  return (
    <YStack f={1} jc="center" ai="center" p="$4" space>
      <YStack space="$4" maw={600}>
        <H1 ta="center">Welcome to Jonline.</H1>
        <Paragraph ta="center">
          This new UI for Jonline's Rust/gRPC backend is built with React and Tamagui. It's a work in progress (WIP).
        </Paragraph>
        <Button {...flutterLinkProps}>Switch to Flutter UI</Button>
        {serversState.server != undefined || <Paragraph ta="center">
          Choose an account or server to get started.
        </Paragraph>}

        {/* <Separator />
        <Paragraph ta="center">
          Made by{' '}
          <Anchor color="$color12" href="https://twitter.com/natebirdman" target="_blank">
            @natebirdman
          </Anchor>
          ,{' '}
          <Anchor
            color="$color12"
            href="https://github.com/tamagui/tamagui"
            target="_blank"
            rel="noreferrer"
          >
            give it a ⭐️
          </Anchor>
        </Paragraph> */}
      </YStack>

      <XStack>
        <Button {...linkProps} marginRight='$1'>[WIP] Link to user</Button>
        <Button {...postLinkProps}>[WIP] Link to post</Button>
      </XStack>

      <AccountsSheet />
    </YStack>
  )
}
