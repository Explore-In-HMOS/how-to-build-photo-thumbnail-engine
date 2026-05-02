export type PackFormat = 'jpeg' | 'png' | 'webp';

export function packMimeType(format: PackFormat): string {
  if (format === 'jpeg') {
    return 'image/jpeg';
  }
  if (format === 'png') {
    return 'image/png';
  }
  return 'image/webp';
}

export function packSupportsQuality(format: PackFormat): boolean {
  return format !== 'png';
}

export function packLabel(format: PackFormat): string {
  if (format === 'jpeg') {
    return 'JPEG';
  }
  if (format === 'png') {
    return 'PNG';
  }
  return 'WebP';
}
