import { DEFAULT_PACK_QUALITY } from '../constants/AppConstants';
import { PackFormat, packSupportsQuality } from '../model/PackFormat';

@Builder function _noop(): void {}

@CustomDialog
export struct PackOptionsPanel {
  controller: CustomDialogController = new CustomDialogController({ builder: _noop });
  onClose: () => void = () => {};
  @State format: PackFormat = 'jpeg';
  @State quality: number = DEFAULT_PACK_QUALITY;
  onConfirm: (format: PackFormat, quality: number) => void = () => {};

  build() {
    Column({ space: 6 }) {
      Text('ImagePacker')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Row({ space: 5 }) {
        this.formatButton('jpeg', 'JPEG')
        this.formatButton('png', 'PNG')
        this.formatButton('webp', 'WebP')
      }
      if (packSupportsQuality(this.format)) {
        Stack() {
          Progress({
            value: this.quality,
            total: 100,
            type: ProgressType.Ring
          })
            .width(60)
            .height(60)
            .color('#1976D2')
            .backgroundColor('#2A2A2A')
            .style({ strokeWidth: 6 })
          Text(`${this.quality}`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1976D2')
        }
        .width(60)
        .height(60)
        Slider({
          value: this.quality,
          min: 1,
          max: 100,
          style: SliderStyle.OutSet
        })
          .width('80%')
          .blockColor('#1976D2')
          .selectedColor('#1976D2')
          .onChange((value: number) => {
            this.quality = Math.round(value);
          })
      } else {
        Text('Lossless')
          .fontSize(11)
          .fontColor('#555555')
          .margin({ top: 2, bottom: 2 })
      }
      Text(packSupportsQuality(this.format) ? `quality ${this.quality}` : 'quality ignored')
        .fontSize(8)
        .fontColor('#777777')
        .maxLines(1)
      Row({ space: 8 }) {
        Button('Cancel')
          .fontSize(10)
          .height(26)
          .backgroundColor('#333333')
          .fontColor('#AAAAAA')
          .borderRadius(13)
          .onClick(() => this.onClose())
        Button('Pack')
          .fontSize(10)
          .height(26)
          .backgroundColor('#1976D2')
          .fontColor('#FFFFFF')
          .borderRadius(13)
          .onClick(() => {
            this.onClose();
            this.onConfirm(this.format, this.quality);
          })
      }
    }
    .padding(12)
    .width('82%')
    .backgroundColor('#1A1A1A')
    .borderRadius(16)
  }

  @Builder
  formatButton(value: PackFormat, label: string) {
    Button(label)
      .fontSize(10)
      .height(26)
      .padding({ left: 8, right: 8 })
      .backgroundColor(this.format === value ? '#1976D2' : '#2E2E2E')
      .fontColor(this.format === value ? '#FFFFFF' : '#777777')
      .borderRadius(13)
      .onClick(() => {
        this.format = value;
      })
  }
}
