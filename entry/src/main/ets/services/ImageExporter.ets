import { image } from '@kit.ImageKit';
import { Logger } from '../utils/Logger';
import { PackFormat, packMimeType, packSupportsQuality } from '../model/PackFormat';
import { PackResult } from '../model/PackResult';

const PACK_BUFFER_SIZE: number = 4 * 1024 * 1024;

export class ImageExporter {
  static async export(pixelMap: image.PixelMap, format: PackFormat, quality: number): Promise<PackResult> {
    const effectiveQuality = packSupportsQuality(format) ? ImageExporter.clampQuality(quality) : 100;
    const option: image.PackingOption = {
      format: packMimeType(format),
      quality: effectiveQuality,
      bufferSize: PACK_BUFFER_SIZE
    };
    const packer: image.ImagePacker = image.createImagePacker();
    let buffer: ArrayBuffer;
    try {
      buffer = await packer.packToData(pixelMap, option);
    } catch (err) {
      Logger.error('ImageExporter.export packing failed', err as Object);
      try {
        await packer.release();
      } catch (releaseErr) {
        Logger.warn('ImagePacker release after pack failure failed');
      }
      throw err as Error;
    }
    try {
      await packer.release();
    } catch (releaseErr) {
      Logger.warn('ImagePacker release failed');
    }

    const previewMap = await ImageExporter.decode(buffer);
    const result: PackResult = {
      format: format,
      quality: effectiveQuality,
      byteLength: buffer.byteLength,
      layers: 1,
      auxiliarySource: 'none',
      buffer: buffer,
      previewMap: previewMap,
      previewSource: 'pack-roundtrip'
    };
    return result;
  }

  static async decode(buffer: ArrayBuffer): Promise<image.PixelMap> {
    const source: image.ImageSource = image.createImageSource(buffer);
    try {
      const decodingOptions: image.DecodingOptions = {
        editable: false,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };
      const pixelMap = await source.createPixelMap(decodingOptions);
      return pixelMap;
    } finally {
      try {
        await source.release();
      } catch (releaseErr) {
        Logger.warn('preview ImageSource release failed');
      }
    }
  }

  private static clampQuality(value: number): number {
    if (!Number.isFinite(value)) {
      return 80;
    }
    if (value < 1) {
      return 1;
    }
    if (value > 100) {
      return 100;
    }
    return Math.round(value);
  }
}
