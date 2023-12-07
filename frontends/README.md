# Jonline Frontends
Jonline has two frontends, both of which can at least in theory build to many platforms (web, iOS, Android).

Native iOS (Swift UI) and/or Android (Jetpack Compose) ports would, be quite welcome contributions!

It is also possible (and welcomed) to build/sell your own closed-source client, and use Jonline as your backend for your own app that you can sell or even charge a subscription fee for. The AGPL license Jonline is released under does not regulate using the APIs Jonline provides (if I'm wrong, please inform me and I'll create a separate `protos/LICENSE.md`!). Note, however, that you *cannot* simply copy-paste the TypeScript from the Web UI to Swift/Kotlin and keep that code closed source, as the TypeScript source is released under the AGPL.

## Web (Tamagui/React/Next.js) Frontend
The [Tamagui frontend, in `frontends/tamagui`](https://github.com/JonLatane/jonline/tree/main/frontends/tamagui), is the "public Web face" of any Jonline instance. It's built with [Tamagui](https://tamagui.dev) (a somewhat Flutter-like UI toolkit and build system built atop [yarn](https://yarnpkg.com/), [React](https://react.dev), [React Native](https://reactnative.dev), and [Next.JS](https://nextjs.org)), along with [Redux](https://redux.js.org) among others.

Notably, in the future, with Tamagui, it should be possible to build iOS/Android apps from the existing Jonline source (after some effort to port less-native-friendly third-party components).

## Flutter Frontend
The [Flutter frontend, in `frontends/flutter`](https://github.com/JonLatane/jonline/tree/main/frontends/flutter), is built with vanilla Flutter, [Provider](https://pub.dev/packages/provider), [`auto_route`](https://pub.dev/packages/auto_route), and [`protoc_plugin`](https://pub.dev/packages/protoc_plugin), among others.

Unlike the React Native app, the Flutter app also builds a *pretty* macOS app, and should in theory support Windows too.
