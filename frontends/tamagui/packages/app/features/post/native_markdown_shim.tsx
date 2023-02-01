
//TODO: Find a way to render markdown on native that doesn't break web.
// This import causes a crash on web if NativeMarkdownShim is used.
import Markdown from 'react-native-markdown-package';

import {Component} from 'react'
import {Platform, View} from 'react-native'


class Nothing extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return <View />
  }
}

export const NativeMarkdownShim = Platform.OS == 'web' ? Nothing : Markdown
export default NativeMarkdownShim;
