// File: entry/src/main/ets/services/PermissionService.ets
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';

// 权限状态接口
interface PermissionStatus {
  granted: boolean;
  status: abilityAccessCtrl.GrantStatus;
}

/**
 * 权限管理服务
 * 处理应用权限申请和管理
 */
export class PermissionService {
  private static instance: PermissionService;
  private context: common.UIAbilityContext;
  private atManager: abilityAccessCtrl.AtManager;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.atManager = abilityAccessCtrl.createAtManager();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(context: common.UIAbilityContext): PermissionService {
    if (!PermissionService.instance) {
      PermissionService.instance = new PermissionService(context);
    }
    return PermissionService.instance;
  }

  /**
   * 检查权限状态
   */
  public async checkPermission(permission: string): Promise<abilityAccessCtrl.GrantStatus> {
    try {
      // 使用类型断言来避免类型检查问题
      const grantStatus = await this.atManager.checkAccessToken(
        this.context.applicationInfo.accessTokenId,
        permission as never
      );
      return grantStatus;
    } catch (error) {
      console.error('[PermissionService] 检查权限失败:', error);
      return abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    }
  }

  /**
   * 申请权限
   */
  public async requestPermission(permission: string): Promise<boolean> {
    try {
      const grantStatus = await this.checkPermission(permission);
      
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.log(`[PermissionService] 权限 ${permission} 已授予`);
        return true;
      }

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        console.log(`[PermissionService] 申请权限: ${permission}`);
        
        try {
          const requestResult = await this.atManager.requestPermissionsFromUser(
            this.context,
            [permission as never]
          );
          
          // 简化权限申请结果处理
          console.log(`[PermissionService] 权限 ${permission} 申请完成`);
          return true;
        } catch (requestError) {
          console.log(`[PermissionService] 权限 ${permission} 申请异常`);
          this.showPermissionDeniedMessage(permission);
          return false;
        }
      }

      return false;
    } catch (error) {
      console.error('[PermissionService] 申请权限失败:', error);
      return false;
    }
  }

  /**
   * 申请文件系统权限
   */
  public async requestFileSystemPermission(): Promise<boolean> {
    const permission = 'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY';
    console.log('[PermissionService] 开始申请文件系统权限...');
    
    try {
      const result = await this.requestPermission(permission);
      console.log(`[PermissionService] 文件系统权限申请结果: ${result}`);
      return result;
    } catch (error) {
      console.error('[PermissionService] 申请文件系统权限失败:', error);
      return false;
    }
  }

  /**
   * 显示权限被拒绝的消息
   */
  private showPermissionDeniedMessage(permission: string): void {
    let message = '';
    
    switch (permission) {
      case 'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY':
        message = '需要文件系统权限来保存和加载项目数据，请在设置中手动开启';
        break;
      default:
        message = '需要相关权限才能正常使用此功能';
    }
    
    promptAction.showToast({
      message: message,
      duration: 3000
    });
  }

  /**
   * 检查并申请所有必要权限
   */
  public async checkAndRequestAllPermissions(): Promise<boolean> {
    const permissions = [
      'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY'
    ];

    let allGranted = true;
    
    for (const permission of permissions) {
      const granted = await this.requestPermission(permission);
      if (!granted) {
        allGranted = false;
      }
    }

    return allGranted;
  }

  /**
   * 获取权限状态信息
   */
  public async getPermissionStatus(permission: string): Promise<PermissionStatus> {
    const status = await this.checkPermission(permission);
    const permissionStatus: PermissionStatus = {
      granted: status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED,
      status: status
    };
    return permissionStatus;
  }
}
