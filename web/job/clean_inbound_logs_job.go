package job

import (
	"yun/logger"
	"yun/web/service"
)

type CleanInboundLogsJob struct {
}

func NewCleanInboundLogsJob() *CleanInboundLogsJob {
	return new(CleanInboundLogsJob)
}

// Run 执行日志清理任务
func (j *CleanInboundLogsJob) Run() {
	logger.Info("开始清理入站日志...")

	logService := &service.InboundLogService{}
	count, err := logService.CleanOldLogs()

	if err != nil {
		logger.Error("清理入站日志失败:", err)
		return
	}

	logger.Info("入站日志清理完成，已删除 ", count, " 条日志")
}
