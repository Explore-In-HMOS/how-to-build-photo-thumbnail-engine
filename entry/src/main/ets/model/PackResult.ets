import { image } from '@kit.ImageKit';
import { PackFormat } from './PackFormat';

export type PreviewSource = 'pack-roundtrip' | 'main-roundtrip-fallback';
export type AuxiliarySource = 'none' | 'extracted-gainmap' | 'generated-gainmap';

export interface PackResult {
  format: PackFormat;
  quality: number;
  byteLength: number;
  layers: number;
  auxiliarySource: AuxiliarySource;
  buffer: ArrayBuffer;
  previewMap: image.PixelMap;
  previewSource: PreviewSource;
}
