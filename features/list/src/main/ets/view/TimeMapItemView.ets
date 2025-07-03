import { TimeMapClass } from "../model/TimeMapClass"
import { bufferToString } from '../utils/bufferUtil'
import { BreakpointType, BreakpointTypeEnum} from 'utils'

@Component
export struct TimeMapView {
  @State timeMapList: TimeMapClass[] = []
  // @Consume('timeMapPathStack') timeMapPathStack: NavPathStack
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.MD;

  aboutToAppear(): void {
    this.getTimeMapDataFromJSON()
  }

  getTimeMapDataFromJSON() {
    getContext(this).resourceManager.getRawFileContent('TimeMapData.json').then(value => {
      this.timeMapList = JSON.parse(bufferToString(value)) as TimeMapClass[];
    })
  }

  build() {
    Column(){
      Grid(){
        ForEach(this.timeMapList, (item: TimeMapClass) => {
          GridItem(){
            TimeMapItem({timeMapItem: item})
              // .onClick(() => {
              //   this.timeMapPathStack.pushPathByName('timeMapDetail', item)
              // })
          }
          .width(new BreakpointType<Length>({ sm: 160, md: 164, lg: 180 }).getValue(this.currentBreakpoint))
        }, (item: TimeMapClass) => item.id)
      }
      .rowsTemplate('1fr')
      .columnsGap(new BreakpointType<Length>({ sm: 8, md: 12, lg: 16 }).getValue(this.currentBreakpoint))
      .scrollBar(BarState.Off)
      .height(169)
      .padding({ top: 2, left: 16, right: 16 })
    }
  }
}

@Component
export struct TimeMapItem {
  @Prop timeMapItem: TimeMapClass

  build() {
    Column(){
      Image($r(this.timeMapItem.imgSrc))
        .width('100%')
        .objectFit(ImageFit.Cover)
        .height(96)
        .borderRadius({
          topLeft: 16,
          topRight: 16
        })
      Text(this.timeMapItem.title)
        .height(19)
        .width('100%')
        .fontSize(14)
        .textAlign(TextAlign.Start)
        .textOverflow({overflow: TextOverflow.Ellipsis})
        .maxLines(1)
        .fontWeight(400)
        .padding({left: 12, right: 12})
        .margin({top:8})
      Text(this.timeMapItem.brief)
        .height(32)
        .width('100%')
        .fontSize(12)
        .textAlign(TextAlign.Start)
        .textOverflow({overflow:TextOverflow.Ellipsis})
        .maxLines(2)
        .fontWeight(400)
        .fontColor('rgba(0,0,0,0.6)')
        .padding({left:12, right:12})
        .margin({top:2})
    }
    .width(160)
    .height(169)
    .borderRadius(16)
    .backgroundColor(Color.White)
  }
}