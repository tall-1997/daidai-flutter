<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, onActivated, defineComponent, h, watch, defineAsyncComponent } from 'vue'
import { useRouter } from 'vue-router'
import { systemApi } from '@/api/system'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import {
  Timer,
  CirclePlus,
  Upload,
  Setting,
  Tickets,
  Connection,
  TrendCharts,
  CircleCheck,
  CircleClose,
  Loading,
  Refresh,
  ArrowRight,
  Cpu,
  Coin,
  FolderOpened,
  ArrowUp,
  ArrowDown,
  View,
  Document,
  More,
} from '@element-plus/icons-vue'
import { useResponsive } from '@/composables/useResponsive'
import { canAdminister, hasRequiredRole } from '@/utils/roles'

const ExecutionTrendChart = defineAsyncComponent(() => import('./components/ExecutionTrendChart.vue'))
const router = useRouter()
const authStore = useAuthStore()
const { isMobile } = useResponsive()
const LOG_STATUS_SUCCESS = 0
const LOG_STATUS_FAILED = 1
const LOG_STATUS_RUNNING = 2

const showTrendChart = ref(false)
const trendChartHostRef = ref<HTMLElement | null>(null)
let trendChartObserver: IntersectionObserver | null = null
let trendChartTimer: number | null = null

const trendRange = ref<7 | 30>(7)
const logFilter = ref<'all' | 'success' | 'failed' | 'running'>('all')
const refreshTimestamp = ref(new Date())
const hasLoadedOnce = ref(false)
const skipInitialActivated = ref(true)
const canViewSystemDetails = computed(() => canAdminister(authStore.user?.role))

const CountUp = defineComponent({
  props: {
    endVal: { type: Number, default: 0 },
    duration: { type: Number, default: 1.2 },
    decimals: { type: Number, default: 0 },
    suffix: { type: String, default: '' },
    prefix: { type: String, default: '' },
  },
  setup(props) {
    const display = ref('0')
    let animFrame = 0

    function animate() {
      const start = 0
      const end = props.endVal
      const dur = props.duration * 1000
      const startTime = performance.now()

      function step(now: number) {
        const elapsed = now - startTime
        const progress = Math.min(elapsed / dur, 1)
        const eased = 1 - Math.pow(1 - progress, 3)
        const current = start + (end - start) * eased
        display.value = formatNumber(current, props.decimals)
        if (progress < 1) {
          animFrame = requestAnimationFrame(step)
        }
      }
      cancelAnimationFrame(animFrame)
      animFrame = requestAnimationFrame(step)
    }

    function formatNumber(n: number, decimals: number) {
      const fixed = n.toFixed(decimals)
      const [intPart = '0', decPart] = fixed.split('.')
      const grouped = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ',')
      return decPart ? grouped + '.' + decPart : grouped
    }

    watch(() => props.endVal, () => animate(), { immediate: true })
    onUnmounted(() => cancelAnimationFrame(animFrame))
    return () => h('span', {}, props.prefix + display.value + props.suffix)
  }
})

const dashboardData = ref<any>({})
const sysInfo = ref<any>({})
const recentLogs = computed(() => dashboardData.value.recent_logs || [])

const greeting = computed(() => {
  const hour = new Date().getHours()
  if (hour < 6) return '夜深了'
  if (hour < 12) return '早上好'
  if (hour < 14) return '中午好'
  if (hour < 18) return '下午好'
  return '晚上好'
})

const greetingSub = computed(() => {
  const hour = new Date().getHours()
  if (hour < 6) return '夜深了，记得早点休息哦~'
  if (hour < 12) return '欢迎回来！今天又是高效执行任务的一天！'
  if (hour < 14) return '该吃午饭啦，注意劳逸结合~'
  if (hour < 18) return '下午也要保持专注哦！'
  return '辛苦一天啦，看看任务运行情况吧~'
})

const todayLogs = computed(() => Number(dashboardData.value.today_logs) || 0)
const successLogs = computed(() => Number(dashboardData.value.success_logs) || 0)
const failedLogs = computed(() => Number(dashboardData.value.failed_logs) || 0)
const taskCount = computed(() => Number(dashboardData.value.task_count) || 0)
const prevTaskCount = computed(() => Number(dashboardData.value.prev_task_count) || 0)
const runningTasks = computed(() => Number(dashboardData.value.running_tasks) || 0)
const yesterdayLogs = computed(() => Number(dashboardData.value.yesterday_logs) || 0)
const yesterdaySuccess = computed(() => Number(dashboardData.value.yesterday_success) || 0)

const todaySuccessRate = computed(() => {
  if (!todayLogs.value) return 0
  return Math.round((successLogs.value / todayLogs.value) * 1000) / 10
})

const yesterdaySuccessRate = computed(() => {
  if (!yesterdayLogs.value) return 0
  return Math.round((yesterdaySuccess.value / yesterdayLogs.value) * 1000) / 10
})

const taskCountDelta = computed(() => taskCount.value - prevTaskCount.value)
const todayLogsDelta = computed(() => todayLogs.value - yesterdayLogs.value)
const successRateDelta = computed(() => {
  return Math.round((todaySuccessRate.value - yesterdaySuccessRate.value) * 10) / 10
})

const statCards = computed(() => [
  {
    key: 'total',
    label: '任务总数',
    value: taskCount.value,
    sub: '已配置任务',
    delta: taskCountDelta.value,
    deltaSuffix: '',
    icon: Tickets,
    color: '#3b82f6',
    bgIcon: 'rgba(59, 130, 246, 0.12)',
    link: '/tasks',
  },
  {
    key: 'running',
    label: '运行中的任务',
    value: runningTasks.value,
    sub: '实时运行中',
    delta: null,
    icon: Loading,
    color: '#10b981',
    bgIcon: 'rgba(16, 185, 129, 0.12)',
    link: '/tasks',
    spinning: runningTasks.value > 0,
  },
  {
    key: 'today',
    label: '今日执行',
    value: todayLogs.value,
    sub: '较昨日',
    delta: todayLogsDelta.value,
    deltaSuffix: '',
    icon: TrendCharts,
    color: '#f59e0b',
    bgIcon: 'rgba(245, 158, 11, 0.12)',
    link: '/logs',
  },
  {
    key: 'success-rate',
    label: '成功率',
    value: todaySuccessRate.value,
    sub: '较昨日',
    delta: successRateDelta.value,
    deltaSuffix: '%',
    icon: CircleCheck,
    color: '#8b5cf6',
    bgIcon: 'rgba(139, 92, 246, 0.12)',
    link: '/logs',
    suffix: '%',
    decimals: 1,
  },
])

const quickActions = computed(() => [
  { key: 'create', label: '新建任务', icon: CirclePlus, color: '#3b82f6', bg: 'rgba(59, 130, 246, 0.1)', minRole: 'operator', action: () => router.push({ path: '/tasks', query: { create: '1' } }) },
  { key: 'import', label: '导入脚本', icon: Upload, color: '#10b981', bg: 'rgba(16, 185, 129, 0.1)', minRole: 'operator', action: () => router.push({ path: '/scripts', query: { upload: '1' } }) },
  { key: 'env', label: '环境变量', icon: Setting, color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.1)', minRole: 'operator', action: () => router.push('/envs') },
  { key: 'log', label: '执行日志', icon: Tickets, color: '#06b6d4', bg: 'rgba(6, 182, 212, 0.1)', minRole: 'viewer', action: () => router.push('/logs') },
  { key: 'api', label: '接口文档', icon: Connection, color: '#8b5cf6', bg: 'rgba(139, 92, 246, 0.1)', minRole: 'viewer', action: () => router.push('/api-docs') },
].filter(action => hasRequiredRole(authStore.user?.role, action.minRole)))

function isRunningLog(status: number | null | undefined) {
  return status === LOG_STATUS_RUNNING || status === null || status === undefined
}

function isSuccessLog(status: number | null | undefined) {
  return status === LOG_STATUS_SUCCESS
}

function isFailedLog(status: number | null | undefined) {
  return status === LOG_STATUS_FAILED
}

function normalizeLabels(labels: unknown): string[] {
  if (Array.isArray(labels)) {
    return labels.map(String).filter(Boolean)
  }
  if (typeof labels === 'string') {
    return labels.split(',').map(item => item.trim()).filter(Boolean)
  }
  return []
}

function taskTypeOf(log: any) {
  return log?.task_type || log?.task?.task_type
}

function labelsOf(log: any) {
  return normalizeLabels(log?.labels ?? log?.task?.labels)
}

const resourceItems = computed(() => {
  const s = sysInfo.value
  return [
    {
      key: 'cpu',
      label: 'CPU',
      icon: Cpu,
      iconColor: '#3b82f6',
      iconBg: 'rgba(59, 130, 246, 0.12)',
      detail: `${s.num_cpu || '-'} 核心`,
      percent: Number(s.cpu_usage) || 0,
      barColor: 'linear-gradient(90deg, #3b82f6, #60a5fa)',
    },
    {
      key: 'memory',
      label: '内存',
      icon: Coin,
      iconColor: '#8b5cf6',
      iconBg: 'rgba(139, 92, 246, 0.12)',
      detail: `${formatBytes(s.memory_used)} / ${formatBytes(s.memory_total)}`,
      percent: Number(s.memory_usage) || 0,
      barColor: 'linear-gradient(90deg, #8b5cf6, #a78bfa)',
    },
    {
      key: 'disk',
      label: '磁盘',
      icon: FolderOpened,
      iconColor: '#10b981',
      iconBg: 'rgba(16, 185, 129, 0.12)',
      detail: `${formatBytes(s.disk_used)} / ${formatBytes(s.disk_total)}`,
      percent: Number(s.disk_usage) || 0,
      barColor: 'linear-gradient(90deg, #10b981, #34d399)',
    },
  ]
})

function formatBytes(bytes: number) {
  if (!bytes) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  let i = 0
  let val = bytes
  while (val >= 1024 && i < units.length - 1) {
    val /= 1024
    i++
  }
  return val.toFixed(1) + ' ' + units[i]
}

function formatTime(t: string) {
  if (!t) return '-'
  return new Date(t).toLocaleString('zh-CN', { hour12: false })
}

function relativeTime(t: string) {
  if (!t) return '-'
  const diff = (Date.now() - new Date(t).getTime()) / 1000
  if (diff < 60) return Math.max(1, Math.floor(diff)) + ' 秒前'
  if (diff < 3600) return Math.floor(diff / 60) + ' 分钟前'
  if (diff < 86400) return Math.floor(diff / 3600) + ' 小时前'
  if (diff < 86400 * 7) return Math.floor(diff / 86400) + ' 天前'
  return new Date(t).toLocaleDateString('zh-CN')
}

function lastUpdatedText() {
  const diff = (Date.now() - refreshTimestamp.value.getTime()) / 1000
  if (diff < 60) return '刚刚'
  if (diff < 3600) return Math.floor(diff / 60) + ' 分钟前'
  return Math.floor(diff / 3600) + ' 小时前'
}

const lastUpdatedTick = ref(0)
let lastUpdatedTimer: number | null = null

const filteredLogs = computed(() => {
  const list = recentLogs.value
  if (logFilter.value === 'all') return list.slice(0, 5)
  if (logFilter.value === 'running') return list.filter((l: any) => isRunningLog(l.status)).slice(0, 5)
  if (logFilter.value === 'success') return list.filter((l: any) => isSuccessLog(l.status)).slice(0, 5)
  if (logFilter.value === 'failed') return list.filter((l: any) => isFailedLog(l.status)).slice(0, 5)
  return list.slice(0, 5)
})

const activityList = computed(() => {
  return recentLogs.value.slice(0, 6).map((log: any) => {
    const isRunning = isRunningLog(log.status)
    const isSuccess = isSuccessLog(log.status)
    return {
      id: log.id,
      title: isRunning ? '任务正在运行' : (isSuccess ? '任务执行成功' : '任务执行失败'),
      desc: log.task_name || '未命名任务',
      time: log.created_at,
      type: isRunning ? 'running' : (isSuccess ? 'success' : 'failed'),
    }
  })
})

const taskStats = computed(() => {
  const dailyStats = (dashboardData.value.daily_stats || []) as Array<{ success: number; failed: number }>
  const totalSuccess = dailyStats.reduce((sum, d) => sum + (d.success || 0), 0)
  const totalFailed = dailyStats.reduce((sum, d) => sum + (d.failed || 0), 0)
  const running = runningTasks.value
  const total = totalSuccess + totalFailed + running

  function pct(n: number) {
    if (!total) return 0
    return Math.round((n / total) * 1000) / 10
  }

  return {
    total,
    success: totalSuccess,
    failed: totalFailed,
    running,
    skipped: 0,
    successPct: pct(totalSuccess),
    failedPct: pct(totalFailed),
    runningPct: pct(running),
    skippedPct: 0,
  }
})

const avgDuration = computed(() => {
  const list = recentLogs.value
  if (!list.length) return 0
  const valid = list.filter((l: any) => l.duration != null)
  if (!valid.length) return 0
  const sum = valid.reduce((s: number, l: any) => s + (l.duration || 0), 0)
  return Math.round((sum / valid.length) * 10) / 10
})

function donutSegments() {
  const radius = 50
  const circ = 2 * Math.PI * radius
  const stats = taskStats.value
  const segs = [
    { color: '#10b981', percent: stats.successPct },
    { color: '#3b82f6', percent: stats.runningPct },
    { color: '#ef4444', percent: stats.failedPct },
    { color: '#94a3b8', percent: stats.skippedPct },
  ]
  let offset = 0
  return segs.map((s) => {
    const length = (s.percent / 100) * circ
    const dasharray = `${length} ${circ - length}`
    const dashoffset = -offset
    offset += length
    return { ...s, dasharray, dashoffset, circ }
  })
}

const loadDashboard = async () => {
  try {
    const res = await systemApi.dashboard(trendRange.value) as any
    dashboardData.value = res.data || {}
    refreshTimestamp.value = new Date()
  } catch {
    ElMessage.error('加载仪表盘数据失败')
  }
}

const loadSysInfo = async () => {
  try {
    const res = await systemApi.info() as any
    sysInfo.value = res.data || {}
  } catch {
    ElMessage.error('加载系统信息失败')
  }
}

watch(trendRange, () => {
  loadDashboard()
})

function activateTrendChart() {
  if (showTrendChart.value || trendChartTimer) return
  trendChartTimer = window.setTimeout(() => {
    showTrendChart.value = true
    trendChartTimer = null
  }, 120)
}

function stopObservingTrendChart() {
  if (trendChartObserver) {
    trendChartObserver.disconnect()
    trendChartObserver = null
  }
}

function scheduleTrendChartRender() {
  if (showTrendChart.value || !trendChartHostRef.value) return
  if (typeof window === 'undefined' || typeof IntersectionObserver === 'undefined') {
    activateTrendChart()
    return
  }
  stopObservingTrendChart()
  trendChartObserver = new IntersectionObserver((entries) => {
    if (!entries.some(e => e.isIntersecting)) return
    stopObservingTrendChart()
    activateTrendChart()
  }, { rootMargin: '160px 0px' })
  trendChartObserver.observe(trendChartHostRef.value)
}

function loadDashboardPage() {
  loadDashboard()
  loadSysInfo()
}

function handleRefresh() {
  loadDashboardPage()
}

onMounted(() => {
  loadDashboardPage()
  hasLoadedOnce.value = true
  scheduleTrendChartRender()
  lastUpdatedTimer = window.setInterval(() => {
    lastUpdatedTick.value++
  }, 30 * 1000)
})

onActivated(() => {
  if (skipInitialActivated.value) {
    skipInitialActivated.value = false
  } else if (hasLoadedOnce.value) {
    loadDashboardPage()
  }
  scheduleTrendChartRender()
})

onUnmounted(() => {
  stopObservingTrendChart()
  if (trendChartTimer) {
    clearTimeout(trendChartTimer)
    trendChartTimer = null
  }
  if (lastUpdatedTimer) {
    clearInterval(lastUpdatedTimer)
    lastUpdatedTimer = null
  }
})

const updatedHint = computed(() => {
  // 触发重新计算（通过 lastUpdatedTick）
  void lastUpdatedTick.value
  return lastUpdatedText()
})

function statusBadgeType(status: number | null | undefined) {
  if (isRunningLog(status)) return 'primary'
  if (isSuccessLog(status)) return 'success'
  return 'danger'
}

function statusBadgeText(status: number | null | undefined) {
  if (isRunningLog(status)) return '运行中'
  if (isSuccessLog(status)) return '成功'
  return '失败'
}

function triggerLabel(taskType: string | undefined) {
  switch (taskType) {
    case 'manual': return '手动执行'
    case 'startup': return '启动执行'
    default: return '定时任务'
  }
}

function envLabel(log: any) {
  const labels = labelsOf(log)
  if (labels.length > 0) return labels[0] || 'default'
  return taskTypeOf(log) === 'manual' ? 'manual' : 'cron'
}

function envBadgeColor(env: string) {
  switch (env) {
    case 'prod':
    case 'production': return { bg: 'rgba(16, 185, 129, 0.1)', color: '#10b981' }
    case 'staging': return { bg: 'rgba(245, 158, 11, 0.1)', color: '#f59e0b' }
    case 'test': return { bg: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6' }
    case 'local': return { bg: 'rgba(148, 163, 184, 0.15)', color: '#64748b' }
    case 'manual': return { bg: 'rgba(245, 158, 11, 0.1)', color: '#f59e0b' }
    case 'cron': return { bg: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6' }
    default: return { bg: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6' }
  }
}

function viewLog(log: any) {
  router.push({ path: '/logs', query: { task_id: log.task_id } })
}

function rerunLog(log: any) {
  router.push({ path: '/tasks', query: { task_id: log.task_id, action: 'run' } })
}
</script>

<template>
  <div class="dashboard-page dd-scroll-page">
    <!-- ============ Hero: Welcome banner + Quick actions ============ -->
    <section class="hero-row">
      <div class="hero-banner">
        <div class="hero-banner__bg">
          <span class="hero-banner__bubble bubble-1"></span>
          <span class="hero-banner__bubble bubble-2"></span>
          <span class="hero-banner__bubble bubble-3"></span>
        </div>
        <div class="hero-banner__content">
          <h2 class="hero-banner__title">
            {{ greeting }}，{{ authStore.user?.username || 'User' }}
            <span class="wave-emoji">👋</span>
          </h2>
          <p class="hero-banner__sub">{{ greetingSub }}</p>
        </div>
        <div class="hero-banner__art">
          <svg viewBox="0 0 220 140" fill="none" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <linearGradient id="screenG" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0%" stop-color="#ffffff" stop-opacity="0.95" />
                <stop offset="100%" stop-color="#ffffff" stop-opacity="0.55" />
              </linearGradient>
              <linearGradient id="chartG" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="#a78bfa" />
                <stop offset="100%" stop-color="#7c3aed" />
              </linearGradient>
            </defs>
            <!-- 行星圆环 -->
            <ellipse cx="160" cy="38" rx="48" ry="9" stroke="rgba(255,255,255,0.4)" stroke-width="1.4" fill="none" />
            <circle cx="160" cy="38" r="14" fill="#fbbf24" />
            <circle cx="160" cy="38" r="14" fill="url(#chartG)" opacity="0.4" />
            <!-- 主屏幕 -->
            <rect x="58" y="34" width="92" height="68" rx="8" fill="url(#screenG)" stroke="rgba(255,255,255,0.7)" stroke-width="1.5" />
            <rect x="65" y="42" width="32" height="6" rx="3" fill="#a78bfa" opacity="0.85" />
            <rect x="65" y="52" width="48" height="4" rx="2" fill="#c4b5fd" opacity="0.7" />
            <rect x="65" y="60" width="36" height="4" rx="2" fill="#c4b5fd" opacity="0.55" />
            <!-- 折线图 -->
            <polyline points="65,90 78,80 91,86 104,72 117,78 130,68 143,74"
                      stroke="#7c3aed" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round" />
            <circle cx="143" cy="74" r="2.4" fill="#7c3aed" />
            <!-- 火箭 -->
            <g transform="translate(28 64) rotate(-22)">
              <path d="M0 14 L10 0 L18 4 L18 22 L10 26 Z" fill="#ffffff" opacity="0.92" />
              <circle cx="11" cy="10" r="2.2" fill="#7c3aed" />
              <path d="M2 22 L-3 30 L4 26 Z" fill="#fbbf24" opacity="0.85" />
            </g>
            <!-- 装饰小气泡 -->
            <circle cx="28" cy="32" r="3" fill="rgba(255,255,255,0.7)" />
            <circle cx="200" cy="100" r="4" fill="rgba(255,255,255,0.55)" />
            <circle cx="190" cy="86" r="2" fill="rgba(255,255,255,0.85)" />
            <!-- 文档卡 -->
            <rect x="160" y="78" width="34" height="26" rx="4" fill="#ffffff" opacity="0.92" />
            <rect x="164" y="84" width="20" height="3" rx="1.5" fill="#a78bfa" opacity="0.7" />
            <rect x="164" y="90" width="16" height="3" rx="1.5" fill="#c4b5fd" opacity="0.6" />
            <rect x="164" y="96" width="12" height="3" rx="1.5" fill="#c4b5fd" opacity="0.6" />
          </svg>
        </div>
      </div>

      <div class="hero-quick">
        <div class="hero-quick__header">
          <span class="hero-quick__title">快捷操作</span>
        </div>
        <div class="hero-quick__grid">
          <button
            v-for="action in quickActions"
            :key="action.key"
            class="quick-tile"
            @click="action.action"
          >
            <span class="quick-tile__icon" :style="{ background: action.bg, color: action.color }">
              <el-icon :size="18"><component :is="action.icon" /></el-icon>
            </span>
            <span class="quick-tile__label">{{ action.label }}</span>
          </button>
        </div>
      </div>
    </section>

    <!-- ============ 4 Stat Cards ============ -->
    <section class="stat-grid">
      <div
        v-for="card in statCards"
        :key="card.key"
        class="stat-card"
        @click="router.push(card.link)"
      >
        <div class="stat-card__main">
          <span class="stat-card__label">{{ card.label }}</span>
          <span class="stat-card__value" :style="{ color: card.color }">
            <CountUp :end-val="card.value" :duration="1.2" :decimals="card.decimals || 0" :suffix="card.suffix || ''" />
          </span>
          <span class="stat-card__delta">
            <template v-if="card.delta !== null && card.delta !== undefined">
              <span class="stat-card__delta-prefix">{{ card.sub }}</span>
              <span
                v-if="card.delta === 0"
                class="stat-card__delta-value is-flat"
              >持平</span>
              <span
                v-else
                class="stat-card__delta-value"
                :class="card.delta > 0 ? 'is-up' : 'is-down'"
              >
                <el-icon :size="11">
                  <component :is="card.delta > 0 ? ArrowUp : ArrowDown" />
                </el-icon>
                {{ card.delta > 0 ? '+' : '' }}{{ card.delta }}{{ card.deltaSuffix || '' }}
              </span>
            </template>
            <template v-else>
              <span class="stat-card__delta-prefix">{{ card.sub }}</span>
            </template>
          </span>
        </div>
        <div class="stat-card__icon" :style="{ background: card.bgIcon, color: card.color }">
          <el-icon :size="20" :class="{ 'icon-spin': card.spinning }">
            <component :is="card.icon" />
          </el-icon>
        </div>
      </div>
    </section>

    <!-- ============ Middle row: Trend / Resources / Activity ============ -->
    <section class="middle-grid">
      <!-- 执行趋势 -->
      <div class="panel panel--trend">
        <div class="panel-header">
          <div class="panel-header__title">
            <el-icon class="panel-header__icon" :size="14" style="color: #3b82f6"><TrendCharts /></el-icon>
            <span>执行趋势</span>
          </div>
          <div class="panel-header__actions">
            <div class="seg-btn-group">
              <button
                class="seg-btn"
                :class="{ 'is-active': trendRange === 7 }"
                @click="trendRange = 7"
              >近7天</button>
              <button
                class="seg-btn"
                :class="{ 'is-active': trendRange === 30 }"
                @click="trendRange = 30"
              >近30天</button>
            </div>
          </div>
        </div>
        <div ref="trendChartHostRef" class="trend-chart-shell">
          <ExecutionTrendChart v-if="showTrendChart" :stats="dashboardData.daily_stats || []" />
          <div v-else class="trend-chart-placeholder">
            <div class="placeholder-bar"></div>
            <div class="placeholder-bar placeholder-bar--short"></div>
            <div class="placeholder-legend"><span></span><span></span><span></span></div>
          </div>
        </div>
      </div>

      <!-- 系统资源 -->
      <div class="panel panel--resource">
        <div class="panel-header">
          <div class="panel-header__title">
            <el-icon class="panel-header__icon" :size="14" style="color: #10b981"><Cpu /></el-icon>
            <span>系统资源</span>
            <span class="panel-header__hint">最近更新：{{ updatedHint }}</span>
          </div>
          <div v-if="canViewSystemDetails" class="panel-header__actions">
            <button class="text-link" @click="router.push('/admin/settings')">
              查看详情 <el-icon :size="11"><ArrowRight /></el-icon>
            </button>
          </div>
        </div>
        <div class="resource-list">
          <div v-for="r in resourceItems" :key="r.key" class="resource-row">
            <div class="resource-row__icon" :style="{ background: r.iconBg, color: r.iconColor }">
              <el-icon :size="16"><component :is="r.icon" /></el-icon>
            </div>
            <div class="resource-row__body">
              <div class="resource-row__top">
                <span class="resource-row__label">{{ r.label }}</span>
                <span class="resource-row__detail">{{ r.detail }}</span>
                <span class="resource-row__pct">{{ r.percent.toFixed(1) }}%</span>
              </div>
              <div class="resource-bar">
                <div class="resource-bar__fill" :style="{ width: Math.min(r.percent, 100) + '%', background: r.barColor }"></div>
              </div>
            </div>
          </div>
          <div class="resource-row">
            <div class="resource-row__icon" style="background: rgba(245, 158, 11, 0.12); color: #f59e0b">
              <el-icon :size="16"><Timer /></el-icon>
            </div>
            <div class="resource-row__body">
              <div class="resource-row__top">
                <span class="resource-row__label">面板运行</span>
                <span class="resource-row__detail uptime-detail">{{ sysInfo.uptime || '-' }}</span>
              </div>
              <div class="uptime-track">
                <span class="uptime-track__dot"></span>
                <span class="uptime-track__line"></span>
                <span class="uptime-track__text">自本次面板启动后持续运行</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 最近活动 -->
      <div class="panel panel--activity">
        <div class="panel-header">
          <div class="panel-header__title">
            <el-icon class="panel-header__icon" :size="14" style="color: #f59e0b"><Refresh /></el-icon>
            <span>最近活动</span>
          </div>
          <div class="panel-header__actions">
            <button class="text-link" @click="router.push('/logs')">
              查看全部 <el-icon :size="11"><ArrowRight /></el-icon>
            </button>
          </div>
        </div>
        <div class="activity-feed">
          <div v-if="activityList.length === 0" class="empty-hint">暂无活动</div>
          <div
            v-for="(act, idx) in activityList"
            :key="act.id || idx"
            class="activity-item"
          >
            <span class="activity-item__icon" :class="`is-${act.type}`">
              <el-icon :size="12">
                <component :is="act.type === 'success' ? CircleCheck : (act.type === 'failed' ? CircleClose : Loading)" />
              </el-icon>
            </span>
            <div class="activity-item__body">
              <span class="activity-item__title">{{ act.title }}</span>
              <span class="activity-item__desc">{{ act.desc }}</span>
            </div>
            <span class="activity-item__time">{{ relativeTime(act.time) }}</span>
          </div>
        </div>
      </div>
    </section>

    <!-- ============ Bottom row: Recent task table / Task stats ring ============ -->
    <section class="bottom-grid">
      <!-- 最近执行任务 -->
      <div class="panel panel--logs">
        <div class="panel-header">
          <div class="panel-header__title">
            <el-icon class="panel-header__icon" :size="14" style="color: #8b5cf6"><Document /></el-icon>
            <span>最近执行任务</span>
            <div class="seg-btn-group seg-btn-group--mini">
              <button
                v-for="opt in [{label:'全部',value:'all'},{label:'成功',value:'success'},{label:'失败',value:'failed'},{label:'运行中',value:'running'}]"
                :key="opt.value"
                class="seg-btn"
                :class="{ 'is-active': logFilter === opt.value }"
                @click="logFilter = opt.value as any"
              >{{ opt.label }}</button>
            </div>
          </div>
          <div class="panel-header__actions">
            <button class="text-link" @click="router.push('/logs')">
              查看更多 <el-icon :size="11"><ArrowRight /></el-icon>
            </button>
          </div>
        </div>
        <div v-if="isMobile" class="log-mobile-list">
          <div v-if="filteredLogs.length === 0" class="empty-hint">暂无记录</div>
          <div v-for="log in filteredLogs" :key="log.id" class="log-mobile-card">
            <div class="log-mobile-card__head">
              <span class="log-mobile-card__name">{{ log.task_name || '未命名任务' }}</span>
              <span class="log-status-chip" :class="`is-${statusBadgeType(log.status)}`">
                {{ statusBadgeText(log.status) }}
              </span>
            </div>
            <div class="log-mobile-card__meta">
              <span>{{ formatTime(log.created_at) }}</span>
              <span v-if="log.duration != null">耗时 {{ log.duration.toFixed(1) }}s</span>
            </div>
          </div>
        </div>
        <table v-else class="log-table">
          <colgroup>
            <col class="log-table__col log-table__col--name" />
            <col class="log-table__col log-table__col--status" />
            <col class="log-table__col log-table__col--time" />
            <col class="log-table__col log-table__col--duration" />
            <col class="log-table__col log-table__col--trigger" />
            <col class="log-table__col log-table__col--env" />
            <col class="log-table__col log-table__col--actions" />
          </colgroup>
          <thead>
            <tr>
              <th>任务名称</th>
              <th class="col-center">状态</th>
              <th>执行时间</th>
              <th class="col-center">耗时</th>
              <th class="col-center">触发方式</th>
              <th class="col-center">环境</th>
              <th class="col-center">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="filteredLogs.length === 0">
              <td colspan="7" class="empty-cell">暂无记录</td>
            </tr>
            <tr v-for="log in filteredLogs" :key="log.id">
              <td>
                <span class="log-cell-name">{{ log.task_name || '未命名任务' }}</span>
              </td>
              <td class="col-center">
                <span class="log-status-chip" :class="`is-${statusBadgeType(log.status)}`">
                  {{ statusBadgeText(log.status) }}
                </span>
              </td>
              <td><span class="log-cell-time">{{ formatTime(log.created_at) }}</span></td>
              <td class="col-center"><span class="log-cell-duration">{{ log.duration != null ? log.duration.toFixed(1) + 's' : '-' }}</span></td>
              <td class="col-center"><span class="log-cell-trigger">{{ triggerLabel(taskTypeOf(log)) }}</span></td>
              <td class="col-center">
                <span
                  class="env-chip"
                  :style="{ background: envBadgeColor(envLabel(log)).bg, color: envBadgeColor(envLabel(log)).color }"
                >{{ envLabel(log) }}</span>
              </td>
              <td class="col-center">
                <div class="log-cell-actions">
                  <button class="icon-btn" title="查看日志" @click="viewLog(log)">
                    <el-icon :size="14"><View /></el-icon>
                  </button>
                  <button class="icon-btn" title="重新运行" @click="rerunLog(log)">
                    <el-icon :size="14"><Refresh /></el-icon>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 任务统计 -->
      <div class="panel panel--stats">
        <div class="panel-header">
          <div class="panel-header__title">
            <el-icon class="panel-header__icon" :size="14" style="color: #ec4899"><TrendCharts /></el-icon>
            <span>任务统计</span>
            <span class="panel-header__hint">近{{ trendRange }}天</span>
          </div>
          <div class="panel-header__actions">
            <button class="text-link" @click="router.push('/logs')">
              查看更多 <el-icon :size="11"><ArrowRight /></el-icon>
            </button>
          </div>
        </div>
        <div class="task-stats-body">
          <div class="task-donut">
            <svg viewBox="0 0 140 140">
              <circle cx="70" cy="70" r="50" fill="none" stroke="var(--el-fill-color)" stroke-width="14" />
              <circle
                v-for="(seg, idx) in donutSegments()"
                :key="idx"
                cx="70" cy="70" r="50" fill="none"
                :stroke="seg.color"
                stroke-width="14"
                stroke-linecap="round"
                :stroke-dasharray="seg.dasharray"
                :stroke-dashoffset="seg.dashoffset"
                transform="rotate(-90 70 70)"
                style="transition: stroke-dasharray 0.6s ease, stroke-dashoffset 0.6s ease"
              />
            </svg>
            <div class="task-donut__center">
              <span class="task-donut__value">
                <CountUp :end-val="taskStats.total" :duration="1.2" />
              </span>
              <span class="task-donut__label">总任务数</span>
            </div>
          </div>
          <div class="task-legend">
            <div class="legend-row">
              <span class="legend-row__dot" style="background: #10b981"></span>
              <span class="legend-row__label">成功</span>
              <span class="legend-row__value">{{ taskStats.success.toLocaleString() }}</span>
              <span class="legend-row__pct">({{ taskStats.successPct }}%)</span>
            </div>
            <div class="legend-row">
              <span class="legend-row__dot" style="background: #ef4444"></span>
              <span class="legend-row__label">失败</span>
              <span class="legend-row__value">{{ taskStats.failed.toLocaleString() }}</span>
              <span class="legend-row__pct">({{ taskStats.failedPct }}%)</span>
            </div>
            <div class="legend-row">
              <span class="legend-row__dot" style="background: #3b82f6"></span>
              <span class="legend-row__label">运行中</span>
              <span class="legend-row__value">{{ taskStats.running.toLocaleString() }}</span>
              <span class="legend-row__pct">({{ taskStats.runningPct }}%)</span>
            </div>
            <div class="legend-row">
              <span class="legend-row__dot" style="background: #94a3b8"></span>
              <span class="legend-row__label">跳过</span>
              <span class="legend-row__value">{{ taskStats.skipped.toLocaleString() }}</span>
              <span class="legend-row__pct">({{ taskStats.skippedPct }}%)</span>
            </div>
          </div>
        </div>
        <div class="task-stats-footer">
          <span class="task-stats-footer__label">平均执行时长</span>
          <span class="task-stats-footer__value">{{ avgDuration }}s</span>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped lang="scss">
.dashboard-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

// ============ Hero ============
.hero-row {
  display: grid;
  grid-template-columns: 1fr 360px;
  gap: 16px;
}

.hero-banner {
  position: relative;
  border-radius: 16px;
  padding: 22px 26px;
  overflow: hidden;
  contain: layout paint;
  background: linear-gradient(135deg, #ede9fe 0%, #e0e7ff 50%, #dbeafe 100%);
  border: 1px solid rgba(139, 92, 246, 0.12);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  min-height: 130px;
}

.hero-banner__bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
  // 把 blur 装饰层提升为独立合成层，浏览器只在初始时计算一次 blur，
  // 后续 hover / 滚动等交互不再触发昂贵的重绘。
  transform: translateZ(0);
}

.hero-banner__bubble {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.45);
  filter: blur(18px);

  &.bubble-1 { width: 120px; height: 120px; top: -40px; left: 30%; }
  &.bubble-2 { width: 80px; height: 80px; bottom: -20px; left: 60%; background: rgba(167, 139, 250, 0.35); }
  &.bubble-3 { width: 60px; height: 60px; top: 30%; right: 4%; background: rgba(96, 165, 250, 0.35); }
}

.hero-banner__content {
  position: relative;
  z-index: 1;
  flex: 1;
  min-width: 0;
}

.hero-banner__title {
  margin: 0;
  font-size: 22px;
  font-weight: 700;
  color: #1e293b;
  line-height: 1.3;
  display: flex;
  align-items: center;
  gap: 6px;
}

.wave-emoji {
  display: inline-block;
  animation: wave 1.6s ease-in-out 0.4s 2;
  transform-origin: 70% 70%;
}

@keyframes wave {
  0%, 100% { transform: rotate(0deg); }
  20% { transform: rotate(14deg); }
  40% { transform: rotate(-10deg); }
  60% { transform: rotate(12deg); }
  80% { transform: rotate(-4deg); }
}

.hero-banner__sub {
  margin: 8px 0 0;
  font-size: 14px;
  color: rgba(30, 41, 59, 0.7);
  line-height: 1.5;
}

.hero-banner__art {
  position: relative;
  z-index: 1;
  width: 220px;
  height: 140px;
  flex-shrink: 0;
}

.hero-banner__art svg {
  width: 100%;
  height: 100%;
}

.hero-quick {
  border-radius: 16px;
  padding: 16px 18px 12px;
  background: var(--el-bg-color);
  border: 1px solid var(--el-border-color-lighter);
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.hero-quick__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.hero-quick__title {
  font-size: 14px;
  font-weight: 700;
  color: var(--el-text-color-primary);
}

.hero-quick__grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 6px;
}

.quick-tile {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 8px 4px;
  border: none;
  background: transparent;
  border-radius: 10px;
  cursor: pointer;
  transition: background 0.18s;

  &:hover {
    background: var(--el-fill-color-light);
  }
}

.quick-tile__icon {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.quick-tile__label {
  font-size: 12px;
  color: var(--el-text-color-regular);
  font-weight: 500;
  white-space: nowrap;
}

// ============ Stat Grid ============
.stat-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

.stat-card {
  background: var(--el-bg-color);
  border: 1px solid var(--el-border-color-lighter);
  border-radius: 14px;
  padding: 16px 18px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  cursor: pointer;
  transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);

  &:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 22px rgba(15, 23, 42, 0.08);
    border-color: var(--el-border-color);
  }
}

.stat-card__main {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.stat-card__label {
  font-size: 13px;
  color: var(--el-text-color-secondary);
  font-weight: 500;
}

.stat-card__value {
  font-size: 26px;
  font-weight: 700;
  line-height: 1.15;
  font-family: 'Inter', var(--dd-font-ui), -apple-system, 'PingFang SC', 'Microsoft YaHei', sans-serif;
  font-variant-numeric: tabular-nums;
  -webkit-font-smoothing: antialiased;
  letter-spacing: -0.01em;
}

.stat-card__delta {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: var(--el-text-color-placeholder);
  flex-wrap: wrap;
}

.stat-card__delta-prefix {
  color: var(--el-text-color-placeholder);
}

.stat-card__delta-value {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 6px;

  &.is-up {
    color: #10b981;
    background: rgba(16, 185, 129, 0.1);
  }

  &.is-down {
    color: #ef4444;
    background: rgba(239, 68, 68, 0.1);
  }

  &.is-flat {
    color: var(--el-text-color-secondary);
    background: var(--el-fill-color);
    padding: 1px 8px;
  }
}

.stat-card__icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.icon-spin {
  animation: spin 2.4s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

// ============ Middle Grid ============
.middle-grid {
  display: grid;
  grid-template-columns: 1.5fr 1.2fr 1fr;
  gap: 16px;
  align-items: stretch;
}

.bottom-grid {
  display: grid;
  grid-template-columns: 2.4fr 1fr;
  gap: 16px;
}

.panel {
  background: var(--el-bg-color);
  border: 1px solid var(--el-border-color-lighter);
  border-radius: 14px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 14px 18px;
  border-bottom: 1px solid var(--el-border-color-lighter);
}

.panel-header__title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  flex-wrap: wrap;
}

.panel-header__icon {
  flex-shrink: 0;
}

.panel-header__hint {
  font-size: 11px;
  font-weight: 400;
  color: var(--el-text-color-placeholder);
}

.panel-header__actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.text-link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  border: none;
  background: transparent;
  cursor: pointer;
  color: var(--el-color-primary);
  font-size: 12px;
  padding: 4px 6px;
  border-radius: 6px;
  transition: background 0.15s;

  &:hover {
    background: var(--el-color-primary-light-9);
  }
}

.seg-btn-group {
  display: inline-flex;
  background: var(--el-fill-color-light);
  border-radius: 8px;
  padding: 2px;
  gap: 2px;

  &--mini {
    margin-left: 8px;
  }
}

.seg-btn {
  border: none;
  background: transparent;
  padding: 4px 10px;
  font-size: 12px;
  border-radius: 6px;
  cursor: pointer;
  color: var(--el-text-color-secondary);
  transition: all 0.18s;

  &:hover {
    color: var(--el-text-color-primary);
  }

  &.is-active {
    background: var(--el-bg-color);
    color: var(--el-color-primary);
    font-weight: 600;
    box-shadow: 0 1px 2px rgba(15, 23, 42, 0.06);
  }
}

// ============ Trend Chart ============
.trend-chart-shell {
  flex: 1;
  min-height: 240px;
  padding: 8px 10px 12px;
}

.trend-chart-placeholder {
  height: 240px;
  border-radius: 10px;
  padding: 18px;
  background: linear-gradient(180deg, rgba(64, 158, 255, 0.04), transparent);
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  gap: 14px;
}

.placeholder-bar {
  height: 8px;
  border-radius: 999px;
  background: linear-gradient(90deg, rgba(59, 130, 246, 0.15), rgba(16, 185, 129, 0.08));
  animation: placeholderPulse 1.6s ease-in-out infinite;
}

.placeholder-bar--short {
  width: 65%;
  animation-delay: 0.12s;
}

.placeholder-legend {
  display: flex;
  gap: 10px;
}

.placeholder-legend span {
  width: 48px;
  height: 6px;
  border-radius: 999px;
  background: rgba(140, 140, 140, 0.12);
}

@keyframes placeholderPulse {
  0%, 100% { opacity: 0.5; }
  50% { opacity: 1; }
}

// ============ Resource ============
.resource-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 16px 18px;
}

.resource-row {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.resource-row__icon {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.resource-row__body {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.resource-row__top {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  flex-wrap: wrap;
}

.resource-row__label {
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.resource-row__detail {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  flex: 1;
  display: inline-flex;
  align-items: center;
  gap: 2px;
}

.resource-row__pct {
  font-size: 13px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  font-family: 'Inter', var(--dd-font-ui), sans-serif;
  font-variant-numeric: tabular-nums;
  -webkit-font-smoothing: antialiased;
}

.resource-bar {
  height: 6px;
  border-radius: 999px;
  background: var(--el-fill-color);
  overflow: hidden;
}

.resource-bar__fill {
  height: 100%;
  border-radius: 999px;
  transition: width 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

.uptime-detail {
  font-family: 'Inter', var(--dd-font-ui), sans-serif;
  font-variant-numeric: tabular-nums;
  font-weight: 700;
  color: #f59e0b;
}

.uptime-track {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
  color: var(--el-text-color-placeholder);
  font-size: 11.5px;
}

.uptime-track__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #f59e0b;
  box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.14);
  flex-shrink: 0;
}

.uptime-track__line {
  height: 6px;
  flex: 1;
  border-radius: 999px;
  background: linear-gradient(90deg, rgba(245, 158, 11, 0.35), rgba(245, 158, 11, 0.08));
  overflow: hidden;
}

.uptime-track__text {
  flex-shrink: 0;
  white-space: nowrap;
}

// ============ Activity ============
.activity-feed {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 8px 14px 12px;
  gap: 4px;
  max-height: 320px;
  overflow-y: auto;
}

.activity-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 10px 6px;
  border-radius: 10px;
  transition: background 0.15s;

  &:hover {
    background: var(--el-fill-color-light);
  }
}

.activity-item__icon {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin-top: 1px;

  &.is-success { background: rgba(16, 185, 129, 0.12); color: #10b981; }
  &.is-failed { background: rgba(239, 68, 68, 0.12); color: #ef4444; }
  &.is-running { background: rgba(59, 130, 246, 0.12); color: #3b82f6; }
}

.activity-item__body {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.activity-item__title {
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-primary);
  line-height: 1.3;
}

.activity-item__desc {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.activity-item__time {
  flex-shrink: 0;
  font-size: 11px;
  color: var(--el-text-color-placeholder);
  margin-top: 3px;
}

// ============ Recent Logs Table ============
.log-table {
  width: 100%;
  table-layout: fixed;
  border-collapse: separate;
  border-spacing: 0;
  font-size: 13px;

  &__col--name { width: 19%; }
  &__col--status { width: 9%; }
  &__col--time { width: 18%; }
  &__col--duration { width: 10%; }
  &__col--trigger { width: 14%; }
  &__col--env { width: 16%; }
  &__col--actions { width: 14%; }

  thead {
    background: var(--el-fill-color-light);
  }

  th {
    text-align: left;
    font-weight: 600;
    font-size: 12px;
    color: var(--el-text-color-secondary);
    padding: 12px 16px;
    border-bottom: 1px solid var(--el-border-color-lighter);
    white-space: nowrap;
    line-height: 1.25;
  }

  tbody tr {
    transition: background 0.15s;

    &:hover {
      background: var(--el-fill-color-light);
    }
  }

  td {
    padding: 12px 16px;
    border-bottom: 1px solid var(--el-border-color-lighter);
    color: var(--el-text-color-primary);
    vertical-align: middle;
    line-height: 1.35;
  }

  tbody tr:last-child td {
    border-bottom: none;
  }
}

.log-table .col-center {
  text-align: center;
}

.empty-cell {
  text-align: center;
  padding: 28px;
  color: var(--el-text-color-placeholder);
  font-size: 13px;
}

.empty-hint {
  text-align: center;
  padding: 28px;
  color: var(--el-text-color-placeholder);
  font-size: 13px;
}

.log-cell-name {
  display: block;
  font-weight: 500;
  color: var(--el-text-color-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.log-cell-time,
.log-cell-duration {
  display: inline-block;
  min-width: 0;
  font-size: 12.5px;
  color: var(--el-text-color-secondary);
  font-family: 'Inter', var(--dd-font-ui), sans-serif;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.log-cell-trigger {
  display: inline-block;
  max-width: 100%;
  font-size: 12.5px;
  color: var(--el-text-color-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.log-status-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 44px;
  padding: 2px 10px;
  border-radius: 999px;
  font-size: 11.5px;
  font-weight: 600;
  line-height: 1.4;

  &.is-success {
    background: rgba(16, 185, 129, 0.12);
    color: #10b981;
  }

  &.is-danger {
    background: rgba(239, 68, 68, 0.12);
    color: #ef4444;
  }

  &.is-primary {
    background: rgba(59, 130, 246, 0.12);
    color: #3b82f6;
  }
}

.env-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  max-width: 100%;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
  font-family: 'Inter', var(--dd-font-ui), sans-serif;
  letter-spacing: 0.02em;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.log-cell-actions {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 2px;
}

.icon-btn {
  width: 26px;
  height: 26px;
  border-radius: 6px;
  border: none;
  background: transparent;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: var(--el-text-color-placeholder);
  transition: all 0.15s;

  &:hover {
    background: var(--el-fill-color);
    color: var(--el-color-primary);
  }
}

.log-mobile-list {
  padding: 8px 14px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.log-mobile-card {
  border: 1px solid var(--el-border-color-lighter);
  border-radius: 10px;
  padding: 10px 12px;
  background: var(--el-fill-color-light);
}

.log-mobile-card__head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.log-mobile-card__name {
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.log-mobile-card__meta {
  display: flex;
  gap: 12px;
  font-size: 11.5px;
  color: var(--el-text-color-secondary);
}

// ============ Task Stats ============
.task-stats-body {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 18px;
}

.task-donut {
  position: relative;
  width: 130px;
  height: 130px;
  flex-shrink: 0;

  svg { width: 100%; height: 100%; }
}

.task-donut__center {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
}

.task-donut__value {
  font-size: 22px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  font-family: 'Inter', var(--dd-font-ui), sans-serif;
  font-variant-numeric: tabular-nums;
  -webkit-font-smoothing: antialiased;
  letter-spacing: -0.01em;
}

.task-donut__label {
  font-size: 11px;
  color: var(--el-text-color-placeholder);
}

.task-legend {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.legend-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
}

.legend-row__dot {
  width: 8px;
  height: 8px;
  border-radius: 2px;
  flex-shrink: 0;
}

.legend-row__label {
  flex: 1;
  color: var(--el-text-color-regular);
}

.legend-row__value {
  font-weight: 700;
  color: var(--el-text-color-primary);
  font-family: 'Inter', var(--dd-font-ui), sans-serif;
  font-variant-numeric: tabular-nums;
}

.legend-row__pct {
  font-size: 11.5px;
  color: var(--el-text-color-placeholder);
}

.task-stats-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 18px;
  border-top: 1px solid var(--el-border-color-lighter);
  font-size: 12.5px;
}

.task-stats-footer__label {
  color: var(--el-text-color-secondary);
}

.task-stats-footer__value {
  font-weight: 700;
  color: var(--el-color-primary);
  font-family: 'Inter', var(--dd-font-ui), sans-serif;
  font-variant-numeric: tabular-nums;
  font-size: 13.5px;
}

// ============ Responsive ============
@media (max-width: 1280px) {
  .hero-row { grid-template-columns: 1fr; }
  .hero-banner__art { width: 180px; height: 110px; }
  .middle-grid { grid-template-columns: 1.4fr 1fr; }
  .panel--activity { grid-column: 1 / -1; }
  .bottom-grid { grid-template-columns: 1fr; }
}

@media (max-width: 960px) {
  .stat-grid { grid-template-columns: repeat(2, 1fr); }
  .middle-grid { grid-template-columns: 1fr; }
  .hero-quick__grid { grid-template-columns: repeat(5, 1fr); }
}

@media (max-width: 768px) {
  .hero-banner { padding: 16px 18px; min-height: auto; }
  .hero-banner__title { font-size: 18px; }
  .hero-banner__sub { font-size: 13px; }
  .hero-banner__art { display: none; }

  .hero-quick__grid { grid-template-columns: repeat(5, 1fr); gap: 4px; }
  .quick-tile__icon { width: 34px; height: 34px; }
  .quick-tile__label { font-size: 11px; }

  .stat-grid { gap: 10px; }
  .stat-card { padding: 14px; }
  .stat-card__value { font-size: 22px; }
  .stat-card__icon { width: 38px; height: 38px; }

  .panel-header { padding: 12px 14px; flex-wrap: wrap; }
  .panel-header__title { font-size: 13px; flex-wrap: wrap; }
  .seg-btn-group--mini { margin-left: 0; margin-top: 4px; }

  .resource-list { padding: 14px; }
  .resource-row__top { gap: 6px; }

  .task-stats-body { flex-direction: column; gap: 16px; padding: 16px; }
  .task-donut { width: 120px; height: 120px; }
  .task-legend { width: 100%; }
}
</style>
