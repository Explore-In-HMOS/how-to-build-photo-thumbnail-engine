@Builder function _noop(): void {}

@CustomDialog
export struct AdvancedSheet {
  controller: CustomDialogController = new CustomDialogController({ builder: _noop });
  onClose: () => void = () => {};
  hasGainMap: boolean = false;
  gainMapSummary: string = 'none';
  inheritedLabel: string = 'JPEG @ 80';
  onComposeMultiLayer: () => void = () => {};

  build() {
    Column({ space: 7 }) {
      Text('Picture')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      this.row('Auxiliary', this.hasGainMap ? 'Extracted' : 'Generated')
      this.row('GainMap', this.gainMapSummary)
      this.row('Pack', this.inheritedLabel)
      Button('Pack')
        .fontSize(10)
        .height(26)
        .backgroundColor('#1976D2')
        .fontColor('#FFFFFF')
        .borderRadius(13)
        .onClick(() => {
          this.onClose();
          this.onComposeMultiLayer();
        })
      Button('Close')
        .fontSize(10)
        .height(24)
        .backgroundColor('#303030')
        .fontColor('#CCCCCC')
        .borderRadius(12)
        .onClick(() => this.onClose())
    }
    .padding(12)
    .width('82%')
    .backgroundColor('#1A1A1A')
    .borderRadius(14)
  }

  @Builder
  row(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(9)
        .fontColor('#888888')
        .layoutWeight(1)
      Text(value)
        .fontSize(9)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.End)
        .layoutWeight(1)
    }
    .width('100%')
  }
}
