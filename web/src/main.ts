import { createApp } from 'vue'
import { createPinia } from 'pinia'
import 'element-plus/theme-chalk/dark/css-vars.css'
import 'element-plus/theme-chalk/el-loading.css'
import 'element-plus/theme-chalk/el-message.css'
import 'element-plus/theme-chalk/el-message-box.css'
import {
  ArrowLeft,
  ArrowRight,
  Bell,
  Box,
  Check,
  CircleCheck,
  CircleCheckFilled,
  CircleClose,
  Clock,
  Close,
  Connection,
  CopyDocument,
  Delete,
  Document,
  DocumentAdd,
  DocumentCopy,
  Download,
  Edit,
  Expand,
  Fold,
  Folder,
  FolderAdd,
  Hide,
  InfoFilled,
  Key,
  Lock,
  Menu,
  Monitor,
  Moon,
  More,
  MoreFilled,
  Odometer,
  Operation,
  Plus,
  Rank,
  Refresh,
  RefreshRight,
  Search,
  Setting,
  SetUp,
  Star,
  Sunny,
  Tickets,
  Timer,
  Top,
  Unlock,
  Upload,
  User,
  UserFilled,
  VideoPause,
  VideoPlay,
  View,
} from '@element-plus/icons-vue'
import App from './App.vue'
import router from './router'
import { fetchAndApplyPanelAppearance } from './utils/panelAppearance'
import './styles/global.scss'
import './styles/animations.css'
import './styles/visual-enhancements.css'

const app = createApp(App)

app.use(createPinia())
app.use(router)

void fetchAndApplyPanelAppearance()

const globalIcons = {
  ArrowLeft,
  ArrowRight,
  Bell,
  Box,
  Check,
  CircleCheck,
  CircleCheckFilled,
  CircleClose,
  Clock,
  Close,
  Connection,
  CopyDocument,
  Delete,
  Document,
  DocumentAdd,
  DocumentCopy,
  Download,
  Edit,
  Expand,
  Fold,
  Folder,
  FolderAdd,
  Hide,
  InfoFilled,
  Key,
  Lock,
  Menu,
  Monitor,
  Moon,
  More,
  MoreFilled,
  Odometer,
  Operation,
  Plus,
  Rank,
  Refresh,
  RefreshRight,
  Search,
  Setting,
  SetUp,
  Star,
  Sunny,
  Tickets,
  Timer,
  Top,
  Unlock,
  Upload,
  User,
  UserFilled,
  VideoPause,
  VideoPlay,
  View,
}

for (const [key, component] of Object.entries(globalIcons)) {
  app.component(key, component)
}

app.mount('#app')
