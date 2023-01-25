import { Button, Paragraph, YStack } from '@jonline/ui'
import { ChevronLeft } from '@tamagui/lucide-icons'
import { RootState, useCredentialDispatch, useTypedSelector } from 'app/store/store'
import React from 'react'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import { TabsNavigation } from '../tabs/tabs_navigation'

const { useParam } = createParam<{ id: string }>()

export function PostDetailsScreen() {
  const [id] = useParam('id')
  const linkProps = useLink({ href: '/' })
  const { dispatch, account_or_server } = useCredentialDispatch();

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" space>
        <Paragraph ta="center" fow="800">{`Post ID: ${id}`}</Paragraph>
        <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button>
      </YStack>
    </TabsNavigation>
  )
}
