// File: entry/src/main/ets/pages/Home.ets
import router from '@ohos.router';
import { StorageService, ProjectMeta } from '../services/StorageService';
import { LoadingService } from '../services/LoadingService';
import { ExportService } from '../services/ExportService';
import { TemplateService } from '../services/TemplateService';
import { PermissionService } from '../services/PermissionService';
import { DataMigrationService } from '../services/DataMigrationService';
import common from '@ohos.app.ability.common';
import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { DashboardView } from '../components/DashboardView';
import { WelcomeView } from '../components/WelcomeView';
import { LoadingView } from '../components/LoadingView';
import { ExportDialog } from '../components/ExportDialog';
import { TemplateDialog } from '../components/TemplateDialog';
import { StorageStatsView } from '../components/StorageStatsView';
import { StorageStatsDialog } from '../components/StorageStatsDialog';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct HomePage {
  @State projectList: ProjectMeta[] = [];
  @State selectedProjectDetail: Project | null = null;
  @State selectedProjectId: string | null = null;
  @State componentKey: number = 0;
  @State isLoading: boolean = false;
  @State showExportDialog: boolean = false;
  @State showTemplateDialog: boolean = false;
  @State showStorageStatsDialog: boolean = false;
  @State emptyProject: Project | null = null;
  @State emptyTask: TaskNode | null = null;

  private storageService: StorageService | null = null;
  private loadingService: LoadingService = LoadingService.getInstance();
  private exportService: ExportService = ExportService.getInstance();
  private templateService: TemplateService = TemplateService.getInstance();
  private permissionService: PermissionService | null = null;
  private migrationService: DataMigrationService | null = null;

  async aboutToAppear() {
    const context = getContext(this);
    
    // 初始化权限服务
    this.permissionService = PermissionService.getInstance(context as common.UIAbilityContext);
    
    // 申请文件系统权限
    console.log('[Home] 开始申请文件系统权限...');
    const hasPermission = await this.permissionService.requestFileSystemPermission();
    console.log(`[Home] 文件系统权限申请结果: ${hasPermission}`);
    
    if (!hasPermission) {
      console.warn('[Home] 文件系统权限申请失败，但继续初始化存储服务');
      promptAction.showToast({ 
        message: '文件系统权限申请失败，部分功能可能受限' 
      });
      // 不直接返回，继续初始化，让用户尝试使用
    }
    
    // 初始化存储服务
    this.storageService = StorageService.getInstance(context.filesDir);
    this.exportService.setStorageService(this.storageService);
    
    // 测试文件系统操作
    console.log('[Home] 开始测试文件系统操作...');
    const fileSystemTestResult = await this.storageService.testFileSystem();
    console.log(`[Home] 文件系统测试结果: ${fileSystemTestResult}`);
    
    if (!fileSystemTestResult) {
      promptAction.showToast({ 
        message: '文件系统测试失败，请检查权限设置' 
      });
    }
    
    // 初始化数据迁移服务
    this.migrationService = DataMigrationService.getInstance(context.filesDir);
    
    // 检查并执行数据迁移
    await this.checkAndMigrateData();
    
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

  // 检查并执行数据迁移
  async checkAndMigrateData() {
    if (!this.migrationService) {
      console.error('[Home] 数据迁移服务未初始化');
      return;
    }
    
    try {
      console.log('[Home] 开始检查数据迁移需求...');
      const needsMigration = await this.migrationService.needsMigration();
      console.log(`[Home] 数据迁移需求检查结果: ${needsMigration}`);
      
      if (needsMigration) {
        console.log('[Home] 检测到需要数据迁移');
        promptAction.showToast({ 
          message: '正在迁移数据到新的存储系统...',
          duration: 2000
        });
        
        console.log('[Home] 开始执行数据迁移...');
        const result = await this.migrationService.migrateData();
        console.log(`[Home] 数据迁移完成，结果: ${JSON.stringify(result)}`);
        
        if (result.success) {
          console.log(`[Home] 数据迁移成功，迁移了 ${result.migratedCount} 个项目`);
          promptAction.showToast({ 
            message: `数据迁移成功，已迁移 ${result.migratedCount} 个项目`,
            duration: 3000
          });
        } else {
          console.error('[Home] 数据迁移失败:', result.errors);
          console.error(`[Home] 迁移错误详情: ${JSON.stringify(result.errors)}`);
          promptAction.showToast({ 
            message: `数据迁移部分失败，${result.errors.length} 个项目迁移失败`,
            duration: 3000
          });
        }
      } else {
        console.log('[Home] 无需数据迁移');
      }
    } catch (error) {
      console.error('[Home] 数据迁移检查失败:', error);
      console.error(`[Home] 迁移错误详情: ${JSON.stringify(error)}`);
      promptAction.showToast({ 
        message: '数据迁移检查失败，请查看日志',
        duration: 3000
      });
    }
  }

  async loadProjects() {
    if (!this.storageService) {
      console.error('[Home] 存储服务未初始化');
      return;
    }
    
    try {
      console.log('[Home] 开始加载项目列表...');
      this.loadingService.setLoading('project_loading', true);
      
      const list = await this.storageService.getProjectList();
      console.log(`[Home] 加载到 ${list.length} 个项目`);
      
      this.projectList = list.sort((a, b) => b.lastModified - a.lastModified);
      console.log(`[Home] 项目列表排序完成，共 ${this.projectList.length} 个项目`);
      
      if (this.selectedProjectId) {
        console.log(`[Home] 恢复选中的项目: ${this.selectedProjectId}`);
        await this.onSelectProject(this.selectedProjectId);
      }
      
      console.log('[Home] 项目列表加载完成');
    } catch (error) {
      console.error('[Home] 加载项目列表失败:', error);
      console.error(`[Home] 错误详情: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: '加载项目列表失败，请查看日志' });
    } finally {
      this.loadingService.setLoading('project_loading', false);
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

  // 从模板创建项目
  async createProjectFromTemplate(templateId: string, projectName: string) {
    if (!this.storageService) {
      this.handleError(new Error("存储服务未初始化"), "createProjectFromTemplate");
      return;
    }

    try {
      console.log(`[Home] Creating project from template: ${templateId}`);

      // 从模板创建项目
      const newProject = this.templateService.createProjectFromTemplate(templateId, projectName);
      
      // 保存项目
      await this.storageService.saveProject(newProject);
      console.log(`[Home] Project created from template: ${newProject.id}`);
      promptAction.showToast({ message: `项目 "${newProject.name}" 已创建` });

      // 导航到编辑器页面
      router.pushUrl({
        url: 'pages/Index',
        params: { projectId: newProject.id }
      });
    } catch (error) {
      this.handleError(error as Error, "createProjectFromTemplate");
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

  // 显示导出对话框
  openExportDialog() {
    this.showExportDialog = true;
  }

  // 关闭导出对话框
  closeExportDialog() {
    this.showExportDialog = false;
  }

  // 显示模板对话框
  openTemplateDialog() {
    this.showTemplateDialog = true;
  }

  // 关闭模板对话框
  closeTemplateDialog() {
    this.showTemplateDialog = false;
  }

  // 显示存储统计对话框
  openStorageStatsDialog() {
    this.showStorageStatsDialog = true;
  }

  // 关闭存储统计对话框
  closeStorageStatsDialog() {
    this.showStorageStatsDialog = false;
  }


  build() {
    Stack() {
      // 主界面
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
          } else {
            WelcomeView()
          }
        }
        .layoutWeight(2)
        .backgroundColor('#F8FAFC')
      }
      .width('100%')
      .height('100%')

      // 导出对话框
      if (this.showExportDialog) {
        ExportDialog({
          visible: true,
          projectId: this.selectedProjectId || undefined,
          projectName: this.selectedProjectDetail?.name,
          onClose: () => {
            this.closeExportDialog();
          }
        })
      }

      // 模板对话框
      if (this.showTemplateDialog) {
        TemplateDialog({
          visible: true,
          onClose: () => {
            this.closeTemplateDialog();
          },
          onTemplateSelected: (templateId: string, projectName: string) => {
            this.createProjectFromTemplate(templateId, projectName);
          }
        })
      }

      // 存储统计对话框
      if (this.showStorageStatsDialog) {
        StorageStatsDialog({
          visible: true,
          onClose: () => {
            this.closeStorageStatsDialog();
          }
        })
      }
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
        

        // 新建项目按钮
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
          // 显示模板选择对话框
          this.openTemplateDialog();
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 操作按钮区域
      if (this.selectedProjectDetail) {
        Column({ space: 12 }) {
          // 导出按钮
          Button() {
            Row({ space: 8 }) {
              Text('📤')
                .fontSize(16)
                .fontColor(Color.White)
              Text('导出数据')
                .fontSize(14)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
            }
          }
          .width('100%')
          .height(40)
          .backgroundColor('#10B981')
          .borderRadius(8)
          .shadow({ radius: 4, color: '#10B98130', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            this.openExportDialog();
          })
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .backgroundColor('#F9FAFB')
        .borderRadius(12)
        .border({ width: 1, color: '#E5E7EB', radius: 12 })
      }

      // 存储统计按钮
      Button() {
        Row({ space: 8 }) {
          Text('📊')
            .fontSize(16)
            .fontColor(Color.White)
          Text('存储统计')
            .fontSize(14)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .height(40)
      .backgroundColor('#007DFF')
      .borderRadius(8)
      .onClick(() => {
        this.openStorageStatsDialog();
      })

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
  EmptyState() {
    Column({ space: 16 }) {
      Image($r('app.media.ic_empty_box')).width(100).height(100).opacity(0.5)
      Text('还没有任何项目')
        .fontSize(18)
        .fontColor(Color.Gray)
      Text('点击上方的"+"按钮来创建一个新项目吧！')
        .fontSize(14)
        .fontColor(Color.Gray)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }
}
