import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { Logger } from '../utils/Logger';
import { PREVIEW_TARGET_PX } from '../constants/AppConstants';

export type ImageLoadSource = 'Raw FD' | 'URI';

export interface LoadedImage {
  source: image.ImageSource;
  pixelMap: image.PixelMap;
  loadSource: ImageLoadSource;
  sourceWidth: number;
  sourceHeight: number;
  decodedWidth: number;
  decodedHeight: number;
}

export class ImageLoader {
  static async loadRawfile(context: common.UIAbilityContext, fileName: string): Promise<LoadedImage> {
    let source: image.ImageSource | undefined = undefined;
    try {
      const rawDescriptor: resourceManager.RawFileDescriptor = context.resourceManager.getRawFdSync(fileName);
      const sourceOptions: image.SourceOptions = { sourceDensity: 0 };
      source = image.createImageSource(rawDescriptor, sourceOptions);
      return await ImageLoader.decodeSource(source, 'Raw FD');
    } catch (err) {
      Logger.error(`ImageLoader.loadRawfile failed for ${fileName}`, err as Object);
      if (source !== undefined) {
        try {
          await source.release();
        } catch (releaseErr) {
          Logger.warn('source release after load failure failed');
        }
      }
      throw err as Error;
    } finally {
      try {
        context.resourceManager.closeRawFdSync(fileName);
      } catch (closeErr) {
        Logger.warn(`closeRawFdSync failed for ${fileName}`);
      }
    }
  }

  static async loadRawfileViaUri(context: common.UIAbilityContext, fileName: string): Promise<LoadedImage> {
    const targetPath = `${context.cacheDir}/${fileName}`;
    let file: fileIo.File | undefined = undefined;
    try {
      const content = context.resourceManager.getRawFileContentSync(fileName);
      const mode = fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC;
      file = fileIo.openSync(targetPath, mode);
      const buffer = content.buffer.slice(content.byteOffset, content.byteOffset + content.byteLength);
      fileIo.writeSync(file.fd, buffer);
    } catch (err) {
      Logger.error(`ImageLoader.loadRawfileViaUri copy failed for ${fileName}`, err as Object);
      throw err as Error;
    } finally {
      if (file !== undefined) {
        try {
          fileIo.closeSync(file);
        } catch (closeErr) {
          Logger.warn('URI staging file close failed');
        }
      }
    }
    return await ImageLoader.loadUri(`file://${targetPath}`);
  }

  static async loadUri(uri: string): Promise<LoadedImage> {
    let source: image.ImageSource | undefined = undefined;
    try {
      const sourceOptions: image.SourceOptions = { sourceDensity: 0 };
      source = image.createImageSource(uri, sourceOptions);
      return await ImageLoader.decodeSource(source, 'URI');
    } catch (err) {
      Logger.error(`ImageLoader.loadUri failed for ${uri}`, err as Object);
      if (source !== undefined) {
        try {
          await source.release();
        } catch (releaseErr) {
          Logger.warn('URI ImageSource release after load failure failed');
        }
      }
      throw err as Error;
    }
  }

  private static async decodeSource(
    source: image.ImageSource,
    loadSource: ImageLoadSource
  ): Promise<LoadedImage> {
    const info: image.ImageInfo = await source.getImageInfo();
    const sourceWidth = info.size.width;
    const sourceHeight = info.size.height;
    const longest = Math.max(sourceWidth, sourceHeight);
    const scale = longest > PREVIEW_TARGET_PX ? PREVIEW_TARGET_PX / longest : 1;
    const decodedWidth = Math.max(1, Math.round(sourceWidth * scale));
    const decodedHeight = Math.max(1, Math.round(sourceHeight * scale));
    const decodingOptions: image.DecodingOptions = {
      desiredSize: { width: decodedWidth, height: decodedHeight },
      editable: true,
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888
    };
    const pixelMap: image.PixelMap = await source.createPixelMap(decodingOptions);
    const result: LoadedImage = {
      source: source,
      pixelMap: pixelMap,
      loadSource: loadSource,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      decodedWidth: decodedWidth,
      decodedHeight: decodedHeight
    };
    return result;
  }
}
