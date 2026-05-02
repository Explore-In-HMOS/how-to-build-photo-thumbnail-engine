import { image } from '@kit.ImageKit';
import { Logger } from '../utils/Logger';

interface OrientationOps {
  flipH: boolean;
  flipV: boolean;
  rotateDeg: number;
}

function opsForOrientation(orientation: string): OrientationOps {
  switch (orientation) {
    case 'Top-left':
    case '1':
      return { flipH: false, flipV: false, rotateDeg: 0 };
    case 'Top-right':
    case '2':
      return { flipH: true, flipV: false, rotateDeg: 0 };
    case 'Bottom-right':
    case '3':
    case '180':
      return { flipH: false, flipV: false, rotateDeg: 180 };
    case 'Bottom-left':
    case '4':
      return { flipH: false, flipV: true, rotateDeg: 0 };
    case 'Left-top':
    case '5':
      return { flipH: true, flipV: false, rotateDeg: 270 };
    case 'Right-top':
    case '6':
    case '90':
      return { flipH: false, flipV: false, rotateDeg: 90 };
    case 'Right-bottom':
    case '7':
      return { flipH: true, flipV: false, rotateDeg: 90 };
    case 'Left-bottom':
    case '8':
    case '270':
      return { flipH: false, flipV: false, rotateDeg: 270 };
    default:
      return { flipH: false, flipV: false, rotateDeg: 0 };
  }
}

export class OrientationFixer {
  static async apply(pixelMap: image.PixelMap, orientation: string): Promise<boolean> {
    const ops = opsForOrientation(orientation);
    if (!ops.flipH && !ops.flipV && ops.rotateDeg === 0) {
      return false;
    }
    try {
      if (ops.flipH || ops.flipV) {
        await pixelMap.flip(ops.flipH, ops.flipV);
      }
      if (ops.rotateDeg !== 0) {
        await pixelMap.rotate(ops.rotateDeg);
      }
      return true;
    } catch (err) {
      Logger.warn('OrientationFixer.apply failed; leaving as decoded');
      return false;
    }
  }
}
