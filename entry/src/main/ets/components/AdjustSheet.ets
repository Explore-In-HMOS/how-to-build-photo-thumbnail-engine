@Builder function _noop(): void {}

@CustomDialog
export struct AdjustSheet {
  controller: CustomDialogController = new CustomDialogController({ builder: _noop });
  onClose: () => void = () => {};
  onRotate: (deg: number) => void = () => {};
  onFlip: (horizontal: boolean) => void = () => {};
  onCropSquare: () => void = () => {};

  build() {
    Column({ space: 7 }) {
      Text('Adjust')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Row({ space: 6 }) {
        this.chip('-90', () => this.fire(() => this.onRotate(-90)))
        this.chip('+90', () => this.fire(() => this.onRotate(90)))
      }
      Row({ space: 6 }) {
        this.chip('FlipH', () => this.fire(() => this.onFlip(true)))
        this.chip('FlipV', () => this.fire(() => this.onFlip(false)))
      }
      this.chip('1:1', () => this.fire(() => this.onCropSquare()))
      Button('Close')
        .fontSize(10)
        .height(24)
        .backgroundColor('#303030')
        .fontColor('#CCCCCC')
        .borderRadius(12)
        .onClick(() => this.onClose())
    }
    .padding(12)
    .width('80%')
    .backgroundColor('#1A1A1A')
    .borderRadius(14)
  }

  private fire(action: () => void): void {
    this.onClose();
    action();
  }

  @Builder
  chip(label: string, action: () => void) {
    Button(label)
      .fontSize(10)
      .height(26)
      .padding({ left: 10, right: 10 })
      .backgroundColor('#252525')
      .fontColor('#CCCCCC')
      .borderRadius(13)
      .onClick(action)
  }
}
