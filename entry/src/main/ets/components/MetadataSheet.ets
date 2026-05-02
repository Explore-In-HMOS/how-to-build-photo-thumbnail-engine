function bytesShort(value: number): string {
  if (value >= 1024 * 1024) {
    return `${(value / (1024 * 1024)).toFixed(2)} MB`;
  }
  if (value >= 1024) {
    return `${(value / 1024).toFixed(1)} KB`;
  }
  return `${value} B`;
}

@Builder function _noop(): void {}

@CustomDialog
export struct MetadataSheet {
  controller: CustomDialogController = new CustomDialogController({ builder: _noop });
  onClose: () => void = () => {};
  sourceWidth: number = 0;
  sourceHeight: number = 0;
  decodedWidth: number = 0;
  decodedHeight: number = 0;
  decodedBytes: number = 0;
  loadSource: string = 'Raw FD';
  orientation: string = 'Top-left';
  orientationApplied: boolean = false;
  dateTime: string = '';
  gainMapSummary: string = 'none';

  build() {
    Column({ space: 6 }) {
      Text('Metadata')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      this.row('Source', `${this.sourceWidth} x ${this.sourceHeight}`)
      this.row('Loaded', this.loadSource)
      this.row('Current', `${this.decodedWidth} x ${this.decodedHeight}`)
      this.row('Orientation', this.orientation.length > 0 ? this.orientation : '-')
      this.row('EXIF Fix', this.orientationApplied ? 'applied' : 'not needed')
      this.row('DateTime', this.dateTime.length > 0 ? this.dateTime : '-')
      this.row('GainMap', this.gainMapSummary)
      this.row('RAM', bytesShort(this.decodedBytes))
      Button('Close')
        .fontSize(11)
        .height(24)
        .backgroundColor('#1976D2')
        .fontColor('#FFFFFF')
        .onClick(() => this.onClose())
    }
    .padding(10)
    .width('82%')
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
  }

  @Builder
  row(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(10)
        .fontColor('#AAAAAA')
        .layoutWeight(1)
      Text(value)
        .fontSize(10)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.End)
        .layoutWeight(1)
    }
    .width('100%')
  }
}
