import { useTheme } from "@jonline/ui";

import { JonlineServer } from '../store/types';
import { useCurrentServer } from './account_or_server/use_current_account_or_server';

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
  transparentBackgroundColor: string;

  warningAnchorColor: string;
  darkMode: boolean;
}

export function useServerTheme(specificServer?: JonlineServer, inverse?: boolean): ServerTheme {
  const currentServer = useCurrentServer();
  const theme = useTheme({ inverse });
  return getServerTheme(specificServer ?? currentServer, theme);
}

export function getServerTheme(server: JonlineServer | undefined, theme?: any): ServerTheme {
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


  const backgroundColor = theme?.background?.val ?? '#FFFFFF';
  const { luma: themeBgLuma, textColor } = colorMeta(backgroundColor);
  const darkMode = themeBgLuma <= 0.5;
  const transparentBackgroundColor = darkMode ? '#000A' : '#FFFA';
  const primaryBgColor = darkMode ? primaryDarkColor : primaryLightColor;
  const primaryAnchorColor = !darkMode ? primaryDarkColor : primaryLightColor;
  const navAnchorColor = !darkMode ? navDarkColor : navLightColor;
  const navBgColor = !darkMode ? navDarkColor : navLightColor;


  const warningAnchorColor = !darkMode ? '#bf6d00' : '#EBDF1C';
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
    transparentBackgroundColor,
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
const _colorLumas = new Map<string, number>();
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
  const colorAsHex = encodeAsColor(r, g, b);
  const red = r / 255;
  const green = g / 255;
  const blue = b / 255;
  const luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue;

  let textColor: string, darkColor: string, lightColor: string

  if (luma > 0.5) {
    textColor = '#000000';
    lightColor = color;
    darkColor = shadeColor(colorAsHex, -20);
    // console.log('darkColor', darkColor, colorLuma(darkColor));
    while (colorLuma(darkColor) > 0.5) {
      const oldDarkColor = darkColor;
      darkColor = shadeColor(oldDarkColor, -20);
      // console.log('darkened', oldDarkColor, colorLuma(oldDarkColor), 'to', darkColor, colorLuma(darkColor));
      if (darkColor == oldDarkColor) {
        break;
      }
    }
  } else {
    textColor = '#FFFFFF';
    darkColor = color;
    // console.log('initial shade ', -(luma - 0.5) * 100)
    lightColor = shadeColor(colorAsHex, 20);
    // console.log('lightColor', lightColor, colorLuma(lightColor));
    while (colorLuma(lightColor) < 0.5) {
      const oldLightColor = lightColor;
      lightColor = shadeColor(oldLightColor, 20);
      // console.log('lightened', oldLightColor, colorLuma(oldLightColor), 'to', lightColor, colorLuma(lightColor));
      if (lightColor == oldLightColor) {
        break;
      }
    }
  }

  // debugger;
  const meta = { color, textColor, darkColor, lightColor, luma }
  _colorMetas[color] = meta;
  return meta;
}

const _shades = new Map<string, Map<number, string>>();
function shadeColor(color: string, percent: number) {
  if (_shades[color]?.[percent] !== undefined) {
    return _shades[color]?.[percent];
  }
  const R = parseInt(color.substring(1, 3), 16);
  const G = parseInt(color.substring(3, 5), 16);
  const B = parseInt(color.substring(5, 7), 16);
  const multiplier = ((100.0 + percent) / 100.0);
  // console.log('initial', color, multiplier, [R, G, B]);
  const [R1, G1, B1] = [R, G, B]
    .map(n => Math.max(10, Math.min(245, n)))
    .map(n => {
      const result = n * multiplier;
      if (Math.round(result) === Math.round(n)) {
        if (multiplier > 1) {
          return n + 1;
        } else if (multiplier < 1) {
          return n - 1;
        }
      }
      return result;
    })
    .map(n => Math.max(0, Math.min(n, 255)))
    .map(Math.round) as [number, number, number];

  // console.log('encoding', [R1, G1, B1]);

  const result = encodeAsColor(R1, G1, B1);

  if (!_shades[color]) {
    _shades[color] = new Map<number, string>();
  }
  _shades[color][percent] = result;

  return result;
}

// Input bounds: 0-255
function encodeAsColor(r: number, g: number, b: number) {

  const [RR, GG, BB] = [r, g, b]
    .map(n => n.toString(16))
    .map(n => (n.length == 1) ? "0" + n : n) as [string, string, string];

  const result = "#" + RR + GG + BB;
  return result;
}

function colorLuma(color: string): number {
  if (_colorLumas.has(color)) {
    return _colorLumas[color];
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
  let { r, g, b } = rgb!;
  [r, g, b] = [r, g, b].map(n => n < 255 ? (n > 0 ? n : 0) : 255) as [number, number, number];
  const red = r / 255;
  const green = g / 255;
  const blue = b / 255;
  const luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue;

  return luma;
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
