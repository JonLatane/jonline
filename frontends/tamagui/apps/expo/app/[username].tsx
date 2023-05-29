import { UsernameDetailsScreen } from 'app/features/user/username_details_screen'
import { Stack } from 'expo-router'

export default function Screen() {
  return (
    <>
      <Stack.Screen
        options={{
          title: 'User',
        }}
      />
      <UsernameDetailsScreen />
    </>
  )
}
