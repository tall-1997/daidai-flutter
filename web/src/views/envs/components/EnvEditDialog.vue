<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { useResponsive } from '@/composables/useResponsive'

type EnvFormModel = {
  id: number
  name: string
  value: string
  remarks: string
  group?: string
  groups: string[]
}

const props = withDefaults(defineProps<{
  modelValue: boolean
  mode: 'create' | 'edit'
  initialData?: EnvFormModel | null
  groups?: string[]
}>(), {
  initialData: null,
  groups: () => []
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  save: [value: EnvFormModel | EnvFormModel[]]
}>()

function splitEnvGroups(value: string): string[] {
  return value
    .split(/[,，;；\n\r\t]/)
    .map(group => group.trim())
    .filter((group, index, list) => group !== '' && list.indexOf(group) === index)
}

function normalizeGroupList(groups: string[]): string[] {
  return splitEnvGroups(groups.join(','))
}

function createEmptyForm(): EnvFormModel {
  return { id: 0, name: '', value: '', remarks: '', group: '', groups: [] }
}

const form = ref<EnvFormModel>(createEmptyForm())
const splitMode = ref(false)
const { dialogFullscreen } = useResponsive()

const isCreate = computed(() => props.mode === 'create')
const dialogTitle = computed(() => isCreate.value ? '新建环境变量' : '编辑环境变量')
const submitText = computed(() => isCreate.value ? '创建' : '保存')

function syncForm() {
  const initial = props.initialData ?? createEmptyForm()
  const initialGroups = initial.groups?.length
    ? normalizeGroupList(initial.groups)
    : splitEnvGroups(initial.group || '')
  form.value = {
    ...createEmptyForm(),
    ...initial,
    group: initialGroups.join(','),
    groups: initialGroups
  }
  splitMode.value = false
}

function closeDialog() {
  emit('update:modelValue', false)
}

function handleSave() {
  const name = form.value.name.trim()
  const remarks = form.value.remarks.trim()
  const groups = normalizeGroupList(form.value.groups)
  const group = groups.join(',')

  if (!name) {
    ElMessage.warning('变量名不能为空')
    return
  }

  if (isCreate.value && splitMode.value) {
    const lines = form.value.value.split('\n').filter(line => line.trim() !== '')
    if (lines.length === 0) {
      ElMessage.warning('请输入至少一行变量值')
      return
    }
    const items: EnvFormModel[] = lines.map(line => ({
      id: 0,
      name,
      value: line.trim(),
      remarks,
      group,
      groups
    }))
    emit('save', items)
  } else {
    emit('save', {
      id: form.value.id,
      name,
      value: form.value.value,
      remarks,
      group,
      groups
    })
  }
}

watch(
  () => [props.modelValue, props.initialData, props.mode],
  ([visible]) => {
    if (visible) {
      syncForm()
    }
  },
  { immediate: true }
)
</script>

<template>
  <el-dialog
    :model-value="modelValue"
    :title="dialogTitle"
    width="500px"
    :fullscreen="dialogFullscreen"
    :close-on-click-modal="false"
    destroy-on-close
    @update:model-value="emit('update:modelValue', $event)"
  >
    <el-form :model="form" :label-width="dialogFullscreen ? 'auto' : '80px'" :label-position="dialogFullscreen ? 'top' : 'right'">
      <el-form-item label="变量名">
        <el-input v-model="form.name" placeholder="变量名 (如: API_KEY)" />
      </el-form-item>
      <el-form-item v-if="isCreate" label="按行拆分">
        <div style="display: flex; align-items: center; gap: 8px; width: 100%">
          <el-switch v-model="splitMode" />
          <span style="font-size: 12px; color: var(--el-text-color-secondary)">
            {{ splitMode ? '每行创建一个变量' : '所有行作为一个变量值' }}
          </span>
        </div>
      </el-form-item>
      <el-form-item label="值">
        <el-input v-model="form.value" type="textarea" :rows="isCreate ? 5 : 3" :placeholder="splitMode ? '每行一个值' : '变量值'" />
      </el-form-item>
      <el-form-item label="备注">
        <el-input v-model="form.remarks" placeholder="备注说明" />
      </el-form-item>
      <el-form-item label="分组">
        <el-select
          v-model="form.groups"
          multiple
          filterable
          allow-create
          default-first-option
          collapse-tags
          collapse-tags-tooltip
          clearable
          placeholder="可选择多个分组，也可直接输入新分组"
          style="width: 100%"
        >
          <el-option v-for="group in groups" :key="group" :label="group" :value="group" />
        </el-select>
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="closeDialog">取消</el-button>
      <el-button type="primary" @click="handleSave">{{ submitText }}</el-button>
    </template>
  </el-dialog>
</template>
