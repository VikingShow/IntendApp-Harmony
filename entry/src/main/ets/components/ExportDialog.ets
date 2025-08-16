// File: entry/src/main/ets/components/ExportDialog.ets

import { ExportService } from '../services/ExportService';
import { CommonButton } from './CommonButton';
import { ThemeConfig } from '../utils/ThemeConfig';
import promptAction from '@ohos.promptAction';
import { picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Component
export struct ExportDialog {
  visible: boolean = false;
  projectId?: string;
  projectName?: string;
  onClose: () => void = () => {};

  private exportService: ExportService = ExportService.getInstance();

  build() {
    if (this.visible) {
      Column() {
        // 标题
        Row({ space: ThemeConfig.spacingM }) {
          Text('📤')
            .fontSize(ThemeConfig.fontSizeXXL)
            .fontColor(ThemeConfig.primaryColor)
          Text('导出项目数据')
            .fontSize(ThemeConfig.fontSizeXXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeConfig.gray800)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(ThemeConfig.spacingL)
        .alignItems(VerticalAlign.Center)

        // 项目信息
        if (this.projectName) {
          Column({ space: ThemeConfig.spacingS }) {
            Text('项目名称')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ThemeConfig.gray600)
            Text(this.projectName)
              .fontSize(ThemeConfig.fontSizeL)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeConfig.gray800)
          }
          .width('100%')
          .padding(ThemeConfig.spacingL)
          .backgroundColor(ThemeConfig.gray50)
          .borderRadius(ThemeConfig.radiusMedium)
          .margin({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL })
        }

        // 导出选项
        Column({ space: ThemeConfig.spacingM }) {
          Text('选择导出格式')
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeConfig.gray800)
            .margin({ top: ThemeConfig.spacingL })

          // 导出选项按钮
          Column({ space: ThemeConfig.spacingS }) {
            CommonButton({
              text: '导出当前项目',
              // icon: '📋',
              type: 'primary',
              onButtonClick: () => {
                this.exportCurrentProject();
              }
            })

            CommonButton({
              text: '导出项目报告',
              // icon: '📊',
              type: 'primary',
              onButtonClick: () => {
                this.exportProjectReport();
              }
            })

            CommonButton({
              text: '导出所有项目',
              // icon: '📁',
              type: 'secondary',
              onButtonClick: () => {
                this.exportAllProjects();
              }
            })
          }
          .margin({ top: ThemeConfig.spacingM })
        }
        .padding(ThemeConfig.spacingL)

        // 底部按钮
        Row({ space: ThemeConfig.spacingM }) {
          CommonButton({
            text: '取消',
            type: 'secondary',
            onButtonClick: () => {
              this.onClose();
            }
          })
          .layoutWeight(1)
        }
        .padding(ThemeConfig.spacingL)
      }
      .width('100%')
      .backgroundColor(ThemeConfig.white)
      .borderRadius(ThemeConfig.radiusLarge)
      .shadow(ThemeConfig.shadowLarge)
      .margin(ThemeConfig.spacingL)
    }
  }

  private async exportCurrentProject() {
    if (!this.projectId) {
      promptAction.showToast({ message: '项目ID不存在' });
      return;
    }

    try {
      const exportData = await this.exportService.exportProject(this.projectId);
      // 创建文件管理器选项实例。
      const documentSaveOptions = new picker.DocumentSaveOptions();
      // 保存文件名（可选）。 默认为空。
      documentSaveOptions.newFileNames = ["DocumentViewPicker01.txt"];
      // 保存文件类型['后缀类型描述|后缀类型'],选择所有文件：'所有文件(*.*)|.*'（可选） ，如果选择项存在多个后缀（做大限制100个过滤后缀），默认选择第一个。如果不传该参数，默认无过滤后缀。
      documentSaveOptions.fileSuffixChoices = ['文档|.txt', 'JSON|.json'];

      let uris: Array<string> = [];
      // 请在组件内获取context，确保this.getUIContext().getHostContext()返回结果为UIAbilityContext
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const documentViewPicker = new picker.DocumentViewPicker(context);
      documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
        uris = documentSaveResult;
        console.info('documentViewPicker.save to file succeed and uris are:' + uris);
      }).catch((err: BusinessError) => {
        console.error(`Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`);
      })
      const uri = '';
      //这里需要注意接口权限参数是fs.OpenMode.READ_WRITE。
      let file = fs.openSync(uri, fs.OpenMode.READ_WRITE);
      console.info('file fd: ' + file.fd);
      let writeLen: number = fs.writeSync(file.fd, 'hello, world');
      console.info('write data to file succeed and size is:' + writeLen);
      fs.closeSync(file);

      promptAction.showToast({ message: '项目数据导出成功' });
      console.log('导出数据:', exportData);
    } catch (error) {
      promptAction.showToast({ message: '导出失败，请重试' });
      console.error('导出失败:', error);
    }
  }

  private async exportProjectReport() {
    if (!this.projectId) {
      promptAction.showToast({ message: '项目ID不存在' });
      return;
    }

    try {
      const report = await this.exportService.generateProjectReport(this.projectId);
      // 这里可以添加文件保存逻辑
      promptAction.showToast({ message: '项目报告生成成功' });
      console.log('项目报告:', report);
    } catch (error) {
      promptAction.showToast({ message: '报告生成失败，请重试' });
      console.error('报告生成失败:', error);
    }
  }

  private async exportAllProjects() {
    try {
      const exportData = await this.exportService.exportAllProjects();
      // 这里可以添加文件保存逻辑
      promptAction.showToast({ message: '所有项目数据导出成功' });
      console.log('导出所有项目数据:', exportData);
    } catch (error) {
      promptAction.showToast({ message: '导出失败，请重试' });
      console.error('导出失败:', error);
    }
  }
} 