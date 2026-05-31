import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

const MOBILE_BREAKPOINT = 768
const TABLET_BREAKPOINT = 1024

export function useResponsive() {
  const width = ref(typeof window !== 'undefined' ? window.innerWidth : TABLET_BREAKPOINT)
  const height = ref(typeof window !== 'undefined' ? window.innerHeight : 0)

  function updateViewport() {
    if (typeof window === 'undefined') return
    width.value = window.innerWidth
    height.value = window.innerHeight
  }

  onMounted(() => {
    updateViewport()
    window.addEventListener('resize', updateViewport, { passive: true })
  })

  onBeforeUnmount(() => {
    if (typeof window === 'undefined') return
    window.removeEventListener('resize', updateViewport)
  })

  const isMobile = computed(() => width.value <= MOBILE_BREAKPOINT)
  const isTablet = computed(() => width.value <= TABLET_BREAKPOINT)
  const dialogFullscreen = computed(() => isMobile.value)

  return {
    width,
    height,
    isMobile,
    isTablet,
    dialogFullscreen,
    updateViewport,
  }
}
