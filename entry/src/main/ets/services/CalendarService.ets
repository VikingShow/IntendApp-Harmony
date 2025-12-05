// File: entry/src/main/ets/services/CalendarService.ets
/**
 * 日历提醒服务模块
 *
 * 使用 HarmonyOS 提供的 reminderAgentManager 能力，在系统提醒中心创建任务提醒。
 * 设计目标：
 * - 封装与系统提醒的交互逻辑，对上层只暴露简单的 API
 * - 默认使用任务的开始日期作为提醒时间，如无则回退为当前时间 + 5 分钟
 * - 只返回结果，由调用方决定如何提示用户
 *
 * 注意事项：
 * - 需要在模块配置中声明权限：ohos.permission.PUBLISH_AGENT_REMINDER
 */

import { TaskNode } from '../model/ProjectData';
import reminderAgentManager from '@ohos.reminderAgentManager';

interface CalendarReminderDateTime {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

interface CalendarReminderRequest {
  reminderType: reminderAgentManager.ReminderType;
  title: string;
  content: string;
  dateTime: CalendarReminderDateTime;
}

/**
 * 日历提醒服务
 */
export class CalendarService {
  private static instance: CalendarService;

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
   * 为指定任务创建日历系统提醒
   *
   * @param task 任务对象（至少包含名称和开始/结束时间）
   * @returns 提醒 ID，失败时返回 null
   */
  public async addTaskReminder(task: TaskNode): Promise<number | null> {
    try {
      const now: Date = new Date();

      // 优先使用任务开始时间；如已过期，则使用结束时间；都不合适则使用当前时间 + 5 分钟
      let fireTime: Date = task.startDate;
      if (fireTime.getTime() <= now.getTime() && task.endDate.getTime() > now.getTime()) {
        fireTime = task.endDate;
      }
      if (fireTime.getTime() <= now.getTime()) {
        fireTime = new Date(now.getTime() + 5 * 60 * 1000);
      }

      const dateTime: CalendarReminderDateTime = {
        year: fireTime.getFullYear(),
        // 月份从 1 开始
        month: fireTime.getMonth() + 1,
        day: fireTime.getDate(),
        hour: fireTime.getHours(),
        minute: fireTime.getMinutes(),
        second: fireTime.getSeconds()
      };

      const reminderReq: CalendarReminderRequest = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        title: task.name,
        content: '来自 EasyFlow 的任务提醒',
        dateTime: dateTime
      };

      console.log('[CalendarService] Publishing calendar reminder:', JSON.stringify(reminderReq));

      const reminderId: number = await reminderAgentManager.publishReminder(
        reminderReq as reminderAgentManager.ReminderRequestCalendar
      );

      console.log('[CalendarService] Reminder published, id =', reminderId);
      return reminderId;
    } catch (error) {
      console.error('[CalendarService] Failed to publish reminder:', error);
      return null;
    }
  }
}

