// File: entry/src/main/ets/services/CalendarService.ets
/**
 * 日历日程服务模块
 *
 * 使用 HarmonyOS Calendar Kit 提供的 calendarManager 能力，
 * 在系统日历中为任务创建对应的日程（带提醒）。
 */

import { TaskNode } from '../model/ProjectData';
import { calendarManager } from '@kit.CalendarKit';
import { calendarMgr } from '../entryability/EntryAbility';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 日历服务
 */
export class CalendarService {
  private static instance: CalendarService;
  private calendar: calendarManager.Calendar | null = null;
  private calendarInitialized: boolean = false;

  /**
   * 获取单例实例
   */
  public static getInstance(): CalendarService {
    if (!CalendarService.instance) {
      CalendarService.instance = new CalendarService();
    }
    return CalendarService.instance;
  }

  // 私有构造函数，确保单例
  private constructor() {}

  /**
   * 确保日历账户已创建并返回对应 Calendar 对象
   */
  private async ensureCalendar(): Promise<calendarManager.Calendar | null> {
    if (this.calendarInitialized && this.calendar) {
      return this.calendar;
    }

    if (!calendarMgr) {
      console.error('[CalendarService] calendarMgr not ready.');
      return null;
    }

    // 指定日历账户信息
    const calendarAccount: calendarManager.CalendarAccount = {
      name: 'EasyFlowCalendar',
      type: calendarManager.CalendarType.LOCAL,
      displayName: 'EasyFlow'
    };

    // 日历配置信息：开启提醒并设置颜色
    const config: calendarManager.CalendarConfig = {
      enableReminder: true,
      color: '#4A90E2'
    };

    try {
      const calendar = await calendarMgr.createCalendar(calendarAccount);
      console.info('[CalendarService] Succeeded in creating calendar:', JSON.stringify(calendar));

      await calendar.setConfig(config);
      console.info('[CalendarService] Succeeded in setting calendar config');

      this.calendar = calendar;
      this.calendarInitialized = true;
      return this.calendar;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[CalendarService] Failed to create calendar. Code: ${err.code}, message: ${err.message}`);
      this.calendar = null;
      this.calendarInitialized = false;
      return null;
    }
  }

  /**
   * 为指定任务创建系统日历日程（带提醒）
   *
   * @param task 任务对象（至少包含名称和开始/结束时间）
   * @returns 日程 ID，失败时返回 null
   */
  public async addTaskReminder(task: TaskNode): Promise<number | null> {
    try {
      const calendar = await this.ensureCalendar();
      if (!calendar) {
        console.error('[CalendarService] Calendar not available.');
        return null;
      }

      const startTime = task.startDate.getTime();
      const endTime = task.endDate.getTime();

      const event: calendarManager.Event = {
        // 日程标题
        title: task.name,
        // 日程类型
        type: calendarManager.EventType.NORMAL,
        // 日程开始/结束时间
        startTime: startTime,
        endTime: endTime,
        // 距离开始时间提前 10 分钟提醒
        reminderTime: [10]
      };

      const eventId: number = await calendar.addEvent(event);
      console.info(`[CalendarService] Succeeded in adding event, id = ${eventId}`);
      return eventId;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[CalendarService] Failed to add event. Code: ${err.code}, message: ${err.message}`);
      return null;
    }
  }
}
