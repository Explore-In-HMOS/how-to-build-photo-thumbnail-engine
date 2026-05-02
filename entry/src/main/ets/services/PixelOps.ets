import { image } from '@kit.ImageKit';
import { Logger } from '../utils/Logger';

export class PixelOps {
  static async rotate(pixelMap: image.PixelMap, deg: number): Promise<void> {
    try {
      await pixelMap.rotate(deg);
    } catch (err) {
      Logger.error('PixelOps.rotate failed', err as Object);
      throw err as Error;
    }
  }

  static async flip(pixelMap: image.PixelMap, horizontal: boolean, vertical: boolean): Promise<void> {
    try {
      await pixelMap.flip(horizontal, vertical);
    } catch (err) {
      Logger.error('PixelOps.flip failed', err as Object);
      throw err as Error;
    }
  }

  static async scale(pixelMap: image.PixelMap, factor: number): Promise<void> {
    if (!Number.isFinite(factor) || factor <= 0) {
      Logger.warn(`PixelOps.scale skipped invalid factor ${factor}`);
      return;
    }
    try {
      await pixelMap.scale(factor, factor);
    } catch (err) {
      Logger.error('PixelOps.scale failed', err as Object);
      throw err as Error;
    }
  }

  static async cropCenterSquare(pixelMap: image.PixelMap): Promise<void> {
    const info: image.ImageInfo = await pixelMap.getImageInfo();
    const side = Math.min(info.size.width, info.size.height);
    const x = Math.max(0, Math.floor((info.size.width - side) / 2));
    const y = Math.max(0, Math.floor((info.size.height - side) / 2));
    const size: image.Size = { width: side, height: side };
    const region: image.Region = { x: x, y: y, size: size };
    await PixelOps.cropToRegion(pixelMap, region);
  }

  static async cropToRegion(pixelMap: image.PixelMap, region: image.Region): Promise<void> {
    try {
      await pixelMap.crop(region);
    } catch (err) {
      Logger.error('PixelOps.cropToRegion failed', err as Object);
      throw err as Error;
    }
  }
}
