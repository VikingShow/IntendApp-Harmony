@Component
struct PersonalInformation {
  build() {
    Row(){
      Image($r('app.media.default_image'))
    }
  }
}

@Preview
@Component
export struct PersonPage {

  build() {
    Column(){
      PersonalInformation()
      Text()
    }
  }
}