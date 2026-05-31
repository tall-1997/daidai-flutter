import axios from 'axios'
import type { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios'
import { useAuthStore } from '@/stores/auth'
import router from '@/router'

const request: AxiosInstance = axios.create({
  baseURL: '/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    'X-Client-Type': 'web',
    'X-Client-App': 'daidai-panel-web'
  }
})

let isRefreshing = false
let pendingRequests: Array<(token: string) => void> = []

function resolvePending(token: string) {
  pendingRequests.forEach(cb => cb(token))
  pendingRequests = []
}

request.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const authStore = useAuthStore()
    if (authStore.accessToken) {
      config.headers.Authorization = `Bearer ${authStore.accessToken}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

request.interceptors.response.use(
  (response: AxiosResponse) => response.data,
  async (error) => {
    const originalRequest = error.config

    if (error.response?.status === 401 && !originalRequest._retry) {
      const authStore = useAuthStore()

      if (!authStore.refreshToken) {
        authStore.clearAuth()
        router.push('/login')
        return Promise.reject(error)
      }

      if (isRefreshing) {
        return new Promise((resolve) => {
          pendingRequests.push((token: string) => {
            originalRequest.headers.Authorization = `Bearer ${token}`
            resolve(request(originalRequest))
          })
        })
      }

      originalRequest._retry = true
      isRefreshing = true

      try {
        const newToken = await authStore.refreshAccessToken()
        isRefreshing = false
        resolvePending(newToken)
        originalRequest.headers.Authorization = `Bearer ${newToken}`
        return request(originalRequest)
      } catch {
        isRefreshing = false
        pendingRequests = []
        authStore.clearAuth()
        router.push('/login')
        return Promise.reject(error)
      }
    }

    return Promise.reject(error)
  }
)

export default request
