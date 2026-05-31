<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { userApi } from '@/api/security'
import { useAuthStore } from '@/stores/auth'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useResponsive } from '@/composables/useResponsive'

const authStore = useAuthStore()
const { isMobile, dialogFullscreen } = useResponsive()
const users = ref<any[]>([])
const loading = ref(false)

const keyword = ref('')
const page = ref(1)
const pageSize = ref(20)

const showCreateDialog = ref(false)
const showResetPwdDialog = ref(false)

const createForm = ref({ username: '', password: '', role: 'operator' })
const resetPwdForm = ref({ id: 0, username: '', password: '' })

const roleFilter = ref('')

const userStats = computed(() => {
  const all = users.value
  const adminCount = all.filter(u => u.role === 'admin').length
  const operatorCount = all.filter(u => u.role === 'operator').length
  const viewerCount = all.filter(u => u.role === 'viewer').length
  return { totalCount: all.length, adminCount, operatorCount, viewerCount }
})

const filteredUsers = computed(() => {
  let list = users.value
  if (roleFilter.value) {
    list = list.filter(u => u.role === roleFilter.value)
  }
  const k = keyword.value.trim().toLowerCase()
  if (!k) return list
  return list.filter(u =>
    (u.username || '').toLowerCase().includes(k) ||
    (u.role || '').toLowerCase().includes(k)
  )
})

const pagedUsers = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return filteredUsers.value.slice(start, start + pageSize.value)
})

const total = computed(() => filteredUsers.value.length)

function handleSearch() { page.value = 1 }

async function loadUsers() {
  loading.value = true
  try {
    const res = await userApi.list()
    users.value = res.data || []
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '加载用户列表失败')
  } finally {
    loading.value = false
  }
}

onMounted(loadUsers)

function openCreate() {
  createForm.value = { username: '', password: '', role: 'operator' }
  showCreateDialog.value = true
}

function validatePassword(pwd: string): string | null {
  if (pwd.length < 6) return '密码至少 6 位'
  if (pwd.length > 128) return '密码不能超过 128 位'
  return null
}

async function handleCreate() {
  const username = createForm.value.username.trim()
  if (!username) {
    ElMessage.warning('用户名不能为空')
    return
  }
  if (!/^[\p{L}\p{N}_]{1,32}$/u.test(username)) {
    ElMessage.warning('用户名需 1-32 位，支持中文、字母、数字和下划线')
    return
  }
  const pwdErr = validatePassword(createForm.value.password)
  if (pwdErr) {
    ElMessage.warning(pwdErr)
    return
  }
  try {
    await userApi.create({ ...createForm.value, username })
    ElMessage.success('创建成功')
    showCreateDialog.value = false
    loadUsers()
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '创建失败')
  }
}

async function handleToggle(row: any) {
  try {
    const enabling = !row.enabled
    await ElMessageBox.confirm(
      enabling
        ? `确认启用用户 ${row.username} 吗？`
        : `确认禁用用户 ${row.username} 吗？禁用后该账号将无法继续登录。`,
      enabling ? '启用确认' : '禁用确认',
      { type: enabling ? 'info' : 'warning' }
    )
    await userApi.update(row.id, { enabled: !row.enabled })
    ElMessage.success(row.enabled ? '已禁用' : '已启用')
    loadUsers()
  } catch (err: any) {
    if (err === 'cancel' || err?.toString?.() === 'cancel') return
    ElMessage.error(err?.response?.data?.error || '操作失败')
  }
}

async function handleRoleChange(row: any, role: string) {
  const originalRole = row.role
  if (role === originalRole) return
  const roleName = getRoleName(role)
  try {
    const tips = originalRole === 'admin' && role !== 'admin'
      ? `确认将用户 ${row.username} 从「管理员」降级为「${roleName}」吗？此操作将立即剥夺该用户的管理员权限。`
      : role === 'admin'
        ? `确认将用户 ${row.username} 提升为「管理员」吗？管理员将拥有全部权限。`
        : `确认将用户 ${row.username} 的角色改为「${roleName}」吗？`
    await ElMessageBox.confirm(tips, '角色变更', { type: 'warning' })
    await userApi.update(row.id, { role })
    ElMessage.success('角色更新成功')
    loadUsers()
  } catch (err: any) {
    if (err === 'cancel' || err?.toString?.() === 'cancel') {
      // 回滚 UI
      loadUsers()
      return
    }
    ElMessage.error(err?.response?.data?.error || '更新失败')
    loadUsers()
  }
}

async function handleDelete(row: any) {
  try {
    await ElMessageBox.confirm(`确定要删除用户 ${row.username} 吗？`, '确认删除', { type: 'warning' })
    await userApi.delete(row.id)
    ElMessage.success('删除成功')
    loadUsers()
  } catch (err: any) {
    if (err === 'cancel' || err?.toString?.() === 'cancel') return
    ElMessage.error(err?.response?.data?.error || '删除失败')
  }
}

function openResetPassword(row: any) {
  resetPwdForm.value = { id: row.id, username: row.username, password: '' }
  showResetPwdDialog.value = true
}

async function handleResetPassword() {
  const pwdErr = validatePassword(resetPwdForm.value.password)
  if (pwdErr) {
    ElMessage.warning(pwdErr)
    return
  }
  try {
    await userApi.resetPassword(resetPwdForm.value.id, resetPwdForm.value.password)
    ElMessage.success('密码重置成功')
    showResetPwdDialog.value = false
  } catch (err: any) {
    ElMessage.error(err?.response?.data?.error || '重置失败')
  }
}

function getRoleTag(role: string) {
  switch (role) {
    case 'admin': return 'danger'
    case 'operator': return ''
    case 'viewer': return 'info'
    default: return 'info'
  }
}

function getRoleName(role: string) {
  switch (role) {
    case 'admin': return '管理员'
    case 'operator': return '操作员'
    case 'viewer': return '观察者'
    default: return role
  }
}
</script>

<template>
  <div class="users-page dd-fixed-page dd-page-hide-heading">
    <div class="page-header">
      <div>
        <h2>👥 用户管理</h2>
        <p class="page-subtitle">管理系统内所有用户的权限和角色，控制用户对系统各功能的访问权限</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="openCreate">
          <el-icon><Plus /></el-icon> 新建用户
        </el-button>
      </div>
    </div>

    <div class="stat-cards">
      <div class="stat-card">
        <div class="stat-card__content">
          <span class="stat-card__label">总用户</span>
          <span class="stat-card__value">{{ userStats.totalCount }}</span>
          <span class="stat-card__sub">系统用户</span>
        </div>
        <div class="stat-card__icon stat-card__icon--blue">
          <el-icon :size="22"><User /></el-icon>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-card__content">
          <span class="stat-card__label">管理员</span>
          <span class="stat-card__value stat-card__value--red">{{ userStats.adminCount }}</span>
          <span class="stat-card__sub">最高权限</span>
        </div>
        <div class="stat-card__icon stat-card__icon--red">
          <el-icon :size="22"><Star /></el-icon>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-card__content">
          <span class="stat-card__label">操作员</span>
          <span class="stat-card__value stat-card__value--orange">{{ userStats.operatorCount }}</span>
          <span class="stat-card__sub">操作权限</span>
        </div>
        <div class="stat-card__icon stat-card__icon--orange">
          <el-icon :size="22"><Operation /></el-icon>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-card__content">
          <span class="stat-card__label">观察者</span>
          <span class="stat-card__value stat-card__value--green">{{ userStats.viewerCount }}</span>
          <span class="stat-card__sub">只读权限</span>
        </div>
        <div class="stat-card__icon stat-card__icon--green">
          <el-icon :size="22"><View /></el-icon>
        </div>
      </div>
    </div>

    <div class="toolbar">
      <div class="toolbar__left">
        <div class="status-tabs">
          <button :class="['status-tab', { active: roleFilter === '' }]" @click="roleFilter = ''; handleSearch()">全部</button>
          <button :class="['status-tab', { active: roleFilter === 'admin' }]" @click="roleFilter = 'admin'; handleSearch()">管理员</button>
          <button :class="['status-tab', { active: roleFilter === 'operator' }]" @click="roleFilter = 'operator'; handleSearch()">操作员</button>
          <button :class="['status-tab', { active: roleFilter === 'viewer' }]" @click="roleFilter = 'viewer'; handleSearch()">观察者</button>
        </div>
        <el-input v-model="keyword" placeholder="搜索用户名/角色" clearable class="toolbar__search" @input="handleSearch">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
      </div>
      <div class="toolbar__right">
        <el-button type="primary" @click="openCreate">
          <el-icon><Plus /></el-icon> 新建用户
        </el-button>
      </div>
    </div>

    <div v-if="isMobile" class="dd-mobile-list">
      <div v-for="row in pagedUsers" :key="row.id" class="dd-mobile-card">
        <div class="dd-mobile-card__header">
          <div class="dd-mobile-card__title-wrap">
            <span class="dd-mobile-card__title">{{ row.username }}</span>
            <div class="dd-mobile-card__badges">
              <el-tag size="small" :type="getRoleTag(row.role)">{{ getRoleName(row.role) }}</el-tag>
              <el-tag v-if="row.two_factor_enabled" size="small" type="success" effect="plain">2FA</el-tag>
            </div>
          </div>
          <el-switch :model-value="row.enabled" size="small" :disabled="row.username === authStore.user?.username" @change="handleToggle(row)" />
        </div>
        <div class="dd-mobile-card__body">
          <div class="dd-mobile-card__grid">
            <div class="dd-mobile-card__field">
              <span class="dd-mobile-card__label">角色</span>
              <div class="dd-mobile-card__value">
                <el-select :model-value="row.role" size="small" :disabled="row.username === authStore.user?.username" @change="(val: string) => handleRoleChange(row, val)">
                  <el-option value="admin" label="管理员" />
                  <el-option value="operator" label="操作员" />
                  <el-option value="viewer" label="观察者" />
                </el-select>
              </div>
            </div>
            <div class="dd-mobile-card__field">
              <span class="dd-mobile-card__label">最后登录</span>
              <span class="dd-mobile-card__value">{{ row.last_login_at ? new Date(row.last_login_at).toLocaleString() : '-' }}</span>
            </div>
            <div class="dd-mobile-card__field">
              <span class="dd-mobile-card__label">创建时间</span>
              <span class="dd-mobile-card__value">{{ new Date(row.created_at).toLocaleString() }}</span>
            </div>
          </div>
          <div class="dd-mobile-card__actions user-card__actions">
            <el-button size="small" type="primary" plain @click="openResetPassword(row)">重置密码</el-button>
            <el-button size="small" type="danger" plain :disabled="row.username === authStore.user?.username" @click="handleDelete(row)">删除</el-button>
          </div>
        </div>
      </div>
      <el-empty v-if="!loading && pagedUsers.length === 0" description="暂无用户" />
    </div>

    <div v-else class="table-card">
      <el-table :data="pagedUsers" v-loading="loading" style="width: 100%" :header-cell-style="{ background: '#f8fafc', color: '#64748b', fontWeight: 600, fontSize: '13px' }">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="username" label="用户名" min-width="150">
          <template #default="{ row }">
            <div class="user-name-cell">
              <div class="user-avatar">{{ (row.username || '?')[0].toUpperCase() }}</div>
              <div class="user-name-info">
                <span class="user-name-text">{{ row.username }}</span>
                <el-tag size="small" :type="getRoleTag(row.role)" round>{{ getRoleName(row.role) }}</el-tag>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="角色" width="140">
          <template #default="{ row }">
            <el-select :model-value="row.role" size="small" :disabled="row.username === authStore.user?.username" @change="(val: string) => handleRoleChange(row, val)">
              <el-option value="admin" label="管理员" />
              <el-option value="operator" label="操作员" />
              <el-option value="viewer" label="观察者" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="2FA" width="80" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.two_factor_enabled" size="small" type="success" effect="plain" round>已启用</el-tag>
            <span v-else class="text-secondary">-</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-switch :model-value="row.enabled" size="small" :disabled="row.username === authStore.user?.username" @change="handleToggle(row)" />
          </template>
        </el-table-column>
        <el-table-column label="最后登录" width="170">
          <template #default="{ row }">
            <span v-if="row.last_login_at" class="time-text">{{ new Date(row.last_login_at).toLocaleString() }}</span>
            <span v-else class="text-secondary">-</span>
          </template>
        </el-table-column>
        <el-table-column label="创建时间" width="170">
          <template #default="{ row }">
            <span class="time-text">{{ new Date(row.created_at).toLocaleString() }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160" fixed="right" align="center">
          <template #default="{ row }">
            <div class="action-btns">
              <el-button size="small" text type="primary" @click="openResetPassword(row)">重置密码</el-button>
              <el-button size="small" text type="danger" :disabled="row.username === authStore.user?.username" @click="handleDelete(row)">删除</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div class="pagination-bar">
      <span class="pagination-total">共 {{ total }} 条数据</span>
      <el-pagination
        v-model:current-page="page"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="sizes, prev, pager, next"
      />
    </div>

    <el-dialog v-model="showCreateDialog" title="新建用户" width="400px" :fullscreen="dialogFullscreen">
      <el-form :model="createForm" :label-width="dialogFullscreen ? 'auto' : '80px'" :label-position="dialogFullscreen ? 'top' : 'right'">
        <el-form-item label="用户名">
          <el-input v-model="createForm.username" placeholder="3-32 位字母/数字/下划线" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="createForm.password" type="password" show-password placeholder="6-128 位密码" />
        </el-form-item>
        <el-form-item label="角色">
          <el-radio-group v-model="createForm.role">
            <el-radio value="admin">管理员</el-radio>
            <el-radio value="operator">操作员</el-radio>
            <el-radio value="viewer">观察者</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="handleCreate">创建</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showResetPwdDialog" title="重置密码" width="400px" :fullscreen="dialogFullscreen">
      <el-form :model="resetPwdForm" :label-width="dialogFullscreen ? 'auto' : '80px'" :label-position="dialogFullscreen ? 'top' : 'right'">
        <el-form-item label="用户">
          <el-input :model-value="resetPwdForm.username" disabled />
        </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="resetPwdForm.password" type="password" show-password placeholder="6-128 位密码" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showResetPwdDialog = false">取消</el-button>
        <el-button type="primary" @click="handleResetPassword">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.users-page { padding: 0; }

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
  &__icon {
    width: 44px; height: 44px; border-radius: 12px;
    display: flex; align-items: center; justify-content: center; flex-shrink: 0;
    &--blue { background: rgba(59, 130, 246, 0.12); color: #3b82f6; }
    &--green { background: rgba(16, 185, 129, 0.12); color: #10b981; }
    &--orange { background: rgba(245, 158, 11, 0.12); color: #f59e0b; }
    &--red { background: rgba(239, 68, 68, 0.12); color: #ef4444; }
    &--purple { background: rgba(139, 92, 246, 0.12); color: #8b5cf6; }
  }
}

.toolbar {
  display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; gap: 12px; flex-wrap: wrap;
  &__left { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; flex: 1; min-width: 0; }
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

.user-name-cell { display: flex; align-items: center; gap: 12px; }
.user-avatar {
  width: 36px; height: 36px; border-radius: 50%;
  background: linear-gradient(135deg, #3b82f6, #60a5fa);
  color: #fff; display: flex; align-items: center; justify-content: center;
  font-weight: 600; font-size: 14px; flex-shrink: 0;
}
.user-name-info { display: flex; align-items: center; gap: 8px; }
.user-name-text { font-weight: 500; color: var(--el-text-color-primary); }
.text-secondary { color: var(--el-text-color-secondary); }
.time-text { font-family: var(--dd-font-mono); font-size: 12px; color: var(--el-text-color-regular); }
.action-btns { display: flex; align-items: center; justify-content: center; gap: 2px; }
.user-card__actions > * { flex: 1 1 calc(50% - 4px); }

.pagination-bar {
  margin-top: 20px; display: flex; justify-content: space-between; align-items: center; padding: 0 4px;
}
.pagination-total { font-size: 13px; color: var(--el-text-color-secondary); }

:deep(.el-table) {
  --el-table-border-color: #f0f0f0;
  .el-table__header-wrapper th { border-bottom: 1px solid #e8e8e8; }
  .el-table__row td { border-bottom: 1px solid #f5f5f5; }
  .el-table__cell { padding: 12px 0; }
}

@media screen and (max-width: 1200px) {
  .stat-cards { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 768px) {
  .page-header { flex-direction: column; gap: 10px; margin-bottom: 14px; h2 { font-size: 18px; } }
  .stat-cards { grid-template-columns: repeat(2, 1fr); gap: 10px; }
  .stat-card { padding: 14px 16px; &__value { font-size: 22px; } &__icon { width: 40px; height: 40px; } }
  .toolbar { flex-direction: column; align-items: stretch; gap: 10px;
    &__left { flex-direction: column; gap: 10px; }
    &__search { width: 100% !important; }
  }
  .status-tabs { width: 100%; overflow-x: auto; }
}
</style>
