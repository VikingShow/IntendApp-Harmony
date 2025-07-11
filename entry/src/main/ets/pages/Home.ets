// File: entry/src/main/ets/pages/Home.ets
import router from '@ohos.router';
import { StorageService, ProjectMeta } from '../services/StorageService';
import { LoadingService } from '../services/LoadingService';
import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { DashboardView } from '../components/DashboardView';
import { WelcomeView } from '../components/WelcomeView';
import { LoadingView } from '../components/LoadingView';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct HomePage {
  @State projectList: ProjectMeta[] = [];
  @State selectedProjectDetail: Project | null = null;
  @State selectedProjectId: string | null = null;
  @State componentKey: number = 0;
  @State isLoading: boolean = false;

  private storageService: StorageService | null = null;
  private loadingService: LoadingService = LoadingService.getInstance();

  async aboutToAppear() {
    const context = getContext(this).getApplicationContext();
    this.storageService = StorageService.getInstance(context.filesDir);
    
    // 注册加载状态监听器
    this.loadingService.addListener((key: string, loading: boolean) => {
      if (key === 'project_loading') {
        this.isLoading = loading;
      }
    });
    
    await this.loadProjects();
  }

  onPageShow() {
    this.loadProjects();
  }

  async loadProjects() {
    if (this.storageService) {
      try {
        this.loadingService.setLoading('project_loading', true);
        const list = await this.storageService.getProjectList();
        this.projectList = list.sort((a, b) => b.lastModified - a.lastModified);
        if (this.selectedProjectId) {
          await this.onSelectProject(this.selectedProjectId);
        }
      } catch (error) {
        promptAction.showToast({ message: '加载项目列表失败' });
        console.error('[Home] Load projects error:', error);
      } finally {
        this.loadingService.setLoading('project_loading', false);
      }
    }
  }

  async onSelectProject(projectId: string) {
    if (this.storageService) {
      console.log(`[Home] Selecting project: ${projectId}`);
      this.selectedProjectId = projectId;
      
      // 显示加载状态
      this.loadingService.setLoading('project_loading', true);
      
      // 先清空当前数据，触发UI更新
      this.selectedProjectDetail = null;
      this.componentKey++;
      
      try {
        // 加载新项目数据
        const loadedProject = await this.storageService.getProject(projectId);
        console.log(`[Home] Project loaded: ${loadedProject?.name} with ${loadedProject?.tasks.length} tasks`);
        
        // 设置新数据
        this.selectedProjectDetail = loadedProject;
        this.componentKey++;
        console.log(`[Home] Project data updated, component key: ${this.componentKey}`);
        
        promptAction.showToast({ message: `已切换到项目: ${loadedProject?.name}` });
      } catch (error) {
        promptAction.showToast({ message: '加载项目失败' });
        this.handleError(error as Error, "onSelectProject");
      } finally {
        // 隐藏加载状态
        this.loadingService.setLoading('project_loading', false);
      }
    }
  }

  // FIX: New method to handle project creation, saving, and navigation.
  async createAndOpenNewProject() {
    if (!this.storageService) {
      this.handleError(new Error("存储服务未初始化"), "createAndOpenNewProject");
      return;
    }

    try {
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
    } catch (error) {
      this.handleError(error as Error, "createAndOpenNewProject");
    }
  }

  // 统一的错误处理
  private handleError(error: Error, context: string) {
    console.error(`[${context}] Error:`, error);
    promptAction.showToast({ message: `操作失败: ${error.message}` });
  }

  async deleteProject(projectId: string) {
    // 添加删除确认对话框
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这个项目吗？删除后无法恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消删除
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#EF4444',
        action: async () => {
          if (this.storageService) {
            try {
              await this.storageService.deleteProject(projectId);
              promptAction.showToast({ message: '项目已删除' });
              if (this.selectedProjectId === projectId) {
                this.selectedProjectId = null;
                this.selectedProjectDetail = null;
              }
              await this.loadProjects();
            } catch (error) {
              promptAction.showToast({ message: '删除失败，请重试' });
              console.error('[Home] Delete project error:', error);
            }
          }
        }
      }
    });
  }

  build() {
    Stack() {
      Row() {
        // --- 左侧边栏 ---
        this.Sidebar()

        // --- 右侧内容区 ---
        Column() {
          if (this.isLoading) {
            LoadingView({ message: '加载项目中...' })
          } else if (this.selectedProjectDetail) {
            // 使用 key 属性强制重新创建组件
            DashboardView({ project: this.selectedProjectDetail })
              .key(`${this.selectedProjectDetail.id}_${this.componentKey}`)
          } else {
            WelcomeView()
          }
        }
        .layoutWeight(2)
        .backgroundColor('#F8FAFC')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Sidebar() {
    Column({ space: 20 }) {
      // 标题区域
      Row({ space: 12 }) {
        Text('📁')
          .fontSize(24)
          .fontColor('#007DFF')
        Text('我的项目')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .layoutWeight(1)
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_add'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(48)
        .height(48)
        .backgroundColor('#007DFF')
        .shadow({ radius: 6, color: '#007DFF30', offsetX: 0, offsetY: 3 })
        .onClick(() => {
          // FIX: Call the new, robust creation method.
          this.createAndOpenNewProject();
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 项目列表
      if (this.projectList.length === 0) {
        Column({ space: 16 }) {
          Image($r('app.media.ic_empty_box'))
            .width(80)
            .height(80)
            .opacity(0.6)
          Text('暂无项目')
            .fontSize(18)
            .fontColor('#6B7280')
            .fontWeight(FontWeight.Medium)
          Text('点击右上角的"+"按钮创建您的第一个项目')
            .fontSize(14)
            .fontColor('#9CA3AF')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.projectList, (meta: ProjectMeta) => {
            ListItem() {
              this.ProjectCard(meta)
            }
            .onClick(() => {
              console.log(`[Home] Project card clicked: ${meta.id}`);
              this.onSelectProject(meta.id);
            })
          })
        }
        .layoutWeight(1)
      }
    }
    .padding(24)
    .backgroundColor('#FFFFFF')
    .border({ width: { right: 1 }, color: '#E5E7EB' })
    .layoutWeight(1)
  }

  @Builder
  ProjectCard(meta: ProjectMeta) {
    Row({ space: 16 }) {
      // 项目图标
      Column() {
        Image($r('app.media.ic_project_file'))
          .width(24)
          .height(24)
          .fillColor('#007DFF')
      }
      .width(48)
      .height(48)
      .backgroundColor('#EFF6FF')
      .justifyContent(FlexAlign.Center)
      .borderRadius(10)
      .border({ width: 1, color: '#DBEAFE', radius: 10 })

      // 项目信息
      Column({ space: 6 }) {
        Text(meta.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`修改于: ${new Date(meta.lastModified).toLocaleDateString()}`)
          .fontSize(12)
          .fontColor('#6B7280')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 删除按钮
      Button() {
        Image($r('app.media.ic_delete'))
          .width(16)
          .height(16)
          .fillColor('#EF4444')
      }
      .width(36)
      .height(36)
      .type(ButtonType.Circle)
      .backgroundColor('#FEF2F2')
      .border({ width: 1, color: '#FECACA', radius: 18 })
      .onClick(() => this.deleteProject(meta.id))
      .hitTestBehavior(HitTestMode.Block)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.selectedProjectId === meta.id ? '#EFF6FF' : '#FFFFFF')
    .borderRadius(12)
    .shadow({ 
      radius: 4, 
      color: this.selectedProjectId === meta.id ? '#007DFF20' : '#00000008', 
      offsetX: 0, 
      offsetY: 1 
    })
    .border({ 
      width: this.selectedProjectId === meta.id ? 2 : 0, 
      color: '#007DFF', 
      radius: 12 
    })
    .useEffect(true)
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
