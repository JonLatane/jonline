import { ServerTheme } from "app/store";

export function themedButtonBackground(color: string | undefined, textColor?: string, opacity?: number) {
  return {
    backgroundColor: color,
    color: textColor,
    opacity: opacity ?? 0.91,
    hoverStyle: {
      backgroundColor: color,
      opacity: opacity ?? 1,
    },
    focusStyle: {
      backgroundColor: color,
      opacity: opacity ?? 1,
    },
    pressStyle: {
      backgroundColor: color,
      opacity: opacity ?? 1,
    }
  }
}

export function highlightedButtonBackground(
  theme: ServerTheme,
  type?: 'primary' | 'nav',
  highlighted: boolean = true,
) {
  return themedButtonBackground(
    highlighted
      ? type === 'primary' ? theme.primaryColor : theme.navColor
      : undefined,
    highlighted
      ? type === 'primary' ? theme.primaryTextColor : theme.navTextColor
      : undefined,
  )
}
