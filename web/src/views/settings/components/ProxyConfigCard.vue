<script setup lang="ts">
import { Connection, Document } from '@element-plus/icons-vue'
import type { SettingsConfigForm } from '../types'

defineProps<{
  configsSaving: boolean
  form: SettingsConfigForm
  onSave: () => void
}>()
</script>

<template>
  <el-card shadow="never">
    <template #header>
      <div class="card-header">
        <span class="card-title"><el-icon><Connection /></el-icon> 网络代理</span>
        <el-button type="primary" :loading="configsSaving" @click="onSave">
          <el-icon><Document /></el-icon>保存配置
        </el-button>
      </div>
    </template>

    <div class="form-field">
      <label>代理地址</label>
      <el-input v-model="form.proxy_url" placeholder="http://127.0.0.1:7890" />
      <span class="form-hint">支持 HTTP/SOCKS5，如 http://127.0.0.1:7890</span>
    </div>

    <div class="form-field">
      <label>系统更新镜像源</label>
      <div class="mirror-row">
        <el-input v-model="form.update_image_mirror" placeholder="docker.1ms.run" />
        <el-button text type="primary" @click="form.update_image_mirror = 'docker.1ms.run'">
          使用推荐镜像
        </el-button>
        <el-button
          v-if="form.update_image_mirror"
          text
          type="danger"
          @click="form.update_image_mirror = ''"
        >
          恢复直连
        </el-button>
      </div>
      <span class="form-hint">
        可填写 docker.1ms.run 或 https://docker.1ms.run/。留空则直接从默认镜像仓库拉取更新镜像。
      </span>
    </div>

    <div class="switch-row">
      <div class="switch-item">
        <span class="switch-label">静默更新</span>
        <el-switch v-model="form.auto_update_enabled" inline-prompt active-text="开" inactive-text="关" />
      </div>
    </div>
    <span class="form-hint">开启后每 24 小时自动检查一次新版本；若检测到更新，将按当前镜像渠道自动尝试更新并通过通知渠道反馈结果。</span>

    <div class="form-field">
      <label>可信代理 CIDR</label>
      <el-input
        v-model="form.trusted_proxy_cidrs"
        type="textarea"
        :rows="5"
        placeholder="127.0.0.1/32&#10;10.0.0.0/8&#10;203.0.113.10"
      />
      <span class="form-hint">
        支持 IP、CIDR、逗号或换行分隔。留空会恢复默认私网段与本机地址；保存后客户端 IP 解析会按这份列表判断可信代理。
      </span>
    </div>
  </el-card>
</template>

<style scoped lang="scss">
@use './config-card-shared.scss' as *;

.mirror-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

@media (max-width: 768px) {
  .mirror-row {
    align-items: stretch;
  }
}
</style>
