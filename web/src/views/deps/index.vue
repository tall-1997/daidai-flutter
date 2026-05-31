<template>
  <div class="deps-page dd-fixed-page dd-page-hide-heading">
    <div class="page-header">
      <div>
        <h2>📚 依赖管理</h2>
        <p class="page-subtitle">管理运行时所需的依赖包和系统软件，确保依赖版本和任务稳定运行</p>
      </div>
    </div>

    <!-- Android 面具版：一键安装 Python / Node 解释器 -->
    <el-card v-if="androidStatus && androidStatus.supported" class="android-runtime-card" shadow="never">
      <template #header>
        <div class="android-runtime-header">
          <span>
            <el-icon><Cpu /></el-icon>
            Android 脚本运行时 <el-tag size="small" type="info">面具版</el-tag>
          </span>
          <span class="android-runtime-meta">
            架构 {{ androidStatus.arch }} · 安装目录 {{ androidStatus.bin_dir }}
            <el-tag v-if="androidStatus.termux_detected" size="small" type="success">已检测 Termux</el-tag>
          </span>
        </div>
      </template>

      <div class="android-runtime-tip">
        <el-alert type="info" :closable="false" show-icon>
          面具环境没有 apt/apk，脚本解释器需要手动安装。点击下方按钮会把运行时下载解压到
          <code>{{ androidStatus.bin_dir }}</code>，随后 Python/Node 脚本即可运行。
          如果装了 Termux，面板也会自动识别 <code>/data/data/com.termux/files/usr/bin</code> 里的解释器。
        </el-alert>
      </div>

      <el-row :gutter="16" class="android-runtime-grid">
        <el-col v-for="item in androidStatus.runtimes" :key="item.name" :xs="24" :sm="12">
          <div class="runtime-item">
            <div class="runtime-item__head">
              <b>{{ item.name }}</b>
              <el-tag v-if="item.installed" type="success" size="small">已安装</el-tag>
              <el-tag v-else type="warning" size="small">未安装</el-tag>
            </div>
            <div class="runtime-item__meta">
              <div v-if="item.installed">
                <div>路径: <code>{{ item.path }}</code></div>
                <div v-if="item.version">版本: {{ item.version }}</div>
              </div>
              <div v-else>
                <template v-if="presetFor(item.name)">
                  将下载 {{ presetFor(item.name)?.label }}（约
                  {{ presetFor(item.name)?.size_mb }}MB）
                  <div v-if="presetFor(item.name)?.note" class="runtime-item__note">
                    提示：{{ presetFor(item.name)?.note }}
                  </div>
                </template>
                <template v-else>
                  当前架构 {{ androidStatus.arch }} 暂无预置下载源
                </template>
              </div>
            </div>
            <div class="runtime-item__actions">
              <el-button
                v-if="!item.installed"
                type="primary"
                size="small"
                :loading="androidInstallingName === item.name"
                :disabled="!presetFor(item.name)"
                @click="installAndroidRuntime(item.name)"
              >
                一键安装
              </el-button>
              <el-button
                v-else
                size="small"
                :loading="androidInstallingName === item.name"
                @click="installAndroidRuntime(item.name)"
              >
                重新安装
              </el-button>
              <el-button
                v-if="item.installed"
                type="danger"
                size="small"
                plain
                @click="uninstallAndroidRuntime(item.name)"
              >
                移除
              </el-button>
            </div>
          </div>
        </el-col>
      </el-row>

      <div v-if="androidInstallLog.length" class="android-runtime-log">
        <div class="android-runtime-log__title">
          安装日志
          <el-button link size="small" @click="androidInstallLog = []">清空</el-button>
        </div>
        <pre v-html="androidInstallLogHtml"></pre>
      </div>
    </el-card>

    <div class="stat-cards">
      <div class="stat-card" :class="{ 'stat-card--active': activeTab === 'nodejs' }" @click="activeTab = 'nodejs'; depsPage = 1; loadData()">
        <div class="stat-card__content">
          <span class="stat-card__label">Node.js 依赖</span>
          <span class="stat-card__value">{{ nodejsCount }}</span>
          <span class="stat-card__sub">已安装依赖包</span>
        </div>
        <div class="stat-card__icon-wrap stat-card__icon-wrap--js">
          <span class="js-icon-block">JS</span>
        </div>
      </div>
      <div class="stat-card" :class="{ 'stat-card--active': activeTab === 'python' }" @click="activeTab = 'python'; depsPage = 1; loadData()">
        <div class="stat-card__content">
          <span class="stat-card__label">Python 依赖</span>
          <span class="stat-card__value stat-card__value--green">{{ pythonCount }}</span>
          <span class="stat-card__sub">已安装依赖包</span>
        </div>
        <div class="stat-card__icon-wrap stat-card__icon-wrap--python">
          <svg viewBox="0 0 24 24" width="28" height="28"><path d="M9.585 11.692h4.328s2.432.039 2.432-2.35V5.391S16.714 3 12.304 3h-1.108C7.787 3 7.155 5.093 7.155 5.093v2.457h4.755v.735H7.155s-3.27-.37-3.27 4.788c0 5.16 2.854 4.975 2.854 4.975h1.705v-2.395s-.092-2.854 2.854-2.854l.287-.107zm-.472-4.868a.845.845 0 1 1 0-1.69.845.845 0 0 1 0 1.69z" fill="#3776AB"/><path d="M14.415 12.308h-4.328s-2.432-.039-2.432 2.35v3.951S7.286 21 11.696 21h1.108c3.409 0 4.041-2.093 4.041-2.093v-2.457h-4.755v-.735h4.755s3.27.37 3.27-4.788c0-5.16-2.854-4.975-2.854-4.975h-1.705v2.395s.092 2.854-2.854 2.854l-.287.107zm.472 4.868a.845.845 0 1 1 0 1.69.845.845 0 0 1 0-1.69z" fill="#FFD43B"/></svg>
        </div>
      </div>
      <div class="stat-card" :class="{ 'stat-card--active': activeTab === 'linux' }" @click="activeTab = 'linux'; depsPage = 1; loadData()">
        <div class="stat-card__content">
          <span class="stat-card__label">Linux 软件包</span>
          <span class="stat-card__value stat-card__value--orange">{{ linuxCount }}</span>
          <span class="stat-card__sub">已安装软件包</span>
        </div>
        <div class="stat-card__icon-wrap stat-card__icon-wrap--linux">
          <svg viewBox="0 0 24 24" width="28" height="28" fill="#333"><path d="M20.581 19.049c-.55-.446-.336-1.431-.907-1.917.553-3.365-.997-6.331-2.845-8.232-1.551-1.595-1.051-3.147-1.051-4.49 0-2.146-.881-4.41-3.55-4.41-2.853 0-3.635 2.38-3.663 3.738-.034 1.65-.1 2.873-.874 3.874-1.02 1.322-3.236 4.124-3.012 8.485-.7.36-.92 1.876-1.272 2.175-.403.343-.81.382-.972.848-.163.466.089.781.217 1.019.128.238.238.419-.038.6-.276.181-.591.157-.838.423-.248.266-.34.546-.076.953.186.288.63.413.857.424.227.011 2.016-.076 2.326-.076.508 0 1.42.454 2.455.454 1.037 0 1.316-.631 2.326-.631 1.01 0 1.316.631 2.326.631 1.037 0 1.42-.454 2.455-.454.31 0 2.1.087 2.326.076.227-.011.671-.136.857-.424.264-.407.172-.687-.076-.953-.247-.266-.562-.242-.838-.423-.276-.181-.166-.362-.038-.6.128-.238.38-.553.217-1.019-.162-.466-.569-.505-.972-.848z"/></svg>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-card__content">
          <span class="stat-card__label">安装失败</span>
          <span class="stat-card__value stat-card__value--red">{{ failedCount }}</span>
          <span class="stat-card__sub">最近 7 天</span>
        </div>
        <div class="stat-card__icon-wrap stat-card__icon-wrap--fail">
          <el-icon :size="28" color="#f56c6c"><CircleClose /></el-icon>
        </div>
      </div>
    </div>

    <div class="deps-tabs">
      <div class="status-tabs">
        <button :class="['status-tab', { active: activeTab === 'nodejs' }]" @click="activeTab = 'nodejs'; depsPage = 1; loadData()">Node.js</button>
        <button :class="['status-tab', { active: activeTab === 'python' }]" @click="activeTab = 'python'; depsPage = 1; loadData()">Python3</button>
        <button :class="['status-tab', { active: activeTab === 'linux' }]" @click="activeTab = 'linux'; depsPage = 1; loadData()">Linux</button>
      </div>
      <div class="status-tabs status-tabs--filter">
        <button :class="['status-tab', { active: statusFilter === '' }]" @click="statusFilter = ''; depsPage = 1">全部</button>
        <button :class="['status-tab status-tab--success', { active: statusFilter === 'installed' }]" @click="statusFilter = statusFilter === 'installed' ? '' : 'installed'; depsPage = 1">
          已安装 <span class="status-tab__count">{{ installedCount }}</span>
        </button>
        <button :class="['status-tab status-tab--danger', { active: statusFilter === 'failed' }]" @click="statusFilter = statusFilter === 'failed' ? '' : 'failed'; depsPage = 1">
          失败 <span class="status-tab__count">{{ failedCount }}</span>
        </button>
      </div>
    </div>

    <div class="toolbar">
      <div class="toolbar__left">
        <el-button type="primary" @click="createType = activeTab; showCreateDialog = true">
          <el-icon><Plus /></el-icon> 新增依赖
        </el-button>
        <el-button @click="loadData" :loading="loading">
          <el-icon><Refresh /></el-icon> 刷新
        </el-button>
        <el-button type="warning" plain @click="handleBatchReinstall" :disabled="batchReinstallIds.length === 0">
          <el-icon><RefreshRight /></el-icon> 批量重装
        </el-button>
        <el-button @click="handleExport" :loading="exporting">
          <el-icon><Download /></el-icon> 导出清单
        </el-button>
        <el-button @click="openMirrorDialog">
          <el-icon><Setting /></el-icon> 镜像源设置
        </el-button>
      </div>
      <div class="toolbar__right">
        <el-input v-model="searchKeyword" placeholder="搜索依赖包名称..." clearable class="toolbar__search" @keyup.enter="depsPage = 1" @clear="depsPage = 1">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="statusFilter" placeholder="所有状态" clearable class="toolbar__filter" @change="depsPage = 1">
          <el-option label="已安装" value="installed" />
          <el-option label="安装中" value="installing" />
          <el-option label="排队中" value="queued" />
          <el-option label="失败" value="failed" />
          <el-option label="已取消" value="cancelled" />
          <el-option label="卸载中" value="removing" />
        </el-select>
        <el-button v-if="selectedIds.length > 0" type="danger" plain @click="handleBatchDelete">
          <el-icon><Delete /></el-icon> 批量卸载
        </el-button>
      </div>
    </div>

    <div v-if="isMobile" class="dd-mobile-list">
      <div
        v-for="(row, index) in paginatedDepsList"
        :key="row.id"
        class="dd-mobile-card"
      >
        <div class="dd-mobile-card__header">
          <div class="dd-mobile-card__title-wrap">
            <div class="deps-card__title-row">
              <div class="dd-mobile-card__selection">
                <el-checkbox :model-value="isSelected(row.id)" @change="toggleSelected(row.id, $event)" />
                <span class="dd-mobile-card__title">{{ row.name }}</span>
              </div>
              <span class="dd-mobile-card__subtitle">#{{ index + 1 }}</span>
            </div>
          </div>
        </div>
        <div class="dd-mobile-card__body">
          <div class="dd-mobile-card__grid">
            <div class="dd-mobile-card__field">
              <span class="dd-mobile-card__label">状态</span>
              <div class="dd-mobile-card__value">
                <el-tag :type="statusType(row.status)" size="small" effect="light">{{ statusLabel(row.status) }}</el-tag>
              </div>
            </div>
            <div class="dd-mobile-card__field">
              <span class="dd-mobile-card__label">创建时间</span>
              <span class="dd-mobile-card__value">{{ new Date(row.created_at).toLocaleString('zh-CN') }}</span>
            </div>
          </div>
          <div class="dd-mobile-card__actions deps-card__actions">
            <el-button size="small" type="primary" plain @click="viewLog(row)">日志</el-button>
            <el-button
              v-if="row.status === 'installing' || row.status === 'removing'"
              size="small"
              type="warning"
              plain
              @click="handleCancel(row)"
            >
              取消
            </el-button>
            <el-button
              size="small"
              type="warning"
              plain
              @click="handleReinstall(row)"
              :disabled="isProcessing(row.status)"
            >
              重装
            </el-button>
            <el-button
              size="small"
              type="danger"
              plain
              @click="handleDelete(row)"
              :disabled="isProcessing(row.status)"
            >
              卸载
            </el-button>
            <el-button
              size="small"
              type="danger"
              @click="handleForceDelete(row)"
              :disabled="isProcessing(row.status)"
            >
              强制卸载
            </el-button>
          </div>
        </div>
      </div>

      <el-empty v-if="!loading && paginatedDepsList.length === 0" description="暂无依赖" />
    </div>

    <div v-else class="table-card">
      <el-table
        :data="paginatedDepsList"
        v-loading="loading"
        style="width: 100%"
        @selection-change="handleSelectionChange"
        :header-cell-style="{ background: '#f8fafc', color: '#64748b', fontWeight: 600, fontSize: '13px' }"
      >
        <el-table-column type="selection" width="40" />
        <el-table-column prop="name" label="名称" min-width="160">
          <template #default="{ row }">
            <div class="dep-name-cell">
              <span class="dep-name-avatar" :style="{ background: getLetterColor(row.name) }">{{ (row.name || '?').charAt(0).toUpperCase() }}</span>
              <span class="dep-name-text" :title="row.name">{{ row.name }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="version" label="版本" width="120">
          <template #default="{ row }">
            <span class="version-text">{{ row.version || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="statusType(row.status)" size="small" effect="light" round>{{ statusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            <span class="time-text">{{ new Date(row.created_at).toLocaleString('zh-CN') }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="176" fixed="right" align="center">
          <template #default="{ row }">
            <div class="action-btns">
              <el-button type="primary" text size="small" @click="viewLog(row)">详情</el-button>
              <el-button v-if="row.status === 'installing' || row.status === 'removing'" type="warning" text size="small" @click="handleCancel(row)">取消</el-button>
              <el-button v-else type="warning" text size="small" @click="handleReinstall(row)" :disabled="isProcessing(row.status)">重装</el-button>
              <el-dropdown trigger="click" placement="bottom-end">
                <el-button text size="small" class="action-more-btn">
                  更多
                  <el-icon><ArrowDown /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item @click="handleDelete(row)" :disabled="isProcessing(row.status)">卸载</el-dropdown-item>
                    <el-dropdown-item @click="handleForceDelete(row)" :disabled="isProcessing(row.status)">
                      <span class="danger-dropdown-text">强制卸载</span>
                    </el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div class="pagination-bar">
      <span class="pagination-total">共 {{ depsTotal }} 条数据</span>
      <el-pagination
        v-model:current-page="depsPage"
        v-model:page-size="depsPageSize"
        :total="depsTotal"
        :page-sizes="[10, 20, 50, 100]"
        layout="sizes, prev, pager, next, jumper"
      />
    </div>
    <el-dialog v-model="showCreateDialog" title="新建依赖" width="500px" :fullscreen="dialogFullscreen">
      <el-form label-width="80px">
        <el-form-item label="类型">
          <el-radio-group v-model="createType">
            <el-radio value="nodejs">Node.js</el-radio>
            <el-radio value="python">Python3</el-radio>
            <el-radio value="linux">Linux</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="名称">
          <el-input v-model="createNames" type="textarea" :rows="5" placeholder="每行一个依赖名称，支持换行/空格/逗号分隔" />
        </el-form-item>
        <el-form-item label="自动拆分">
          <el-switch v-model="autoSplit" />
          <span style="margin-left: 8px; font-size: 12px; color: var(--el-text-color-secondary)">开启后自动按换行、空格、逗号拆分为多个依赖</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="handleCreate" :loading="creating">安装</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="showLogDialog" title="安装日志" width="70%" :fullscreen="dialogFullscreen">
      <div class="log-dialog-toolbar">
        <div>
          <el-tag v-if="!logDone" type="warning" size="small" class="running-tag">
            <span class="spinner"></span> 执行中
          </el-tag>
          <el-tag v-else-if="currentLogRow?.status === 'cancelled'" type="info" size="small">已取消</el-tag>
          <el-tag v-else type="success" size="small">已完成</el-tag>
        </div>
        <el-button
          v-if="currentLogRow && !logDone"
          type="warning"
          plain
          size="small"
          @click="handleCancel(currentLogRow)"
        >
          取消当前任务
        </el-button>
      </div>
      <pre ref="logContainerRef" class="log-content" v-html="logContentHtml"></pre>
    </el-dialog>
    <el-dialog v-model="showMirrorDialog" title="软件包镜像源设置" width="560px" :fullscreen="dialogFullscreen">
      <el-form label-width="110px" v-loading="mirrorLoading">
        <el-form-item label="Python (pip)">
          <el-input v-model="mirrorForm.pip_mirror" placeholder="留空恢复默认加速源" clearable>
            <template #append>
              <el-dropdown @command="(v: string) => mirrorForm.pip_mirror = v" trigger="click">
                <el-button>快捷选择</el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="https://mirrors.aliyun.com/pypi/simple">阿里云 (默认)</el-dropdown-item>
                    <el-dropdown-item command="https://pypi.tuna.tsinghua.edu.cn/simple">清华大学</el-dropdown-item>
                    <el-dropdown-item command="https://pypi.doubanio.com/simple">豆瓣</el-dropdown-item>
                    <el-dropdown-item command="https://mirrors.cloud.tencent.com/pypi/simple">腾讯云</el-dropdown-item>
                    <el-dropdown-item command="https://repo.huaweicloud.com/repository/pypi/simple">华为云</el-dropdown-item>
                    <el-dropdown-item command="">恢复默认加速源</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </template>
          </el-input>
        </el-form-item>
        <el-form-item label="Node.js (npm)">
          <el-input v-model="mirrorForm.npm_mirror" placeholder="留空恢复默认加速源" clearable>
            <template #append>
              <el-dropdown @command="(v: string) => mirrorForm.npm_mirror = v" trigger="click">
                <el-button>快捷选择</el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="https://registry.npmmirror.com">淘宝 (npmmirror)</el-dropdown-item>
                    <el-dropdown-item command="https://mirrors.cloud.tencent.com/npm/">腾讯云</el-dropdown-item>
                    <el-dropdown-item command="https://repo.huaweicloud.com/repository/npm/">华为云</el-dropdown-item>
                    <el-dropdown-item command="">恢复默认加速源</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </template>
          </el-input>
        </el-form-item>
        <el-form-item :label="linuxMirrorLabel">
          <el-input
            v-model="mirrorForm.linux_mirror"
            :placeholder="linuxMirrorSupported ? '留空恢复默认加速源' : '当前包管理器暂不支持镜像设置'"
            :disabled="!linuxMirrorSupported"
            clearable
          >
            <template #append>
              <el-dropdown @command="(v: string) => mirrorForm.linux_mirror = v" trigger="click" :disabled="!linuxMirrorSupported || linuxMirrorOptions.length === 0">
                <el-button :disabled="!linuxMirrorSupported || linuxMirrorOptions.length === 0">快捷选择</el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item
                      v-for="option in linuxMirrorOptions"
                      :key="option.value"
                      :command="option.value"
                    >
                      {{ option.label }}
                    </el-dropdown-item>
                    <el-dropdown-item command="">恢复默认加速源</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </template>
          </el-input>
          <div class="mirror-hint">
            当前检测：{{ linuxMirrorManagerText }}
            <span v-if="linuxMirrorDistributionText"> / {{ linuxMirrorDistributionText }}</span>
            <span v-if="linuxMirrorMessage">。{{ linuxMirrorMessage }}</span>
          </div>
        </el-form-item>
        <el-alert type="info" :closable="false" show-icon>
          依赖管理默认优先使用加速源；清空输入框并保存，会恢复到内置的默认加速源配置。
        </el-alert>
      </el-form>
      <template #footer>
        <el-button @click="showMirrorDialog = false">取消</el-button>
        <el-button type="primary" @click="handleSaveMirrors" :loading="mirrorSaving">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, onActivated, watch, computed } from 'vue'
import { depsApi, type MirrorsResponse } from '@/api/deps'
import {
  androidRuntimeApi,
  type AndroidRuntimeStatus,
  type AndroidRuntimePreset,
} from '@/api/androidRuntime'
import { ElMessage, ElMessageBox } from 'element-plus'
import { openAuthorizedEventStream, type EventStreamConnection } from '@/utils/sse'
import { usePageActivity } from '@/composables/usePageActivity'
import { useResponsive } from '@/composables/useResponsive'
import { ansiToHtml, normalizeAnsi } from '@/utils/ansi'

// ---------- Android 面具版脚本运行时 ----------
const androidStatus = ref<AndroidRuntimeStatus | null>(null)
const androidInstallingName = ref<string>('')
const androidInstallLog = ref<string[]>([])
const androidInstallLogHtml = computed(() => ansiToHtml(normalizeAnsi(androidInstallLog.value.join('\n'))))
let androidInstallAbort: AbortController | null = null

async function loadAndroidStatus() {
  try {
    const res = await androidRuntimeApi.status()
    androidStatus.value = res.data
  } catch (e) {
    androidStatus.value = null
  }
}

function presetFor(name: string): AndroidRuntimePreset | undefined {
  return androidStatus.value?.presets?.find((p) => p.name === name)
}

async function installAndroidRuntime(name: string) {
  if (androidInstallingName.value) return
  const preset = presetFor(name)
  if (!preset) {
    ElMessage.warning('当前架构没有预置下载源')
    return
  }
  try {
    await ElMessageBox.confirm(
      `将从 ${preset.url} 下载约 ${preset.size_mb}MB 并解压到 /data/adb/daidai-panel/bin/${name}，是否继续？`,
      '安装确认',
      { confirmButtonText: '开始安装', cancelButtonText: '取消' },
    )
  } catch {
    return
  }

  androidInstallingName.value = name
  androidInstallLog.value = [`[${new Date().toLocaleTimeString()}] 准备安装 ${name}...`]
  androidInstallAbort = new AbortController()

  try {
    const resp = await androidRuntimeApi.installStream(name, androidInstallAbort.signal)
    if (!resp.ok) {
      const text = await resp.text()
      androidInstallLog.value.push(`HTTP ${resp.status}: ${text}`)
      ElMessage.error('安装失败: HTTP ' + resp.status)
      return
    }
    const reader = resp.body?.getReader()
    if (!reader) {
      ElMessage.error('无法建立流式连接')
      return
    }
    const decoder = new TextDecoder()
    let buf = ''
    for (;;) {
      const { done, value } = await reader.read()
      if (done) break
      buf += decoder.decode(value, { stream: true })
      let idx
      while ((idx = buf.indexOf('\n\n')) >= 0) {
        const line = buf.slice(0, idx)
        buf = buf.slice(idx + 2)
        const m = line.match(/^data:\s?(.*)$/)
        if (m && m[1] !== undefined) androidInstallLog.value.push(m[1].replace(/\\n/g, '\n'))
      }
    }
    ElMessage.success(`${name} 安装完成`)
    await loadAndroidStatus()
  } catch (e: any) {
    if (e?.name !== 'AbortError') {
      androidInstallLog.value.push('异常: ' + (e?.message || String(e)))
      ElMessage.error(e?.message || '安装过程异常')
    }
  } finally {
    androidInstallingName.value = ''
    androidInstallAbort = null
  }
}

async function uninstallAndroidRuntime(name: string) {
  try {
    await ElMessageBox.confirm(
      `确定移除 /data/adb/daidai-panel/bin/${name}？`,
      '确认',
      { type: 'warning' },
    )
  } catch {
    return
  }
  try {
    await androidRuntimeApi.uninstall(name)
    ElMessage.success('已移除')
    await loadAndroidStatus()
  } catch (e: any) {
    ElMessage.error('移除失败: ' + (e?.message || String(e)))
  }
}
// ---------- /Android 面具版 ----------

const activeTab = ref('nodejs')
const depsList = ref<any[]>([])
const loading = ref(false)
const showCreateDialog = ref(false)
const showLogDialog = ref(false)
const logContent = ref('')
const logContentHtml = computed(() => ansiToHtml(normalizeAnsi(logContent.value || '暂无日志')))
const logDone = ref(true)
const currentLogRow = ref<any | null>(null)
let eventSource: EventStreamConnection | null = null
const logContainerRef = ref<HTMLElement>()
let depsLogBuffer: string[] = []
let depsLogFlushRaf = 0
const createType = ref('nodejs')
const createNames = ref('')
const autoSplit = ref(true)
const creating = ref(false)
const exporting = ref(false)
const selectedIds = ref<number[]>([])
const selectedIdSet = computed(() => new Set(selectedIds.value))
const selectedRows = computed(() => depsList.value.filter(dep => selectedIdSet.value.has(dep.id)))
const batchReinstallRows = computed(() => selectedRows.value.filter(dep => !isProcessing(dep.status)))
const batchReinstallIds = computed(() => batchReinstallRows.value.map(dep => dep.id))
let refreshTimer: ReturnType<typeof setInterval> | null = null
const { isMobile, dialogFullscreen } = useResponsive()
const { isPageActive } = usePageActivity()

const showMirrorDialog = ref(false)
const mirrorLoading = ref(false)
const mirrorSaving = ref(false)
const mirrorForm = ref({ pip_mirror: '', npm_mirror: '', linux_mirror: '' })
const mirrorMeta = ref<MirrorsResponse>({
  pip_mirror: '',
  npm_mirror: '',
  linux_mirror: '',
  linux_package_manager: '',
  linux_distribution: '',
  linux_mirror_supported: false,
  linux_mirror_label: 'Linux',
  linux_mirror_message: '',
})
let mounted = false

const nodejsCount = ref(0)
const pythonCount = ref(0)
const linuxCount = ref(0)
const searchKeyword = ref('')
const statusFilter = ref('')

const failedCount = computed(() => depsList.value.filter(dep => dep.status === 'failed').length)
const installedCount = computed(() => depsList.value.filter(dep => dep.status === 'installed').length)

const filteredDepsList = computed(() => {
  let list = depsList.value
  if (searchKeyword.value) {
    const kw = searchKeyword.value.toLowerCase()
    list = list.filter(dep => dep.name?.toLowerCase().includes(kw))
  }
  if (statusFilter.value) {
    list = list.filter(dep => dep.status === statusFilter.value)
  }
  return list
})

const paginatedDepsList = computed(() => {
  const start = (depsPage.value - 1) * depsPageSize.value
  return filteredDepsList.value.slice(start, start + depsPageSize.value)
})

const depsTotal = computed(() => filteredDepsList.value.length)
const depsPage = ref(1)
const depsPageSize = ref(20)

function statusType(status: string) {
  switch (status) {
    case 'queued': return 'warning'
    case 'installed': return 'success'
    case 'installing': return 'warning'
    case 'removing': return 'warning'
    case 'cancelled': return 'info'
    case 'failed': return 'danger'
    default: return 'info'
  }
}

function statusLabel(status: string) {
  switch (status) {
    case 'queued': return '排队中'
    case 'installed': return '已安装'
    case 'installing': return '安装中'
    case 'removing': return '卸载中'
    case 'cancelled': return '已取消'
    case 'failed': return '失败'
    default: return status
  }
}

function isProcessing(status: string) {
  return status === 'queued' || status === 'installing' || status === 'removing'
}

const hasPendingDeps = computed(() => depsList.value.some(dep => isProcessing(dep.status)))

watch([hasPendingDeps, isPageActive], () => {
  syncPendingRefresh()
})

const linuxMirrorLabel = computed(() => mirrorMeta.value.linux_mirror_label || 'Linux')
const linuxMirrorSupported = computed(() => mirrorMeta.value.linux_mirror_supported)
const linuxMirrorMessage = computed(() => mirrorMeta.value.linux_mirror_message || '')
const linuxMirrorManagerText = computed(() => mirrorMeta.value.linux_package_manager || '未识别')
const linuxMirrorDistributionText = computed(() => mirrorMeta.value.linux_distribution || '')
const linuxMirrorOptions = computed(() => {
  const manager = mirrorMeta.value.linux_package_manager
  const distro = mirrorMeta.value.linux_distribution

  if (manager === 'apk') {
    return [
      { label: '阿里云 (默认)', value: 'https://mirrors.aliyun.com/alpine' },
      { label: '清华大学', value: 'https://mirrors.tuna.tsinghua.edu.cn/alpine' },
      { label: '腾讯云', value: 'https://mirrors.cloud.tencent.com/alpine' },
      { label: '华为云', value: 'https://repo.huaweicloud.com/alpine' },
      { label: '中科大', value: 'https://mirrors.ustc.edu.cn/alpine' },
    ]
  }

  if (manager === 'apt') {
    if (distro === 'debian') {
      return [
        { label: '阿里云 Debian (默认)', value: 'https://mirrors.aliyun.com/debian' },
        { label: '清华大学 Debian', value: 'https://mirrors.tuna.tsinghua.edu.cn/debian' },
        { label: '腾讯云 Debian', value: 'https://mirrors.cloud.tencent.com/debian' },
      ]
    }
    return [
      { label: '阿里云 Ubuntu (默认)', value: 'https://mirrors.aliyun.com/ubuntu' },
      { label: '清华大学 Ubuntu', value: 'https://mirrors.tuna.tsinghua.edu.cn/ubuntu' },
      { label: '腾讯云 Ubuntu', value: 'https://mirrors.cloud.tencent.com/ubuntu' },
      { label: '华为云 Ubuntu', value: 'https://repo.huaweicloud.com/ubuntu' },
    ]
  }

  return []
})

async function loadData() {
  loading.value = true
  try {
    const res = await depsApi.list(activeTab.value)
    depsList.value = res.data || []
    selectedIds.value = selectedIds.value.filter(id => depsList.value.some(dep => dep.id === id))
    const countMap: Record<string, (v: number) => void> = {
      nodejs: (v) => nodejsCount.value = v,
      python: (v) => pythonCount.value = v,
      linux: (v) => linuxCount.value = v,
    }
    countMap[activeTab.value]?.(depsList.value.length)
    syncPendingRefresh()
  } catch {
    if (!refreshTimer) {
      depsList.value = []
    }
    syncPendingRefresh()
  } finally {
    loading.value = false
  }
}

function stopRefreshTimer() {
  if (refreshTimer) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
}

function syncPendingRefresh() {
  if (hasPendingDeps.value && isPageActive.value) {
    if (!refreshTimer) {
      refreshTimer = setInterval(() => {
        void loadData()
      }, 3000)
    }
    return
  }
  stopRefreshTimer()
}

function parseNames(text: string): string[] {
  if (!autoSplit.value) return [text.trim()].filter(Boolean)
  return text.split(/[\n,\s]+/).map(s => s.trim()).filter(Boolean)
}

async function handleCreate() {
  const names = parseNames(createNames.value)
  if (names.length === 0) { ElMessage.warning('请输入依赖名称'); return }
  creating.value = true
  try {
    await depsApi.create(createType.value, names)
    ElMessage.success(`已提交 ${names.length} 个依赖安装`)
    showCreateDialog.value = false
    createNames.value = ''
    activeTab.value = createType.value
    loadData()
  } catch { ElMessage.error('提交安装失败') }
  finally { creating.value = false }
}

function handleSelectionChange(rows: any[]) {
  selectedIds.value = rows.map(r => r.id)
}

function isSelected(id: number) {
  return selectedIdSet.value.has(id)
}

function toggleSelected(id: number, checked: boolean | string | number) {
  const next = new Set(selectedIds.value)
  if (checked) {
    next.add(id)
  } else {
    next.delete(id)
  }
  selectedIds.value = [...next]
}

async function handleBatchDelete() {
  if (selectedIds.value.length === 0) return
  try {
    await ElMessageBox.confirm(`确定批量卸载选中的 ${selectedIds.value.length} 个依赖？`, '批量卸载', { type: 'warning' })
    await depsApi.batchDelete(selectedIds.value)
    ElMessage.success('批量卸载已提交')
    selectedIds.value = []
    loadData()
  } catch (err: any) {
    if (err !== 'cancel' && err?.toString() !== 'cancel') {
      ElMessage.error(err?.response?.data?.error || '批量卸载失败')
    }
  }
}

async function handleBatchReinstall() {
  if (selectedIds.value.length === 0) return
  if (batchReinstallIds.value.length === 0) {
    ElMessage.warning('选中的依赖当前都在处理中，暂时无法重装')
    return
  }

  const skippedCount = selectedIds.value.length - batchReinstallIds.value.length
  const skipHint = skippedCount > 0 ? `\n其中 ${skippedCount} 个依赖正在处理中，已自动跳过。` : ''

  try {
    await ElMessageBox.confirm(`确定顺序重装选中的 ${batchReinstallIds.value.length} 个依赖吗？${skipHint}`, '批量重装', { type: 'warning' })
    await depsApi.batchReinstall(batchReinstallIds.value)
    ElMessage.success(`已提交 ${batchReinstallIds.value.length} 个依赖顺序重装`)
    loadData()
  } catch (err: any) {
    if (err !== 'cancel' && err?.toString() !== 'cancel') {
      ElMessage.error(err?.response?.data?.error || '批量重装失败')
    }
  }
}

async function handleDelete(row: any) {
  try {
    await ElMessageBox.confirm(`确认卸载 ${row.name}？`, '提示', { type: 'warning' })
  } catch { return }
  try {
    await depsApi.delete(row.id)
    ElMessage.success('卸载中')
    loadData()
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '卸载失败')
  }
}

async function handleForceDelete(row: any) {
  try {
    await ElMessageBox.confirm(`确认强制卸载 ${row.name}？\n强制卸载会跳过依赖检查直接删除`, '强制卸载', { type: 'warning' })
  } catch { return }
  try {
    await depsApi.delete(row.id, true)
    ElMessage.success('强制卸载中')
    loadData()
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '强制卸载失败')
  }
}

async function handleReinstall(row: any) {
  try {
    await depsApi.reinstall(row.id)
    ElMessage.success('重新安装中')
    loadData()
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '操作失败')
  }
}

async function handleExport() {
  exporting.value = true
  try {
    const blob = await depsApi.exportList(activeTab.value)
    const url = window.URL.createObjectURL(blob)
    const anchor = document.createElement('a')
    const timestamp = new Date().toISOString().slice(0, 19).replace(/[-:T]/g, '')
    anchor.href = url
    anchor.download = `dependencies-${activeTab.value}-${timestamp}.txt`
    document.body.appendChild(anchor)
    anchor.click()
    document.body.removeChild(anchor)
    window.URL.revokeObjectURL(url)
    ElMessage.success('依赖清单已导出')
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '导出失败')
  } finally {
    exporting.value = false
  }
}

async function handleCancel(row: any) {
  try {
    await depsApi.cancel(row.id)
    ElMessage.success('取消请求已提交')
    loadData()
  } catch (e: any) {
    ElMessage.error(e?.response?.data?.error || '取消失败')
  }
}

function viewLog(row: any) {
  currentLogRow.value = row
  logContent.value = ''
  logDone.value = !(row.status === 'installing' || row.status === 'removing')
  showLogDialog.value = true

  closeSSE()

  if (logDone.value) {
    depsApi.getStatus(row.id).then(res => {
      logContent.value = res.data?.log || '暂无日志'
    }).catch(() => { logContent.value = '获取日志失败' })
    return
  }

  const url = `/api/v1/deps/${row.id}/log-stream`
  eventSource = openAuthorizedEventStream(url, {
    onMessage(data) {
      depsLogBuffer.push(data)
      if (!depsLogFlushRaf) {
        depsLogFlushRaf = requestAnimationFrame(() => {
          logContent.value += depsLogBuffer.join('\n') + '\n'
          depsLogBuffer = []
          depsLogFlushRaf = 0
          if (logContainerRef.value) {
            logContainerRef.value.scrollTop = logContainerRef.value.scrollHeight
          }
        })
      }
    },
    onEvent(event) {
      if (event.event === 'done') {
        logDone.value = true
        closeSSE()
        loadData()
      }
    },
    onError() {
      logDone.value = true
      closeSSE()
      loadData()
    }
  })
}

function closeSSE() {
  if (eventSource) {
    eventSource.close()
    eventSource = null
  }
}

watch(showLogDialog, (val) => {
  if (!val) {
    closeSSE()
    currentLogRow.value = null
  }
})

async function openMirrorDialog() {
  showMirrorDialog.value = true
  mirrorLoading.value = true
  try {
    const res = await depsApi.getMirrors()
    mirrorMeta.value = res
    mirrorForm.value.pip_mirror = res.pip_mirror || ''
    mirrorForm.value.npm_mirror = res.npm_mirror || ''
    mirrorForm.value.linux_mirror = res.linux_mirror || ''
  } catch { ElMessage.error('获取镜像源配置失败') }
  finally { mirrorLoading.value = false }
}

async function handleSaveMirrors() {
  if (!linuxMirrorSupported.value && mirrorForm.value.linux_mirror.trim()) {
    ElMessage.warning(linuxMirrorMessage.value || '当前系统暂不支持 Linux 镜像设置')
    return
  }
  mirrorSaving.value = true
  try {
    await depsApi.setMirrors(mirrorForm.value)
    ElMessage.success('镜像源设置成功')
    showMirrorDialog.value = false
  } catch (e: any) {
    ElMessage.error(e?.response?.data?.error || '设置失败')
  } finally { mirrorSaving.value = false }
}

const letterColors: Record<string, string> = {
  a: '#409eff', b: '#67c23a', c: '#e6a23c', d: '#67c23a', e: '#f56c6c',
  f: '#909399', g: '#b37feb', h: '#36cfc9', i: '#409eff', j: '#ff85c0',
  k: '#ffc53d', l: '#b37feb', m: '#e6a23c', n: '#409eff', o: '#36cfc9',
  p: '#67c23a', q: '#f56c6c', r: '#ff85c0', s: '#ffc53d', t: '#409eff',
  u: '#b37feb', v: '#36cfc9', w: '#e6a23c', x: '#909399', y: '#67c23a',
  z: '#f56c6c',
}
function getLetterColor(name: string): string {
  const ch = (name || '?').charAt(0).toLowerCase()
  return letterColors[ch] || '#409eff'
}

onMounted(async () => {
  mounted = true
  createType.value = activeTab.value
  loadData()
  loadAndroidStatus()
  const types = ['nodejs', 'python', 'linux'] as const
  const countRefs = { nodejs: nodejsCount, python: pythonCount, linux: linuxCount }
  for (const t of types) {
    if (t !== activeTab.value) {
      depsApi.list(t).then(res => { countRefs[t].value = (res.data || []).length }).catch(() => {})
    }
  }
})

onActivated(() => {
  if (!mounted) {
    void loadData()
  }
  mounted = false
})

onBeforeUnmount(() => {
  closeSSE()
  stopRefreshTimer()
  if (depsLogFlushRaf) { cancelAnimationFrame(depsLogFlushRaf); depsLogFlushRaf = 0 }
})
</script>

<style scoped lang="scss">
.deps-page { padding: 0; }

.page-header {
  margin-bottom: 18px;

  h2 { margin: 0; font-size: 22px; font-weight: 700; color: var(--el-text-color-primary); line-height: 1.3; }
  .page-subtitle { font-size: 13px; color: var(--el-text-color-secondary); margin: 4px 0 0; }
}

// ---------- Stat Cards ----------
.stat-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
  margin-bottom: 18px;
}

.stat-card {
  background: var(--el-bg-color);
  border-radius: 14px;
  padding: 16px 18px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
  border: 1px solid var(--el-border-color-lighter);
  transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s;
  cursor: pointer;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 22px rgba(15, 23, 42, 0.08);
  }
  &--active {
    border-color: var(--el-color-primary);
    box-shadow: 0 4px 16px rgba(59, 130, 246, 0.14);
  }

  &__content { display: flex; flex-direction: column; gap: 4px; min-width: 0; flex: 1; }
  &__label { font-size: 13px; color: var(--el-text-color-secondary); font-weight: 500; }
  &__value {
    font-size: 26px; font-weight: 700; color: #3b82f6; line-height: 1.15;
    font-family: 'Inter', var(--dd-font-ui), sans-serif;
    font-variant-numeric: tabular-nums;
    -webkit-font-smoothing: antialiased;
    letter-spacing: -0.01em;
    &--green { color: #10b981; }
    &--orange { color: #f59e0b; }
    &--red { color: #ef4444; }
    &--purple { color: #8b5cf6; }
  }
  &__sub { font-size: 12px; color: var(--el-text-color-placeholder); }
  &__trend {
    font-size: 11.5px;
    font-weight: 600;
    margin-top: 4px;
    padding: 1px 7px;
    border-radius: 6px;
    align-self: flex-start;
    &--green { color: #10b981; background: rgba(16, 185, 129, 0.1); }
    &--red { color: #ef4444; background: rgba(239, 68, 68, 0.1); }
  }
  &__icon-wrap {
    width: 44px; height: 44px; border-radius: 12px;
    display: flex; align-items: center; justify-content: center; flex-shrink: 0;
    &--js { background: #fef3c7; }
    &--python { background: rgba(59, 130, 246, 0.12); }
    &--linux { background: rgba(245, 158, 11, 0.12); }
    &--fail { background: rgba(239, 68, 68, 0.12); }
  }
}

// ---------- Toolbar ----------
.toolbar {
  display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; gap: 12px; flex-wrap: wrap;
  &__left { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
  &__right { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
  &__search { width: 240px; }
  &__filter { width: 140px; }
}

// ---------- Table Card ----------
.table-card {
  background: var(--el-bg-color); border-radius: 14px;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04); border: 1px solid var(--el-border-color-lighter); overflow: hidden;
}

.dep-name-cell {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.dep-name-avatar {
  width: 24px; height: 24px; border-radius: 8px;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
  font-size: 11px; font-weight: 700; color: #fff;
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.18);
}

.js-icon-block {
  width: 28px; height: 28px; border-radius: 4px;
  background: #323330; color: #f7df1e;
  display: flex; align-items: center; justify-content: center;
  font-size: 12px; font-weight: 800; font-family: Arial, sans-serif;
}

.deps-tabs { margin-bottom: 14px; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.status-tabs {
  display: inline-flex; background: var(--el-fill-color-light); border-radius: 10px; padding: 3px; gap: 2px;
}
.status-tab {
  padding: 6px 18px; border-radius: 7px; border: none; background: transparent;
  color: var(--el-text-color-secondary); font-size: 13px; font-weight: 500; cursor: pointer;
  transition: all 0.18s; white-space: nowrap; display: inline-flex; align-items: center; gap: 5px;
  &:hover { color: var(--el-text-color-primary); }
  &.active { background: var(--el-bg-color); color: var(--el-color-primary); box-shadow: 0 1px 2px rgba(15, 23, 42, 0.06); font-weight: 600; }
  &--success.active { color: var(--el-color-success); }
  &--danger.active { color: var(--el-color-danger); }
}
.status-tab__count {
  font-size: 11px; font-weight: 700; min-width: 18px; height: 18px; line-height: 18px;
  text-align: center; border-radius: 9px; background: var(--el-fill-color); display: inline-block;
  .status-tab.active & { background: currentColor; color: #fff; background-clip: padding-box; }
  .status-tab--success.active & { background: var(--el-color-success); color: #fff; }
  .status-tab--danger.active & { background: var(--el-color-danger); color: #fff; }
}
.dep-name-text {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 500;
  color: var(--el-text-color-primary);
}
.version-text { font-family: var(--dd-font-mono); font-size: 13px; color: var(--el-text-color-secondary); }
.time-text { font-family: var(--dd-font-mono); font-size: 12px; color: var(--el-text-color-regular); }
.action-btns {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  min-width: 0;

  :deep(.el-button) {
    height: 26px;
    padding: 0 5px;
    margin-left: 0;
    font-size: 12px;
  }

  :deep(.el-button + .el-button) {
    margin-left: 0;
  }
}

.action-more-btn {
  display: inline-flex;
  align-items: center;
  gap: 2px;
}

.danger-dropdown-text {
  color: var(--el-color-danger);
}

// ---------- Pagination ----------
.pagination-bar {
  margin-top: 20px; display: flex; justify-content: space-between; align-items: center; padding: 0 4px;
}
.pagination-total { font-size: 13px; color: var(--el-text-color-secondary); }

:deep(.el-table) {
  --el-table-border-color: #f0f0f0;
  .el-table__header-wrapper th { border-bottom: 1px solid #e8e8e8; }
  .el-table__row td { border-bottom: 1px solid #f5f5f5; }
  .el-table__cell { padding: 8px 0; }
  .el-table__fixed-right .el-table__cell { padding-left: 4px; padding-right: 4px; }
}

// ---------- Mobile card layout ----------
.deps-card__title-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}

.deps-card__actions > * {
  flex: 1 1 calc(50% - 4px);
}

// ---------- Log dialog ----------
.log-content {
  background: #1e1e1e;
  color: #d4d4d4;
  border-radius: 6px;
  padding: 16px;
  font-family: var(--dd-font-mono);
  font-size: 13px;
  line-height: 1.6;
  min-height: 200px;
  max-height: 60vh;
  overflow-y: auto;
  margin: 0;
  white-space: pre-wrap;
  word-break: break-all;
}

.log-dialog-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 8px;
}

.mirror-hint {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  line-height: 1.5;
  margin-top: 6px;
}

.running-tag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.spinner {
  display: inline-block;
  width: 12px;
  height: 12px;
  border: 2px solid rgba(230, 162, 60, 0.3);
  border-top-color: #e6a23c;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

// ---------- Responsive ----------
@media screen and (max-width: 1200px) {
  .stat-cards { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 768px) {
  .page-header { margin-bottom: 14px; h2 { font-size: 18px; } }
  .stat-cards { grid-template-columns: repeat(2, 1fr); gap: 10px; }
  .stat-card { padding: 14px 16px; &__value { font-size: 22px; } &__icon { width: 40px; height: 40px; } }

  .toolbar {
    flex-direction: column; align-items: stretch; gap: 10px;
    &__left {
      width: 100%;
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 8px;

      :deep(.el-button) {
        width: 100%;
        margin-left: 0;
      }
    }
    &__right { flex-direction: column; gap: 10px; }
    &__search { width: 100% !important; }
    &__filter { width: 100% !important; }
  }

  .deps-card__title-row {
    flex-direction: column;
  }

  .pagination-bar {
    flex-direction: column;
    gap: 10px;
    align-items: center;
  }
}

// ---------- Android Runtime ----------
.android-runtime-card {
  margin-bottom: 16px;
  border: 1px solid var(--el-border-color-lighter);
}
.android-runtime-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}
.android-runtime-header .el-icon { vertical-align: middle; margin-right: 6px; }
.android-runtime-meta {
  color: var(--el-text-color-secondary);
  font-size: 12px;
  display: flex;
  gap: 8px;
  align-items: center;
}
.android-runtime-tip { margin-bottom: 12px; }
.android-runtime-grid { margin-top: 8px; }
.runtime-item {
  border: 1px solid var(--el-border-color-lighter);
  border-radius: 8px;
  padding: 12px 14px;
  margin-bottom: 12px;
  background: var(--el-fill-color-lighter);
}
.runtime-item__head { display: flex; gap: 8px; align-items: center; margin-bottom: 6px; }
.runtime-item__meta { font-size: 12px; color: var(--el-text-color-secondary); line-height: 1.6; }
.runtime-item__note { color: var(--el-color-warning); margin-top: 4px; }
.runtime-item__actions { margin-top: 10px; display: flex; gap: 8px; }
.android-runtime-log {
  margin-top: 12px;
  border-top: 1px dashed var(--el-border-color-lighter);
  padding-top: 10px;
}
.android-runtime-log__title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
  color: var(--el-text-color-secondary);
  margin-bottom: 6px;
}
.android-runtime-log pre {
  background: var(--el-fill-color);
  border-radius: 6px;
  padding: 10px 12px;
  font-size: 12px;
  max-height: 240px;
  overflow: auto;
  margin: 0;
}
</style>
