<template>
  <div class="open-api-page dd-fixed-page dd-page-hide-heading">
    <div class="page-header">
      <div>
        <h2>🔑 Open API 管理</h2>
        <p class="page-subtitle">创建和管理外部 API 调用应用密钥，控制接口访问权限和速率。</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="showCreateDialog">
          <el-icon><Plus /></el-icon> 创建令牌
        </el-button>
      </div>
    </div>

    <!-- ======= Stat Cards + Trend Chart ======= -->
    <div class="stat-section">
      <div class="stat-cards">
        <div class="stat-card">
          <div class="stat-card__content">
            <span class="stat-card__label">API 令牌数</span>
            <span class="stat-card__value">{{ apiStats.tokenCount }}</span>
            <span class="stat-card__sub">已创建应用</span>
          </div>
          <div class="stat-card__sparkline">
            <svg viewBox="0 0 60 24" preserveAspectRatio="none">
              <polyline points="0,18 10,14 20,16 30,10 40,12 50,6 60,8" fill="none" stroke="#409eff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-card__content">
            <span class="stat-card__label">今日调用数</span>
            <span class="stat-card__value stat-card__value--green">{{ apiStats.totalRequests.toLocaleString() }}</span>
            <span class="stat-card__sub">全部应用今日累计</span>
          </div>
          <div class="stat-card__sparkline">
            <svg viewBox="0 0 60 24" preserveAspectRatio="none">
              <polyline points="0,16 10,12 20,14 30,8 40,10 50,4 60,6" fill="none" stroke="#67c23a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-card__content">
            <span class="stat-card__label">每小时额度</span>
            <span class="stat-card__value stat-card__value--orange">{{ apiStats.rateLimitDisplay }}</span>
            <span class="stat-card__sub">已配置限流应用的小时额度合计</span>
          </div>
          <div class="stat-card__sparkline">
            <svg viewBox="0 0 60 24" preserveAspectRatio="none">
              <polyline points="0,20 10,16 20,18 30,12 40,14 50,8 60,10" fill="none" stroke="#e6a23c" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-card__content">
            <span class="stat-card__label">启用率</span>
            <span class="stat-card__value">{{ apiStats.successRate }}</span>
            <span class="stat-card__sub">已启用占比</span>
          </div>
          <div class="stat-card__sparkline">
            <svg viewBox="0 0 60 24" preserveAspectRatio="none">
              <polyline points="0,14 10,10 20,12 30,6 40,8 50,4 60,5" fill="none" stroke="#409eff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
        </div>
      </div>
      <div class="trend-chart-card">
        <div class="trend-chart-card__header">
          <span class="trend-chart-card__title">请求趋势</span>
          <div class="trend-chart-card__legend">
            <span class="trend-chart-card__legend-item trend-chart-card__legend-item--success"><span class="legend-dot"></span>成功</span>
            <span class="trend-chart-card__legend-item trend-chart-card__legend-item--fail"><span class="legend-dot"></span>失败</span>
          </div>
        </div>
        <div class="trend-chart-card__body">
          <svg viewBox="0 0 280 100" preserveAspectRatio="none" class="trend-area-chart">
            <defs>
              <linearGradient id="apiSuccessGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="#409eff" stop-opacity="0.25"/>
                <stop offset="100%" stop-color="#409eff" stop-opacity="0.02"/>
              </linearGradient>
              <linearGradient id="apiFailGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="#f56c6c" stop-opacity="0.2"/>
                <stop offset="100%" stop-color="#f56c6c" stop-opacity="0.02"/>
              </linearGradient>
            </defs>
            <polygon points="0,60 40,45 80,50 120,30 160,35 200,20 240,25 280,15 280,100 0,100" fill="url(#apiSuccessGrad)"/>
            <polyline points="0,60 40,45 80,50 120,30 160,35 200,20 240,25 280,15" fill="none" stroke="#409eff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <polygon points="0,85 40,80 80,82 120,75 160,78 200,72 240,76 280,70 280,100 0,100" fill="url(#apiFailGrad)"/>
            <polyline points="0,85 40,80 80,82 120,75 160,78 200,72 240,76 280,70" fill="none" stroke="#f56c6c" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
      </div>
    </div>

    <div class="toolbar">
      <div class="toolbar__left">
        <div class="status-tabs">
          <button :class="['status-tab', { active: statusFilter === '' }]" @click="statusFilter = ''">全部</button>
          <button :class="['status-tab', { active: statusFilter === 'enabled' }]" @click="statusFilter = 'enabled'">已启用</button>
          <button :class="['status-tab', { active: statusFilter === 'disabled' }]" @click="statusFilter = 'disabled'">已禁用</button>
        </div>
        <el-input v-model="searchKeyword" placeholder="搜索应用名称或 Key" clearable class="toolbar__search" @keyup.enter="handleSearch" @clear="handleSearch">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
      </div>
      <div class="toolbar__right">
        <el-button type="primary" @click="showCreateDialog">
          <el-icon><Plus /></el-icon> 创建令牌
        </el-button>
        <el-button @click="loadApps" title="刷新列表">
          <el-icon><Refresh /></el-icon>
        </el-button>
      </div>
    </div>

    <div v-if="isMobile" class="dd-mobile-list">
      <div
        v-for="row in pagedApps"
        :key="row.id"
        class="dd-mobile-card"
      >
        <div class="dd-mobile-card__header">
          <div class="dd-mobile-card__title-wrap">
            <span class="dd-mobile-card__title">{{ row.name }}</span>
            <div class="dd-mobile-card__subtitle">{{ row.app_key }}</div>
          </div>
          <el-switch
            :model-value="row.enabled"
            @change="(val: boolean) => toggleEnabled(row, val)"
            size="small"
          />
        </div>

        <div class="dd-mobile-card__body">
          <div class="dd-mobile-card__grid">
            <div class="dd-mobile-card__field dd-mobile-card__field--full">
              <span class="dd-mobile-card__label">App Secret</span>
              <div class="dd-mobile-card__value">
                <template v-if="revealedSecrets[row.id]">
                  <div class="key-display">
                    <code class="key-code secret-code">{{ revealedSecrets[row.id] }}</code>
                    <el-button class="copy-btn" size="small" @click="copyText(revealedSecrets[row.id] || '')">
                      <el-icon><DocumentCopy /></el-icon>
                    </el-button>
                    <el-button class="copy-btn" size="small" @click="hideSecret(row.id)">
                      <el-icon><Hide /></el-icon>
                    </el-button>
                  </div>
                </template>
                <template v-else>
                  <div class="key-display">
                    <span class="secret-mask">••••••••••••••••</span>
                    <el-button type="primary" link size="small" @click="viewSecret(row)">
                      <el-icon><View /></el-icon>查看
                    </el-button>
                  </div>
                </template>
              </div>
            </div>
            <div class="dd-mobile-card__field dd-mobile-card__field--full">
              <span class="dd-mobile-card__label">权限范围</span>
              <div class="dd-mobile-card__value">
                <el-tag
                  v-for="s in parseScopesTags(row.scopes)"
                  :key="s"
                  size="small"
                  style="margin: 2px 4px 2px 0"
                >{{ s }}</el-tag>
                <span v-if="!row.scopes" style="color: var(--el-text-color-secondary)">未授权任何范围</span>
              </div>
            </div>
            <div class="dd-mobile-card__field">
              <span class="dd-mobile-card__label">速率限制</span>
              <span class="dd-mobile-card__value">{{ formatRateLimit(row.rate_limit) }}</span>
            </div>
            <div class="dd-mobile-card__field">
              <span class="dd-mobile-card__label">今日调用</span>
              <span class="dd-mobile-card__value">{{ row.call_count }}</span>
            </div>
          </div>

          <div class="dd-mobile-card__actions open-api-card__actions">
            <el-button size="small" type="primary" plain @click="editApp(row)">编辑</el-button>
            <el-button size="small" type="warning" plain @click="resetSecret(row)">重置密钥</el-button>
            <el-button size="small" @click="showLogs(row)">日志</el-button>
            <el-button size="small" type="danger" plain @click="deleteApp(row)">删除</el-button>
          </div>
        </div>
      </div>

      <el-empty v-if="!loading && filteredApps.length === 0" description="暂无应用" />
    </div>

    <div v-else class="table-card">
      <el-table
        :data="pagedApps"
        v-loading="loading"
        style="width: 100%"
        :header-cell-style="{ background: '#f8fafc', color: '#64748b', fontWeight: 600, fontSize: '13px' }"
      >
        <el-table-column prop="name" label="应用名称" min-width="180">
          <template #default="{ row }">
            <div class="app-name-cell">
              <span class="app-avatar" :style="{ background: getAvatarColor(row.name) }">{{ getInitial(row.name) }}</span>
              <div class="app-name-info">
                <span class="app-name-text">{{ row.name }}</span>
                <span class="app-name-desc">{{ row.scopes ? parseScopesTags(row.scopes).join('、') : '暂无权限' }}</span>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="API Key" min-width="220">
          <template #default="{ row }">
            <div class="key-display">
              <code class="key-code">{{ maskKey(row.app_key) }}</code>
              <el-button class="copy-btn" size="small" @click="copyText(row.app_key)">
                <el-icon><DocumentCopy /></el-icon>
              </el-button>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="App Secret" min-width="240">
          <template #default="{ row }">
            <div v-if="revealedSecrets[row.id]" class="key-display">
              <code class="key-code secret-code">{{ revealedSecrets[row.id] }}</code>
              <el-button class="copy-btn" size="small" @click="copyText(revealedSecrets[row.id] || '')">
                <el-icon><DocumentCopy /></el-icon>
              </el-button>
              <el-button class="copy-btn" size="small" @click="hideSecret(row.id)">
                <el-icon><Hide /></el-icon>
              </el-button>
            </div>
            <div v-else class="key-display">
              <span class="secret-mask">••••••••••••••••</span>
              <el-button type="primary" link size="small" @click="viewSecret(row)">
                <el-icon><View /></el-icon>查看
              </el-button>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="权限" min-width="200">
          <template #default="{ row }">
            <el-tag
              v-for="s in parseScopesTags(row.scopes)"
              :key="s"
              size="small"
              class="scope-tag"
            >{{ s }}</el-tag>
            <span v-if="!row.scopes" style="color: var(--el-text-color-secondary)">未授权</span>
          </template>
        </el-table-column>
        <el-table-column prop="call_count" label="今日调用" width="90" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-switch
              :model-value="row.enabled"
              @change="(val: boolean) => toggleEnabled(row, val)"
              size="small"
            />
          </template>
        </el-table-column>
        <el-table-column label="创建时间" width="170">
          <template #default="{ row }">
            <span class="time-text">{{ row.created_at ? new Date(row.created_at).toLocaleString('zh-CN') : '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="editApp(row)">编辑</el-button>
            <el-button type="warning" link size="small" @click="resetSecret(row)">重置</el-button>
            <el-button type="info" link size="small" @click="showLogs(row)">日志</el-button>
            <el-button type="danger" link size="small" @click="deleteApp(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div class="pagination-bar">
      <span class="pagination-total">共 {{ filteredApps.length }} 条</span>
      <el-pagination
        v-if="filteredApps.length > apiPageSize"
        v-model:current-page="apiPage"
        :total="filteredApps.length"
        :page-size="apiPageSize"
        layout="prev, pager, next"
        small
      />
    </div>

    <div class="info-cards">
      <div class="info-card">
        <div class="info-card__header">
          <div class="info-card__icon info-card__icon--blue">
            <el-icon :size="20"><Lock /></el-icon>
          </div>
          <h3 class="info-card__title">安全建议</h3>
        </div>
        <ul class="info-card__list">
          <li>定期轮换 API 密钥，建议每 90 天更换一次</li>
          <li>使用最小权限原则，仅授权必要的接口范围</li>
          <li>配置合理的速率限制，防止接口被滥用</li>
          <li>不要在客户端代码中暴露 App Secret</li>
        </ul>
      </div>
      <div class="info-card">
        <div class="info-card__header">
          <div class="info-card__icon info-card__icon--green">
            <el-icon :size="20"><Connection /></el-icon>
          </div>
          <h3 class="info-card__title">开发者文档</h3>
        </div>
        <ul class="info-card__list">
          <li>使用 App Key + App Secret 生成签名进行身份验证</li>
          <li>所有 API 请求需在 Header 中携带认证信息</li>
          <li>接口返回标准 JSON 格式，包含 code 和 data 字段</li>
          <li>超过速率限制将返回 429 状态码，请合理控制频率</li>
        </ul>
      </div>
    </div>

    <el-dialog v-model="dialogVisible" :title="editingApp ? '编辑应用' : '新建应用'" width="500px" :fullscreen="dialogFullscreen">
      <el-form :model="form" label-position="top">
        <el-form-item label="应用名称" required>
          <el-input v-model="form.name" placeholder="例如：外部调度系统" />
        </el-form-item>
        <el-form-item label="权限范围">
          <el-select
            v-model="form.scopesList"
            multiple
            filterable
            placeholder="请选择允许访问的资源范围"
            style="width: 100%"
          >
            <el-option v-for="s in scopeOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
          <div style="margin-top: 6px; color: var(--el-text-color-secondary); font-size: 12px">
            默认拒绝。留空表示该应用创建成功，但没有任何接口访问权限。
          </div>
        </el-form-item>
        <el-form-item label="速率限制">
          <el-input-number v-model="form.rate_limit" :min="0" :max="10000" />
          <span style="margin-left: 8px; color: var(--el-text-color-secondary)">次/小时，填 0 表示无限制</span>
          <div style="margin-top: 6px; color: var(--el-text-color-secondary); font-size: 12px">
            调用次数按当天统计展示，每日会重新从 0 开始累计。
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitForm">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="secretDialogVisible" title="应用密钥" width="560px" :fullscreen="dialogFullscreen" :close-on-click-modal="false">
      <el-alert type="warning" :closable="false" style="margin-bottom: 16px">
        请妥善保管密钥，关闭后需要验证密码才能再次查看 App Secret。
      </el-alert>
      <div class="secret-display-card">
        <div class="secret-row">
          <span class="secret-label">App Key</span>
          <div class="secret-value-box">
            <code class="secret-value-text">{{ secretData.app_key }}</code>
            <el-button class="copy-btn" size="small" @click="copyText(secretData.app_key)">
              <el-icon><DocumentCopy /></el-icon> 复制
            </el-button>
          </div>
        </div>
        <div class="secret-row">
          <span class="secret-label">App Secret</span>
          <div class="secret-value-box">
            <code class="secret-value-text">{{ secretData.app_secret }}</code>
            <el-button class="copy-btn" size="small" @click="copyText(secretData.app_secret)">
              <el-icon><DocumentCopy /></el-icon> 复制
            </el-button>
          </div>
        </div>
      </div>
    </el-dialog>

    <el-dialog v-model="logsDialogVisible" title="调用日志" width="700px" :fullscreen="dialogFullscreen">
      <el-table :data="callLogs" size="small" max-height="400">
        <el-table-column prop="endpoint" label="接口" min-width="200" show-overflow-tooltip />
        <el-table-column prop="method" label="方法" width="80" />
        <el-table-column prop="status" label="状态码" width="80" align="center" />
        <el-table-column prop="duration" label="耗时(ms)" width="90" align="center" />
        <el-table-column prop="ip" label="IP" width="140" />
        <el-table-column prop="created_at" label="时间" width="170">
          <template #default="{ row }">
            {{ new Date(row.created_at).toLocaleString('zh-CN') }}
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        v-if="logTotal > 20"
        style="margin-top: 12px; justify-content: flex-end"
        layout="total, prev, pager, next"
        :total="logTotal"
        :page-size="20"
        v-model:current-page="logPage"
        @current-change="loadLogs"
      />
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { openApiApi } from '@/api/open-api'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useResponsive } from '@/composables/useResponsive'

const apps = ref<any[]>([])
const loading = ref(false)
const dialogVisible = ref(false)
const secretDialogVisible = ref(false)
const logsDialogVisible = ref(false)
const editingApp = ref<any>(null)
const secretData = ref<any>({})
const callLogs = ref<any[]>([])
const logTotal = ref(0)
const logPage = ref(1)
const currentLogAppId = ref(0)
const revealedSecrets = reactive<Record<number, string>>({})
const { isMobile, dialogFullscreen } = useResponsive()

const searchKeyword = ref('')
const statusFilter = ref('')
const apiPage = ref(1)
const apiPageSize = 10

const form = ref({ name: '', scopesList: [] as string[], rate_limit: 0 })

const scopeOptions = [
  { label: '任务管理', value: 'tasks' },
  { label: '脚本管理', value: 'scripts' },
  { label: '环境变量', value: 'envs' },
  { label: '订阅管理', value: 'subscriptions' },
  { label: '日志查看', value: 'logs' },
  { label: '系统信息', value: 'system' },
  { label: '系统备份', value: 'backup' },
]

const scopeLabelMap: Record<string, string> = Object.fromEntries(scopeOptions.map(s => [s.value, s.label]))

const parseScopesTags = (scopes: string): string[] => {
  if (!scopes) return []
  return scopes.split(',').map(s => s.trim()).filter(Boolean).map(s => scopeLabelMap[s] || s)
}

const scopesToString = (list: string[]): string => list.join(',')

const stringToScopes = (str: string): string[] => {
  if (!str) return []
  return str.split(',').map(s => s.trim()).filter(Boolean)
}

const formatRateLimit = (value: number | null | undefined) => {
  return Number(value || 0) > 0 ? `${value} / 小时` : '无限制'
}

const avatarColors = ['#409eff', '#67c23a', '#e6a23c', '#f56c6c', '#909399', '#8b5cf6', '#06b6d4', '#ec4899']

const getAvatarColor = (name: string): string => {
  if (!name) return avatarColors[0]!
  let hash = 0
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash)
  return avatarColors[Math.abs(hash) % avatarColors.length]!
}

const getInitial = (name: string): string => {
  if (!name) return '?'
  return name.charAt(0).toUpperCase()
}

const maskKey = (key: string): string => {
  if (!key) return ''
  if (key.length <= 8) return key
  return key.substring(0, 3) + '***' + key.substring(key.length - 5)
}

const filteredApps = computed(() => {
  let list = apps.value
  if (statusFilter.value === 'enabled') {
    list = list.filter(a => a.enabled)
  } else if (statusFilter.value === 'disabled') {
    list = list.filter(a => !a.enabled)
  }
  if (searchKeyword.value.trim()) {
    const kw = searchKeyword.value.trim().toLowerCase()
    list = list.filter(a =>
      (a.name || '').toLowerCase().includes(kw) ||
      (a.app_key || '').toLowerCase().includes(kw)
    )
  }
  return list
})

const pagedApps = computed(() => {
  const start = (apiPage.value - 1) * apiPageSize
  return filteredApps.value.slice(start, start + apiPageSize)
})

const apiStats = computed(() => {
  const tokenCount = apps.value.length
  const totalRequests = apps.value.reduce((sum: number, a: any) => sum + (Number(a.call_count) || 0), 0)
  const rateLimits = apps.value.filter((a: any) => Number(a.rate_limit) > 0).map((a: any) => Number(a.rate_limit))
  const rateLimitDisplay = rateLimits.length > 0
    ? rateLimits.reduce((sum: number, v: number) => sum + v, 0).toLocaleString()
    : '0'
  const enabledCount = apps.value.filter((a: any) => a.enabled).length
  const successRate = tokenCount > 0
    ? ((enabledCount / tokenCount) * 100).toFixed(1) + '%'
    : '0%'
  return { tokenCount, totalRequests, rateLimitDisplay, successRate }
})

const handleSearch = () => {
  apiPage.value = 1
}

const copyText = async (text: string) => {
  if (!text) return
  try {
    await navigator.clipboard.writeText(text)
    ElMessage.success('已复制')
  } catch {
    const textarea = document.createElement('textarea')
    textarea.value = text
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand('copy')
    document.body.removeChild(textarea)
    ElMessage.success('已复制')
  }
}

const loadApps = async () => {
  loading.value = true
  try {
    const res = await openApiApi.list()
    apps.value = (res as any).data || []
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '加载应用列表失败')
  } finally {
    loading.value = false
  }
}

const showCreateDialog = () => {
  editingApp.value = null
  form.value = { name: '', scopesList: [], rate_limit: 0 }
  dialogVisible.value = true
}

const editApp = (app: any) => {
  editingApp.value = app
  form.value = { name: app.name, scopesList: stringToScopes(app.scopes || ''), rate_limit: Number(app.rate_limit || 0) }
  dialogVisible.value = true
}

const submitForm = async () => {
  if (!form.value.name) {
    ElMessage.warning('请输入应用名称')
    return
  }
  const payload = {
    name: form.value.name,
    scopes: scopesToString(form.value.scopesList),
    rate_limit: form.value.rate_limit,
  }
  try {
    if (editingApp.value) {
      await openApiApi.update(editingApp.value.id, payload)
      ElMessage.success('更新成功')
    } else {
      const res = await openApiApi.create(payload)
      secretData.value = (res as any).data || {}
      secretDialogVisible.value = true
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    loadApps()
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '操作失败')
  }
}

const viewSecret = async (app: any) => {
  try {
    const { value: password } = await ElMessageBox.prompt('请输入登录密码以查看 App Secret', '身份验证', {
      inputType: 'password',
      inputPlaceholder: '请输入密码',
      confirmButtonText: '确认',
      cancelButtonText: '取消',
    })
    if (!password) return
    const res = await openApiApi.viewSecret(app.id, password) as any
    revealedSecrets[app.id] = res.data?.app_secret || ''
  } catch (e: any) {
    if (e === 'cancel' || e?.toString() === 'cancel') return
    ElMessage.error(e?.response?.data?.error || '验证失败')
  }
}

const hideSecret = (id: number) => {
  delete revealedSecrets[id]
}

const toggleEnabled = async (app: any, val: boolean) => {
  try {
    await ElMessageBox.confirm(
      val
        ? `确认启用应用「${app.name}」吗？`
        : `确认禁用应用「${app.name}」吗？禁用后该 App Key / App Secret 将立即失效。`,
      val ? '启用确认' : '禁用确认',
      { type: val ? 'info' : 'warning' }
    )
    if (val) {
      await openApiApi.enable(app.id)
    } else {
      await openApiApi.disable(app.id)
    }
    app.enabled = val
    ElMessage.success(val ? '已启用' : '已禁用')
  } catch (err: any) {
    if (err === 'cancel' || err?.toString?.() === 'cancel') return
    ElMessage.error(err?.response?.data?.error || '操作失败')
  }
}

const resetSecret = async (app: any) => {
  try {
    await ElMessageBox.confirm('确认重置密钥？旧密钥将立即失效。', '警告', { type: 'warning' })
  } catch { return }
  try {
    const res = await openApiApi.resetSecret(app.id)
    secretData.value = (res as any).data || {}
    secretDialogVisible.value = true
    delete revealedSecrets[app.id]
    ElMessage.success('密钥已重置')
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '重置失败')
  }
}

const deleteApp = async (app: any) => {
  try {
    await ElMessageBox.confirm(`确认删除应用 "${app.name}"？`, '提示', { type: 'warning' })
  } catch { return }
  try {
    await openApiApi.delete(app.id)
    ElMessage.success('删除成功')
    loadApps()
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '删除失败')
  }
}

const showLogs = (app: any) => {
  currentLogAppId.value = app.id
  logPage.value = 1
  logsDialogVisible.value = true
  loadLogs()
}

const loadLogs = async () => {
  try {
    const res = await openApiApi.callLogs(currentLogAppId.value, {
      page: logPage.value,
      page_size: 20,
    })
    callLogs.value = (res as any).data || []
    logTotal.value = (res as any).total || 0
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '加载调用日志失败')
  }
}

onMounted(loadApps)
</script>

<style scoped lang="scss">
.open-api-page { padding: 0; }

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 18px;
  gap: 16px;

  h2 { margin: 0; font-size: 22px; font-weight: 700; color: var(--el-text-color-primary); line-height: 1.3; }
  .page-subtitle { font-size: 13px; color: var(--el-text-color-secondary); margin: 4px 0 0; }
  .header-actions { display: flex; gap: 10px; flex-shrink: 0; }
}

/* =============== Stat Section (cards + trend chart) =============== */
.stat-section {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 14px;
  margin-bottom: 18px;
}

.stat-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
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
  transition: transform 0.22s ease, box-shadow 0.22s ease;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 22px rgba(15, 23, 42, 0.08);
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
  &__sparkline {
    width: 60px;
    height: 24px;
    flex-shrink: 0;
    svg { width: 100%; height: 100%; }
  }
}

/* =============== Trend Chart Card =============== */
.trend-chart-card {
  background: var(--el-bg-color);
  border-radius: 14px;
  padding: 16px 18px;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
  border: 1px solid var(--el-border-color-lighter);
  width: 320px;
  display: flex;
  flex-direction: column;

  &__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 14px;
  }

  &__title { font-size: 14px; font-weight: 600; color: var(--el-text-color-primary); }

  &__legend { display: flex; gap: 12px; }

  &__legend-item {
    font-size: 11px;
    color: var(--el-text-color-secondary);
    display: flex;
    align-items: center;
    gap: 4px;

    .legend-dot { width: 8px; height: 8px; border-radius: 50%; }

    &--success .legend-dot { background: #409eff; }
    &--fail .legend-dot { background: #f56c6c; }
  }

  &__body { flex: 1; display: flex; align-items: flex-end; }
}

.trend-area-chart { width: 100%; height: 100%; min-height: 80px; }

.toolbar {
  display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; gap: 12px; flex-wrap: wrap;
  &__left { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; flex: 1; min-width: 0; }
  &__right { display: flex; align-items: center; gap: 8px; }
  &__search { width: 260px; }
}

.status-tabs {
  display: inline-flex; background: var(--el-fill-color-light); border-radius: 10px; padding: 3px; gap: 2px;
}

.status-tab {
  padding: 6px 14px; border-radius: 7px; border: none; background: transparent;
  color: var(--el-text-color-secondary); font-size: 13px; font-weight: 500; cursor: pointer;
  transition: all 0.18s; white-space: nowrap;
  &:hover { color: var(--el-text-color-primary); }
  &.active { background: var(--el-bg-color); color: var(--el-color-primary); box-shadow: 0 1px 2px rgba(15, 23, 42, 0.06); font-weight: 600; }
}

.table-card {
  background: var(--el-bg-color); border-radius: 14px;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04); border: 1px solid var(--el-border-color-lighter); overflow: hidden;
}

.app-name-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.app-avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-weight: 700;
  font-size: 14px;
  flex-shrink: 0;
}

.app-name-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.app-name-text { font-weight: 500; color: var(--el-text-color-primary); font-size: 14px; }
.app-name-desc { font-size: 12px; color: var(--el-text-color-placeholder); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.scope-tag { margin: 2px 4px 2px 0; }

.time-text { font-family: var(--dd-font-mono); font-size: 12px; color: var(--el-text-color-regular); }

.key-display {
  display: flex;
  align-items: center;
  gap: 6px;
}

.key-code {
  font-size: 12px;
  word-break: break-all;
  background: var(--el-fill-color-light);
  padding: 4px 8px;
  border-radius: 4px;
  border: 1px solid var(--el-border-color-lighter);
  font-family: var(--dd-font-mono);
  flex: 1;
  min-width: 0;
}

.secret-code {
  background: var(--el-color-warning-light-9);
  border-color: var(--el-color-warning-light-5);
}

.secret-mask {
  color: var(--el-text-color-placeholder);
  letter-spacing: 2px;
}

.copy-btn {
  flex-shrink: 0;
  border: 1px solid var(--el-border-color);
  background: var(--el-fill-color-blank);
  &:hover {
    color: var(--el-color-primary);
    border-color: var(--el-color-primary-light-5);
    background: var(--el-color-primary-light-9);
  }
}

:deep(.el-table) {
  --el-table-border-color: #f0f0f0;
  .el-table__header-wrapper th { border-bottom: 1px solid #e8e8e8; }
  .el-table__row td { border-bottom: 1px solid #f5f5f5; }
  .el-table__cell { padding: 12px 0; }
}

.pagination-bar {
  margin-top: 20px; display: flex; justify-content: space-between; align-items: center; padding: 0 4px;
}
.pagination-total { font-size: 13px; color: var(--el-text-color-secondary); }

.info-cards {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  margin-top: 24px;
}

.info-card {
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  border: 1px solid #f0f0f0;

  &__header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 16px;
  }

  &__icon {
    width: 40px; height: 40px; border-radius: 10px;
    display: flex; align-items: center; justify-content: center; flex-shrink: 0;
    &--blue { background: rgba(64, 158, 255, 0.1); color: #409eff; }
    &--green { background: rgba(103, 194, 58, 0.1); color: #67c23a; }
  }

  &__title {
    margin: 0;
    font-size: 15px;
    font-weight: 600;
    color: var(--el-text-color-primary);
  }

  &__list {
    margin: 0;
    padding: 0 0 0 18px;
    list-style: disc;
    li {
      font-size: 13px;
      color: var(--el-text-color-secondary);
      line-height: 2;
    }
  }
}

.secret-display-card {
  background: var(--el-fill-color-light);
  border-radius: 8px;
  padding: 20px;
  border: 1px solid var(--el-border-color-lighter);
}

.secret-row {
  &:not(:last-child) {
    margin-bottom: 16px;
    padding-bottom: 16px;
    border-bottom: 1px dashed var(--el-border-color-lighter);
  }
}

.secret-label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-secondary);
  margin-bottom: 8px;
}

.secret-value-box {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--el-fill-color-blank);
  border: 1px solid var(--el-border-color);
  border-radius: 6px;
  padding: 10px 12px;
}

.secret-value-text {
  flex: 1;
  font-size: 13px;
  font-family: var(--dd-font-mono);
  word-break: break-all;
  line-height: 1.5;
}

.open-api-card__actions > * {
  flex: 1 1 calc(50% - 4px);
}

@media screen and (max-width: 1200px) {
  .stat-section { grid-template-columns: 1fr; }
  .stat-cards { grid-template-columns: repeat(2, 1fr); }
  .trend-chart-card { width: 100%; }
  .info-cards { grid-template-columns: 1fr; }
}

@media (max-width: 768px) {
  .page-header { flex-direction: column; gap: 10px; margin-bottom: 14px; h2 { font-size: 18px; } }
  .stat-section { grid-template-columns: 1fr; }
  .stat-cards { grid-template-columns: repeat(2, 1fr); gap: 10px; }
  .stat-card { padding: 14px 16px; &__value { font-size: 22px; } &__sparkline { width: 48px; height: 20px; } }
  .trend-chart-card { width: 100%; }
  .toolbar { flex-direction: column; align-items: stretch; gap: 10px;
    &__left { flex-direction: column; gap: 10px; }
    &__search { width: 100% !important; }
    &__right { justify-content: flex-end; }
  }
  .status-tabs { width: 100%; overflow-x: auto; }
  .info-cards { grid-template-columns: 1fr; }
}
</style>
