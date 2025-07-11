// File: entry/src/main/ets/pages/Home.ets
import router from '@ohos.router';
import { StorageService, ProjectMeta } from '../services/StorageService';
import promptAction from '@ohos.promptAction';
import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { DashboardView } from '../components/DashboardView';
import { WelcomeView } from '../components/WelcomeView';

@Entry
@Component
struct HomePage {
  @State projectList: ProjectMeta[] = [];
  @State selectedProjectDetail: Project | null = null;
  @State selectedProjectId: string | null = null;

  private storageService: StorageService | null = null;

  async aboutToAppear() {
    const context = getContext(this).getApplicationContext();
    this.storageService = StorageService.getInstance(context.filesDir);
    await this.loadProjects();
  }

  onPageShow() {
    this.loadProjects();
  }

  async loadProjects() {
    if (this.storageService) {
      const list = await this.storageService.getProjectList();
      this.projectList = list.sort((a, b) => b.lastModified - a.lastModified);
      if (this.selectedProjectId) {
        await this.onSelectProject(this.selectedProjectId);
      }
    }
  }

  async onSelectProject(projectId: string) {
    if (this.storageService) {
      this.selectedProjectId = projectId;
      this.selectedProjectDetail = await this.storageService.getProject(projectId);
    }
  }

  // FIX: New method to handle project creation, saving, and navigation.
  async createAndOpenNewProject() {
    if (!this.storageService) {
      promptAction.showToast({ message: "存储服务未初始化" });
      return;
    }

    console.log("[EasyFlow] Creating new project from Home page");

    // 1. Create a new project with example data.
    const newProject = new Project(undefined, '新移动应用开发计划');
    const today = new Date();
    const task1: TaskNode = {
      id: 'task_1', name: '需求分析与原型设计',
      startDate: today,
      endDate: new Date(today.getTime() + 4 * 24 * 60 * 60 * 1000),
      checklist: [
        { id: 'c1_1', text: '收集用户反馈', isCompleted: true },
        { id: 'c1_2', text: '绘制线框图', isCompleted: true },
        { id: 'c1_3', text: '制作交互原型', isCompleted: false },
      ],
      x: 50, y: 150
    };
    const task2: TaskNode = {
      id: 'task_2', name: 'UI/UX视觉设计',
      startDate: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000),
      endDate: new Date(today.getTime() + 9 * 24 * 60 * 60 * 1000),
      checklist: [],
      x: 350, y: 50
    };
    newProject.tasks = [task1, task2];
    newProject.dependencies = [{ fromId: 'task_1', toId: 'task_2' }];

    // 2. Save the new project to storage immediately.
    await this.storageService.saveProject(newProject);
    console.log(`[EasyFlow] Project saved with ID: ${newProject.id}`);
    promptAction.showToast({ message: `项目 "${newProject.name}" 已创建` });

    // 3. Navigate to the editor page with the new project's ID.
    router.pushUrl({
      url: 'pages/Index',
      params: { projectId: newProject.id }
    });
  }

  async deleteProject(projectId: string) {
    if (this.storageService) {
      await this.storageService.deleteProject(projectId);
      promptAction.showToast({ message: '项目已删除' });
      if (this.selectedProjectId === projectId) {
        this.selectedProjectId = null;
        this.selectedProjectDetail = null;
      }
      await this.loadProjects();
    }
  }

  build() {
    Row() {
      // --- 左侧边栏 ---
      this.Sidebar()

      // --- 右侧内容区 ---
      Column() {
        if (this.selectedProjectDetail) {
          DashboardView({ project: this.selectedProjectDetail })
        } else {
          WelcomeView()
        }
      }
      .layoutWeight(2)
      .backgroundColor('#F9F9F9')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Sidebar() {
    Column({ space: 15 }) {
      Row({ space: 10 }) {
        Text('我的项目')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.ic_add')).width(20).height(20)
        }
        .width(44).height(44)
        .onClick(() => {
          // FIX: Call the new, robust creation method.
          this.createAndOpenNewProject();
        })
      }
      .width('100%')

      List({ space: 10 }) {
        ForEach(this.projectList, (meta: ProjectMeta) => {
          ListItem() {
            this.ProjectCard(meta)
          }
          .onClick(() => this.onSelectProject(meta.id))
        })
      }
      .layoutWeight(1)
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .border({ width: { right: 1 }, color: '#E0E0E0' })
    .layoutWeight(1)
  }

  @Builder
  ProjectCard(meta: ProjectMeta) {
    Row({ space: 12 }) {
      Column() {
        Image($r('app.media.ic_project_file')).width(24).height(24)
      }.width(48).height(48).backgroundColor('#E0EFFF').justifyContent(FlexAlign.Center).borderRadius(8)

      Column({ space: 4 }) {
        Text(meta.name).fontSize(16).fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`修改于: ${new Date(meta.lastModified).toLocaleDateString()}`).fontSize(12).fontColor(Color.Gray)
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)

      Button() {
        Image($r('app.media.ic_delete')).width(18).height(18).fillColor('#F16363')
      }
      .width(40).height(40).type(ButtonType.Circle).backgroundColor(Color.Transparent)
      .onClick(() => this.deleteProject(meta.id))
      .hitTestBehavior(HitTestMode.Block)
    }
    .width('100%')
    .padding(12)
    .borderRadius(10)
    .backgroundColor(this.selectedProjectId === meta.id ? '#F0F8FF' : Color.Transparent)
  }

  @Builder
  EmptyState() {
    Column({ space: 16 }) {
      Image($r('app.media.ic_empty_box')).width(100).height(100).opacity(0.5)
      Text('还没有任何项目')
        .fontSize(18)
        .fontColor(Color.Gray)
      Text('点击上方的“+”按钮来创建一个新项目吧！')
        .fontSize(14)
        .fontColor(Color.Gray)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }
}
