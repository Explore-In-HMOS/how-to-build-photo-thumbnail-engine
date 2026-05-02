import { image } from '@kit.ImageKit';
import { Logger } from '../utils/Logger';

export interface MetadataDigest {
  orientation: string;
  dateTime: string;
  hasGainMap: boolean;
  gainMapSummary: string;
}

const PROPS: image.PropertyKey[] = [
  image.PropertyKey.ORIENTATION,
  image.PropertyKey.DATE_TIME
];

export class MetadataReader {
  static async read(source: image.ImageSource): Promise<MetadataDigest> {
    let orientation = 'Top-left';
    let dateTime = '';
    try {
      const props: Record<string, string | null> = await source.getImageProperties(PROPS);
      const orientationValue = props[image.PropertyKey.ORIENTATION];
      if (orientationValue !== null && orientationValue !== undefined && orientationValue.length > 0) {
        orientation = orientationValue;
      }
      const dateTimeValue = props[image.PropertyKey.DATE_TIME];
      if (dateTimeValue !== null && dateTimeValue !== undefined) {
        dateTime = dateTimeValue;
      }
    } catch (err) {
      Logger.warn('getImageProperties failed; using defaults');
    }

    const gainMapSummary = await MetadataReader.readGainMapSummary(source);
    const hasGainMap = gainMapSummary.length > 0;
    const result: MetadataDigest = {
      orientation: orientation,
      dateTime: dateTime,
      hasGainMap: hasGainMap,
      gainMapSummary: hasGainMap ? gainMapSummary : 'none'
    };
    return result;
  }

  static async extractGainMap(source: image.ImageSource): Promise<image.AuxiliaryPicture | null> {
    let picture: image.Picture | null = null;
    let aux: image.AuxiliaryPicture | null = null;
    let cloned: image.AuxiliaryPicture | null = null;
    try {
      const decodingOptions: image.DecodingOptionsForPicture = {
        desiredAuxiliaryPictures: [image.AuxiliaryPictureType.GAINMAP]
      };
      picture = await source.createPicture(decodingOptions);
      aux = picture.getAuxiliaryPicture(image.AuxiliaryPictureType.GAINMAP);
      if (aux === null) {
        return null;
      }
      const info = aux.getAuxiliaryPictureInfo();
      const buffer = await aux.readPixelsToBuffer();
      cloned = image.createAuxiliaryPicture(buffer, info.size, image.AuxiliaryPictureType.GAINMAP);
      cloned.setAuxiliaryPictureInfo(info);
      return cloned;
    } catch (err) {
      if (cloned !== null) {
        try {
          cloned.release();
        } catch (releaseErr) {
          Logger.warn('Cloned gain map release failed');
        }
      }
      Logger.info('No extractable HDR gain map available for this image');
      return null;
    } finally {
      if (aux !== null) {
        try {
          aux.release();
        } catch (releaseErr) {
          Logger.warn('AuxiliaryPicture release failed');
        }
      }
      if (picture !== null) {
        try {
          picture.release();
        } catch (releaseErr) {
          Logger.warn('Picture release failed');
        }
      }
    }
  }

  private static async readGainMapSummary(source: image.ImageSource): Promise<string> {
    const aux = await MetadataReader.extractGainMap(source);
    if (aux === null) {
      return '';
    }
    try {
      const info = aux.getAuxiliaryPictureInfo();
      return `${info.size.width} x ${info.size.height}`;
    } finally {
      try {
        aux.release();
      } catch (releaseErr) {
        Logger.warn('Gain map summary release failed');
      }
    }
  }
}
