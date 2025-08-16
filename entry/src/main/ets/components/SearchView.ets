// File: entry/src/main/ets/components/SearchView.ets

import { SearchService, SearchResult, SearchOptions } from '../services/SearchService';
import { CommonButton } from './CommonButton';
import { ThemeConfig } from '../utils/ThemeConfig';
import { ProjectMeta } from '../services/StorageService';
import { TaskNode } from '../model/ProjectData';
import { LoadingView } from './LoadingView';

@Component
export struct SearchView {
  @State searchKeyword: string = '';
  @State searchResults: SearchResult[] = [];
  @State isSearching: boolean = false;
  @State showFilters: boolean = false;
  @State includeCompleted: boolean = true;
  @State includeIncomplete: boolean = true;
  @State popularKeywords: string[] = [];
  @State searchSuggestions: string[] = [];

  onProjectSelect: (projectId: string) => void = () => {};
  onClose: () => void = () => {};

  private searchService: SearchService = SearchService.getInstance();

  async aboutToAppear() {
    await this.loadPopularKeywords();
  }

  async loadPopularKeywords() {
    try {
      this.popularKeywords = await this.searchService.getPopularKeywords();
    } catch (error) {
      console.error('加载热门关键词失败:', error);
    }
  }

  async performSearch() {
    if (!this.searchKeyword.trim()) {
      this.searchResults = [];
      return;
    }

    this.isSearching = true;
    try {
      const options: SearchOptions = {
        keyword: this.searchKeyword,
        includeCompleted: this.includeCompleted,
        includeIncomplete: this.includeIncomplete
      };

      this.searchResults = await this.searchService.searchProjects(options);
    } catch (error) {
      console.error('搜索失败:', error);
    } finally {
      this.isSearching = false;
    }
  }

  async getSuggestions(keyword: string) {
    if (keyword.length < 1) {
      this.searchSuggestions = [];
      return;
    }

    try {
      this.searchSuggestions = await this.searchService.getSearchSuggestions(keyword);
    } catch (error) {
      console.error('获取搜索建议失败:', error);
    }
  }

  build() {
    Column() {
      // 搜索头部
      this.SearchHeader()

      // 搜索过滤器
      if (this.showFilters) {
        this.SearchFilters()
      }

      // 搜索建议
      if (this.searchSuggestions.length > 0 && this.searchKeyword) {
        this.SearchSuggestions()
      }

      // 热门关键词
      if (this.popularKeywords.length > 0 && !this.searchKeyword) {
        this.PopularKeywords()
      }

      // 搜索结果
      if (this.searchResults.length > 0) {
        this.SearchResults()
      } else if (this.searchKeyword && !this.isSearching) {
        this.EmptyResults()
      }

      // 加载状态
      if (this.isSearching) {
        this.LoadingState()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeConfig.white)
  }

  @Builder
  SearchHeader() {
    Row({ space: ThemeConfig.spacingM }) {
      // 返回按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_back'))
          .width(20)
          .height(20)
          .fillColor(ThemeConfig.gray600)
      }
      .width(40)
      .height(40)
      .backgroundColor(ThemeConfig.gray100)
      .onClick(() => {
        this.onClose();
      })

      // 搜索输入框
      TextInput({ 
        placeholder: '搜索项目、任务或检查清单...',
        text: this.searchKeyword 
      })
        .backgroundColor(ThemeConfig.gray50)
        .borderRadius(ThemeConfig.radiusMedium)
        .padding(ThemeConfig.spacingM)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.searchKeyword = value;
          this.getSuggestions(value);
        })
        .onSubmit(() => {
          this.performSearch();
        })

      // 过滤器按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_select'))
          .width(20)
          .height(20)
          .fillColor(this.showFilters ? ThemeConfig.primaryColor : ThemeConfig.gray600)
      }
      .width(40)
      .height(40)
      .backgroundColor(this.showFilters ? ThemeConfig.primaryLight : ThemeConfig.gray100)
      .onClick(() => {
        this.showFilters = !this.showFilters;
      })

      // 搜索按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_calculate'))
          .width(20)
          .height(20)
          .fillColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor(ThemeConfig.primaryColor)
      .onClick(() => {
        this.performSearch();
      })
    }
    .width('100%')
    .padding(ThemeConfig.spacingL)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SearchFilters() {
    Column({ space: ThemeConfig.spacingM }) {
      Text('搜索过滤器')
        .fontSize(ThemeConfig.fontSizeM)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeConfig.gray800)

      Row({ space: ThemeConfig.spacingM }) {
        Toggle({ type: ToggleType.Checkbox, isOn: this.includeCompleted })
          .onChange((isOn: boolean) => {
            this.includeCompleted = isOn;
          })
        Text('包含已完成')
          .fontSize(ThemeConfig.fontSizeS)
          .fontColor(ThemeConfig.gray700)
      }
      .alignItems(VerticalAlign.Center)

      Row({ space: ThemeConfig.spacingM }) {
        Toggle({ type: ToggleType.Checkbox, isOn: this.includeIncomplete })
          .onChange((isOn: boolean) => {
            this.includeIncomplete = isOn;
          })
        Text('包含未完成')
          .fontSize(ThemeConfig.fontSizeS)
          .fontColor(ThemeConfig.gray700)
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(ThemeConfig.spacingL)
    .backgroundColor(ThemeConfig.gray50)
    .borderRadius(ThemeConfig.radiusMedium)
    .margin({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL })
  }

  @Builder
  SearchSuggestions() {
    Column({ space: ThemeConfig.spacingS }) {
      Text('搜索建议')
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ThemeConfig.gray600)
        .margin({ left: ThemeConfig.spacingL })

      ForEach(this.searchSuggestions, (suggestion: string) => {
        Row() {
          Text(suggestion)
            .fontSize(ThemeConfig.fontSizeM)
            .fontColor(ThemeConfig.gray800)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(ThemeConfig.spacingM)
        .backgroundColor(ThemeConfig.white)
        .onClick(() => {
          this.searchKeyword = suggestion;
          this.searchSuggestions = [];
          this.performSearch();
        })
      })
    }
    .margin({ top: ThemeConfig.spacingS })
  }

  @Builder
  PopularKeywords() {
    Column({ space: ThemeConfig.spacingM }) {
      Text('热门搜索')
        .fontSize(ThemeConfig.fontSizeM)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeConfig.gray800)
        .margin({ left: ThemeConfig.spacingL })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.popularKeywords, (keyword: string) => {
          Button() {
            Text(keyword)
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ThemeConfig.primaryColor)
          }
          .height(28)
          .backgroundColor(ThemeConfig.primaryLight)
          .borderRadius(ThemeConfig.radiusSmall)
          .margin({ right: ThemeConfig.spacingS, bottom: ThemeConfig.spacingS })
          .onClick(() => {
            this.searchKeyword = keyword;
            this.performSearch();
          })
        })
      }
      .padding(ThemeConfig.spacingL)
    }
  }

  @Builder
  SearchResults() {
    List({ space: ThemeConfig.spacingM }) {
      ForEach(this.searchResults, (result: SearchResult) => {
        ListItem() {
          this.SearchResultCard(result)
        }
      })
    }
    .padding(ThemeConfig.spacingL)
  }

  @Builder
  SearchResultCard(result: SearchResult) {
    Column({ space: ThemeConfig.spacingS }) {
      // 项目信息
      Row({ space: ThemeConfig.spacingM }) {
        Text('📁')
          .fontSize(ThemeConfig.fontSizeL)
          .fontColor(ThemeConfig.primaryColor)
        
        Column({ space: ThemeConfig.spacingXS }) {
          Text(result.project.name)
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeConfig.gray800)
          
          Text(`相关性: ${result.relevanceScore}`)
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ThemeConfig.gray500)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button() {
          Text('查看')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(Color.White)
        }
        .height(28)
        .layoutWeight(0.1)
        .backgroundColor(ThemeConfig.primaryColor)
        .borderRadius(ThemeConfig.radiusSmall)
        .onClick(() => {
          this.onProjectSelect(result.project.id);
        })
      }

      // 匹配的任务
      if (result.matchedTasks.length > 0) {
        Column({ space: ThemeConfig.spacingXS }) {
          Text(`匹配的任务 (${result.matchedTasks.length})`)
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ThemeConfig.gray600)
            .margin({ top: ThemeConfig.spacingS })

          ForEach(result.matchedTasks, (task: TaskNode) => {
            Row({ space: ThemeConfig.spacingS }) {
              Text('•')
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ThemeConfig.gray500)
              
              Text(task.name)
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ThemeConfig.gray700)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              
              Text(task.checklist.every(item => item.isCompleted) ? '✅已完成' : '⏳未完成')
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ThemeConfig.gray500)
            }
            .width('100%')
            .padding({ left: ThemeConfig.spacingM })
          })
        }
      }
    }
    .width('100%')
    .padding(ThemeConfig.spacingM)
    .backgroundColor(ThemeConfig.white)
    .borderRadius(ThemeConfig.radiusMedium)
    .border({ width: 1, color: ThemeConfig.gray200, radius: ThemeConfig.radiusMedium })
  }

  @Builder
  EmptyResults() {
    Column({ space: ThemeConfig.spacingM }) {
      Image($r('app.media.ic_empty_box'))
        .width(80)
        .height(80)
        .opacity(0.6)
      
      Text('未找到相关结果')
        .fontSize(ThemeConfig.fontSizeL)
        .fontColor(ThemeConfig.gray600)
        .fontWeight(FontWeight.Medium)
      
      Text('尝试使用不同的关键词或调整搜索条件')
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ThemeConfig.gray500)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  LoadingState() {
    Column({ space: ThemeConfig.spacingM }) {
      LoadingView({ message: '搜索中...' })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
} 