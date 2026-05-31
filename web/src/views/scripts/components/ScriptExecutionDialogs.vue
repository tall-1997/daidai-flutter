<script setup lang="ts">
import { Edit, RefreshRight, Select, Tickets, VideoPause, VideoPlay } from '@element-plus/icons-vue'
import { computed, defineAsyncComponent } from 'vue'
import { ansiToHtml, normalizeAnsi } from '@/utils/ansi'

const MonacoEditor = defineAsyncComponent(() => import('@/components/MonacoEditor.vue'))

const showCodeRunner = defineModel<boolean>('showCodeRunner', { required: true })
const runnerCode = defineModel<string>('runnerCode', { required: true })
const runnerLanguage = defineModel<string>('runnerLanguage', { required: true })
const showDebugDialog = defineModel<boolean>('showDebugDialog', { required: true })
const debugCode = defineModel<string>('debugCode', { required: true })
const debugCodeChanged = defineModel<boolean>('debugCodeChanged', { required: true })

const props = defineProps<{
  isMobile: boolean
  editorLanguage: string
  debugFileName: string
  debugLogs: string[]
  debugRunning: boolean
  debugSaving: boolean
  debugError: string
  debugExitCode: number | null
  runnerLogs: string[]
  runnerRunning: boolean
  runnerExitCode: number | null
  runnerError: string
  onDebugStart: () => void | Promise<void>
  onDebugSave: () => void | Promise<void>
  onDebugStop: () => void | Promise<void>
  onRunCode: () => void | Promise<void>
  onStopRunner: () => void | Promise<void>
}>()

const debugLogsHtml = computed(() => ansiToHtml(normalizeAnsi(props.debugLogs.join('\n'))))
const runnerLogsHtml = computed(() => ansiToHtml(normalizeAnsi(props.runnerLogs.join('\n'))))

function markDebugCodeChanged() {
  debugCodeChanged.value = true
}
</script>

<template>
  <el-dialog v-model="showCodeRunner" title="代码运行器" :width="isMobile ? '98%' : '86%'" :fullscreen="isMobile" :close-on-click-modal="false" :top="isMobile ? '2vh' : '3vh'" destroy-on-close>
    <div class="debug-container debug-dialog-container" :class="{ mobile: isMobile }">
      <div class="debug-code-panel">
        <div class="panel-header">
          <el-icon><Edit /></el-icon>
          <span>代码编辑</span>
          <el-select v-model="runnerLanguage" size="small" style="width: 130px; margin-left: auto">
            <el-option label="Python" value="python" />
            <el-option label="JavaScript" value="javascript" />
            <el-option label="TypeScript" value="typescript" />
            <el-option label="Shell" value="shell" />
            <el-option label="Go" value="go" />
          </el-select>
        </div>
        <div class="panel-content" style="padding: 0">
          <MonacoEditor
            v-if="showCodeRunner"
            v-model="runnerCode"
            :language="runnerLanguage === 'shell' ? 'shell' : runnerLanguage"
            min-height="0"
            style="height: 100%; min-height: 0"
          />
        </div>
      </div>
      <div class="debug-log-panel">
        <div class="panel-header">
          <el-icon><Tickets /></el-icon>
          <span>运行输出</span>
          <el-tag v-if="runnerRunning" type="warning" size="small" effect="plain">运行中</el-tag>
          <el-tag v-else-if="runnerError || runnerLogs.length > 0" :type="runnerExitCode === 0 ? 'success' : 'danger'" size="small" effect="plain">
            {{ runnerExitCode === 0 ? '成功' : '失败' }}
          </el-tag>
        </div>
        <div class="panel-content">
          <div v-if="runnerError" class="debug-error">
            <el-alert type="error" :title="runnerError === 'failed' ? `退出码: ${runnerExitCode}` : runnerError" :closable="false" show-icon />
          </div>
          <pre v-if="runnerLogs.length > 0" class="debug-logs" v-html="runnerLogsHtml"></pre>
          <el-empty v-if="!runnerLogs.length && !runnerError" description="点击运行按钮执行代码" :image-size="80" />
        </div>
      </div>
    </div>
    <template #footer>
      <el-button v-if="!runnerRunning && !runnerLogs.length && !runnerError" type="primary" @click="onRunCode">
        <el-icon><VideoPlay /></el-icon>运行
      </el-button>
      <el-button v-if="runnerRunning" type="danger" @click="onStopRunner">
        <el-icon><VideoPause /></el-icon>停止
      </el-button>
      <el-button v-if="!runnerRunning && (runnerLogs.length > 0 || runnerError)" type="primary" @click="onRunCode">
        <el-icon><RefreshRight /></el-icon>重新运行
      </el-button>
      <el-button @click="showCodeRunner = false">关闭</el-button>
    </template>
  </el-dialog>

  <el-dialog v-model="showDebugDialog" title="调试运行" :width="isMobile ? '98%' : '86%'" :fullscreen="isMobile" :close-on-click-modal="false" :top="isMobile ? '2vh' : '3vh'" destroy-on-close>
    <div class="debug-container debug-dialog-container" :class="{ mobile: isMobile }">
      <div class="debug-code-panel">
        <div class="panel-header">
          <el-icon><Edit /></el-icon>
          <span>{{ debugFileName }}</span>
          <el-tag v-if="debugCodeChanged" type="warning" size="small" effect="plain">已修改</el-tag>
        </div>
        <div class="panel-content" style="padding: 0">
          <MonacoEditor
            v-if="showDebugDialog"
            v-model="debugCode"
            :language="editorLanguage"
            min-height="0"
            style="height: 100%; min-height: 0"
            @update:modelValue="markDebugCodeChanged"
          />
        </div>
      </div>
      <div class="debug-log-panel">
        <div class="panel-header">
          <el-icon><Tickets /></el-icon>
          <span>调试日志</span>
          <el-tag v-if="debugRunning" type="warning" size="small" effect="plain">运行中</el-tag>
          <el-tag v-else-if="debugLogs.length > 0" type="success" size="small" effect="plain">已完成</el-tag>
        </div>
        <div class="panel-content">
          <div v-if="debugError" class="debug-error">
            <el-alert type="error" :title="`退出码: ${debugExitCode}`" :closable="false" show-icon />
          </div>
          <pre v-if="debugLogs.length > 0" class="debug-logs" v-html="debugLogsHtml"></pre>
          <el-empty v-if="!debugLogs.length && !debugError" description="点击运行按钮开始调试" :image-size="80" />
        </div>
      </div>
    </div>
    <template #footer>
      <el-button v-if="!debugRunning && !debugLogs.length && !debugError" type="primary" @click="onDebugStart">
        <el-icon><VideoPlay /></el-icon>运行
      </el-button>
      <el-button :disabled="!debugCodeChanged || debugRunning || debugSaving" @click="onDebugSave">
        <el-icon><Select /></el-icon>{{ debugSaving ? '保存中' : '保存' }}
      </el-button>
      <el-button v-if="debugRunning" type="danger" @click="onDebugStop">
        <el-icon><VideoPause /></el-icon>停止
      </el-button>
      <el-button v-if="!debugRunning && (debugLogs.length > 0 || debugError)" type="primary" @click="onDebugStart">
        <el-icon><RefreshRight /></el-icon>重新运行
      </el-button>
      <el-button @click="showDebugDialog = false">关闭</el-button>
    </template>
  </el-dialog>
</template>

<style scoped lang="scss">
.debug-container {
  display: flex;
  gap: 16px;
  height: min(76dvh, 860px);
  min-height: clamp(320px, 52dvh, 520px);
  max-height: calc(100dvh - 220px);
  min-width: 0;
}

.debug-code-panel,
.debug-log-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  border: 1px solid var(--el-border-color-light);
  border-radius: 8px;
  overflow: hidden;
  background: var(--el-bg-color);
}

.debug-dialog-container {
  height: min(64dvh, 680px);
  min-height: clamp(280px, 46dvh, 430px);
  max-height: calc(100dvh - 190px);
}

.panel-header {
  padding: 12px 16px;
  background: var(--el-fill-color-light);
  border-bottom: 1px solid var(--el-border-color-light);
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  font-size: 14px;
  flex-shrink: 0;
}

.panel-content {
  flex: 1;
  min-height: 0;
  overflow: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
}

.debug-error {
  margin-bottom: 12px;
}

.debug-logs {
  font-family: var(--dd-font-mono);
  font-size: 13px;
  line-height: 1.6;
  margin: 0;
  white-space: pre-wrap;
  word-break: break-all;
  color: var(--el-text-color-primary);
  flex: 1;
}

.debug-container.mobile {
  flex-direction: column;
  height: min(100%, calc(100dvh - 160px));
  min-height: 0;
  max-height: calc(100dvh - 160px);

  .debug-code-panel,
  .debug-log-panel {
    flex: 1 1 0;
    min-height: 180px;
    max-height: none;
  }

  .panel-content {
    padding: 8px;
  }
}
</style>
