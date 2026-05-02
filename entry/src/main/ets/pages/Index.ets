import { IMAGE_EXAMPLES } from '../constants/AppConstants';
import { ImageExample } from '../model/ImageExample';
import { EditorPageDestination } from './EditorPage';
import { ResultPageDestination, ResultPageParam } from './ResultPage';

@Entry
@Component
struct Index {
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack();
  @State selectedKind: string = 'load-decode';
  private readonly examples: ImageExample[] = IMAGE_EXAMPLES;

  build() {
    Navigation(this.pathStack) {
      Column({ space: 7 }) {
        List({ space: 5 }) {
          ForEach(this.examples, (example: ImageExample) => {
            ListItem() {
              this.exampleRow(example)
            }
          }, (example: ImageExample) => example.kind)
        }
        .width(210)
        .height(190)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#000000')
      .padding({ bottom: 8 })
    }
    .navDestination(this.buildDestination)
    .mode(NavigationMode.Stack)
    .hideToolBar(true)
    .hideTitleBar(true)
    .backgroundColor('#000000')
  }

  @Builder
  exampleRow(example: ImageExample) {
    Row({ space: 8 }) {
      Stack() {
        Circle({ width: 30, height: 30 })
          .fill(example.accent)
        Text(`${example.sequence}`)
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(30)
      .height(30)

      Column({ space: 1 }) {
        Text(example.label)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .maxLines(1)
        Text(example.detail)
          .fontSize(8)
          .fontColor('#8A8A8A')
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(12)
        .fontColor(example.accent)
    }
    .height(40)
    .width(example.kind === this.selectedKind ? 194 : 178)
    .padding({ left: 8, right: 8 })
    .backgroundColor(example.kind === this.selectedKind ? '#202020' : '#141414')
    .borderRadius(20)
    .opacity(example.kind === this.selectedKind ? 1 : 0.82)
    .margin({ left: example.kind === this.selectedKind ? 0 : 8 })
    .onClick(() => {
      this.selectedKind = example.kind;
      this.pathStack.pushPathByName('EditorPage', example);
    })
  }

  @Builder
  buildDestination(name: string, param: Object) {
    if (name === 'EditorPage') {
      EditorPageDestination({ example: param as ImageExample });
    } else if (name === 'ResultPage') {
      ResultPageDestination({ params: param as ResultPageParam });
    }
  }
}
