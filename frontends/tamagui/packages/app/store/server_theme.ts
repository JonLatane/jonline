import { useTheme } from "@jonline/ui";
import { RootState, useRootSelector } from "./store";
import { JonlineServer } from './types';

export type ServerTheme = {
  server?: JonlineServer;

  primaryColor: string;
  primaryTextColor: string;
  primaryDarkColor: string;
  primaryLightColor: string;
  primaryBgColor: string;
  primaryAnchorColor: string;

  navColor: string;
  navTextColor: string;
  navDarkColor: string;
  navLightColor: string;
  navBgColor: string;
  navAnchorColor: string;

  textColor: string;

  backgroundColor: string;

  warningAnchorColor: string;
  darkMode: boolean;
}
export function useServerTheme(): ServerTheme {
  const server = useRootSelector((state: RootState) => state.servers.server);
  const primaryColorInt = server?.serverConfiguration?.serverInfo?.colors?.primary ?? 0x424242;
  const navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation ?? 0xFFFFFF;

  const {
    color: primaryColor,
    textColor: primaryTextColor,
    darkColor: primaryDarkColor,
    lightColor: primaryLightColor,
  } = colorIntMeta(primaryColorInt);
  const {
    color: navColor,
    textColor: navTextColor,
    darkColor: navDarkColor,
    lightColor: navLightColor,
  } = colorIntMeta(navColorInt);


  const theme = useTheme();
  const backgroundColor = theme.background.val;
  const { luma: themeBgLuma, textColor } = colorMeta(backgroundColor);
  const darkMode = themeBgLuma <= 0.5;
  const primaryBgColor = darkMode ? primaryDarkColor : primaryLightColor;
  const primaryAnchorColor = !darkMode ? primaryDarkColor : primaryLightColor;
  const navAnchorColor = !darkMode ? navDarkColor : navLightColor;
  const navBgColor = !darkMode ? navDarkColor : navLightColor;

  const warningAnchorColor = !darkMode ? '#d1c504' : '#EBDF1C';
  // debugger;
  return {
    server,
    backgroundColor,
    textColor,
    darkMode,

    warningAnchorColor,

    primaryColor, primaryTextColor, primaryDarkColor, primaryLightColor,
    primaryBgColor, primaryAnchorColor,

    navColor, navTextColor, navDarkColor, navLightColor,
    navBgColor, navAnchorColor,
  };
}

type ColorMeta = {
  // A string representation of the int-encoded server color data.
  color: string;
  // Foreground color for text on top of this color
  textColor: string;
  // This color, if it is suitable for light backgrounds. Otherwise, a darker version of this color that is.
  darkColor: string;
  // This color, if it is suitable for dark backgrounds. Otherwise, a lighter version of this color that is.
  lightColor: string;
  luma: number;
}

const _colorMetas = new Map<string, ColorMeta>();
export function colorIntMeta(colorInt: number): ColorMeta {
  const color = '#' + colorInt.toString(16).slice(-6);
  return colorMeta(color);
}
export function colorMeta(color: string): ColorMeta {
  if (_colorMetas.has(color)) {
    return _colorMetas[color];
  }
  const parsed = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(color);
  let rgb = parsed ? {
    r: parseInt(parsed[1]!, 16),
    g: parseInt(parsed[2]!, 16),
    b: parseInt(parsed[3]!, 16),
  } : null;
  if (!rgb) {
    const parsedHsl = /hsl\(\s*(\d+)\s*,\s*(\d+(?:\.\d+)?%)\s*,\s*(\d+(?:\.\d+)?%)\)/.exec(color);
    const hsl = parsedHsl ? {
      h: parseInt(parsedHsl[1]!, 10),
      s: parseFloat(parsedHsl[2]!),
      l: parseFloat(parsedHsl[3]!),
    } : null;
    if (!hsl) throw 'Invalid color: ' + color;
    let [r, g, b] = hslToRgb(hsl.h, hsl.s, hsl.l);
    rgb = { r: r!, g: g!, b: b! };
  }
  const { r, g, b } = rgb!;
  const red = r / 255;
  const green = g / 255;
  const blue = b / 255;
  const luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue;

  let textColor: string, darkColor: string, lightColor: string
  if (luma > 0.5) {
    textColor = '#000000';
    lightColor = color;
    darkColor = shadeColor(color, -40);
  } else {
    textColor = '#FFFFFF';
    darkColor = color;
    lightColor = shadeColor(color, 40);
  }

  // debugger;
  const meta = { color, textColor, darkColor, lightColor, luma }
  _colorMetas[color] = meta;
  return meta;
}
function shadeColor(color: string, percent: number) {

  var R = parseInt(color.substring(1, 3), 16);
  var G = parseInt(color.substring(3, 5), 16);
  var B = parseInt(color.substring(5, 7), 16);

  R = R * (100 + percent) / 100;
  G = G * (100 + percent) / 100;
  B = B * (100 + percent) / 100;

  R = (R < 255) ? R : 255;
  G = (G < 255) ? G : 255;
  B = (B < 255) ? B : 255;

  R = Math.round(R)
  G = Math.round(G)
  B = Math.round(B)

  var RR = ((R.toString(16).length == 1) ? "0" + R.toString(16) : R.toString(16));
  var GG = ((G.toString(16).length == 1) ? "0" + G.toString(16) : G.toString(16));
  var BB = ((B.toString(16).length == 1) ? "0" + B.toString(16) : B.toString(16));

  return "#" + RR + GG + BB;
}
function hslToRgb(h: number, s: number, l: number): number[] {
  var r, g, b;

  if (s == 0) {
    r = g = b = l; // achromatic
  } else {
    var hue2rgb = function hue2rgb(p, q, t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    var p = 2 * l - q;
    r = hue2rgb(p, q, h + 1 / 3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1 / 3);
  }

  return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
}
