import { image } from '@kit.ImageKit';

@Observed
export class PreviewWrapper {
  pixelMap: image.PixelMap | undefined = undefined;
  version: number = 0;

  set(pixelMap: image.PixelMap | undefined): void {
    this.pixelMap = pixelMap;
    this.version = this.version + 1;
  }
}

@Component
export struct PreviewCanvas {
  @ObjectLink wrapper: PreviewWrapper;
  diameter: number = 150;
  circular: boolean = false;

  build() {
    Stack() {
      if (this.wrapper.pixelMap !== undefined) {
        Image(this.wrapper.pixelMap)
          .width(this.diameter)
          .height(this.diameter)
          .objectFit(this.circular ? ImageFit.Cover : ImageFit.Contain)
          .borderRadius(this.circular ? this.diameter / 2 : 12)
          .clip(true)
      } else {
        if (this.circular) {
          Circle({ width: this.diameter, height: this.diameter })
            .fill('#0D0D0D')
            .stroke('#1E1E1E')
            .strokeWidth(2)
        } else {
          Rect({ width: this.diameter, height: this.diameter })
            .fill('#0D0D0D')
            .stroke('#1E1E1E')
            .strokeWidth(2)
            .radius(12)
        }
        LoadingProgress()
          .width(this.diameter * 0.32)
          .height(this.diameter * 0.32)
          .color('#1976D2')
      }
    }
    .width(this.diameter)
    .height(this.diameter)
  }
}
