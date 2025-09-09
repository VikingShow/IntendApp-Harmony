// File: entry/src/main/ets/components/ProjectHeader.ets

import { Project } from '../model/ProjectData';
import promptAction from '@ohos.promptAction';

/**
 * 项目头部组件
 * 显示项目名称、统计信息和编辑功能
 */
@Component
export struct ProjectHeader {
  @ObjectLink project: Project;
  @State isEditingProjectName: boolean = false;
  @State tempProjectName: string = '';

  onUpdateProjectName: (newName: string) => void = () => {};

  aboutToAppear() {
    this.tempProjectName = this.project.name;
  }

  /**
   * 保存项目名称
   */
  private saveProjectName(): void {
    if (this.tempProjectName.trim() === '') {
      promptAction.showToast({ message: '项目名称不能为空' });
      return;
    }
    
    if (this.tempProjectName.trim().length > 50) {
      promptAction.showToast({ message: '项目名称不能超过50个字符' });
      return;
    }

    this.onUpdateProjectName(this.tempProjectName.trim());
    this.isEditingProjectName = false;
  }

  /**
   * 开始编辑项目名称
   */
  private startEditing(): void {
    this.tempProjectName = this.project.name;
    this.isEditingProjectName = true;
  }

  /**
   * 取消编辑
   */
  private cancelEditing(): void {
    this.tempProjectName = this.project.name;
    this.isEditingProjectName = false;
  }

  build() {
    Column({ space: 16 }) {
      // 项目标题区域
      Row({ space: 12 }) {
        if (this.isEditingProjectName) {
          TextInput({ text: this.tempProjectName })
            .layoutWeight(1)
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#F5F5F7')
            .borderRadius(12)
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onChange((value: string) => { 
              this.tempProjectName = value; 
            })
            .onSubmit(() => { 
              this.saveProjectName(); 
            })
        } else {
          Text(this.project.name)
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(1)
            .fontColor('#1D1D1F')
        }

        // 编辑按钮
        Button() {
          Image(this.isEditingProjectName ? $r('app.media.ic_confirm') : $r('app.media.ic_edit'))
            .width(18)
            .height(18)
            .fillColor(this.isEditingProjectName ? '#28A745' : '#666666')
        }
        .width(44)
        .height(44)
        .type(ButtonType.Circle)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 6, color: '#00000012', offsetX: 0, offsetY: 2 })
        .onClick(() => {
          if (this.isEditingProjectName) {
            this.saveProjectName();
          } else {
            this.startEditing();
          }
        })

        // 取消编辑按钮（仅在编辑模式下显示）
        if (this.isEditingProjectName) {
          Button() {
            Text('✕')
              .fontSize(16)
              .fontColor('#FF3B30')
              .fontWeight(FontWeight.Medium)
          }
          .width(44)
          .height(44)
          .type(ButtonType.Circle)
          .backgroundColor('#FFFFFF')
          .borderRadius(22)
          .shadow({ radius: 6, color: '#00000012', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            this.cancelEditing();
          })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 项目统计卡片
      Row({ space: 20 }) {
        // 总任务数
        Column() {
          Text(this.project.tasks.length.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#007AFF')
          Text('总任务')
            .fontSize(13)
            .fontColor('#86868B')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })

        // 关键任务数
        Column() {
          Text(this.project.tasks.filter(t => t.isCritical).length.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FF3B30')
          Text('关键任务')
            .fontSize(13)
            .fontColor('#86868B')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })

        // 已完成任务数
        Column() {
          const completedTasks = this.project.tasks.filter(task => 
            task.checklist && task.checklist.length > 0 && 
            task.checklist.every(item => item.isCompleted)
          ).length;
          Text(completedTasks.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#34C759')
          Text('已完成')
            .fontSize(13)
            .fontColor('#86868B')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })
      }
      .width('100%')

      // 项目进度条
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('项目进度')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1D1D1F')
          
          const totalTasks = this.project.tasks.length;
          const completedTasks = this.project.tasks.filter(task => 
            task.checklist && task.checklist.length > 0 && 
            task.checklist.every(item => item.isCompleted)
          ).length;
          const progress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;
          
          Text(`${progress}%`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#007AFF')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 进度条
        Progress({ value: progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(8)
          .color('#007AFF')
          .backgroundColor('#E5E5E7')
          .borderRadius(4)
      }
      .width('100%')
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 20, color: '#00000008', offsetX: 0, offsetY: 4 })
  }
}
