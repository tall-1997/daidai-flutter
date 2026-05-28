<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, nextTick, computed, watch, type CSSProperties } from 'vue'
import { envApi } from '@/api/env'
import { configScriptApi } from '@/api/system'
import { ElMessage, ElMessageBox } from 'element-plus'
import { copyText } from '@/utils/clipboard'
import EnvBatchGroupDialog from './components/EnvBatchGroupDialog.vue'
import EnvBatchRenameDialog from './components/EnvBatchRenameDialog.vue'
import EnvEditDialog from './components/EnvEditDialog.vue'
import EnvImportDialog from './components/EnvImportDialog.vue'
import { useResponsive } from '@/composables/useResponsive'

const envTableDensityStorageKey = 'daidai-env-table-density'
const envPageSizeStorageKey = 'daidai-env-page-size'
const envAllFetchBatchSize = 100
const { isMobile } = useResponsive()

type EnvPageSizeSelection = '20' | '50' | '100' | 'all'

type EnvFormModel = {
  id: number
  name: string
  value: string
  remarks: string
  group?: string
  groups: string[]
}

const envList = ref<any[]>([])
const loading = ref(true)
const total = ref(0)
const page = ref(1)
const initialPageSizeSelection = readEnvPageSizeSelection()
const pageSizeSelection = ref<EnvPageSizeSelection>(initialPageSizeSelection)
const pageSize = ref(initialPageSizeSelection === 'all' ? envAllFetchBatchSize : Number(initialPageSizeSelection))
const keyword = ref('')
const groupFilters = ref<string[]>([])
const groups = ref<string[]>([])
const selectedIds = ref<number[]>([])
const selectedIdSet = computed(() => new Set(selectedIds.value))
const selectedCountInCurrentPage = computed(() =>
  envList.value.filter((item) => selectedIdSet.value.has(item.id)).length
)
const showAllEnvs = computed(() => pageSizeSelection.value === 'all')
const pinnedCountInCurrentPage = computed(() =>
  envList.value.filter((item) => isTopPinned(item)).length
)
const currentPageOffset = computed(() => (showAllEnvs.value ? 0 : (page.value - 1) * pageSize.value))
const statusFilter = ref<'' | 'enabled' | 'disabled'>('')
const showFooterBar = computed(() => total.value > 0 || selectedCountInCurrentPage.value > 0)
const showPager = computed(() => !showAllEnvs.value && total.value > pageSize.value)
const sortableEnabled = computed(() => !showAllEnvs.value && envList.value.length >= 2)
const pageSizeOptions: Array<{ label: string; value: EnvPageSizeSelection }> = [
  { label: '20 / 页', value: '20' },
  { label: '50 / 页', value: '50' },
  { label: '100 / 页', value: '100' },
  { label: '全部', value: 'all' }
]
const selectionScopeText = computed(() =>
  showAllEnvs.value ? '批量操作作用于当前已勾选的数据。' : '批量操作仅作用于当前页勾选的数据。'
)
const envStats = computed(() => {
  const list = filteredEnvList.value
  const totalCount = list.length
  const enabledCount = list.filter(item => item.enabled).length
  const remarkCount = list.filter(item => item.remarks && item.remarks.length > 0).length
  const lastUpdated = list.reduce((latest: string, item: any) => {
    if (!item.updated_at) return latest
    return !latest || new Date(item.updated_at) > new Date(latest) ? item.updated_at : latest
  }, '')
  return { totalCount, enabledCount, remarkCount, lastUpdated }
})
const filteredEnvList = computed(() => {
  if (statusFilter.value === 'enabled') return envList.value.filter(item => item.enabled)
  if (statusFilter.value === 'disabled') return envList.value.filter(item => !item.enabled)
  return envList.value
})
const mobileEmptyDescription = computed(() =>
  statusFilter.value ? '当前筛选条件下暂无环境变量' : '暂无环境变量'
)
const envTableClass = computed(() => ['env-table', 'env-table--' + tableDensity.value])
const envTableHeaderStyle = { background: '#f8fafc', color: '#64748b', fontWeight: 600, fontSize: '13px' }
const tableDensity = ref<'comfortable' | 'compact'>(
  typeof window !== 'undefined' && window.localStorage.getItem(envTableDensityStorageKey) === 'compact'
    ? 'compact'
    : 'comfortable'
)

const showEditDialog = ref(false)
const editDialogMode = ref<'create' | 'edit'>('create')
const currentEditEnv = ref<EnvFormModel | null>(null)

const showImportDialog = ref(false)

const showExportDialog = ref(false)
const exportFormat = ref('shell')
const exportContent = ref('')
const exportScopeText = computed(() =>
  selectedIds.value.length > 0 ? `已选中的 ${selectedIds.value.length} 项环境变量` : '当前列表中的全部已启用环境变量'
)

const showBatchRenameDialog = ref(false)
const showBatchGroupDialog = ref(false)
const showConfigScriptDialog = ref(false)
const configScriptContent = ref('')
const configScriptLoading = ref(false)
const configScriptSaving = ref(false)

const tableRef = ref()
const desktopTableReady = ref(false)
const showDesktopLoadingPlaceholder = computed(
  () => !isMobile.value && (!desktopTableReady.value || (loading.value && envList.value.length === 0))
)
const showDesktopEmptyState = computed(
  () => !isMobile.value && desktopTableReady.value && !loading.value && envList.value.length === 0
)
let sortableInstance: any = null
let sortableLoader: Promise<any> | null = null
let dragPointerY = 0
let dragAutoScrollFrame = 0
let sortableInitFrame = 0
let desktopTableReadyFrame = 0
const groupBadgeStyleCache = new Map<string, CSSProperties>()

function readEnvPageSizeSelection(): EnvPageSizeSelection {
  if (typeof window === 'undefined') {
    return '20'
  }

  const raw = window.localStorage.getItem(envPageSizeStorageKey)
  if (raw === '20' || raw === '50' || raw === '100' || raw === 'all') {
    return raw
  }

  return '20'
}

function persistEnvPageSizeSelection(value: EnvPageSizeSelection) {
  if (typeof window !== 'undefined') {
    window.localStorage.setItem(envPageSizeStorageKey, value)
  }
}

function applyEnvPageSizeSelection(value: EnvPageSizeSelection) {
  pageSizeSelection.value = value
  pageSize.value = value === 'all' ? envAllFetchBatchSize : Number(value)
  persistEnvPageSizeSelection(value)
}

function loadSortable() {
  if (!sortableLoader) {
    sortableLoader = import('sortablejs').then((mod) => mod.default)
  }
  return sortableLoader
}

function clearTableSelection() {
  selectedIds.value = []
  tableRef.value?.clearSelection?.()
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

function handleDensityChange(value: 'comfortable' | 'compact') {
  tableDensity.value = value
  if (typeof window !== 'undefined') {
    window.localStorage.setItem(envTableDensityStorageKey, value)
  }
}

function buildStringHue(value: string) {
  let hash = 0
  for (const char of value) {
    hash = ((hash << 5) - hash + char.charCodeAt(0)) | 0
  }
  return Math.abs(hash) % 360
}

function getGroupBadgeStyle(group: string): CSSProperties {
  const cacheKey = group || 'default'
  const cached = groupBadgeStyleCache.get(cacheKey)
  if (cached) {
    return cached
  }

  const style = {
    '--group-hue': String(buildStringHue(cacheKey))
  } as CSSProperties
  groupBadgeStyleCache.set(cacheKey, style)
  return style
}

function splitEnvGroups(value: string): string[] {
  return value
    .split(/[,，;；\n\r\t]/)
    .map(group => group.trim())
    .filter((group, index, list) => group !== '' && list.indexOf(group) === index)
}

function normalizeGroupList(value: unknown): string[] {
  if (Array.isArray(value)) {
    return splitEnvGroups(value.filter(item => typeof item === 'string').join(','))
  }
  if (typeof value === 'string') {
    return splitEnvGroups(value)
  }
  return []
}

function normalizeEnvRow(row: any) {
  const rowGroups = normalizeGroupList(row.groups?.length ? row.groups : row.group)
  return {
    ...row,
    group: rowGroups.join(','),
    groups: rowGroups
  }
}

function normalizeEnvRows(rows: any[]) {
  return rows.map(row => normalizeEnvRow(row))
}

function updateDragPointer(evt: any) {
  const pointerEvent = evt?.originalEvent || evt
  if (typeof pointerEvent?.clientY === 'number') {
    dragPointerY = pointerEvent.clientY
    return
  }

  const touch = pointerEvent?.touches?.[0] || pointerEvent?.changedTouches?.[0]
  if (touch && typeof touch.clientY === 'number') {
    dragPointerY = touch.clientY
  }
}

function startDragAutoScroll() {
  stopDragAutoScroll()

  const tick = () => {
    const bodyWrapper = (
      isMobile.value
        ? document.querySelector('.env-mobile-scroll')
        : document.querySelector('.env-table .el-table__body-wrapper')
    ) as HTMLElement | null
    const tableThreshold = 72
    const viewportThreshold = 88
    const tableScrollStep = 22
    const pageScrollStep = 18

    if (bodyWrapper) {
      const rect = bodyWrapper.getBoundingClientRect()
      const canScrollTable = bodyWrapper.scrollHeight > bodyWrapper.clientHeight + 4
      if (canScrollTable) {
        if (dragPointerY < rect.top + tableThreshold && bodyWrapper.scrollTop > 0) {
          bodyWrapper.scrollTop -= tableScrollStep
        } else if (
          dragPointerY > rect.bottom - tableThreshold &&
          bodyWrapper.scrollTop + bodyWrapper.clientHeight < bodyWrapper.scrollHeight
        ) {
          bodyWrapper.scrollTop += tableScrollStep
        }
      }
    }

    if (dragPointerY < viewportThreshold) {
      window.scrollBy({ top: -pageScrollStep, behavior: 'auto' })
    } else if (dragPointerY > window.innerHeight - viewportThreshold) {
      window.scrollBy({ top: pageScrollStep, behavior: 'auto' })
    }

    dragAutoScrollFrame = window.requestAnimationFrame(tick)
  }

  dragAutoScrollFrame = window.requestAnimationFrame(tick)
}

function stopDragAutoScroll() {
  if (dragAutoScrollFrame) {
    window.cancelAnimationFrame(dragAutoScrollFrame)
    dragAutoScrollFrame = 0
  }
}

function clearQueuedSortableInit() {
  if (sortableInitFrame) {
    window.cancelAnimationFrame(sortableInitFrame)
    sortableInitFrame = 0
  }
}

function queueSortableInit() {
  if (typeof window === 'undefined') return
  if (!sortableEnabled.value) {
    if (sortableInstance) {
      sortableInstance.destroy()
      sortableInstance = null
    }
    return
  }
  clearQueuedSortableInit()
  sortableInitFrame = window.requestAnimationFrame(() => {
    sortableInitFrame = 0
    void initSortable()
  })
}

function clearDesktopTableReadyQueue() {
  if (desktopTableReadyFrame) {
    window.cancelAnimationFrame(desktopTableReadyFrame)
    desktopTableReadyFrame = 0
  }
}

function queueDesktopTableReady() {
  if (typeof window === 'undefined' || isMobile.value || desktopTableReady.value) return
  clearDesktopTableReadyQueue()
  desktopTableReadyFrame = window.requestAnimationFrame(() => {
    desktopTableReadyFrame = 0
    desktopTableReady.value = true
  })
}

let loadDataDepth = 0
async function loadData() {
  if (loadDataDepth >= 3) {
    // 防止空页重算递归堆叠，超过 3 层直接中止
    loadDataDepth = 0
    loading.value = false
    return
  }
  loadDataDepth += 1
  loading.value = true
  selectedIds.value = []
  try {
    const params = {
      keyword: keyword.value || undefined,
      groups: groupFilters.value.length > 0 ? groupFilters.value.join(',') : undefined,
      enabled: statusFilter.value === 'enabled' ? true : statusFilter.value === 'disabled' ? false : undefined
    }

    if (showAllEnvs.value) {
      // 服务端通过 all=1 一次性返回（带 5000 条硬上限保护），避免循环分页造成的等待与滚动卡顿。
      const res = await envApi.list({ ...params, all: 1 })
      envList.value = normalizeEnvRows(res.data || [])
      total.value = res.total || envList.value.length
    } else {
      const res = await envApi.list({
        ...params,
        page: page.value,
        page_size: pageSize.value
      })
      envList.value = normalizeEnvRows(res.data || [])
      total.value = res.total || 0

      if (envList.value.length === 0 && total.value > 0 && page.value > 1) {
        page.value = Math.max(1, Math.ceil(total.value / pageSize.value))
        await loadData()
        return
      }
    }
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '加载环境变量失败')
  } finally {
    loading.value = false
    loadDataDepth = Math.max(0, loadDataDepth - 1)
  }

  await nextTick()
  queueDesktopTableReady()
  clearTableSelection()
  queueSortableInit()
}

async function loadGroups() {
  try {
    const res = await envApi.groups()
    groups.value = normalizeGroupList(res.data || [])
  } catch {
    // ignore
  }
}

onMounted(() => {
  queueDesktopTableReady()
  void loadData()
  void loadGroups()
})

watch(isMobile, () => {
  nextTick(() => {
    queueDesktopTableReady()
    queueSortableInit()
  })
})

onBeforeUnmount(() => {
  stopDragAutoScroll()
  clearQueuedSortableInit()
  clearDesktopTableReadyQueue()
  if (sortableInstance) {
    sortableInstance.destroy()
    sortableInstance = null
  }
})

async function initSortable() {
  if (sortableInstance) {
    sortableInstance.destroy()
    sortableInstance = null
  }
  if (loading.value || !sortableEnabled.value) return
  const el = document.querySelector(
    isMobile.value
      ? '.env-mobile-list'
      : '.env-table .el-table__body-wrapper tbody'
  )
  if (!el) return
  try {
    const Sortable = await loadSortable()
    sortableInstance = Sortable.create(el as HTMLElement, {
      animation: 150,
      ghostClass: 'sortable-ghost',
      chosenClass: 'sortable-chosen',
      dragClass: 'sortable-drag',
      forceFallback: true,
      fallbackOnBody: true,
      scroll: true,
      bubbleScroll: true,
      scrollSensitivity: 100,
      scrollSpeed: 18,
      ...(isMobile.value
        ? { handle: '.env-mobile-drag-handle', delay: 350, delayOnTouchOnly: true, touchStartThreshold: 8 }
        : { handle: '.env-drag-handle', delay: 0, touchStartThreshold: 4 }),
      onStart: (evt: any) => {
        updateDragPointer(evt)
        startDragAutoScroll()
      },
      onMove: (evt: any) => {
        updateDragPointer(evt)
      },
      onEnd: async (evt: any) => {
        stopDragAutoScroll()
        updateDragPointer(evt)

        const { oldIndex, newIndex } = evt
        if (oldIndex === newIndex) return

        const sourceItem = envList.value[oldIndex]
        if (!sourceItem) return

        const movedItem = envList.value.splice(oldIndex, 1)[0]
        envList.value.splice(newIndex, 0, movedItem)
        const nextItem = envList.value[newIndex + 1]
        const sourceSortOrder = Number(sourceItem.sort_order || 0)
        const targetSortOrder = nextItem ? Number(nextItem.sort_order || 0) : sourceSortOrder

        if (targetSortOrder !== sourceSortOrder) {
          ElMessage.warning('置顶区和普通区请分别排序，跨区移动请使用置顶按钮')
          void loadData()
          return
        }

        try {
          await envApi.sort(sourceItem.id, nextItem?.id)
        } catch (err: any) {
          ElMessage.error(err?.response?.data?.error || err?.message || '排序失败')
          void loadData()
        }
      }
    })
  } catch {
    ElMessage.error('拖拽排序组件加载失败')
  }
}

function handleSearch() {
  page.value = 1
  void loadData()
}

function handleGroupSelect() {
  page.value = 1
  void loadData()
}

function handlePageChange(newPage: number) {
  page.value = newPage
  void loadData()
}

function handlePageSizeChange(newSize: EnvPageSizeSelection) {
  applyEnvPageSizeSelection(newSize)
  page.value = 1
  void loadData()
}

function handlePageSizeSelect(value: string) {
  handlePageSizeChange(value as EnvPageSizeSelection)
}

function openCreate() {
  editDialogMode.value = 'create'
  currentEditEnv.value = { id: 0, name: '', value: '', remarks: '', group: '', groups: [] }
  showEditDialog.value = true
}

function openDuplicate(row: any) {
  editDialogMode.value = 'create'
  currentEditEnv.value = {
    id: 0,
    name: row.name || '',
    value: '',
    remarks: row.remarks || '',
    group: row.group || '',
    groups: normalizeGroupList(row.groups?.length ? row.groups : row.group)
  }
  showEditDialog.value = true
}

function openEdit(row: any) {
  editDialogMode.value = 'edit'
  currentEditEnv.value = {
    id: row.id,
    name: row.name || '',
    value: row.value || '',
    remarks: row.remarks || '',
    group: row.group || '',
    groups: normalizeGroupList(row.groups?.length ? row.groups : row.group)
  }
  showEditDialog.value = true
}

async function handleSave(data: EnvFormModel | EnvFormModel[]) {
  try {
    if (Array.isArray(data)) {
      await envApi.create(data as any)
      ElMessage.success(`批量创建 ${data.length} 个变量成功`)
    } else if (editDialogMode.value === 'create') {
      await envApi.create(data)
      ElMessage.success('创建成功')
    } else {
      await envApi.update(data.id, {
        name: data.name,
        value: data.value,
        remarks: data.remarks,
        group: data.group,
        groups: data.groups
      })
      ElMessage.success('更新成功')
    }
    showEditDialog.value = false
    void loadData()
    void loadGroups()
  } catch {
    ElMessage.error(editDialogMode.value === 'create' ? '创建失败' : '更新失败')
  }
}

function isTopPinned(row: any) {
  return Number(row.sort_order || 0) > 0
}

function getRowClassName({ row }: { row: any }) {
  return isTopPinned(row) ? 'env-row-pinned' : ''
}

async function handleToggleTop(row: any) {
  try {
    if (isTopPinned(row)) {
      await envApi.cancelTop(row.id)
      ElMessage.success('已取消置顶')
    } else {
      await envApi.moveToTop(row.id)
      ElMessage.success('已置顶')
    }
    void loadData()
  } catch {
    ElMessage.error('操作失败')
  }
}

async function handleDelete(id: number) {
  try {
    await ElMessageBox.confirm('确定要删除该环境变量吗？', '确认删除', { type: 'warning' })
    await envApi.delete(id)
    ElMessage.success('删除成功')
    void loadData()
  } catch {
    // cancelled
  }
}

async function handleToggle(row: any) {
  try {
    const enabling = !row.enabled
    await ElMessageBox.confirm(
      enabling
        ? `确认启用环境变量 ${row.name} 吗？`
        : `确认禁用环境变量 ${row.name} 吗？禁用后脚本将无法读取该变量。`,
      enabling ? '启用确认' : '禁用确认',
      { type: enabling ? 'info' : 'warning' }
    )
    if (row.enabled) {
      await envApi.disable(row.id)
    } else {
      await envApi.enable(row.id)
    }
    ElMessage.success(row.enabled ? '已禁用' : '已启用')
    void loadData()
  } catch (err: any) {
    if (err === 'cancel' || err?.toString?.() === 'cancel') return
    ElMessage.error('操作失败')
  }
}

async function handleBatchDelete() {
  if (selectedIds.value.length === 0) return
  try {
    await ElMessageBox.confirm(`确定要删除选中的 ${selectedIds.value.length} 个环境变量吗？`, '批量删除', { type: 'warning' })
    await envApi.batchDelete(selectedIds.value)
    ElMessage.success('批量删除成功')
    clearTableSelection()
    void loadData()
  } catch {
    // cancelled
  }
}

async function handleBatchGroup() {
  if (selectedIds.value.length === 0) return
  showBatchGroupDialog.value = true
}

function handleBatchRename() {
  if (selectedIds.value.length === 0) return
  showBatchRenameDialog.value = true
}

async function confirmBatchRename(payload: { name: string }) {
  try {
    const res = await envApi.batchRename(selectedIds.value, payload.name)
    ElMessage.success(res.message || '批量改名成功')
    showBatchRenameDialog.value = false
    clearTableSelection()
    void loadData()
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || err?.message || '批量改名失败')
  }
}

async function confirmBatchGroup(groups: string[]) {
  try {
    await envApi.batchSetGroup(selectedIds.value, normalizeGroupList(groups))
    ElMessage.success('批量分组成功')
    showBatchGroupDialog.value = false
    clearTableSelection()
    void loadData()
    void loadGroups()
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || err?.message || '批量分组失败')
  }
}

async function handleBatchEnable() {
  if (selectedIds.value.length === 0) return
  try {
    await ElMessageBox.confirm(`确认启用选中的 ${selectedIds.value.length} 个环境变量吗？`, '批量启用', { type: 'info' })
    await envApi.batchEnable(selectedIds.value)
    ElMessage.success('批量启用成功')
    void loadData()
  } catch (err: any) {
    if (err === 'cancel' || err?.toString?.() === 'cancel') return
    ElMessage.error('批量启用失败')
  }
}

async function handleBatchDisable() {
  if (selectedIds.value.length === 0) return
  try {
    await ElMessageBox.confirm(`确认禁用选中的 ${selectedIds.value.length} 个环境变量吗？`, '批量禁用', { type: 'warning' })
    await envApi.batchDisable(selectedIds.value)
    ElMessage.success('批量禁用成功')
    void loadData()
  } catch (err: any) {
    if (err === 'cancel' || err?.toString?.() === 'cancel') return
    ElMessage.error('批量禁用失败')
  }
}

function handleSelectionChange(rows: any[]) {
  selectedIds.value = rows.map(r => r.id)
}

async function handleImport(payload: { envs: any[]; mode: string }) {
  try {
    const res = await envApi.import(payload.envs, payload.mode)
    ElMessage.success(res.message)
    showImportDialog.value = false
    void loadData()
    void loadGroups()
  } catch {
    ElMessage.error('导入失败')
  }
}

watch(showConfigScriptDialog, async (visible) => {
  if (!visible) return
  configScriptLoading.value = true
  try {
    const res = await configScriptApi.get()
    configScriptContent.value = (res as any)?.content ?? ''
  } catch {
    configScriptContent.value = ''
  } finally {
    configScriptLoading.value = false
  }
})

async function handleSaveConfigScript() {
  configScriptSaving.value = true
  try {
    await configScriptApi.save(configScriptContent.value)
    ElMessage.success('配置文件已保存')
    showConfigScriptDialog.value = false
  } catch {
    ElMessage.error('保存失败')
  } finally {
    configScriptSaving.value = false
  }
}

async function handleExportAll() {
  try {
    const exportIds = selectedIds.value.length > 0 ? [...selectedIds.value] : undefined
    const res = await envApi.exportAll(exportIds)
    const json = JSON.stringify(res.data, null, 2)
    const blob = new Blob([json], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = exportIds?.length ? `env_vars_selected_${exportIds.length}.json` : 'env_vars.json'
    a.click()
    URL.revokeObjectURL(url)
  } catch {
    ElMessage.error('导出失败')
  }
}

async function handleExportFiles() {
  showExportDialog.value = true
  try {
    const exportIds = selectedIds.value.length > 0 ? [...selectedIds.value] : undefined
    const enabledOnly = exportIds == null
    const res = await envApi.exportFiles(exportFormat.value, enabledOnly, exportIds)
    exportContent.value = res.data[exportFormat.value] || ''
  } catch {
    ElMessage.error('导出失败')
  }
}

async function refreshExport() {
  try {
    const exportIds = selectedIds.value.length > 0 ? [...selectedIds.value] : undefined
    const enabledOnly = exportIds == null
    const res = await envApi.exportFiles(exportFormat.value, enabledOnly, exportIds)
    exportContent.value = res.data[exportFormat.value] || ''
  } catch {
    // ignore
  }
}

async function copyExport() {
  try {
    await copyText(exportContent.value)
    ElMessage.success('已复制到剪贴板')
  } catch {
    ElMessage.error('复制失败，请检查浏览器权限或站点访问方式')
  }
}

async function copyEnvValue(value: string) {
  try {
    await copyText(value)
    ElMessage.success('已复制到剪贴板')
  } catch {
    ElMessage.error('复制失败，请检查浏览器权限或站点访问方式')
  }
}

function formatDateTime(t: string | null) {
  if (!t) return '-'
  const d = new Date(t)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}  ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
}

function formatShortDateTime(t: string | null) {
  if (!t) return '-'
  const d = new Date(t)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function handleStatusFilter(value: '' | 'enabled' | 'disabled') {
  if (statusFilter.value === value) {
    return
  }
  statusFilter.value = value
  page.value = 1
  void loadData()
}
</script>

<template>
  <div class="envs-page dd-fixed-page dd-page-hide-heading">
    <div class="stat-cards">
      <div class="stat-card">
        <div class="stat-card__content">
          <span class="stat-card__label">当前页变量</span>
          <span class="stat-card__value">{{ envStats.totalCount }}</span>
          <span class="stat-card__sub">本页展示变量</span>
        </div>
        <div class="stat-card__icon stat-card__icon--blue">
          <el-icon :size="22"><Clock /></el-icon>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-card__content">
          <span class="stat-card__label">本页启用</span>
          <span class="stat-card__value stat-card__value--green">{{ envStats.enabledCount }}</span>
          <span class="stat-card__sub">当前页生效变量</span>
        </div>
        <div class="stat-card__icon stat-card__icon--green">
          <el-icon :size="22"><Check /></el-icon>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-card__content">
          <span class="stat-card__label">备注变量</span>
          <span class="stat-card__value stat-card__value--orange">{{ envStats.remarkCount }}</span>
          <span class="stat-card__sub">当前页有备注</span>
        </div>
        <div class="stat-card__icon stat-card__icon--orange">
          <el-icon :size="22"><Connection /></el-icon>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-card__content">
          <span class="stat-card__label">本页最近更新</span>
          <span class="stat-card__value stat-card__value--green" style="font-size: 18px;">{{ formatShortDateTime(envStats.lastUpdated) }}</span>
          <span class="stat-card__sub">当前页最后更新时间</span>
        </div>
        <div class="stat-card__icon stat-card__icon--green">
          <el-icon :size="22"><Timer /></el-icon>
        </div>
      </div>
    </div>

    <div class="toolbar">
      <div class="toolbar__left">
        <div class="status-tabs">
          <button :class="['status-tab', { active: statusFilter === '' }]" @click="handleStatusFilter('')">全部变量</button>
          <button :class="['status-tab', { active: statusFilter === 'enabled' }]" @click="handleStatusFilter('enabled')">已启用</button>
          <button :class="['status-tab', { active: statusFilter === 'disabled' }]" @click="handleStatusFilter('disabled')">已禁用</button>
        </div>
        <el-input
          v-model="keyword"
          placeholder="搜索变量名、值、备注或分组"
          clearable
          class="toolbar__search"
          @keyup.enter="handleSearch"
          @clear="handleSearch"
        >
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select
          v-model="groupFilters"
          placeholder="分组筛选"
          multiple
          collapse-tags
          collapse-tags-tooltip
          clearable
          class="toolbar__group-filter"
          @change="handleGroupSelect"
        >
          <el-option v-for="g in groups" :key="g" :label="g" :value="g" />
        </el-select>
      </div>
      <div class="toolbar__right">
        <el-dropdown trigger="click">
          <el-button><el-icon><More /></el-icon></el-button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item @click="handleExportAll">导出 JSON</el-dropdown-item>
              <el-dropdown-item @click="exportFormat = 'shell'; handleExportFiles()">导出 Shell</el-dropdown-item>
              <el-dropdown-item @click="exportFormat = 'js'; handleExportFiles()">导出 JS</el-dropdown-item>
              <el-dropdown-item @click="exportFormat = 'python'; handleExportFiles()">导出 Python</el-dropdown-item>
              <el-dropdown-item divided @click="showImportDialog = true">导入</el-dropdown-item>
              <el-dropdown-item divided @click="showConfigScriptDialog = true">
                <el-icon><Document /></el-icon> 配置文件 (config.sh)
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
        <div v-if="selectedIds.length > 0" class="batch-actions">
          <el-button @click="handleBatchRename">批量改名</el-button>
          <el-button @click="handleBatchEnable">批量启用</el-button>
          <el-button @click="handleBatchDisable">批量禁用</el-button>
          <el-button @click="handleBatchGroup">批量分组</el-button>
          <el-button type="danger" @click="handleBatchDelete">批量删除</el-button>
        </div>
        <el-button type="primary" @click="openCreate">
          <el-icon><Plus /></el-icon> 新建变量
        </el-button>
      </div>
    </div>

    <div v-if="isMobile" class="env-mobile-scroll">
      <div class="dd-mobile-list env-mobile-list">
        <div
          v-for="row in filteredEnvList"
          :key="row.id"
          class="dd-mobile-card env-card"
          :class="{ 'env-card--pinned': isTopPinned(row) }"
        >
          <div class="dd-mobile-card__header">
            <div class="dd-mobile-card__title-wrap">
              <div class="env-card__title-row">
                <div class="dd-mobile-card__selection">
                  <button
                    v-if="sortableEnabled"
                    class="env-mobile-drag-handle"
                    type="button"
                    aria-label="长按拖动排序"
                    @click.stop
                  >
                    <el-icon :size="16"><Rank /></el-icon>
                  </button>
                  <el-checkbox :model-value="isSelected(row.id)" @change="toggleSelected(row.id, $event)" />
                  <div class="env-name-wrap">
                    <span class="env-name">{{ row.name }}</span>
                    <span v-if="isTopPinned(row)" class="pinned-chip">
                      <el-icon><Top /></el-icon>
                      置顶
                    </span>
                  </div>
                </div>
                <div class="env-card__tools">
                  <div v-if="row.groups.length > 0" class="group-pill-list">
                    <span
                      v-for="group in row.groups"
                      :key="group"
                      class="group-pill"
                      :style="getGroupBadgeStyle(group)"
                    >
                      <span class="group-dot" />
                      <span class="group-pill__text">{{ group }}</span>
                    </span>
                  </div>
                  <span v-else class="env-empty-text">未分组</span>
                </div>
              </div>
            </div>
          </div>

          <div class="dd-mobile-card__body">
            <div class="dd-mobile-card__grid">
              <div class="dd-mobile-card__field dd-mobile-card__field--full">
                <span class="dd-mobile-card__label">值</span>
                <div class="dd-mobile-card__value env-value-cell">
                  <span class="env-value-text">{{ row.value || '-' }}</span>
                  <el-button v-if="row.value" size="small" link @click.stop="copyEnvValue(row.value)">
                    <el-icon :size="14"><CopyDocument /></el-icon>
                  </el-button>
                </div>
              </div>
              <div class="dd-mobile-card__field dd-mobile-card__field--full">
                <span class="dd-mobile-card__label">备注</span>
                <span class="dd-mobile-card__value env-remarks-text">{{ row.remarks || '-' }}</span>
              </div>
              <div class="dd-mobile-card__field">
                <span class="dd-mobile-card__label">状态</span>
                <div class="dd-mobile-card__value env-status-inline">
                  <el-switch :model-value="row.enabled" size="small" @change="handleToggle(row)" />
                  <span class="env-status-text" :class="{ enabled: row.enabled }">
                    {{ row.enabled ? '启用' : '禁用' }}
                  </span>
                </div>
              </div>
              <div class="dd-mobile-card__field">
                <span class="dd-mobile-card__label">更新时间</span>
                <span class="dd-mobile-card__value time-text">{{ formatDateTime(row.updated_at) }}</span>
              </div>
            </div>

            <div class="dd-mobile-card__actions env-card__actions">
              <el-button size="small" type="primary" @click="openEdit(row)">编辑</el-button>
              <el-button size="small" @click="openDuplicate(row)">复制</el-button>
              <el-button
                size="small"
                :type="isTopPinned(row) ? 'info' : 'warning'"
                @click="handleToggleTop(row)"
              >
                {{ isTopPinned(row) ? '取消置顶' : '置顶' }}
              </el-button>
              <el-button size="small" type="danger" plain @click="handleDelete(row.id)">删除</el-button>
            </div>
          </div>
        </div>

        <el-empty v-if="!loading && filteredEnvList.length === 0" :description="mobileEmptyDescription" />
      </div>
    </div>

    <div v-else-if="showDesktopLoadingPlaceholder" class="env-desktop-state env-desktop-state--loading" aria-hidden="true">
      <div class="env-skeleton env-skeleton--title" />
      <div class="env-skeleton env-skeleton--toolbar" />
      <div v-for="n in 6" :key="`env-skeleton-${n}`" class="env-skeleton env-skeleton--row" />
    </div>

    <div v-else-if="showDesktopEmptyState" class="env-desktop-state">
      <el-empty description="暂无环境变量">
        <template #description>
          <div class="env-empty-copy">
            <strong>暂无环境变量</strong>
            <span>可以直接新建变量，或导入已有的 JSON 配置。</span>
          </div>
        </template>
        <div class="env-empty-actions">
          <el-button type="primary" @click="openCreate">新建环境变量</el-button>
          <el-button @click="showImportDialog = true">导入 JSON</el-button>
        </div>
      </el-empty>
    </div>

    <div v-else class="table-card">
      <el-table
        ref="tableRef"
        :data="filteredEnvList"
        v-loading="loading"
        @selection-change="handleSelectionChange"
        :row-class-name="getRowClassName"
        :class="envTableClass"
        :header-cell-style="envTableHeaderStyle"
        row-key="id"
        style="width: 100%"
      >
        <el-table-column type="selection" width="44" />
        <el-table-column width="32" class-name="env-drag-col">
          <template #default>
            <el-icon class="env-drag-handle"><Rank /></el-icon>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="名称" min-width="188">
          <template #default="{ row }">
            <div class="env-name-wrap">
              <span class="env-name">{{ row.name }}</span>
              <span v-if="isTopPinned(row)" class="pinned-chip">
                <el-icon><Top /></el-icon>
                置顶
              </span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="value" label="值" min-width="280">
          <template #default="{ row }">
            <div class="env-value-cell">
              <span class="env-value-text" :title="row.value || ''">{{ row.value || '-' }}</span>
              <el-tooltip v-if="row.value" content="复制" placement="top">
                <el-button class="env-copy-btn" size="small" link @click.stop="copyEnvValue(row.value)">
                  <el-icon :size="14"><CopyDocument /></el-icon>
                </el-button>
              </el-tooltip>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="remarks" label="备注" min-width="180">
          <template #default="{ row }">
            <span class="env-remarks-text" :title="row.remarks || ''">{{ row.remarks || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="group" label="分组" min-width="180" align="center">
          <template #default="{ row }">
            <div v-if="row.groups.length > 0" class="group-pill-list group-pill-list--table">
              <span
                v-for="group in row.groups"
                :key="group"
                class="group-pill"
                :style="getGroupBadgeStyle(group)"
              >
                <span class="group-dot" />
                <span class="group-pill__text">{{ group }}</span>
              </span>
            </div>
            <span v-else class="env-empty-text">未分组</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="92" align="center">
          <template #default="{ row }">
            <div class="env-status-cell">
              <el-switch
                :model-value="row.enabled"
                size="small"
                @change="handleToggle(row)"
              />
              <span class="env-status-text" :class="{ enabled: row.enabled }">
                {{ row.enabled ? '启用' : '禁用' }}
              </span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="更新时间" width="168" align="center">
          <template #default="{ row }">
            <span class="time-text">{{ formatDateTime(row.updated_at) }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="176" align="center">
          <template #default="{ row }">
            <div class="action-group">
              <el-tooltip content="编辑" placement="top">
                <el-button size="small" type="primary" plain circle @click="openEdit(row)">
                  <el-icon><Edit /></el-icon>
                </el-button>
              </el-tooltip>
              <el-tooltip content="复制同名变量" placement="top">
                <el-button size="small" plain circle @click="openDuplicate(row)">
                  <el-icon><CopyDocument /></el-icon>
                </el-button>
              </el-tooltip>
              <el-tooltip :content="isTopPinned(row) ? '取消置顶' : '置顶'" placement="top">
                <el-button
                  size="small"
                  :type="isTopPinned(row) ? 'info' : 'warning'"
                  :class="{ 'top-action-active': isTopPinned(row) }"
                  plain
                  circle
                  @click="handleToggleTop(row)"
                >
                  <el-icon><Top /></el-icon>
                </el-button>
              </el-tooltip>
              <el-tooltip content="删除" placement="top">
                <el-button size="small" type="danger" plain circle @click="handleDelete(row.id)">
                  <el-icon><Delete /></el-icon>
                </el-button>
              </el-tooltip>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div class="pagination-bar">
      <span class="pagination-total">共 {{ total }} 条数据</span>
      <div class="pagination-actions">
        <div class="page-size-picker">
          <span class="page-size-picker__label">每页</span>
          <el-select
            :model-value="pageSizeSelection"
            size="small"
            style="width: 112px"
            @change="handlePageSizeSelect"
          >
            <el-option
              v-for="option in pageSizeOptions"
              :key="option.value"
              :label="option.label"
              :value="option.value"
            />
          </el-select>
        </div>
        <el-pagination
          v-if="showPager"
          v-model:current-page="page"
          :page-size="pageSize"
          :total="total"
          layout="prev, pager, next"
          @current-change="handlePageChange"
        />
      </div>
    </div>

    <el-dialog v-model="showExportDialog" title="导出环境变量" width="600px" :fullscreen="isMobile">
      <div class="export-format-switch">
        <el-radio-group v-model="exportFormat" @change="refreshExport">
          <el-radio-button value="shell">Shell</el-radio-button>
          <el-radio-button value="js">JavaScript</el-radio-button>
          <el-radio-button value="python">Python</el-radio-button>
        </el-radio-group>
        <el-button size="small" @click="copyExport">
          <el-icon><CopyDocument /></el-icon>复制
        </el-button>
      </div>
      <el-alert
        type="info"
        :closable="false"
        show-icon
        style="margin-bottom: 12px"
        :title="`导出范围：${exportScopeText}`"
      />
      <pre class="export-preview">{{ exportContent }}</pre>
    </el-dialog>

    <EnvEditDialog
      v-model="showEditDialog"
      :mode="editDialogMode"
      :initial-data="currentEditEnv"
      :groups="groups"
      @save="handleSave"
    />

    <EnvImportDialog
      v-model="showImportDialog"
      @import="handleImport"
    />

    <EnvBatchRenameDialog
      v-model="showBatchRenameDialog"
      @confirm="confirmBatchRename"
    />

    <EnvBatchGroupDialog
      v-model="showBatchGroupDialog"
      :groups="groups"
      @confirm="confirmBatchGroup"
    />

    <el-dialog v-model="showConfigScriptDialog" title="配置文件 (config.sh)" width="680px" :fullscreen="isMobile" destroy-on-close>
      <el-alert type="info" :closable="false" show-icon style="margin-bottom: 14px">
        适合存放不常变动的参数变量。文件中的变量会在每次任务执行时自动加载，优先级低于环境变量。
        <br />格式：每行一个 <code>KEY=VALUE</code> 或 <code>export KEY="VALUE"</code>，<code>#</code> 开头为注释。
      </el-alert>
      <el-input
        v-model="configScriptContent"
        v-loading="configScriptLoading"
        type="textarea"
        :rows="18"
        placeholder="# 示例：&#10;export MY_TOKEN=&quot;abc123&quot;&#10;API_BASE=&quot;https://example.com&quot;"
        spellcheck="false"
        style="font-family: var(--dd-font-mono); font-size: 13px"
      />
      <template #footer>
        <el-button @click="showConfigScriptDialog = false">取消</el-button>
        <el-button type="primary" :loading="configScriptSaving" @click="handleSaveConfigScript">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.envs-page {
  padding: 0;
}

/* ---- Page Header ---- */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 18px;
  gap: 16px;

  h2 {
    margin: 0;
    font-size: 22px;
    font-weight: 700;
    color: var(--el-text-color-primary);
    line-height: 1.3;
  }

  .page-subtitle {
    font-size: 13px;
    color: var(--el-text-color-secondary);
    margin: 4px 0 0;
  }

  .header-actions {
    display: flex;
    gap: 10px;
    flex-shrink: 0;
  }
}

/* ---- Stat Cards ---- */
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
  transition: transform 0.22s ease, box-shadow 0.22s ease;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 22px rgba(15, 23, 42, 0.08);
  }

  &__content {
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 0;
    flex: 1;
  }

  &__label {
    font-size: 13px;
    color: var(--el-text-color-secondary);
    font-weight: 500;
  }

  &__value {
    font-size: 26px;
    font-weight: 700;
    color: #3b82f6;
    line-height: 1.15;
    font-family: 'Inter', var(--dd-font-ui), sans-serif;
    font-variant-numeric: tabular-nums;
    -webkit-font-smoothing: antialiased;
    letter-spacing: -0.01em;

    &--orange { color: #f59e0b; }
    &--green { color: #10b981; }
    &--red { color: #ef4444; }
    &--purple { color: #8b5cf6; }
  }

  &__sub {
    font-size: 12px;
    color: var(--el-text-color-placeholder);
  }

  &__icon {
    width: 44px;
    height: 44px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;

    &--blue {
      background: rgba(59, 130, 246, 0.12);
      color: #3b82f6;
    }
    &--orange {
      background: rgba(245, 158, 11, 0.12);
      color: #f59e0b;
    }
    &--green {
      background: rgba(16, 185, 129, 0.12);
      color: #10b981;
    }
    &--red {
      background: rgba(239, 68, 68, 0.12);
      color: #ef4444;
    }
    &--purple {
      background: rgba(139, 92, 246, 0.12);
      color: #8b5cf6;
    }
  }
}

/* ---- Toolbar ---- */
.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
  gap: 12px;
  flex-wrap: wrap;

  &__left {
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
    flex: 1;
    min-width: 0;
  }

  &__right {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  &__search {
    width: 260px;
  }

  &__group-filter {
    width: 220px;
  }
}

.status-tabs {
  display: inline-flex;
  background: var(--el-fill-color-light);
  border-radius: 10px;
  padding: 3px;
  gap: 2px;
}

.status-tab {
  padding: 6px 14px;
  border-radius: 7px;
  border: none;
  background: transparent;
  color: var(--el-text-color-secondary);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.18s;
  white-space: nowrap;

  &:hover {
    color: var(--el-text-color-primary);
  }

  &.active {
    background: var(--el-bg-color);
    color: var(--el-color-primary);
    box-shadow: 0 1px 2px rgba(15, 23, 42, 0.06);
    font-weight: 600;
  }
}

.batch-actions {
  display: flex;
  gap: 8px;
}

/* ---- Table Card ---- */
.table-card {
  background: var(--el-bg-color);
  border-radius: 14px;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
  border: 1px solid var(--el-border-color-lighter);
  overflow: hidden;
}

/* ---- Pagination Bar ---- */
.pagination-bar {
  margin-top: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 0 4px;
}

.pagination-total {
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.pagination-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 12px;
  flex-wrap: wrap;
}

.page-size-picker {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.page-size-picker__label {
  font-size: 13px;
  color: var(--el-text-color-secondary);
  white-space: nowrap;
}

/* ---- Table internals ---- */
:deep(.el-table) {
  --el-table-border-color: #f0f0f0;

  .el-table__header-wrapper th {
    border-bottom: 1px solid #e8e8e8;
  }

  .el-table__row td {
    border-bottom: 1px solid #f5f5f5;
  }

  .el-table__cell {
    padding: 12px 0;
  }
}

:deep(.env-table--compact .el-table__cell) {
  padding-top: 8px;
  padding-bottom: 8px;
}

:deep(.env-table--compact .env-value-text),
:deep(.env-table--compact .env-remarks-text),
:deep(.env-table--compact .env-name) {
  font-size: 12px;
}

:deep(.env-table--compact .time-text) {
  font-size: 11px;
}

:deep(.env-table--compact .pinned-chip),
:deep(.env-table--compact .group-pill) {
  padding-top: 2px;
  padding-bottom: 2px;
  font-size: 11px;
}

/* ---- Mobile ---- */
.env-mobile-scroll {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* ---- Desktop States ---- */
.env-desktop-state {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 360px;
  padding: 28px 24px;
  border: 1px solid color-mix(in srgb, var(--el-border-color) 70%, transparent);
  border-radius: 18px;
  background:
    linear-gradient(180deg, color-mix(in srgb, var(--el-fill-color-lighter) 62%, white) 0%, var(--el-bg-color) 100%);
  box-shadow: 0 14px 32px rgba(15, 23, 42, 0.05);
}

.env-desktop-state--loading {
  display: grid;
  align-content: start;
  justify-items: stretch;
  gap: 16px;
}

.env-skeleton {
  position: relative;
  overflow: hidden;
  border-radius: 14px;
  background: color-mix(in srgb, var(--el-fill-color) 82%, white);
}

.env-skeleton::after {
  content: '';
  position: absolute;
  inset: 0;
  transform: translateX(-100%);
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(255, 255, 255, 0.6) 48%,
    transparent 100%
  );
  animation: env-skeleton-shimmer 1.35s ease-in-out infinite;
}

.env-skeleton--title {
  width: min(320px, 32%);
  height: 22px;
}

.env-skeleton--toolbar {
  width: min(460px, 48%);
  height: 40px;
  margin-bottom: 8px;
}

.env-skeleton--row {
  width: 100%;
  height: 58px;
}

.env-empty-copy {
  display: inline-flex;
  flex-direction: column;
  gap: 6px;
  color: var(--el-text-color-secondary);
}

.env-empty-copy strong {
  font-size: 16px;
  color: var(--el-text-color-primary);
}

.env-empty-copy span {
  font-size: 13px;
}

.env-empty-actions {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

/* ---- Mobile Card ---- */
.env-card__title-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}

.env-mobile-drag-handle {
  flex-shrink: 0;
  width: 30px;
  height: 30px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--el-border-color-lighter);
  background: var(--el-fill-color-light);
  border-radius: 8px;
  color: var(--el-text-color-secondary);
  cursor: grab;
  touch-action: none;
  transition: background 0.18s, color 0.18s, border-color 0.18s;
  -webkit-user-select: none;
  user-select: none;
  padding: 0;
}

.env-mobile-drag-handle:active {
  cursor: grabbing;
  background: var(--el-color-primary-light-9);
  color: var(--el-color-primary);
  border-color: var(--el-color-primary-light-7);
}

.env-card__tools {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
  min-width: 0;
}

.env-card__actions > * {
  flex: 1 1 calc(33.33% - 6px);
}

.env-card--pinned {
  border-color: rgba(245, 166, 35, 0.28);
  box-shadow:
    inset 4px 0 0 #f5a623,
    0 10px 28px rgba(15, 23, 42, 0.07);
}

/* ---- Cell Styles ---- */
.action-group {
  display: flex;
  align-items: center;
  gap: 6px;
}

.env-name-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.env-name {
  min-width: 0;
  flex: 1;
  font-family: var(--dd-font-mono);
  font-size: 13px;
  color: var(--el-color-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.pinned-chip {
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
  color: #8a4b00;
  background: linear-gradient(135deg, #fff1bf 0%, #ffd66b 100%);
  box-shadow: inset 0 0 0 1px rgba(196, 118, 0, 0.18);
}

.env-value-text,
.env-remarks-text {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.env-value-cell {
  display: flex;
  align-items: center;
  gap: 4px;
  min-width: 0;
}

.env-value-text {
  font-family: var(--dd-font-mono);
  color: var(--el-text-color-primary);
}

.env-copy-btn {
  flex-shrink: 0;
  opacity: 0;
  transition: opacity 0.2s;
  color: var(--el-text-color-secondary);
  padding: 2px;
}

:deep(.el-table__row:hover) .env-copy-btn {
  opacity: 1;
}

.env-remarks-text {
  color: var(--el-text-color-regular);
}

.env-empty-text {
  font-size: 12px;
  color: var(--el-text-color-placeholder);
}

.group-pill {
  --group-hue: 210;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  max-width: 100%;
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
  color: hsl(var(--group-hue) 55% 32%);
  background: hsl(var(--group-hue) 85% 96%);
  box-shadow: inset 0 0 0 1px hsl(var(--group-hue) 72% 78% / 0.7);
}

.group-pill-list {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 6px;
  min-width: 0;
}

.group-pill-list--table {
  justify-content: center;
}

.group-pill__text {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.group-dot {
  width: 7px;
  height: 7px;
  border-radius: 999px;
  background: hsl(var(--group-hue) 72% 48%);
  flex-shrink: 0;
}

.env-status-cell {
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.env-status-inline {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.env-status-text {
  font-size: 11px;
  line-height: 1;
  color: var(--el-text-color-placeholder);
}

.env-status-text.enabled {
  color: var(--el-color-success);
}

.time-text {
  font-family: var(--dd-font-mono);
  font-size: 12px;
  color: var(--el-text-color-regular);
}

.env-drag-handle {
  cursor: grab;
  color: var(--el-text-color-placeholder);
  font-size: 16px;
  transition: color 0.15s;

  &:hover {
    color: var(--el-text-color-secondary);
  }

  &:active {
    cursor: grabbing;
  }
}

:deep(.env-drag-col) {
  padding: 0 !important;
}

.top-action-active {
  box-shadow: 0 0 0 1px rgba(245, 166, 35, 0.2);
}

.sortable-ghost {
  opacity: 0.4;
  background: var(--el-color-primary-light-9) !important;
}

.sortable-chosen {
  background: color-mix(in srgb, var(--el-color-primary) 10%, var(--el-bg-color)) !important;
}

.sortable-drag {
  opacity: 0.96 !important;
  box-shadow: 0 18px 36px rgba(15, 23, 42, 0.16);
}

/* ---- Pinned Row ---- */
:deep(.env-row-pinned > td) {
  background:
    linear-gradient(90deg, rgba(255, 214, 107, 0.22) 0, rgba(255, 214, 107, 0.08) 32px, transparent 220px),
    var(--el-table-tr-bg-color);
}

:deep(.env-row-pinned > td:first-child) {
  box-shadow: inset 4px 0 0 #f5a623;
}

/* ---- Export Dialog ---- */
.export-format-switch {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.export-preview {
  background: var(--el-bg-color-page);
  border-radius: 6px;
  padding: 16px;
  font-family: var(--dd-font-mono);
  font-size: 13px;
  line-height: 1.6;
  max-height: 400px;
  overflow-y: auto;
  margin: 0;
  white-space: pre-wrap;
  word-break: break-all;
}

@keyframes env-skeleton-shimmer {
  100% {
    transform: translateX(100%);
  }
}

/* ---- Responsive: 1200px ---- */
@media screen and (max-width: 1200px) {
  .stat-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* ---- Responsive: 768px (Mobile) ---- */
@media screen and (max-width: 768px) {
  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
    margin-bottom: 14px;

    h2 { font-size: 18px; }

    .header-actions {
      width: 100%;
      flex-wrap: wrap;
    }
  }

  .stat-cards {
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
  }

  .stat-card {
    padding: 14px 16px;

    &__value {
      font-size: 22px;
    }

    &__icon {
      width: 40px;
      height: 40px;
    }
  }

  .toolbar {
    flex-direction: column;
    align-items: stretch;
    gap: 10px;

    &__left {
      flex-direction: column;
      gap: 10px;
    }

    &__search {
      width: 100% !important;
    }

    &__group-filter {
      width: 100% !important;
    }

    &__right {
      justify-content: flex-end;
    }
  }

  .status-tabs {
    width: 100%;
    overflow-x: auto;
  }

  .batch-actions {
    flex-wrap: wrap;
  }

  .pagination-bar {
    flex-direction: column;
    align-items: stretch;
  }

  .pagination-actions {
    justify-content: space-between;
  }

  .page-size-picker {
    width: 100%;
    justify-content: space-between;
  }

  .env-card__title-row {
    flex-direction: column;
  }

  .env-card__tools {
    width: 100%;
    justify-content: space-between;
  }

  .env-card__actions > * {
    flex: 1 1 calc(50% - 4px);
  }
}
</style>
