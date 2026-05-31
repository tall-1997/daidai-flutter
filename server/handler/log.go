package handler

import (
	"fmt"
	"io"
	"strconv"
	"strings"
	"time"

	"daidai-panel/config"
	"daidai-panel/database"
	"daidai-panel/middleware"
	"daidai-panel/model"
	"daidai-panel/pkg/response"
	"daidai-panel/service"

	"github.com/gin-gonic/gin"
)

type LogHandler struct{}

func NewLogHandler() *LogHandler {
	return &LogHandler{}
}

func (h *LogHandler) List(c *gin.Context) {
	taskIDStr := c.Query("task_id")
	statusStr := c.Query("status")
	keyword := c.Query("keyword")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	query := database.DB.Model(&model.TaskLog{}).
		Joins("LEFT JOIN tasks ON tasks.id = task_logs.task_id")

	if taskIDStr != "" {
		taskID, _ := strconv.ParseUint(taskIDStr, 10, 32)
		query = query.Where("task_logs.task_id = ?", taskID)
	}
	if statusStr != "" {
		status, err := strconv.Atoi(statusStr)
		if err == nil {
			query = query.Where("task_logs.status = ?", status)
		}
	}
	if keyword != "" {
		query = query.Where("tasks.name LIKE ?", "%"+keyword+"%")
	}

	var total int64
	query.Count(&total)

	var logs []model.TaskLog
	query.Select("task_logs.*").
		Preload("Task").
		Order("task_logs.started_at DESC").
		Offset((page - 1) * pageSize).Limit(pageSize).Find(&logs)

	data := make([]map[string]interface{}, len(logs))
	for i, l := range logs {
		data[i] = l.ToDict()
	}

	response.Paginated(c, data, total, page, pageSize)
}

func (h *LogHandler) Stream(c *gin.Context) {
	taskIDStr := c.Param("id")
	taskID, _ := strconv.ParseUint(taskIDStr, 10, 32)

	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("X-Accel-Buffering", "no")

	mgr := service.GetTinyLogManager()
	tl := mgr.FindByTaskID(uint(taskID))

	if tl != nil {
		history, _ := tl.ReadAll()
		if len(history) > 0 {
			for _, line := range strings.Split(string(history), "\n") {
				if line != "" {
					fmt.Fprintf(c.Writer, "data: %s\n\n", line)
				}
			}
			c.Writer.Flush()
		}

		sub := tl.Subscribe()
		defer tl.Unsubscribe(sub)

		ctx := c.Request.Context()
		for {
			select {
			case data, ok := <-sub:
				if !ok {
					fmt.Fprintf(c.Writer, "event: done\ndata: finished\n\n")
					c.Writer.Flush()
					return
				}
				for _, line := range strings.Split(string(data), "\n") {
					if line != "" {
						fmt.Fprintf(c.Writer, "data: %s\n\n", line)
					}
				}
				c.Writer.Flush()
			case <-ctx.Done():
				return
			case <-time.After(60 * time.Second):
				fmt.Fprintf(c.Writer, "event: done\ndata: timeout\n\n")
				c.Writer.Flush()
				return
			}
		}
	}

	var task model.Task
	database.DB.First(&task, taskID)
	if task.Status != model.TaskStatusRunning {
		time.Sleep(1500 * time.Millisecond)
		tl = mgr.FindByTaskID(uint(taskID))
		if tl != nil {
			history, _ := tl.ReadAll()
			if len(history) > 0 {
				for _, line := range strings.Split(string(history), "\n") {
					if line != "" {
						fmt.Fprintf(c.Writer, "data: %s\n\n", line)
					}
				}
				c.Writer.Flush()
			}
		}
		fmt.Fprintf(c.Writer, "event: done\ndata: finished\n\n")
		c.Writer.Flush()
	} else {
		idleCount := 0
		c.Stream(func(w io.Writer) bool {
			tl = mgr.FindByTaskID(uint(taskID))
			if tl != nil {
				history, _ := tl.ReadAll()
				if len(history) > 0 {
					fmt.Fprintf(w, "data: %s\n\n", string(history))
					c.Writer.Flush()
				}
				fmt.Fprintf(w, "event: done\ndata: reconnect\n\n")
				c.Writer.Flush()
				return false
			}

			idleCount++
			if idleCount >= 120 {
				fmt.Fprintf(w, "event: done\ndata: timeout\n\n")
				c.Writer.Flush()
				return false
			}

			time.Sleep(500 * time.Millisecond)
			return true
		})
	}
}

func (h *LogHandler) Detail(c *gin.Context) {
	logID, _ := strconv.ParseUint(c.Param("id"), 10, 32)

	var taskLog model.TaskLog
	if err := database.DB.Preload("Task").First(&taskLog, logID).Error; err != nil {
		response.NotFound(c, "日志不存在")
		return
	}

	result := taskLog.ToDict()
	if taskLog.Content != "" {
		decompressed, err := service.DecompressFromBase64(taskLog.Content)
		if err == nil {
			result["content"] = decompressed
		}
	} else if taskLog.LogPath != nil {
		content, err := service.ReadLogFile(*taskLog.LogPath, config.C.Data.LogDir)
		if err == nil {
			result["content"] = content
		}
	}

	response.Success(c, result)
}

func (h *LogHandler) Delete(c *gin.Context) {
	logID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		response.BadRequest(c, "无效的日志ID")
		return
	}
	result := database.DB.Where("id = ?", logID).Delete(&model.TaskLog{})
	if result.RowsAffected == 0 {
		response.NotFound(c, "日志不存在")
		return
	}
	response.Success(c, gin.H{"message": "日志已删除"})
}

func (h *LogHandler) BatchDelete(c *gin.Context) {
	var req struct {
		IDs []uint `json:"ids" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil || len(req.IDs) == 0 {
		response.BadRequest(c, "请求参数错误")
		return
	}

	result := database.DB.Where("id IN ?", req.IDs).Delete(&model.TaskLog{})
	response.Success(c, gin.H{
		"message": fmt.Sprintf("已删除 %d 条日志", result.RowsAffected),
	})
}

func (h *LogHandler) Clean(c *gin.Context) {
	defaultDays := model.GetRegisteredConfigInt("log_retention_days")
	daysStr := c.DefaultQuery("days", strconv.Itoa(defaultDays))
	days, _ := strconv.Atoi(daysStr)
	if days < 1 {
		days = defaultDays
	}

	cutoff := time.Now().AddDate(0, 0, -days)
	result := database.DB.Where("started_at < ?", cutoff).Delete(&model.TaskLog{})
	response.Success(c, gin.H{
		"message": fmt.Sprintf("已清理 %d 条日志（保留最近 %d 天）", result.RowsAffected, days),
	})
}

func (h *LogHandler) RegisterRoutes(r *gin.RouterGroup) {
	logs := r.Group("/logs")
	{
		logs.GET("", middleware.JWTAuth(), middleware.OpenAPIAccess("logs"), middleware.RequireRole("viewer"), h.List)
		logs.DELETE("/batch", middleware.JWTAuth(), middleware.RequireUserToken(), middleware.RequireRole("operator"), h.BatchDelete)
		logs.POST("/batch-delete", middleware.JWTAuth(), middleware.RequireUserToken(), middleware.RequireRole("operator"), h.BatchDelete)
		logs.DELETE("/clean", middleware.JWTAuth(), middleware.RequireUserToken(), middleware.RequireRole("operator"), h.Clean)
		logs.GET("/:id/stream", middleware.JWTAuth(), middleware.RequireUserToken(), middleware.RequireRole("viewer"), h.Stream)
		logs.GET("/:id", middleware.JWTAuth(), middleware.OpenAPIAccess("logs"), middleware.RequireRole("viewer"), h.Detail)
		logs.DELETE("/:id", middleware.JWTAuth(), middleware.RequireUserToken(), middleware.RequireRole("operator"), h.Delete)
	}
}
