package service

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"daidai-panel/pkg/pathutil"
)

type LogStreamManager struct {
	mu        sync.Mutex
	streams   map[string]*os.File
	fileSizes map[string]int64
	maxSize   int64
}

var logStreamMgr = &LogStreamManager{
	streams:   make(map[string]*os.File),
	fileSizes: make(map[string]int64),
	maxSize:   10 * 1024 * 1024,
}

func GetLogStreamManager() *LogStreamManager {
	return logStreamMgr
}

func (m *LogStreamManager) Write(filePath, data string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	f, exists := m.streams[filePath]
	if !exists {
		dir := filepath.Dir(filePath)
		os.MkdirAll(dir, 0755)

		var err error
		f, err = os.OpenFile(filePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
		if err != nil {
			return err
		}
		m.streams[filePath] = f
		m.fileSizes[filePath] = 0
	}

	if m.fileSizes[filePath] >= m.maxSize {
		return nil
	}

	n, err := f.WriteString(data)
	if err != nil {
		return err
	}
	f.Sync()
	m.fileSizes[filePath] += int64(n)

	if m.fileSizes[filePath] >= m.maxSize {
		f.WriteString("\n[日志文件已达到大小限制，停止写入]")
		f.Sync()
	}

	return nil
}

func (m *LogStreamManager) CloseStream(filePath string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if f, ok := m.streams[filePath]; ok {
		f.Close()
		delete(m.streams, filePath)
		delete(m.fileSizes, filePath)
	}
}

func (m *LogStreamManager) CloseAll() {
	m.mu.Lock()
	defer m.mu.Unlock()

	for _, f := range m.streams {
		f.Close()
	}
	m.streams = make(map[string]*os.File)
	m.fileSizes = make(map[string]int64)
}

func GetLogPath(taskID uint, logDir string) string {
	ts := time.Now().Format("2006-01-02-15-04-05-000")
	dir := filepath.Join(logDir, fmt.Sprintf("task_%d", taskID))
	return filepath.Join(dir, ts+".log")
}

func GetRelativeLogPath(taskID uint) string {
	ts := time.Now().Format("2006-01-02-15-04-05-000")
	return fmt.Sprintf("task_%d/%s.log", taskID, ts)
}

func ReadLogFile(logPath, logDir string) (string, error) {
	fullPath := logPath
	if !filepath.IsAbs(logPath) {
		fullPath = filepath.Join(logDir, logPath)
	}

	absPath, err := pathutil.ResolveWithinBase(logDir, fullPath, true)
	if err != nil {
		if os.IsNotExist(err) {
			return "", err
		}
		return "", fmt.Errorf("检测到路径遍历攻击")
	}

	data, err := os.ReadFile(absPath)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

type LogFileInfo struct {
	Filename  string `json:"filename"`
	Path      string `json:"path"`
	Size      int64  `json:"size"`
	CreatedAt string `json:"created_at"`
}

func ListLogFiles(taskID uint, logDir string) []LogFileInfo {
	dir := filepath.Join(logDir, fmt.Sprintf("task_%d", taskID))
	entries, err := os.ReadDir(dir)
	if err != nil {
		return []LogFileInfo{}
	}

	files := make([]LogFileInfo, 0)
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".log") {
			continue
		}
		info, err := entry.Info()
		if err != nil {
			continue
		}
		relPath := fmt.Sprintf("task_%d/%s", taskID, entry.Name())
		files = append(files, LogFileInfo{
			Filename:  entry.Name(),
			Path:      relPath,
			Size:      info.Size(),
			CreatedAt: info.ModTime().Format(time.RFC3339),
		})
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].Filename > files[j].Filename
	})

	return files
}

func DeleteLogFile(logPath, logDir string) error {
	fullPath := logPath
	if !filepath.IsAbs(logPath) {
		fullPath = filepath.Join(logDir, logPath)
	}

	absPath, err := pathutil.ResolveWithinBase(logDir, fullPath, true)
	if err != nil {
		if os.IsNotExist(err) {
			return err
		}
		return fmt.Errorf("检测到路径遍历攻击")
	}

	return os.Remove(absPath)
}

func CleanOldLogs(logDir string, days int) int {
	cutoff := time.Now().AddDate(0, 0, -days)
	count := 0

	filepath.Walk(logDir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return nil
		}
		if !strings.HasSuffix(info.Name(), ".log") {
			return nil
		}
		if info.ModTime().Before(cutoff) {
			if os.Remove(path) == nil {
				count++
			}
		}
		return nil
	})

	entries, _ := os.ReadDir(logDir)
	for _, entry := range entries {
		if entry.IsDir() && strings.HasPrefix(entry.Name(), "task_") {
			taskDir := filepath.Join(logDir, entry.Name())
			subEntries, _ := os.ReadDir(taskDir)
			if len(subEntries) == 0 {
				os.Remove(taskDir)
			}
		}
	}

	return count
}
