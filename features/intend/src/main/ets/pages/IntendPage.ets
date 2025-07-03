
import { webview } from '@kit.ArkWeb';

@Component
export struct IntendPage {
  private webviewController: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      Web({ src: $rawfile("intend/index.html"), controller: this.webviewController })
        .domStorageAccess(true)
        .javaScriptAccess(true) // 允许JavaScript执行
        .mixedMode(MixedMode.All) // 允许混合内容（HTTP和HTTPS）
        .fileAccess(true) // 允许文件访问（如果从本地rawfile加载）
        .mixedMode(MixedMode.All)
        .width('100%')
        .height('100%')
        .onConsole((event)=> {
          console.info(`[React App Console]: ${event.message.getMessage()}`)
          return true
        })
    }
  }
}