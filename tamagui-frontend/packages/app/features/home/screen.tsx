import { Anchor, Button, H1, Input, Paragraph, Separator, Sheet, XStack, YStack } from '@jonline/ui'
import { ChevronDown, ChevronUp } from '@tamagui/lucide-icons'
import { RootState, useTypedDispatch, useTypedSelector } from 'app/store/store';
import React, { useState } from 'react'
import { useLink } from 'solito/link'
import { createServer, selectAllServers } from "../../store/modules/Servers";
import { selectAllAccounts } from "../../store/modules/Accounts";
import { AccountsSheet } from '../accounts/server_sheet';


export function HomeScreen() {
  const linkProps = useLink({
    href: '/user/nate',
  })

  return (
    <YStack f={1} jc="center" ai="center" p="$4" space>
      <YStack space="$4" maw={600}>
        <H1 ta="center">Welcome to Jonline.</H1>
        <Paragraph ta="center">
          Login or choose a server to get started.
        </Paragraph>

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
        <Button {...linkProps}>Link to user</Button>
      </XStack>

      <AccountsSheet />
    </YStack>
  )
}
