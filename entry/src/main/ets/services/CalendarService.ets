// File: entry/src/main/ets/services/CalendarService.ets

import { TaskNode } from '../model/ProjectData';
import { calendarManager } from '@kit.CalendarKit';
import { calendarMgr } from '../entryability/EntryAbility';
import { BusinessError } from '@kit.BasicServicesKit';

export enum CalendarErrorType {
  NONE = 'NONE',
  MANAGER_NOT_READY = 'MANAGER_NOT_READY',
  CALENDAR_CREATE_FAILED = 'CALENDAR_CREATE_FAILED',
  NO_AVAILABLE_CALENDAR = 'NO_AVAILABLE_CALENDAR',
  ADD_EVENT_FAILED = 'ADD_EVENT_FAILED'
}

// 扩展 CalendarManager，补充可能存在的获取日历列表方法
interface CalendarManagerWithList extends calendarManager.CalendarManager {
  getCalendars?(): Promise<Array<calendarManager.Calendar>>;
}

export class CalendarService {
  private static instance: CalendarService;
  private calendar: calendarManager.Calendar | null = null;
  private calendarInitialized: boolean = false;
  private lastErrorType: CalendarErrorType = CalendarErrorType.NONE;

  public static getInstance(): CalendarService {
    if (!CalendarService.instance) {
      CalendarService.instance = new CalendarService();
    }
    return CalendarService.instance;
  }

  private constructor() {}

  public getLastErrorType(): CalendarErrorType {
    return this.lastErrorType;
  }

  private resetError() {
    this.lastErrorType = CalendarErrorType.NONE;
  }

  private async ensureCalendar(): Promise<calendarManager.Calendar | null> {
    if (this.calendarInitialized && this.calendar) {
      return this.calendar;
    }

    if (!calendarMgr) {
      console.error('[CalendarService] calendarMgr not ready.');
      this.lastErrorType = CalendarErrorType.MANAGER_NOT_READY;
      return null;
    }

    const calendarAccount: calendarManager.CalendarAccount = {
      name: 'EasyFlowCalendar',
      type: calendarManager.CalendarType.LOCAL,
      displayName: 'EasyFlow'
    };

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
      this.resetError();
      return this.calendar;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[CalendarService] Failed to create calendar. Code: ${err.code}, message: ${err.message}`);
      this.calendar = null;
      this.calendarInitialized = false;
      this.lastErrorType = CalendarErrorType.CALENDAR_CREATE_FAILED;
    }

    try {
      const manager: CalendarManagerWithList = calendarMgr as CalendarManagerWithList;
      let calendars: Array<calendarManager.Calendar> | null = null;

      if (manager.getCalendars) {
        calendars = await manager.getCalendars();
      } else if (manager.getAllCalendars) {
        calendars = await manager.getAllCalendars();
      } else {
        calendars = [];
      }

      if (calendars && calendars.length > 0) {
        const fallbackCalendar = calendars[0];
        console.info('[CalendarService] Fallback to existing calendar');
        this.calendar = fallbackCalendar;
        this.calendarInitialized = true;
        this.resetError();
        return this.calendar;
      } else {
        console.error('[CalendarService] No existing calendars available.');
        this.calendar = null;
        this.calendarInitialized = false;
        this.lastErrorType = CalendarErrorType.NO_AVAILABLE_CALENDAR;
        return null;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[CalendarService] Failed to obtain existing calendars. Code: ${err.code}, message: ${err.message}`);
      this.calendar = null;
      this.calendarInitialized = false;
      // 保持之前设置的错误类型（CALENDAR_CREATE_FAILED 或 NO_AVAILABLE_CALENDAR）
      return null;
    }
  }

  public async addTaskReminder(task: TaskNode): Promise<number | null> {
    try {
      this.resetError();
      const calendar = await this.ensureCalendar();
      if (!calendar) {
        console.error('[CalendarService] Calendar not available.');
        return null;
      }

      const startTime = task.startDate.getTime();
      const endTime = task.endDate.getTime();

      const event: calendarManager.Event = {
        title: task.name,
        type: calendarManager.EventType.NORMAL,
        startTime: startTime,
        endTime: endTime,
        reminderTime: [10]
      };

      const eventId: number = await calendar.addEvent(event);
      console.info(`[CalendarService] Succeeded in adding event, id = ${eventId}`);
      this.resetError();
      return eventId;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[CalendarService] Failed to add event. Code: ${err.code}, message: ${err.message}`);
      this.lastErrorType = CalendarErrorType.ADD_EVENT_FAILED;
      return null;
    }
  }
}
