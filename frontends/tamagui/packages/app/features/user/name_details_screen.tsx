import { Button, Paragraph, YStack } from '@jonline/ui'
import { ChevronLeft } from '@tamagui/lucide-icons'
import { RootState, useCredentialDispatch, useTypedSelector } from 'app/store/store'
import React from 'react'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import { TabsNavigation } from '../tabs/tabs_navigation'

const { useParam } = createParam<{ id: string }>()

export function UsernameDetailsScreen() {
  const [username] = useParam('id')
  const linkProps = useLink({ href: '/' })
  const { dispatch, accountOrServer } = useCredentialDispatch();

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" space>
        <Paragraph ta="center" fow="800">{`Username: ${username}`}</Paragraph>
        <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button>
      </YStack>
    </TabsNavigation>
  )
}
