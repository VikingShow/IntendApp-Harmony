// File: entry/src/main/ets/components/TaskEditor.ets
/**
 * 浠诲姟缂栬緫鍣ㄧ粍浠舵ā鍧? * 
 * 鏈粍浠舵槸浠诲姟璇︽儏缂栬緫鐨勬牳蹇冪晫闈紝鎻愪緵浠诲姟灞炴€х紪杈戙€佹鏌ユ竻鍗曠鐞嗐€? * 渚濊禆鍏崇郴鍒涘缓绛夊畬鏁村姛鑳姐€傞噰鐢ㄨ嫻鏋滈鏍艰璁★紝鎻愪緵浼橀泤鐨勭敤鎴蜂綋楠屻€? * 
 * 涓昏鍔熻兘锛? * 1. 浠诲姟灞炴€х紪杈戯細缂栬緫浠诲姟鍚嶇О銆佸紑濮嬫椂闂淬€佺粨鏉熸椂闂寸瓑鍩烘湰淇℃伅
 * 2. 妫€鏌ユ竻鍗曠鐞嗭細娣诲姞銆佺紪杈戙€佸垹闄や换鍔＄殑妫€鏌ユ竻鍗曢」鐩? * 3. 杩涘害璺熻釜锛氶€氳繃妫€鏌ユ竻鍗曞畬鎴愭儏鍐佃窡韪换鍔¤繘搴? * 4. 渚濊禆鍏崇郴锛氬垱寤哄拰绠＄悊浠诲姟闂寸殑渚濊禆鍏崇郴
 * 5. 浠诲姟鎿嶄綔锛氬垹闄や换鍔°€佽繑鍥炲垪琛ㄧ瓑鍩烘湰鎿嶄綔
 * 6. 鏁版嵁楠岃瘉锛氭彁渚涜緭鍏ユ暟鎹殑鏈夋晥鎬ч獙璇佸拰閿欒鎻愮ず
 * 
 * 璁捐鐗圭偣锛? * - 鑻规灉椋庢牸锛氶噰鐢ㄨ嫻鏋滆璁¤瑷€锛屾彁渚涗紭闆呯殑瑙嗚浣撻獙
 * - 鍝嶅簲寮忓竷灞€锛氭牴鎹唴瀹瑰姩鎬佽皟鏁寸晫闈㈠竷灞€
 * - 瀹炴椂楠岃瘉锛氭彁渚涘疄鏃剁殑杈撳叆楠岃瘉鍜岄敊璇彁绀? * - 浜や簰鍙嬪ソ锛氭彁渚涗赴瀵岀殑浜や簰鍙嶉鍜岀姸鎬佹寚绀? * - 妯″潡鍖栬璁★細灏嗕笉鍚屽姛鑳芥ā鍧楀寲涓虹嫭绔嬬殑UI缁勪欢
 * 
 * 鐣岄潰缁撴瀯锛? * - 澶撮儴淇℃伅锛氫换鍔″熀鏈俊鎭拰缂栬緫鐘舵€? * - 灞炴€х紪杈戯細浠诲姟鍚嶇О銆佹椂闂寸瓑灞炴€х紪杈戝尯鍩? * - 妫€鏌ユ竻鍗曪細浠诲姟妫€鏌ユ竻鍗曠殑绠＄悊鍜岀紪杈? * - 鎿嶄綔鎸夐挳锛氫换鍔＄浉鍏崇殑鍚勭鎿嶄綔鎸夐挳
 * - 搴曢儴瀵艰埅锛氳繑鍥炪€佸垹闄ょ瓑瀵艰埅鎿嶄綔
 * 
 * @author EasyFlow寮€鍙戝洟闃? * @version 1.0.0
 * @since 2024-01-01
 */

import { TaskNode, ChecklistItem } from '../model/ProjectData';
import { CommonButton } from './CommonButton';
import { ValidationUtils } from '../utils/ValidationUtils';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { PromptAction } from '@kit.ArkUI';

/**
 * 浠诲姟缂栬緫鍣ㄧ粍浠? * 
 * 瀹炵幇浠诲姟璇︽儏缂栬緫鐨勬牳蹇僓I缁勪欢锛屾彁渚涘畬鏁寸殑浠诲姟绠＄悊鍔熻兘銆? * 閲囩敤鑻规灉椋庢牸璁捐锛岀‘淇濈敤鎴风晫闈㈢殑涓€鑷存€у拰鏄撶敤鎬с€? * 
 * 缁勪欢鐗规€э細
 * - 鍝嶅簲寮忔暟鎹粦瀹氾細浣跨敤@Prop瀹炵幇鏁版嵁鐨勮嚜鍔ㄥ悓姝? * - 瀹炴椂楠岃瘉锛氭彁渚涜緭鍏ユ暟鎹殑瀹炴椂楠岃瘉鍜岄敊璇彁绀? * - 妯″潡鍖栬璁★細灏嗗姛鑳藉垎瑙ｄ负鐙珛鐨刄I妯″潡
 * - 浜や簰鍙嶉锛氭彁渚涗赴瀵岀殑鐢ㄦ埛鎿嶄綔鍙嶉
 * 
 * @author EasyFlow寮€鍙戝洟闃? * @version 1.0.0
 * @since 2024-01-01
 */
@Component
export struct TaskEditor {
  /** 褰撳墠缂栬緫鐨勪换鍔″璞?*/
  @Prop task: TaskNode | null;
  @State newChecklistItemText: string = '';
  @State private localTask: TaskNode | null = null;
  @State private forceUpdateKey: number = 0;
  @State private autoSaveTimer: number | null = null;
  @State private hasUnsavedChanges: boolean = false;
  @State private debounceTimer: number | null = null;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  onUpdateTask: (taskId: string, updates: Partial<TaskNode>) => void = () => {
  };
  onDeleteTask: (id: string) => void = () => {
  };
  onBack: () => void = () => {
  };
  onStartConnecting: () => void = () => {
  };
  onUpdateChecklist: (taskId: string, checklist: ChecklistItem[]) => void = () => {
  };
  onAddChecklistItem: (taskId: string, text: string) => void = () => {
  };
  onDeleteChecklistItem: (taskId: string, itemId: string) => void = () => {
  };
  // 涓哄綋鍓嶄换鍔℃坊鍔犳棩鍘嗘彁閱掔殑鍥炶皟锛堢敱鐖剁粍浠跺疄鐜板叿浣撻€昏緫锛?  onAddReminder: (task: TaskNode) => void = () => {
  };

  aboutToAppear() {
    this.localTask = this.task;
  }

  aboutToDisappear() {
    // 缁勪欢閿€姣佹椂淇濆瓨鏈繚瀛樼殑鏇存敼
    if (this.hasUnsavedChanges && this.localTask) {
      this.saveTaskChanges();
    }
    // 娓呯悊瀹氭椂鍣?    if (this.autoSaveTimer) {
      clearTimeout(this.autoSaveTimer);
    }
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
  }

  aboutToUpdate() {
    // 褰搕ask鍙樺寲鏃讹紝鏇存柊localTask
    if (this.localTask?.id !== this.task?.id) {
      console.log(`[TaskEditor] Task changed, updating localTask`);
      this.localTask = this.task;
    } else if (this.task && this.localTask) {
      // 濡傛灉ID鐩稿悓浣嗗唴瀹瑰彲鑳戒笉鍚岋紝鍚屾鏇存柊鍐呭
      const oldChecklistLength = this.localTask.checklist?.length || 0;
      const newChecklistLength = this.task.checklist?.length || 0;
      
      // 妫€鏌hecklist闀垮害鍙樺寲
      if (oldChecklistLength !== newChecklistLength) {
        console.log(`[TaskEditor] Checklist length updated: ${oldChecklistLength} -> ${newChecklistLength}`);
        this.forceUpdateKey++;
      }
      
      // 妫€鏌hecklist鍐呭鍙樺寲锛堝嬀閫夌姸鎬佺瓑锛?      if (this.localTask.checklist && this.task.checklist && 
          this.localTask.checklist.length === this.task.checklist.length) {
        const hasContentChange = this.localTask.checklist.some((oldItem, index) => {
          const newItem = this.task!.checklist[index];
          return !newItem || oldItem.isCompleted !== newItem.isCompleted || oldItem.text !== newItem.text;
        });
        
        if (hasContentChange) {
          console.log(`[TaskEditor] Checklist content updated`);
          this.forceUpdateKey++;
        }
      }
      
      // 寮哄埗鏇存柊localTask浠ヨЕ鍙戝搷搴斿紡鏇存柊
      this.localTask = this.task;
    }
  }

  private getDuration(): number {
    if (!this.localTask) return 0;
    const diffTime = this.localTask.endDate.getTime() - this.localTask.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  // 灏佽涓€涓粺涓€鐨勬坊鍔犲嚱鏁?  private submitNewChecklistItem() {
    if (this.localTask && this.newChecklistItemText.trim() !== '') {
      // 楠岃瘉娓呭崟椤?      const validation = ValidationUtils.validateChecklistItem(this.newChecklistItemText);
      if (!validation.isValid) {
        this.promptAction.showToast({ message: validation.message });
        return;
      }

      console.log(`[TaskEditor] Adding new checklist item: ${this.newChecklistItemText}`);
      
      // 鍏堟洿鏂發ocalTask浠ョ珛鍗冲弽鏄燯I鍙樺寲
      const newItem: ChecklistItem = {
        id: `item_${Date.now()}`,
        text: this.newChecklistItemText,
        isCompleted: false
      };
      
      this.localTask.checklist = this.localTask.checklist.concat([newItem]);
      this.forceUpdateKey++;
      this.newChecklistItemText = '';
      
      // 鐒跺悗閫氱煡鐖剁粍浠舵洿鏂版暟鎹?      this.onAddChecklistItem(this.localTask.id, newItem.text);
    }
  }

  // 鍒犻櫎瀛愪换鍔?  private deleteChecklistItem(itemId: string) {
    if (this.localTask && this.localTask.checklist) {
      console.log(`[TaskEditor] Deleting checklist item: ${itemId}`);
      
      // 鍏堟洿鏂發ocalTask浠ョ珛鍗冲弽鏄燯I鍙樺寲
      const newChecklist = this.localTask.checklist.filter(item => item.id !== itemId);
      this.localTask.checklist = newChecklist;
      this.forceUpdateKey++;
      
      // 鐒跺悗閫氱煡鐖剁粍浠舵洿鏂版暟鎹?      this.onDeleteChecklistItem(this.localTask.id, itemId);
      
      this.promptAction.showToast({ message: '瀛愪换鍔″凡鍒犻櫎' });
    }
  }

  // 闃叉姈鐨勮嚜鍔ㄤ繚瀛樹换鍔℃洿鏀?  private scheduleAutoSave() {
    this.hasUnsavedChanges = true;
    
    // 娓呴櫎涔嬪墠鐨勯槻鎶栧畾鏃跺櫒
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
    
    // 璁剧疆闃叉姈瀹氭椂鍣紙500ms鍚庤Е鍙戣嚜鍔ㄤ繚瀛橈級
    this.debounceTimer = setTimeout(() => {
      this.performAutoSave();
    }, 500);
  }

  // 鎵ц鑷姩淇濆瓨
  private performAutoSave() {
    // 娓呴櫎涔嬪墠鐨勮嚜鍔ㄤ繚瀛樺畾鏃跺櫒
    if (this.autoSaveTimer) {
      clearTimeout(this.autoSaveTimer);
    }
    
    // 璁剧疆鏂扮殑鑷姩淇濆瓨瀹氭椂鍣紙1绉掑悗淇濆瓨锛?    this.autoSaveTimer = setTimeout(() => {
      this.saveTaskChanges();
    }, 1000);
  }

  // 淇濆瓨浠诲姟鏇存敼
  private saveTaskChanges() {
    if (this.localTask && this.hasUnsavedChanges) {
      console.log(`[TaskEditor] Auto-saving task: ${this.localTask.id}`);
      this.onUpdateTask(this.localTask.id, {
        name: this.localTask.name,
        startDate: this.localTask.startDate,
        endDate: this.localTask.endDate,
        checklist: this.localTask.checklist
      });
      this.hasUnsavedChanges = false;
      
      // 鏄剧ず淇濆瓨鎻愮ず
      this.promptAction.showToast({
        message: '宸茶嚜鍔ㄤ繚瀛?, 
        duration: 1000 
      });
    }
  }

  build() {
    // 浣跨敤localTask鏉ョ‘淇濆搷搴斿紡鏇存柊
    if (this.localTask) {
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 16 }) {
            Row({ space: 12 }) {
              Text('缂栬緫浠诲姟')
                 .fontSize(ThemeConfig.fontSizeXXL)
                 .fontWeight(ThemeConfig.fontWeightMedium)
                 .fontColor(ColorResource.surfaceDeep)
                 .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Column({ space: 8 }) {
              Text('浠诲姟鍚嶇О')
                .fontSize(ThemeConfig.fontSizeS)
                .fontWeight(ThemeConfig.fontWeightMedium)
                .fontColor(ColorResource.surfaceEmphasized)
              TextInput({ text: this.localTask.name || '', placeholder: '璇疯緭鍏ヤ换鍔″悕绉? })
                .backgroundColor(ColorResource.transparent)
                .borderRadius(ThemeConfig.radiusMedium)
                .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
                .fontSize(ThemeConfig.fontSizeL)
                .width('100%')
                .fontColor(ColorResource.surfaceDeep)
                .placeholderColor(ColorResource.surfaceEmphasized)
                .shadow(ThemeConfig.inputShadow)
                .border({ 
                  width: 2, 
                  color: ColorResource.surfaceNeutral, 
                  radius: ThemeConfig.radiusMedium 
                })
                .onFocus(() => {
                  // 鑱氱劍鏃剁殑瑙嗚鍙嶉
                  console.log('[TaskEditor] Task name input focused');
                })
                .onBlur(() => {
                  // 澶辩劍鏃朵繚瀛樻暟鎹?                  if (this.localTask) {
                    this.onUpdateTask(this.localTask.id, { name: this.localTask.name });
                  }
                })
                .enterKeyType(EnterKeyType.Done)
                .onSubmit(() => {
                  // 鎻愪氦鏃朵繚瀛樺苟鑱氱劍鍒颁笅涓€涓緭鍏ユ
                  if (this.localTask) {
                    this.onUpdateTask(this.localTask.id, { name: this.localTask.name });
                  }
                })
                .onChange((value: string) => {
                  if (this.localTask) {
                    // 楠岃瘉浠诲姟鍚嶇О
                    const validation = ValidationUtils.validateProjectName(value);
                    if (!validation.isValid) {
                      this.promptAction.showToast({ message: validation.message });
                      return;
                    }

                    // 鏇存柊鏈湴浠诲姟鍚嶇О
                    this.localTask.name = value;
                    
                    // 瑙﹀彂鑷姩淇濆瓨
                    this.scheduleAutoSave();
                  }
                })
            }

             // 鏃ユ湡閫夋嫨鍖哄煙
             Column({ space: 12 }) {
               // 寮€濮嬫棩鏈?- 鐙崰涓€琛岋紝纭繚鏈夎冻澶熷搴?               Column({ space: 8 }) {
                 Text('寮€濮嬫棩鏈?)
                   .fontSize(13)
                   .fontWeight(FontWeight.Medium)
                   .fontColor(ColorResource.textTertiary)
                 DatePicker({
                   start: new Date('2020-01-01'),
                   end: new Date('2030-12-31'),
                   selected: this.localTask.startDate || new Date()
                 })
                   .backgroundColor(ColorResource.transparent)
                   .borderRadius(12)
                   .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                   .border({ width: 0, radius: 12 })
                   .width('100%')
                   .onDateChange((value: Date) => {
                     if (this.localTask) {
                       const newStartDate = value;
                       const newEndDate = this.localTask.endDate < newStartDate ? newStartDate : this.localTask.endDate;
                       
                       // 鍙紶閫掗渶瑕佹洿鏂扮殑瀛楁
                       this.onUpdateTask(this.localTask.id, { 
                         startDate: newStartDate,
                         endDate: newEndDate
                       });
                     }
                   })
               }

               // 缁撴潫鏃ユ湡 - 鐙崰涓€琛岋紝纭繚鏈夎冻澶熷搴?               Column({ space: 8 }) {
                 Text('缁撴潫鏃ユ湡')
                   .fontSize(13)
                   .fontWeight(FontWeight.Medium)
                   .fontColor(ColorResource.textTertiary)
                 DatePicker({
                   start: new Date('2020-01-01'),
                   end: new Date('2030-12-31'),
                   selected: this.localTask.endDate || new Date()
                 })
                   .backgroundColor(ColorResource.transparent)
                   .borderRadius(12)
                   .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                   .border({ width: 0, radius: 12 })
                   .width('100%')
                   .onDateChange((value: Date) => {
                     if (this.localTask) {
                       const newEndDate = value;
                       const newStartDate = this.localTask.startDate > newEndDate ? newEndDate : this.localTask.startDate;
                       
                       // 鍙紶閫掗渶瑕佹洿鏂扮殑瀛楁
                       this.onUpdateTask(this.localTask.id, { 
                         startDate: newStartDate,
                         endDate: newEndDate
                       });
                     }
                   })
               }
             }

            // 宸ユ湡鏄剧ず涓庢棩鍘嗘彁閱?            Row({ space: 8 }) {
              Text(`宸ユ湡: ${this.getDuration()} 澶ー)
                .fontSize(13)
                .fontColor(ColorResource.textTertiary)
                .fontWeight(FontWeight.Medium)
              if (this.localTask) {
                CommonButton({
                  text: '娣诲姞鏃ュ巻鎻愰啋',
                  type: 'secondary',
                  buttonSize: 'small',
                  onButtonClick: () => {
                    this.onAddReminder(this.localTask!);
                  }
                })
                  .width(140)
              }
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .padding(ThemeConfig.spacingXL)
          .backgroundColor(ColorResource.transparent)
          .borderRadius(ThemeConfig.radiusXLarge)
          .shadow(ThemeConfig.cardShadow)
          .border({ width: 0, color: 'transparent', radius: ThemeConfig.radiusXLarge })

          // --- 浠诲姟娓呭崟鍗＄墖  ---
          Column({ space: 16 }) {
            // 娓呭崟鏍囬
            Row({ space: 8 }) {
              Text('浠诲姟娓呭崟')
                 .fontSize(18)
                 .fontWeight(FontWeight.Medium)
                 .fontColor(ColorResource.textPrimary)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 娣诲姞鏂板瓙浠诲姟
            Row({ space: 12 }) {
              TextInput({ 
                placeholder: '娣诲姞涓€涓瓙浠诲姟...', 
                text: this.newChecklistItemText 
              })
                .layoutWeight(1)
                .backgroundColor(ColorResource.transparent)
                .borderRadius(ThemeConfig.radiusMedium)
                .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
                .fontSize(ThemeConfig.fontSizeL)
                .fontColor(ColorResource.surfaceDeep)
                .placeholderColor(ColorResource.surfaceEmphasized)
                .shadow(ThemeConfig.inputShadow)
                .border({ 
                  width: 2, 
                  color: ColorResource.surfaceNeutral, 
                  radius: ThemeConfig.radiusMedium 
                })
                .enterKeyType(EnterKeyType.Go)
                .onSubmit(() => {
                  this.submitNewChecklistItem();
                })
                .onFocus(() => {
                  console.log('[TaskEditor] Checklist input focused');
                })
                .onChange((value: string) => {
                  this.newChecklistItemText = value;
                })
                .onSubmit(() => {
                  this.submitNewChecklistItem();
                })
              Button() {
                Text('+')
                  .fontSize(ThemeConfig.fontSizeXL)
                  .fontColor(Color.White)
                  .fontWeight(ThemeConfig.fontWeightBold)
              }
              .width(52)
              .height(52)
              .backgroundColor(ColorResource.primaryColor)
              .borderRadius(ThemeConfig.radiusMedium)
              .shadow(ThemeConfig.shadowMedium)
              .border({ width: 2, color: ColorResource.primaryUltraLight, radius: ThemeConfig.radiusMedium })
              .onClick(() => {
                this.submitNewChecklistItem();
              })
            }

            // 瀛愪换鍔″垪琛?
            if (!this.localTask || !this.localTask.checklist || this.localTask.checklist.length === 0) {
              Column({ space: 12 }) {
                Image($r('app.media.ic_empty_box'))
                  .width(32)
                  .height(32)
                  .opacity(0.4)
                Text('鏆傛棤瀛愪换鍔?)
                  .fontSize(14)
                  .fontColor(ColorResource.textTertiary)
              }
              .width('100%')
              .padding(24)
              .justifyContent(FlexAlign.Center)
              .key(`empty-checklist-${this.forceUpdateKey}`)
            } else if (this.localTask && this.localTask.checklist) {
              Column({ space: 8 }) {
                ForEach(this.localTask.checklist, (item: ChecklistItem) => {
                  Row({ space: 12 }) {
                    Checkbox({ name: item.id, group: 'checklist' })
                      .select(item.isCompleted)
                      .onChange((value: boolean) => {
                        if (this.localTask && this.localTask.checklist) {
                          console.log(`[TaskEditor] Checkbox changed for item ${item.id}: ${value}`);
                          
                          const newChecklist = this.localTask.checklist.map(i => {
                            if (i.id === item.id) {
                              return {
                                id: i.id,
                                text: i.text,
                                isCompleted: value
                              };
                            }
                            return i;
                          });
                          
                          // 鍏堟洿鏂發ocalTask浠ョ珛鍗冲弽鏄燯I鍙樺寲
                          this.localTask.checklist = newChecklist;
                          this.forceUpdateKey++;
                          
                          // 鐒跺悗閫氱煡鐖剁粍浠舵洿鏂版暟鎹?                          this.onUpdateChecklist(this.localTask.id, newChecklist);
                        }
                      })
                    Text(item.text)
                      .fontSize(15)
                      .fontColor(item.isCompleted ? ColorResource.textTertiary : ColorResource.textPrimary)
                      .decoration({ type: item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
                      .layoutWeight(1)
                      .textAlign(TextAlign.Start)
                    
                    // 鍒犻櫎鎸夐挳 - 鐜颁唬鍖栬璁★紝澧炲己浜や簰鍙嶉
                    Button() {
                      Text('脳')
                        .fontSize(16)
                        .fontColor(ColorResource.errorColor)
                        .fontWeight(ThemeConfig.fontWeightBold)
                    }
                    .width(40)
                    .height(40)
                    .type(ButtonType.Circle)
                    .backgroundColor(ColorResource.errorLight)
                    .border({ width: 2, color: ColorResource.errorColor, radius: 20 })
                    .shadow(ThemeConfig.shadowMedium)
                    .onClick(() => {
                      this.deleteChecklistItem(item.id);
                    })
                  }
                  .width('100%')
                  .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
                  .backgroundColor(item.isCompleted ? ColorResource.surfaceLight : ColorResource.transparent)
                  .borderRadius(ThemeConfig.radiusMedium)
                  .shadow(item.isCompleted ? ThemeConfig.shadowSmall : ThemeConfig.shadowSmall)
                  .border({ 
                    width: 0, 
                    color: 'transparent', 
                    radius: ThemeConfig.radiusMedium 
                  })
                  .margin({ bottom: ThemeConfig.spacingXS })
                }, (item: ChecklistItem) => item.id)
              }
              .key(`checklist-${this.localTask?.id}-${this.forceUpdateKey}`)
            }
          }
          .padding(ThemeConfig.spacingXL)
          .backgroundColor(ColorResource.transparent)
          .borderRadius(ThemeConfig.radiusXLarge)
          .shadow(ThemeConfig.cardShadow)
          .border({ width: 0, color: 'transparent', radius: ThemeConfig.radiusXLarge })

          // --- 搴曢儴鎿嶄綔鎸夐挳 - 鑻规灉椋庢牸锛氭洿浼橀泤鐨勬寜閽璁?---
          Column({ space: 12 }) {
            CommonButton({
              text: '鍒涘缓渚濊禆浠庢浠诲姟寮€濮?,
              type: 'primary',
              onButtonClick: () => {
                this.onStartConnecting()
              }
            })


            CommonButton({
              text: '杩斿洖鍒楄〃',
              icon: '鈫?,
              type: 'secondary',
              onButtonClick: () => {
                this.onBack()
              }
            })
          }
          .padding(20)
        }
        .padding(20) // 鑻规灉椋庢牸锛氭洿澶х殑澶栬竟璺?      }
    }
  }
}
