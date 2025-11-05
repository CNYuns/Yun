package service

import (
	"regexp"
	"strings"
	"time"

	"yun/database"
	"yun/database/model"
)

type InboundLogService struct {
}

// AddLog 添加入站日志
func (s *InboundLogService) AddLog(inboundId int, inboundTag, logType, remoteAddr, message string) error {
	db := database.GetDB()
	log := &model.InboundLog{
		InboundId:  inboundId,
		InboundTag: inboundTag,
		LogType:    logType,
		RemoteAddr: remoteAddr,
		Message:    message,
		CreatedAt:  time.Now().Unix(),
	}
	return db.Create(log).Error
}

// GetLogsByInboundId 根据入站ID获取日志
func (s *InboundLogService) GetLogsByInboundId(inboundId int, page, pageSize int, logType string) ([]*model.InboundLog, int64, error) {
	db := database.GetDB()
	var logs []*model.InboundLog
	var total int64

	query := db.Model(&model.InboundLog{}).Where("inbound_id = ?", inboundId)

	if logType != "" {
		query = query.Where("log_type = ?", logType)
	}

	// 获取总数
	query.Count(&total)

	// 分页查询
	offset := (page - 1) * pageSize
	err := query.Order("created_at DESC").Limit(pageSize).Offset(offset).Find(&logs).Error

	return logs, total, err
}

// GetLogsByInboundTag 根据入站Tag获取日志
func (s *InboundLogService) GetLogsByInboundTag(inboundTag string, page, pageSize int, logType string) ([]*model.InboundLog, int64, error) {
	db := database.GetDB()
	var logs []*model.InboundLog
	var total int64

	query := db.Model(&model.InboundLog{}).Where("inbound_tag = ?", inboundTag)

	if logType != "" {
		query = query.Where("log_type = ?", logType)
	}

	// 获取总数
	query.Count(&total)

	// 分页查询
	offset := (page - 1) * pageSize
	err := query.Order("created_at DESC").Limit(pageSize).Offset(offset).Find(&logs).Error

	return logs, total, err
}

// CleanOldLogs 清理30天前的日志
func (s *InboundLogService) CleanOldLogs() (int64, error) {
	db := database.GetDB()
	thirtyDaysAgo := time.Now().AddDate(0, 0, -30).Unix()

	result := db.Where("created_at < ?", thirtyDaysAgo).Delete(&model.InboundLog{})
	return result.RowsAffected, result.Error
}

// ParseXrayLog 解析Xray日志并存储
func (s *InboundLogService) ParseXrayLog(logLine string) error {
	// Xray日志格式示例：
	// 2024/01/01 12:00:00 [Info] inbound/http: connection from tcp:192.168.1.100:12345
	// 2024/01/01 12:00:00 [Warning] inbound/vmess: invalid request from tcp:192.168.1.100:12345
	// 2024/01/01 12:00:00 [Error] inbound/trojan: connection error: EOF

	// 解析日志级别和入站tag
	logLevelPattern := regexp.MustCompile(`\[(Info|Warning|Error)\]`)
	inboundPattern := regexp.MustCompile(`inbound/(\w+):`)
	remoteAddrPattern := regexp.MustCompile(`tcp:([0-9\.\:]+)`)

	logLevelMatches := logLevelPattern.FindStringSubmatch(logLine)
	inboundMatches := inboundPattern.FindStringSubmatch(logLine)
	remoteAddrMatches := remoteAddrPattern.FindStringSubmatch(logLine)

	if len(inboundMatches) < 2 {
		// 不是入站相关的日志，忽略
		return nil
	}

	inboundTag := inboundMatches[1]
	var logType string
	var remoteAddr string

	if len(logLevelMatches) >= 2 {
		level := logLevelMatches[1]
		switch level {
		case "Info":
			// 只记录连接日志
			if !strings.Contains(logLine, "connection from") && !strings.Contains(logLine, "accepted") {
				return nil
			}
			logType = "connection"
		case "Warning":
			logType = "warning"
		case "Error":
			logType = "error"
		default:
			return nil
		}
	}

	if len(remoteAddrMatches) >= 2 {
		remoteAddr = remoteAddrMatches[1]
	}

	// 查找对应的入站
	inboundService := &InboundService{}
	inbound, err := inboundService.GetInboundByTag(inboundTag)
	if err != nil {
		// 找不到对应的入站，可能是已删除或其他入站
		return nil
	}

	// 存储日志
	return s.AddLog(inbound.Id, inboundTag, logType, remoteAddr, logLine)
}

// GetInboundByTag 根据tag获取入站（在InboundService中实现）
func (s *InboundService) GetInboundByTag(tag string) (*model.Inbound, error) {
	db := database.GetDB()
	var inbound model.Inbound
	err := db.Where("tag = ?", tag).First(&inbound).Error
	return &inbound, err
}
