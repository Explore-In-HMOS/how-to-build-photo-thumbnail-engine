import { image } from '@kit.ImageKit';
import { PackFormat, packLabel } from '../model/PackFormat';
import { AuxiliarySource, PreviewSource } from '../model/PackResult';
import { Logger } from '../utils/Logger';
import { RESULT_PREVIEW_SIZE } from '../constants/AppConstants';

export interface ResultPageParam {
  exampleTitle: string;
  accent: string;
  format: PackFormat;
  quality: number;
  byteLength: number;
  decodedBytes: number;
  sourceWidth: number;
  sourceHeight: number;
  currentWidth: number;
  currentHeight: number;
  layers: number;
  auxiliarySource: AuxiliarySource;
  orientationApplied: boolean;
  hasGainMap: boolean;
  previewMap: image.PixelMap;
  previewSource: PreviewSource;
}

function bytesLabel(value: number): string {
  if (value >= 1024 * 1024) {
    return `${(value / (1024 * 1024)).toFixed(2)} MB`;
  }
  if (value >= 1024) {
    return `${(value / 1024).toFixed(1)} KB`;
  }
  return `${value} B`;
}

@Component
export struct ResultPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @Prop params: ResultPageParam;
  private released: boolean = false;

  private compressionPct(): number {
    if (this.params.decodedBytes <= 0) {
      return 0;
    }
    const saved = this.params.decodedBytes - this.params.byteLength;
    return Math.min(99, Math.max(0, Math.round(saved * 100 / this.params.decodedBytes)));
  }

  private isFallback(): boolean {
    return this.params.previewSource === 'main-roundtrip-fallback';
  }

  aboutToDisappear(): void {
    this.releasePreview();
  }

  build() {
    Scroll() {
      Column({ space: 5 }) {
        Stack() {
          Progress({
            value: this.compressionPct(),
            total: 100,
            type: ProgressType.Ring
          })
            .width(118)
            .height(118)
            .color(this.params.accent)
            .backgroundColor('#1C1C1C')
            .style({ strokeWidth: 9 })
          Image(this.params.previewMap)
            .width(RESULT_PREVIEW_SIZE)
            .height(RESULT_PREVIEW_SIZE)
            .objectFit(ImageFit.Cover)
            .borderRadius(RESULT_PREVIEW_SIZE / 2)
            .backgroundColor('#101010')
            .border({ width: 1, color: '#2A2A2A', radius: RESULT_PREVIEW_SIZE / 2 })
        }
        .width(118)
        .height(118)

        Text(`${this.compressionPct()}% smaller`)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.params.accent)
          .maxLines(1)
        Text(`${packLabel(this.params.format)} @ ${this.params.quality}`)
          .fontSize(9)
          .fontColor('#777777')
          .maxLines(1)

        Row({ space: 4 }) {
          this.badge(this.params.layers > 1, this.params.layers > 1 ? 'Multi' : '1 layer')
          if (this.params.orientationApplied) {
            this.badge(true, 'EXIF')
          }
          if (this.params.hasGainMap) {
            this.badge(true, 'GainMap')
          }
          if (this.params.auxiliarySource === 'extracted-gainmap') {
            this.badge(true, 'Extracted')
          }
          if (this.isFallback()) {
            this.badge(true, 'Fallback')
          }
        }

        this.statRow('Source', `${this.params.sourceWidth} x ${this.params.sourceHeight}`)
        this.statRow('Current', `${this.params.currentWidth} x ${this.params.currentHeight}`)
        this.statRow('RAM', bytesLabel(this.params.decodedBytes))
        this.statRow('Packed', bytesLabel(this.params.byteLength))

        Button('Done')
          .fontSize(11)
          .height(28)
          .width(88)
          .backgroundColor(this.params.accent)
          .fontColor('#FFFFFF')
          .borderRadius(14)
          .margin({ top: 4 })
          .onClick(() => this.pathStack.pop())
      }
      .width('100%')
      .padding({ top: 12, bottom: 16, left: 12, right: 12 })
      .alignItems(HorizontalAlign.Center)
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  badge(active: boolean, label: string) {
    Text(label)
      .fontSize(8)
      .fontColor(active ? '#FFFFFF' : '#777777')
      .backgroundColor(active ? '#242424' : '#151515')
      .borderRadius(8)
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .maxLines(1)
  }

  @Builder
  statRow(label: string, value: string) {
    Row({ space: 8 }) {
      Text(label)
        .fontSize(9)
        .fontColor('#666666')
      Text(value)
        .fontSize(9)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CCCCCC')
    }
  }

  private async releasePreview(): Promise<void> {
    if (this.released) {
      return;
    }
    this.released = true;
    try {
      await this.params.previewMap.release();
    } catch (err) {
      Logger.warn('ResultPage preview release failed');
    }
  }
}

@Component
export struct ResultPageDestination {
  @Prop params: ResultPageParam;

  build() {
    NavDestination() {
      ResultPage({ params: this.params })
    }
    .hideTitleBar(true)
    .backgroundColor('#000000')
  }
}
