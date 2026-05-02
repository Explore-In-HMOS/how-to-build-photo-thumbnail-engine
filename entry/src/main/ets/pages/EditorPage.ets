import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { ImageExample } from '../model/ImageExample';
import { PackFormat, packLabel } from '../model/PackFormat';
import { PackResult } from '../model/PackResult';
import { ImageLoader, ImageLoadSource, LoadedImage } from '../services/ImageLoader';
import { MetadataReader, MetadataDigest } from '../services/MetadataReader';
import { OrientationFixer } from '../services/OrientationFixer';
import { PixelOps } from '../services/PixelOps';
import { ImageExporter } from '../services/ImageExporter';
import { PictureComposer } from '../services/PictureComposer';
import { Logger } from '../utils/Logger';
import { PreviewCanvas, PreviewWrapper } from '../components/PreviewCanvas';
import { MetadataSheet } from '../components/MetadataSheet';
import { PackOptionsPanel } from '../components/PackOptionsPanel';
import { AdjustSheet } from '../components/AdjustSheet';
import { AdvancedSheet } from '../components/AdvancedSheet';
import { EDITOR_PREVIEW_SIZE, DEFAULT_PACK_QUALITY, PREVIEW_TARGET_PX } from '../constants/AppConstants';
import { ResultPageParam } from './ResultPage';

@Component
export struct EditorPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @Prop example: ImageExample;
  @State preview: PreviewWrapper = new PreviewWrapper();
  @State busy: boolean = false;
  @State roundAdapted: boolean = false;

  private source: image.ImageSource | undefined = undefined;
  private pixelMap: image.PixelMap | undefined = undefined;
  private sourceWidth: number = 0;
  private sourceHeight: number = 0;
  private currentWidth: number = 0;
  private currentHeight: number = 0;
  private decodedBytes: number = 0;
  private loadSource: ImageLoadSource = 'Raw FD';
  private orientation: string = '';
  private orientationApplied: boolean = false;
  private dateTime: string = '';
  private hasGainMap: boolean = false;
  private gainMapSummary: string = 'none';
  private lastPackFormat: PackFormat = 'jpeg';
  private lastPackQuality: number = DEFAULT_PACK_QUALITY;

  aboutToAppear(): void {
    this.loadImage();
  }

  aboutToDisappear(): void {
    this.releaseSession();
  }

  build() {
    Column({ space: 3 }) {
      Stack() {
        PreviewCanvas({
          wrapper: this.preview,
          diameter: EDITOR_PREVIEW_SIZE,
          circular: this.example.kind === 'round-adapt' && this.roundAdapted
        })
        if (this.busy) {
          LoadingProgress()
            .width(28)
            .height(28)
            .color(this.example.accent)
        }
      }
      .width(EDITOR_PREVIEW_SIZE)
      .height(EDITOR_PREVIEW_SIZE)

      Text(this.example.label)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .maxLines(1)

      Text(this.example.detail)
        .fontSize(7)
        .fontColor('#777777')
        .maxLines(1)

      this.actionPanel()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#000000')
    .padding({ top: 4, bottom: 4 })
  }

  @Builder
  actionPanel() {
    if (this.example.kind === 'load-decode') {
      Row({ space: 7 }) {
        this.primaryButton('Info', () => this.openMetadata())
        this.secondaryButton('URI', () => this.loadViaUri())
      }
    } else if (this.example.kind === 'round-adapt') {
      Row({ space: 6 }) {
        this.primaryButton(this.roundAdapted ? 'Pack' : 'Fit', () => {
          if (this.roundAdapted) {
            this.openPack();
          } else {
            this.fitRound();
          }
        })
        this.secondaryButton('Adjust', () => this.openAdjust())
      }
    } else if (this.example.kind === 'exif-metadata') {
      Row({ space: 7 }) {
        this.primaryButton('Info', () => this.openMetadata())
        this.secondaryButton('Pack', () => this.openPack())
      }
    } else if (this.example.kind === 'pack-export') {
      this.primaryButton('Pack', () => this.openPack())
    } else {
      Row({ space: 7 }) {
        this.primaryButton('Build', () => this.composeAdvanced())
        this.secondaryButton('Info', () => this.openAdvanced())
      }
    }
  }

  @Builder
  primaryButton(label: string, action: () => void) {
    Button(label)
      .fontSize(10)
      .fontWeight(FontWeight.Bold)
      .height(26)
      .width(66)
      .backgroundColor(this.example.accent)
      .fontColor('#FFFFFF')
      .borderRadius(15)
      .enabled(!this.busy && this.pixelMap !== undefined)
      .opacity(!this.busy && this.pixelMap !== undefined ? 1 : 0.5)
      .onClick(action)
  }

  @Builder
  secondaryButton(label: string, action: () => void) {
    Button(label)
      .fontSize(8)
      .height(24)
      .width(58)
      .backgroundColor('#242424')
      .fontColor('#CCCCCC')
      .borderRadius(13)
      .enabled(!this.busy && this.pixelMap !== undefined)
      .opacity(!this.busy && this.pixelMap !== undefined ? 1 : 0.5)
      .onClick(action)
  }

  private async loadImage(): Promise<void> {
    this.busy = true;
    try {
      const context = AppStorage.get<common.UIAbilityContext>('abilityContext');
      if (context === undefined) {
        Logger.error('UIAbilityContext missing in AppStorage');
        return;
      }
      const loaded = await ImageLoader.loadRawfile(context, this.example.rawFileName);
      await this.applyLoadedImage(loaded);
    } catch (err) {
      Logger.error('EditorPage loadImage failed', err as Object);
    } finally {
      this.busy = false;
    }
  }

  private async loadViaUri(): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    try {
      const context = AppStorage.get<common.UIAbilityContext>('abilityContext');
      if (context === undefined) {
        Logger.error('UIAbilityContext missing in AppStorage');
        return;
      }
      await this.releaseSession();
      const loaded = await ImageLoader.loadRawfileViaUri(context, this.example.rawFileName);
      await this.applyLoadedImage(loaded);
    } catch (err) {
      Logger.error('EditorPage loadViaUri failed', err as Object);
    } finally {
      this.busy = false;
    }
  }

  private async applyLoadedImage(loaded: LoadedImage): Promise<void> {
    const digest: MetadataDigest = await MetadataReader.read(loaded.source);
    this.source = loaded.source;
    this.pixelMap = loaded.pixelMap;
    this.loadSource = loaded.loadSource;
    this.sourceWidth = loaded.sourceWidth;
    this.sourceHeight = loaded.sourceHeight;
    this.currentWidth = loaded.decodedWidth;
    this.currentHeight = loaded.decodedHeight;
    this.decodedBytes = loaded.pixelMap.getPixelBytesNumber();
    this.orientation = digest.orientation;
    this.dateTime = digest.dateTime;
    this.hasGainMap = digest.hasGainMap;
    this.gainMapSummary = digest.gainMapSummary;
    this.roundAdapted = false;
    this.orientationApplied = await OrientationFixer.apply(loaded.pixelMap, digest.orientation);
    this.preview.set(this.pixelMap);
  }

  private async runOp(op: (pm: image.PixelMap) => Promise<void>): Promise<void> {
    const pm = this.pixelMap;
    if (pm === undefined || this.busy) {
      return;
    }
    this.busy = true;
    try {
      await op(pm);
      const info: image.ImageInfo = await pm.getImageInfo();
      this.currentWidth = info.size.width;
      this.currentHeight = info.size.height;
      this.decodedBytes = pm.getPixelBytesNumber();
      this.preview.set(pm);
    } catch (err) {
      Logger.error('EditorPage op failed', err as Object);
    } finally {
      this.busy = false;
    }
  }

  private async fitRound(): Promise<void> {
    await this.runOp(async (pm: image.PixelMap): Promise<void> => {
      await PixelOps.cropCenterSquare(pm);
      const info: image.ImageInfo = await pm.getImageInfo();
      const longest: number = Math.max(info.size.width, info.size.height);
      if (longest > PREVIEW_TARGET_PX) {
        await PixelOps.scale(pm, PREVIEW_TARGET_PX / longest);
      }
      this.roundAdapted = true;
    });
  }

  private async applyRotate(deg: number): Promise<void> {
    await this.runOp((pm: image.PixelMap): Promise<void> => PixelOps.rotate(pm, deg));
  }

  private async applyFlip(horizontal: boolean): Promise<void> {
    await this.runOp((pm: image.PixelMap): Promise<void> => PixelOps.flip(pm, horizontal, !horizontal));
  }

  private async cropSquare(): Promise<void> {
    await this.runOp((pm: image.PixelMap): Promise<void> => PixelOps.cropCenterSquare(pm));
  }

  private openAdjust(): void {
    if (this.pixelMap === undefined) {
      return;
    }
    let ctrl: CustomDialogController | undefined = undefined;
    ctrl = new CustomDialogController({
      builder: AdjustSheet({
        onClose: (): void => { ctrl?.close(); },
        onRotate: (deg: number) => this.applyRotate(deg),
        onFlip: (horizontal: boolean) => this.applyFlip(horizontal),
        onCropSquare: () => this.cropSquare()
      }),
      customStyle: true,
      alignment: DialogAlignment.Center
    });
    ctrl.open();
  }

  private openMetadata(): void {
    if (this.pixelMap === undefined) {
      return;
    }
    let ctrl: CustomDialogController | undefined = undefined;
    ctrl = new CustomDialogController({
      builder: MetadataSheet({
        onClose: (): void => { ctrl?.close(); },
        sourceWidth: this.sourceWidth,
        sourceHeight: this.sourceHeight,
        decodedWidth: this.currentWidth,
        decodedHeight: this.currentHeight,
        decodedBytes: this.decodedBytes,
        loadSource: this.loadSource,
        orientation: this.orientation,
        orientationApplied: this.orientationApplied,
        dateTime: this.dateTime,
        gainMapSummary: this.gainMapSummary
      }),
      customStyle: true,
      alignment: DialogAlignment.Center
    });
    ctrl.open();
  }

  private openPack(): void {
    if (this.pixelMap === undefined) {
      return;
    }
    let ctrl: CustomDialogController | undefined = undefined;
    ctrl = new CustomDialogController({
      builder: PackOptionsPanel({
        onClose: (): void => { ctrl?.close(); },
        onConfirm: (format: PackFormat, quality: number) => this.pack(format, quality)
      }),
      customStyle: true,
      alignment: DialogAlignment.Center
    });
    ctrl.open();
  }

  private openAdvanced(): void {
    if (this.pixelMap === undefined) {
      return;
    }
    let ctrl: CustomDialogController | undefined = undefined;
    ctrl = new CustomDialogController({
      builder: AdvancedSheet({
        onClose: (): void => { ctrl?.close(); },
        hasGainMap: this.hasGainMap,
        gainMapSummary: this.gainMapSummary,
        inheritedLabel: `${packLabel(this.lastPackFormat)} @ ${this.lastPackQuality}`,
        onComposeMultiLayer: () => this.composeAdvanced()
      }),
      customStyle: true,
      alignment: DialogAlignment.Center
    });
    ctrl.open();
  }

  private async pack(format: PackFormat, quality: number): Promise<void> {
    const pm = this.pixelMap;
    if (pm === undefined || this.busy) {
      return;
    }
    this.busy = true;
    try {
      const result: PackResult = await ImageExporter.export(pm, format, quality);
      this.lastPackFormat = result.format;
      this.lastPackQuality = result.quality;
      this.openResult(result);
    } catch (err) {
      Logger.error('pack failed', err as Object);
    } finally {
      this.busy = false;
    }
  }

  private async composeAdvanced(): Promise<void> {
    const pm = this.pixelMap;
    if (pm === undefined || this.busy) {
      return;
    }
    this.busy = true;
    try {
      const gainMap = this.source !== undefined ? await MetadataReader.extractGainMap(this.source) : null;
      const result: PackResult = await PictureComposer.composeAndPack(
        pm,
        this.lastPackFormat,
        this.lastPackQuality,
        gainMap
      );
      this.openResult(result);
    } catch (err) {
      Logger.error('composeAdvanced failed', err as Object);
    } finally {
      this.busy = false;
    }
  }

  private openResult(result: PackResult): void {
    const param: ResultPageParam = {
      exampleTitle: this.example.label,
      accent: this.example.accent,
      format: result.format,
      quality: result.quality,
      byteLength: result.byteLength,
      decodedBytes: this.decodedBytes,
      sourceWidth: this.sourceWidth,
      sourceHeight: this.sourceHeight,
      currentWidth: this.currentWidth,
      currentHeight: this.currentHeight,
      layers: result.layers,
      auxiliarySource: result.auxiliarySource,
      orientationApplied: this.orientationApplied,
      hasGainMap: this.hasGainMap,
      previewMap: result.previewMap,
      previewSource: result.previewSource
    };
    this.pathStack.pushPathByName('ResultPage', param);
  }

  private async releaseSession(): Promise<void> {
    this.preview.set(undefined);
    const pm = this.pixelMap;
    const src = this.source;
    this.pixelMap = undefined;
    this.source = undefined;
    if (pm !== undefined) {
      try {
        await pm.release();
      } catch (err) {
        Logger.warn('PixelMap release failed');
      }
    }
    if (src !== undefined) {
      try {
        await src.release();
      } catch (err) {
        Logger.warn('ImageSource release failed');
      }
    }
  }
}

@Component
export struct EditorPageDestination {
  @Prop example: ImageExample;

  build() {
    NavDestination() {
      EditorPage({ example: this.example })
    }
    .hideTitleBar(true)
    .backgroundColor('#000000')
  }
}
