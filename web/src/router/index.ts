import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { getCachedPanelTitle, loadPanelSettings } from '@/utils/panelSettings'

const roleLevel: Record<string, number> = {
  viewer: 1,
  operator: 2,
  admin: 3,
}

function hasRequiredRole(role: string | undefined, minRole: string | undefined) {
  if (!minRole) return true
  if (!role) return false
  return (roleLevel[role] || 0) >= (roleLevel[minRole] || 0)
}

const legacyRouteMap: Record<string, string> = {
  '/notifications': '/admin/notifications',
  '/users': '/admin/users',
  '/open-api': '/admin/open-api',
  '/admin/deps': '/deps',
}

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'Login',
      component: () => import('@/views/login/index.vue'),
      meta: { requiresAuth: false }
    },
    {
      path: '/',
      component: () => import('@/layouts/MainLayout.vue'),
      meta: { requiresAuth: true, section: 'workspace' },
      children: [
        {
          path: '',
          redirect: '/dashboard'
        },
        {
          path: 'dashboard',
          name: 'Dashboard',
          component: () => import('@/views/dashboard/index.vue'),
          meta: { title: '仪表板', icon: 'Odometer', minRole: 'viewer' }
        },
        {
          path: 'tasks',
          name: 'Tasks',
          component: () => import('@/views/tasks/index.vue'),
          meta: { title: '定时任务', icon: 'Timer', minRole: 'viewer' }
        },
        {
          path: 'scripts',
          name: 'Scripts',
          component: () => import('@/views/scripts/index.vue'),
          meta: { title: '脚本管理', icon: 'Document', minRole: 'operator' }
        },
        {
          path: 'envs',
          name: 'Envs',
          component: () => import('@/views/envs/index.vue'),
          meta: { title: '环境变量', icon: 'Setting', minRole: 'operator' }
        },
        {
          path: 'subscriptions',
          name: 'Subscriptions',
          component: () => import('@/views/subscriptions/index.vue'),
          meta: { title: '订阅管理', icon: 'Download', minRole: 'operator' }
        },
        {
          path: 'logs',
          name: 'Logs',
          component: () => import('@/views/logs/index.vue'),
          meta: { title: '执行日志', icon: 'Tickets', minRole: 'viewer' }
        },
        {
          path: 'deps',
          name: 'Deps',
          component: () => import('@/views/deps/index.vue'),
          meta: { title: '依赖管理', icon: 'Box', minRole: 'admin' }
        },
        {
          path: 'notifications',
          name: 'Notifications',
          component: () => import('@/views/notifications/index.vue'),
          meta: { title: '通知渠道', icon: 'Bell', minRole: 'admin' }
        },
        {
          path: 'users',
          name: 'Users',
          component: () => import('@/views/users/index.vue'),
          meta: { title: '用户管理', icon: 'UserFilled', minRole: 'admin' }
        },
        {
          path: 'profile',
          name: 'Profile',
          component: () => import('@/views/profile/index.vue'),
          meta: { title: '个人设置', icon: 'User', minRole: 'viewer' }
        },
        {
          path: 'api-docs',
          name: 'ApiDocs',
          component: () => import('@/views/api-docs/index.vue'),
          meta: { title: '接口文档', icon: 'Connection', minRole: 'viewer' }
        }
      ]
    },
    {
      path: '/admin',
      component: () => import('@/layouts/MainLayout.vue'),
      meta: { requiresAuth: true, section: 'admin' },
      children: [
        {
          path: '',
          redirect: '/admin/settings'
        },
        {
          path: 'settings',
          name: 'AdminSettings',
          component: () => import('@/views/settings/index.vue'),
          meta: { title: '系统设置', icon: 'SetUp', minRole: 'admin' }
        },
        {
          path: 'notifications',
          name: 'AdminNotifications',
          component: () => import('@/views/notifications/index.vue'),
          meta: { title: '通知渠道', icon: 'Bell', minRole: 'admin' }
        },
        {
          path: 'users',
          name: 'AdminUsers',
          component: () => import('@/views/users/index.vue'),
          meta: { title: '用户管理', icon: 'UserFilled', minRole: 'admin' }
        },
        {
          path: 'open-api',
          name: 'AdminOpenAPI',
          component: () => import('@/views/open-api/index.vue'),
          meta: { title: 'Open API', icon: 'Key', minRole: 'admin' }
        }
      ]
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/'
    }
  ]
})

router.beforeEach(async (to, _from, next) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAuth === false) {
    if (authStore.isLoggedIn && to.name === 'Login') {
      next('/')
      return
    }
    next()
    return
  }

  if (!authStore.isLoggedIn) {
    next('/login')
    return
  }

  if (!authStore.user) {
    try {
      await authStore.fetchUser()
    } catch {
      authStore.clearAuth()
      next('/login')
      return
    }
  }

  if (to.path === '/settings') {
    next(hasRequiredRole(authStore.user?.role, 'admin') ? '/admin/settings' : '/profile')
    return
  }

  const legacyRedirect = legacyRouteMap[to.path]
  if (legacyRedirect) {
    if (!hasRequiredRole(authStore.user?.role, 'admin')) {
      next('/dashboard')
      return
    }
    next(legacyRedirect)
    return
  }

  const minRole = to.meta.minRole as string | undefined
  if (!hasRequiredRole(authStore.user?.role, minRole)) {
    next('/dashboard')
    return
  }

  next()
})

router.afterEach((to) => {
  const title = to.meta.title as string | undefined
  const panelTitle = getCachedPanelTitle()
  document.title = title ? `${panelTitle} - ${title}` : panelTitle
})

void loadPanelSettings().then(() => {
  const currentRoute = router.currentRoute.value
  const title = currentRoute.meta.title as string | undefined
  const panelTitle = getCachedPanelTitle()
  document.title = title ? `${panelTitle} - ${title}` : panelTitle
})

export default router
