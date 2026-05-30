# 用户指令记忆

本文件记录了用户的指令、偏好和教导，用于在未来的交互中提供参考。

## 格式

### 用户指令条目
用户指令条目应遵循以下格式：

[用户指令摘要]
- Date: [YYYY-MM-DD]
- Context: [提及的场景或时间]
- Instructions:
  - [用户教导或指示的内容，逐行描述]

### 项目知识条目
Agent 在任务执行过程中发现的条目应遵循以下格式：

[项目知识摘要]
- Date: [YYYY-MM-DD]
- Context: Agent 在执行 [具体任务描述] 时发现
- Category: [运维部署|构建方法|测试方法|排错调试|工作流协作|环境配置]
- Instructions:
  - [具体的知识点，逐行描述]

## 去重策略
- 添加新条目前，检查是否存在相似或相同的指令
- 若发现重复，跳过新条目或与已有条目合并
- 合并时，更新上下文或日期信息
- 这有助于避免冗余条目，保持记忆文件整洁

## 条目

[面板访问和SSH连接信息]
- Date: 2026-05-28
- Context: 用户提供面板访问和SSH连接配置信息
- Category: 运维部署
- Instructions:
  - 面板启动后访问地址: http://127.0.0.1:5700
  - 端口配置文件: /data/adb/daidai-panel/ports.conf
  - 端口配置格式: PANEL_PORT=5700, SSH_PORT=22
  - SSH连接命令: ssh root@<设备IP> -p 22
  - SSH默认密码: 123456
  - rootfs位置: /data/local/daidai
  - 数据目录: /data/local/daidai/app/Dumb-Panel

[App服务器配置功能]
- Date: 2026-05-28
- Context: 用户要求检查App服务器配置逻辑并添加服务器地址选择功能
- Category: 开发功能
- Instructions:
  - App默认服务器地址: http://127.0.0.1:5700
  - 服务器配置存储在SharedPreferences中
  - 添加了服务器地址选择对话框
  - 支持预设常用服务器地址和历史记录
  - 登录页面和设置页面都可以选择服务器地址
  - 后端API实际运行在端口5701（本地开发环境）

[Android App开发进度]
- Date: 2026-05-30
- Context: Agent 在执行 Android App 功能开发时记录
- Category: 开发功能
- Instructions:
  - 当前版本: 0.0.8
  - APK位置: /workspace/download/daidai-app-0.0.8-debug.apk
  - Git仓库: https://github.com/tall-1997/daidai-panel
  - 最新commit: 6cd2811
  - 后端运行端口: 5701
  - 登录账号: admin/admin123
  - 已实现功能:
    1. 登录功能（自动登录、记住密码）
    2. 任务列表（搜索、分页、状态显示）
    3. 任务详情（查看/执行/停止/启用/禁用/置顶/复制/删除）
    4. 任务创建（任务类型选择、Cron模板、脚本上传）
    5. 环境变量管理（创建/编辑/删除/启用/禁用）
    6. 依赖管理（安装/删除/重新安装）
    7. 日志管理（查看/删除）
    8. 系统设置
  - 技术栈: Kotlin + Jetpack Compose + Hilt + Retrofit
