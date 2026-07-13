import { Button, Paragraph, YStack } from '@jonline/ui'
import { ChevronLeft } from '@tamagui/lucide-icons'
import { useCredentialDispatch } from 'app/hooks'
import React from 'react'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import { TabsNavigation } from '../navigation/tabs_navigation'

const { useParam } = createParam<{ id: string }>()

export function UserDetailsScreen() {
  const [id] = useParam('id')
  const linkProps = useLink({ href: '/' })
  const { dispatch, accountOrServer } = useCredentialDispatch();

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" space>
        <Paragraph ta="center" fow="800">{`User ID: ${id}`}</Paragraph>
        <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button>
      </YStack>
    </TabsNavigation>
  )
}
