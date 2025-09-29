// File: entry/src/main/ets/test/CriticalPathService.test.ets

import { CriticalPathService, TaskWithDuration } from '../services/CriticalPathService';
import { Dependency } from '../model/ProjectData';

/**
 * 关键路径服务单元测试
 */
describe('CriticalPathService', () => {
  let service: CriticalPathService;

  beforeEach(() => {
    service = new CriticalPathService();
  });

  describe('calculate', () => {
    it('should calculate critical path for simple project', () => {
      // 准备测试数据
      const tasks: TaskWithDuration[] = [
        { id: 'task1', duration: 5 },
        { id: 'task2', duration: 3 },
        { id: 'task3', duration: 2 }
      ];

      const dependencies: Dependency[] = [
        { fromId: 'task1', toId: 'task2' },
        { fromId: 'task2', toId: 'task3' }
      ];

      // 执行计算
      const result = service.calculate(tasks, dependencies);

      // 验证结果
      expect(result.success).toBe(true);
      expect(result.criticalTasks).toEqual(['task1', 'task2', 'task3']);
      expect(result.projectDuration).toBe(10);

      // 验证任务属性
      expect(tasks[0].earlyStart).toBe(0);
      expect(tasks[0].earlyFinish).toBe(5);
      expect(tasks[0].lateStart).toBe(0);
      expect(tasks[0].lateFinish).toBe(5);
      expect(tasks[0].isCritical).toBe(true);

      expect(tasks[1].earlyStart).toBe(5);
      expect(tasks[1].earlyFinish).toBe(8);
      expect(tasks[1].lateStart).toBe(5);
      expect(tasks[1].lateFinish).toBe(8);
      expect(tasks[1].isCritical).toBe(true);

      expect(tasks[2].earlyStart).toBe(8);
      expect(tasks[2].earlyFinish).toBe(10);
      expect(tasks[2].lateStart).toBe(8);
      expect(tasks[2].lateFinish).toBe(10);
      expect(tasks[2].isCritical).toBe(true);
    });

    it('should handle parallel tasks correctly', () => {
      // 准备测试数据 - 并行任务
      const tasks: TaskWithDuration[] = [
        { id: 'task1', duration: 5 },
        { id: 'task2', duration: 3 },
        { id: 'task3', duration: 2 },
        { id: 'task4', duration: 4 }
      ];

      const dependencies: Dependency[] = [
        { fromId: 'task1', toId: 'task2' },
        { fromId: 'task1', toId: 'task3' },
        { fromId: 'task2', toId: 'task4' },
        { fromId: 'task3', toId: 'task4' }
      ];

      // 执行计算
      const result = service.calculate(tasks, dependencies);

      // 验证结果
      expect(result.success).toBe(true);
      expect(result.projectDuration).toBe(12);

      // 验证关键路径
      expect(tasks[0].isCritical).toBe(true); // task1
      expect(tasks[1].isCritical).toBe(true); // task2
      expect(tasks[2].isCritical).toBe(false); // task3 (有浮动时间)
      expect(tasks[3].isCritical).toBe(true); // task4
    });

    it('should detect circular dependencies', () => {
      // 准备测试数据 - 循环依赖
      const tasks: TaskWithDuration[] = [
        { id: 'task1', duration: 5 },
        { id: 'task2', duration: 3 }
      ];

      const dependencies: Dependency[] = [
        { fromId: 'task1', toId: 'task2' },
        { fromId: 'task2', toId: 'task1' } // 循环依赖
      ];

      // 执行计算
      const result = service.calculate(tasks, dependencies);

      // 验证结果
      expect(result.success).toBe(false);
      expect(result.error).toContain('循环依赖');
    });

    it('should handle empty task list', () => {
      // 准备测试数据
      const tasks: TaskWithDuration[] = [];
      const dependencies: Dependency[] = [];

      // 执行计算
      const result = service.calculate(tasks, dependencies);

      // 验证结果
      expect(result.success).toBe(false);
      expect(result.error).toContain('任务列表不能为空');
    });

    it('should handle invalid task duration', () => {
      // 准备测试数据
      const tasks: TaskWithDuration[] = [
        { id: 'task1', duration: 0 }, // 无效工期
        { id: 'task2', duration: 3 }
      ];

      const dependencies: Dependency[] = [
        { fromId: 'task1', toId: 'task2' }
      ];

      // 执行计算
      const result = service.calculate(tasks, dependencies);

      // 验证结果
      expect(result.success).toBe(false);
      expect(result.error).toContain('工期必须大于0');
    });

    it('should handle non-existent task in dependencies', () => {
      // 准备测试数据
      const tasks: TaskWithDuration[] = [
        { id: 'task1', duration: 5 }
      ];

      const dependencies: Dependency[] = [
        { fromId: 'task1', toId: 'task2' } // task2不存在
      ];

      // 执行计算
      const result = service.calculate(tasks, dependencies);

      // 验证结果
      expect(result.success).toBe(false);
      expect(result.error).toContain('目标任务 task2 不存在');
    });
  });

  describe('getTaskSlack', () => {
    it('should calculate task slack correctly', () => {
      const task: TaskWithDuration = {
        id: 'task1',
        duration: 5,
        earlyStart: 0,
        lateStart: 2
      };

      const slack = service.getTaskSlack(task);
      expect(slack).toBe(2);
    });
  });

  describe('getCriticalTasks', () => {
    it('should return only critical tasks', () => {
      const tasks: TaskWithDuration[] = [
        { id: 'task1', duration: 5, isCritical: true },
        { id: 'task2', duration: 3, isCritical: false },
        { id: 'task3', duration: 2, isCritical: true }
      ];

      const criticalTasks = service.getCriticalTasks(tasks);
      expect(criticalTasks).toHaveLength(2);
      expect(criticalTasks.map(t => t.id)).toEqual(['task1', 'task3']);
    });
  });

  describe('getProjectDuration', () => {
    it('should return maximum early finish time', () => {
      const tasks: TaskWithDuration[] = [
        { id: 'task1', duration: 5, earlyFinish: 5 },
        { id: 'task2', duration: 3, earlyFinish: 8 },
        { id: 'task3', duration: 2, earlyFinish: 10 }
      ];

      const duration = service.getProjectDuration(tasks);
      expect(duration).toBe(10);
    });
  });
});

/**
 * 测试断言接口
 */
interface TestAssertions {
  toBe: (expected: string | number | boolean) => void;
  toEqual: (expected: string[] | number[] | boolean[] | object) => void;
  toContain: (expected: string) => void;
  toHaveLength: (expected: number) => void;
}

/**
 * 测试工具函数
 */
function expect(actual: string | number | boolean | object | Array<string | number | boolean | object> | undefined): TestAssertions {
  return {
    toBe: (expected: string | number | boolean) => {
      if (actual !== expected) {
        throw new Error(`Expected ${expected}, but got ${actual}`);
      }
    },
    toEqual: (expected: string[] | number[] | boolean[] | object) => {
      if (JSON.stringify(actual) !== JSON.stringify(expected)) {
        throw new Error(`Expected ${JSON.stringify(expected)}, but got ${JSON.stringify(actual)}`);
      }
    },
    toContain: (expected: string) => {
      if (typeof actual === 'string' && !actual.includes(expected)) {
        throw new Error(`Expected "${actual}" to contain "${expected}"`);
      }
    },
    toHaveLength: (expected: number) => {
      if (Array.isArray(actual) && actual.length !== expected) {
        throw new Error(`Expected length ${expected}, but got ${actual.length}`);
      }
    }
  };
}

function describe(name: string, fn: () => void) {
  console.log(`\n=== ${name} ===`);
  fn();
}

function beforeEach(fn: () => void) {
  fn();
}

function it(name: string, fn: () => void) {
  try {
    fn();
    console.log(`✓ ${name}`);
  } catch (error) {
    console.error(`✗ ${name}: ${error.message}`);
  }
}
