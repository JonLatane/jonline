import { PostDetailsScreen } from 'app/features/post/post_details_screen'
import { Stack } from 'expo-router'

export default function Screen() {
  return (
    <>
      <Stack.Screen
        options={{
          title: 'Post',
        }}
      />
      <PostDetailsScreen />
    </>
  )
}
