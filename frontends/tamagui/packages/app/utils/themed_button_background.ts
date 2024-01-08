
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