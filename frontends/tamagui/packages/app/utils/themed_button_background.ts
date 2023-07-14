
export function themedButtonBackground(color: string, textColor?: string) {
  return {
    backgroundColor: color,
    color: textColor,
    opacity: 0.95,
    hoverStyle: {
      backgroundColor: color,
      opacity: 1,
    },
    pressStyle: {
      backgroundColor: color,
      opacity: 1,
    }
  }
}