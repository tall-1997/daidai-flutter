import fs from 'node:fs'
import path from 'node:path'

const sourceDir = path.resolve(process.cwd(), 'node_modules/monaco-editor/min')
const targetDir = path.resolve(process.cwd(), 'dist/monaco')

function copyDirectory(source, target) {
  fs.mkdirSync(target, { recursive: true })

  for (const entry of fs.readdirSync(source, { withFileTypes: true })) {
    const sourcePath = path.join(source, entry.name)
    const targetPath = path.join(target, entry.name)

    if (entry.isDirectory()) {
      copyDirectory(sourcePath, targetPath)
      continue
    }

    fs.copyFileSync(sourcePath, targetPath)
  }
}

copyDirectory(sourceDir, targetDir)
console.log('[copy-monaco-assets] copied monaco-editor/min -> dist/monaco')
