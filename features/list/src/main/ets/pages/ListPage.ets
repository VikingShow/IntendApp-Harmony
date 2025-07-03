import { TimeMapView } from '../view/TimeMapItemView'
import { BreakpointType, BreakpointTypeEnum } from 'utils'
import { Header } from '../view/Header';

@Entry
@Component
export struct ListPage {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.MD;

  build() {
    Column(){
      Header()
      Scroll(){
        Column(){
          TimeMapView()
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}