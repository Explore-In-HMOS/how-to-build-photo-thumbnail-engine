import { ImageExample } from '../model/ImageExample';

export const PREVIEW_TARGET_PX: number = 320;
export const DEFAULT_PACK_QUALITY: number = 80;
export const EDITOR_PREVIEW_SIZE: number = 132;
export const RESULT_PREVIEW_SIZE: number = 92;

export const IMAGE_EXAMPLES: ImageExample[] = [
  {
    kind: 'load-decode',
    sequence: 1,
    label: 'Load & Decode',
    detail: 'ImageSource · DecodingOptions',
    rawFileName: 'sample1.jpg',
    accent: '#FFB347'
  },
  {
    kind: 'round-adapt',
    sequence: 2,
    label: 'Round Adapt',
    detail: 'Full image · Fit',
    rawFileName: 'sample2.jpg',
    accent: '#4CAF50'
  },
  {
    kind: 'exif-metadata',
    sequence: 3,
    label: 'EXIF Metadata',
    detail: 'ImageProperty · orientation',
    rawFileName: 'sample3.jpg',
    accent: '#03A9F4'
  },
  {
    kind: 'pack-export',
    sequence: 4,
    label: 'Pack & Export',
    detail: 'ImagePacker · PackingOption',
    rawFileName: 'sample4.jpg',
    accent: '#FF7043'
  },
  {
    kind: 'picture',
    sequence: 5,
    label: 'Picture Layers',
    detail: 'Picture · AuxiliaryPicture',
    rawFileName: 'sample2.jpg',
    accent: '#26A69A'
  }
];
