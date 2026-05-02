import { image } from '@kit.ImageKit';
import { Logger } from '../utils/Logger';
import { PackFormat, packMimeType, packSupportsQuality } from '../model/PackFormat';
import { PackResult } from '../model/PackResult';
import { ImageExporter } from './ImageExporter';

interface ComposedResult {
  buffer: ArrayBuffer;
  layers: number;
  auxiliarySource: 'extracted-gainmap' | 'generated-gainmap';
}

export class PictureComposer {
  static async composeAndPack(
    main: image.PixelMap,
    format: PackFormat,
    quality: number,
    extractedGainMap: image.AuxiliaryPicture | null
  ): Promise<PackResult> {
    const effectiveQuality = packSupportsQuality(format) ? PictureComposer.clampQuality(quality) : 100;
    const composed = await PictureComposer.packPicture(main, format, effectiveQuality, extractedGainMap);
    const fallback = await ImageExporter.export(main, format, effectiveQuality);
    const result: PackResult = {
      format: format,
      quality: effectiveQuality,
      byteLength: composed.buffer.byteLength,
      layers: composed.layers,
      auxiliarySource: composed.auxiliarySource,
      buffer: composed.buffer,
      previewMap: fallback.previewMap,
      previewSource: 'main-roundtrip-fallback'
    };
    return result;
  }

  private static async packPicture(
    main: image.PixelMap,
    format: PackFormat,
    quality: number,
    extractedGainMap: image.AuxiliaryPicture | null
  ): Promise<ComposedResult> {
    const picture: image.Picture = image.createPicture(main);
    let aux: image.AuxiliaryPicture | null = extractedGainMap;
    let auxiliarySource: 'extracted-gainmap' | 'generated-gainmap' = 'extracted-gainmap';
    let layers = 1;
    try {
      if (aux === null) {
        aux = await PictureComposer.buildAuxiliary(main);
        auxiliarySource = 'generated-gainmap';
      }
      if (aux !== null) {
        picture.setAuxiliaryPicture(image.AuxiliaryPictureType.GAINMAP, aux);
        layers = 2;
      }
      const packer = image.createImagePacker();
      const option: image.PackingOption = {
        format: packMimeType(format),
        quality: quality
      };
      try {
        const buffer = await packer.packing(picture, option);
        const result: ComposedResult = {
          buffer: buffer,
          layers: layers,
          auxiliarySource: auxiliarySource
        };
        return result;
      } catch (err) {
        Logger.error('PictureComposer packPicture failed', err as Object);
        throw err as Error;
      } finally {
        try {
          await packer.release();
        } catch (releaseErr) {
          Logger.warn('Composer packer release failed');
        }
      }
    } finally {
      if (aux !== null) {
        try {
          aux.release();
        } catch (releaseErr) {
          Logger.warn('Composer aux release failed');
        }
      }
      try {
        picture.release();
      } catch (releaseErr) {
        Logger.warn('Composer Picture release failed');
      }
    }
  }

  private static async buildAuxiliary(main: image.PixelMap): Promise<image.AuxiliaryPicture | null> {
    try {
      const info: image.ImageInfo = await main.getImageInfo();
      const auxWidth = Math.max(1, Math.floor(info.size.width / 2));
      const auxHeight = Math.max(1, Math.floor(info.size.height / 2));
      const bytesPerPixel = 4;
      const buffer = new ArrayBuffer(auxWidth * auxHeight * bytesPerPixel);
      const view = new Uint8Array(buffer);
      for (let i = 0; i < view.length; i = i + 4) {
        view[i] = 0x80;
        view[i + 1] = 0x80;
        view[i + 2] = 0x80;
        view[i + 3] = 0xFF;
      }
      const size: image.Size = { width: auxWidth, height: auxHeight };
      const aux = image.createAuxiliaryPicture(buffer, size, image.AuxiliaryPictureType.GAINMAP);
      return aux;
    } catch (err) {
      Logger.warn('buildAuxiliary failed; composing single layer');
      return null;
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
