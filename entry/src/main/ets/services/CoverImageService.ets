import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { NetworkHttpMethod, NetworkService } from './NetworkService';

export interface CoverPalette {
  surfaceColor: string;
  primaryTextColor: string;
  secondaryTextColor: string;
  disabledTextColor: string;
  trackColor: string;
}

interface ColorSwatch {
  red: number;
  green: number;
  blue: number;
  population: number;
  hex: string;
}

interface ColorBucket {
  red: number;
  green: number;
  blue: number;
  population: number;
}

export class CoverImageService {
  private static readonly CONTRAST_RATIO: number = 4.5;
  private static readonly COLOR_SIMILARITY_THRESHOLD: number = 150;
  private static readonly PALETTE_SIZE: number = 16;
  private static readonly SAMPLE_SIZE: number = 64;

  static readonly FALLBACK_PALETTE: CoverPalette = {
    surfaceColor: '#D8D1C3',
    primaryTextColor: '#211A17',
    secondaryTextColor: '#3F332D',
    disabledTextColor: '#8F847A',
    trackColor: '#B9B0A3'
  };

  static async cacheCover(
    context: common.Context,
    remoteUrl: string,
    key: string,
    header?: Record<string, string>
  ): Promise<string> {
    const url = remoteUrl.trim();
    if (url.length === 0 || url.startsWith('file://')) {
      return url;
    }

    try {
      const response = await NetworkService.requestBuffer(url, {
        method: NetworkHttpMethod.GET,
        header: header,
        connectTimeout: 12000,
        readTimeout: 12000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return '';
      }
      if (!(response.body.byteLength > 0)) {
        return '';
      }

      const directory = `${context.cacheDir}/ha_music_covers`;
      CoverImageService.ensureDirectory(directory);
      const filePath = `${directory}/${CoverImageService.safeFileName(key)}.img`;
      const file = fs.openSync(filePath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, response.body);
      } finally {
        fs.closeSync(file);
      }
      return `file://${filePath}`;
    } catch (_) {
      return '';
    }  }

  static async extractPalette(coverUrl: string): Promise<CoverPalette> {
    const path = CoverImageService.localPath(coverUrl);
    if (path.length === 0) {
      return CoverImageService.FALLBACK_PALETTE;
    }

    let file: fs.File | undefined = undefined;
    let source: image.ImageSource | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;
    try {
      if (!fs.accessSync(path)) {
        return CoverImageService.FALLBACK_PALETTE;
      }
      file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      source = image.createImageSource(file.fd);
      pixelMap = await source.createPixelMap({
        desiredSize: {
          width: CoverImageService.SAMPLE_SIZE,
          height: CoverImageService.SAMPLE_SIZE
        },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      const buffer = new ArrayBuffer(pixelMap.getPixelBytesNumber());
      await pixelMap.readPixelsToBuffer(buffer);
      return CoverImageService.paletteFromPixels(new Uint8Array(buffer));
    } catch (_) {
      return CoverImageService.FALLBACK_PALETTE;
    } finally {
      if (pixelMap) {
        try {
          await pixelMap.release();
        } catch (_) {
        }
      }
      if (source) {
        try {
          await source.release();
        } catch (_) {
        }
      }
      if (file) {
        try {
          fs.closeSync(file);
        } catch (_) {
        }
      }
    }
  }

  private static ensureDirectory(path: string): void {
    try {
      if (!fs.accessSync(path)) {
        fs.mkdirSync(path, true);
      }
    } catch (_) {
      try {
        fs.mkdirSync(path, true);
      } catch (_) {
      }
    }
  }

  private static safeFileName(value: string): string {
    const source = value.trim().length > 0 ? value.trim() : 'cover';
    let result = '';
    for (let i = 0; i < source.length; i++) {
      const code = source.charCodeAt(i);
      const isDigit = code >= 48 && code <= 57;
      const isUpper = code >= 65 && code <= 90;
      const isLower = code >= 97 && code <= 122;
      result += isDigit || isUpper || isLower ? source.charAt(i) : '_';
    }
    return result.length > 0 ? result : 'cover';
  }

  private static localPath(coverUrl: string): string {
    const value = coverUrl.trim();
    if (value.startsWith('file://')) {
      return value.substring(7);
    }
    if (value.startsWith('/')) {
      return value;
    }
    return '';
  }

  private static paletteFromPixels(pixels: Uint8Array): CoverPalette {
    const swatches = CoverImageService.quantizePixels(pixels);
    if (swatches.length === 0) {
      return CoverImageService.FALLBACK_PALETTE;
    }

    const background = swatches[0];
    const foreground = CoverImageService.pickForeground(background, swatches);
    const secondary = CoverImageService.mixSwatch(foreground, background, 0.32);
    const disabled = CoverImageService.mixSwatch(foreground, background, 0.58);
    const track = CoverImageService.mixSwatch(foreground, background, 0.72);

    return {
      surfaceColor: background.hex,
      primaryTextColor: foreground.hex,
      secondaryTextColor: secondary.hex,
      disabledTextColor: disabled.hex,
      trackColor: track.hex
    };
  }

  private static quantizePixels(pixels: Uint8Array): ColorSwatch[] {
    const buckets = new Map<number, ColorBucket>();
    for (let i = 0; i + 3 < pixels.length; i += 4) {
      const red = pixels[i];
      const green = pixels[i + 1];
      const blue = pixels[i + 2];
      const alpha = pixels[i + 3];
      if (alpha < 64 || CoverImageService.isExtremeColor(red, green, blue)) {
        continue;
      }

      const key = CoverImageService.bucketKey(red, green, blue);
      const bucket = buckets.get(key);
      if (bucket) {
        bucket.red += red;
        bucket.green += green;
        bucket.blue += blue;
        bucket.population++;
      } else {
        buckets.set(key, {
          red,
          green,
          blue,
          population: 1
        });
      }
    }

    const swatches: ColorSwatch[] = [];
    buckets.forEach((bucket: ColorBucket) => {
      const red = Math.round(bucket.red / bucket.population);
      const green = Math.round(bucket.green / bucket.population);
      const blue = Math.round(bucket.blue / bucket.population);
      swatches.push({
        red,
        green,
        blue,
        population: bucket.population,
        hex: CoverImageService.toHex(red, green, blue)
      });
    });

    swatches.sort((a: ColorSwatch, b: ColorSwatch): number => {
      return CoverImageService.swatchScore(b) - CoverImageService.swatchScore(a);
    });

    if (swatches.length > CoverImageService.PALETTE_SIZE) {
      return swatches.slice(0, CoverImageService.PALETTE_SIZE);
    }
    return swatches;
  }

  private static pickForeground(background: ColorSwatch, swatches: ColorSwatch[]): ColorSwatch {
    for (let i = 1; i < swatches.length; i++) {
      const candidate = swatches[i];
      if (CoverImageService.contrastRatio(background, candidate) > CoverImageService.CONTRAST_RATIO) {
        return candidate;
      }

      for (let j = i + 1; j < swatches.length; j++) {
        const similar = swatches[j];
        if (CoverImageService.rgbDiff(candidate, similar) > CoverImageService.COLOR_SIMILARITY_THRESHOLD) {
          continue;
        }
        if (CoverImageService.contrastRatio(background, similar) > CoverImageService.CONTRAST_RATIO) {
          return similar;
        }
      }
    }

    return CoverImageService.yiq(background) < 200
      ? CoverImageService.createSwatch(255, 255, 255, 0)
      : CoverImageService.createSwatch(0, 0, 0, 0);
  }

  private static mix(source: number[], target: number[], targetWeight: number): number[] {
    const sourceWeight = 1 - targetWeight;
    return [
      CoverImageService.clamp(Math.round(source[0] * sourceWeight + target[0] * targetWeight)),
      CoverImageService.clamp(Math.round(source[1] * sourceWeight + target[1] * targetWeight)),
      CoverImageService.clamp(Math.round(source[2] * sourceWeight + target[2] * targetWeight))
    ];
  }

  private static mixSwatch(source: ColorSwatch, target: ColorSwatch, targetWeight: number): ColorSwatch {
    const mixed = CoverImageService.mix(
      [source.red, source.green, source.blue],
      [target.red, target.green, target.blue],
      targetWeight
    );
    return CoverImageService.createSwatch(mixed[0], mixed[1], mixed[2], 0);
  }

  private static createSwatch(red: number, green: number, blue: number, population: number): ColorSwatch {
    return {
      red,
      green,
      blue,
      population,
      hex: CoverImageService.toHex(red, green, blue)
    };
  }

  private static bucketKey(red: number, green: number, blue: number): number {
    return ((red >> 3) << 10) | ((green >> 3) << 5) | (blue >> 3);
  }

  private static isExtremeColor(red: number, green: number, blue: number): boolean {
    return (red > 248 && green > 248 && blue > 248) || (red < 6 && green < 6 && blue < 6);
  }

  private static swatchScore(swatch: ColorSwatch): number {
    const saturation = CoverImageService.saturation(swatch.red, swatch.green, swatch.blue);
    const luminance = CoverImageService.luminance(swatch.red, swatch.green, swatch.blue);
    const luminancePenalty = Math.abs(luminance - 145) / 255;
    return swatch.population * (1 + saturation * 0.24 - luminancePenalty * 0.10);
  }

  private static saturation(red: number, green: number, blue: number): number {
    const max = Math.max(red, Math.max(green, blue)) / 255;
    const min = Math.min(red, Math.min(green, blue)) / 255;
    if (max === 0) {
      return 0;
    }
    return (max - min) / max;
  }

  private static luminance(red: number, green: number, blue: number): number {
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
  }

  private static relativeLuminance(red: number, green: number, blue: number): number {
    const r = CoverImageService.linearRgb(red);
    const g = CoverImageService.linearRgb(green);
    const b = CoverImageService.linearRgb(blue);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  private static linearRgb(value: number): number {
    const normalized = value / 255;
    if (normalized <= 0.03928) {
      return normalized / 12.92;
    }
    return Math.pow((normalized + 0.055) / 1.055, 2.4);
  }

  private static contrastRatio(first: ColorSwatch, second: ColorSwatch): number {
    const firstLuminance = CoverImageService.relativeLuminance(first.red, first.green, first.blue);
    const secondLuminance = CoverImageService.relativeLuminance(second.red, second.green, second.blue);
    const lighter = Math.max(firstLuminance, secondLuminance);
    const darker = Math.min(firstLuminance, secondLuminance);
    return (lighter + 0.05) / (darker + 0.05);
  }

  private static rgbDiff(first: ColorSwatch, second: ColorSwatch): number {
    return Math.abs(first.red - second.red) + Math.abs(first.green - second.green) + Math.abs(first.blue - second.blue);
  }

  private static yiq(color: ColorSwatch): number {
    return (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
  }

  private static toHex(red: number, green: number, blue: number): string {
    return `#${CoverImageService.hex(red)}${CoverImageService.hex(green)}${CoverImageService.hex(blue)}`;
  }

  private static hex(value: number): string {
    const normalized = CoverImageService.clamp(value).toString(16).toUpperCase();
    return normalized.length === 1 ? `0${normalized}` : normalized;
  }

  private static clamp(value: number): number {
    return Math.max(0, Math.min(255, value));
  }
}
