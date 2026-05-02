export type ImageExampleKind =
  'load-decode' |
  'round-adapt' |
  'exif-metadata' |
  'pack-export' |
  'picture';

export interface ImageExample {
  kind: ImageExampleKind;
  sequence: number;
  label: string;
  detail: string;
  rawFileName: string;
  accent: string;
}
