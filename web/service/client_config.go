package service

import (
	"encoding/json"
	"fmt"
	"net"
	"time"

	"yun/database/model"
)

type ClientConfigService struct {
}

// GetServerIP 获取服务器公网IP
func (s *ClientConfigService) GetServerIP() string {
	// 尝试获取公网IP
	addrs, err := net.InterfaceAddrs()
	if err == nil {
		for _, addr := range addrs {
			if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
				if ipnet.IP.To4() != nil {
					return ipnet.IP.String()
				}
			}
		}
	}
	return "YOUR_SERVER_IP"
}

// GenerateV2rayConfig 生成 V2Ray/Xray 客户端配置
func (s *ClientConfigService) GenerateV2rayConfig(inbound *model.Inbound) (string, error) {
	serverIP := s.GetServerIP()

	config := map[string]interface{}{
		"log": map[string]interface{}{
			"loglevel": "warning",
		},
		"inbounds": []map[string]interface{}{
			{
				"port":     1080,
				"listen":   "127.0.0.1",
				"protocol": "socks",
				"settings": map[string]interface{}{
					"auth": "noauth",
					"udp":  true,
				},
			},
			{
				"port":     1081,
				"listen":   "127.0.0.1",
				"protocol": "http",
				"settings": map[string]interface{}{},
			},
		},
		"outbounds": []map[string]interface{}{
			{
				"protocol": string(inbound.Protocol),
				"settings": s.generateOutboundSettings(inbound),
				"streamSettings": s.generateStreamSettings(inbound, serverIP),
				"tag": "proxy",
			},
			{
				"protocol": "freedom",
				"tag":      "direct",
			},
		},
		"routing": map[string]interface{}{
			"rules": []map[string]interface{}{
				{
					"type":        "field",
					"outboundTag": "direct",
					"domain":      []string{"geosite:cn"},
				},
				{
					"type":        "field",
					"outboundTag": "direct",
					"ip":          []string{"geoip:cn", "geoip:private"},
				},
			},
		},
	}

	configJSON, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return "", err
	}

	return string(configJSON), nil
}

// generateOutboundSettings 生成出站设置
func (s *ClientConfigService) generateOutboundSettings(inbound *model.Inbound) map[string]interface{} {
	// 解析 settings
	var settings map[string]interface{}
	if err := json.Unmarshal([]byte(inbound.Settings), &settings); err != nil {
		return map[string]interface{}{}
	}

	// 根据协议生成配置
	outboundSettings := map[string]interface{}{}
	serverIP := s.GetServerIP()

	switch inbound.Protocol {
	case model.VMESS, model.VLESS:
		// 从 settings 中提取客户端信息
		if clients, ok := settings["clients"].([]interface{}); ok && len(clients) > 0 {
			if clientMap, ok := clients[0].(map[string]interface{}); ok {
				users := []map[string]interface{}{
					{
						"id":         clientMap["id"],
						"encryption": "none",
					},
				}
				if inbound.Protocol == model.VMESS {
					users[0]["alterId"] = 0
					users[0]["security"] = "auto"
				}
				vnext := map[string]interface{}{
					"address": serverIP,
					"port":    inbound.Port,
					"users":   users,
				}
				outboundSettings["vnext"] = []interface{}{vnext}
			}
		}

	case model.Trojan:
		// Trojan 配置
		if clients, ok := settings["clients"].([]interface{}); ok && len(clients) > 0 {
			if clientMap, ok := clients[0].(map[string]interface{}); ok {
				outboundSettings["servers"] = []map[string]interface{}{
					{
						"address":  serverIP,
						"port":     inbound.Port,
						"password": clientMap["password"],
					},
				}
			}
		}

	case model.Shadowsocks:
		// Shadowsocks 配置
		if method, ok := settings["method"].(string); ok {
			if password, ok := settings["password"].(string); ok {
				outboundSettings["servers"] = []map[string]interface{}{
					{
						"address":  serverIP,
						"port":     inbound.Port,
						"method":   method,
						"password": password,
					},
				}
			}
		}

	case model.Socks:
		// Socks5 配置
		outboundSettings["servers"] = []map[string]interface{}{
			{
				"address": serverIP,
				"port":    inbound.Port,
			},
		}
		// 如果有认证信息
		if accounts, ok := settings["accounts"].([]interface{}); ok && len(accounts) > 0 {
			if accountMap, ok := accounts[0].(map[string]interface{}); ok {
				servers := outboundSettings["servers"].([]map[string]interface{})
				servers[0]["users"] = []map[string]interface{}{
					{
						"user": accountMap["user"],
						"pass": accountMap["pass"],
					},
				}
			}
		}
	}

	return outboundSettings
}

// generateStreamSettings 生成传输设置
func (s *ClientConfigService) generateStreamSettings(inbound *model.Inbound, serverIP string) map[string]interface{} {
	// 解析 streamSettings
	var streamSettings map[string]interface{}
	if err := json.Unmarshal([]byte(inbound.StreamSettings), &streamSettings); err != nil {
		return map[string]interface{}{"network": "tcp"}
	}

	result := map[string]interface{}{}

	// 网络类型
	network := "tcp"
	if n, ok := streamSettings["network"].(string); ok {
		network = n
	}
	result["network"] = network

	// 根据不同的网络类型配置
	switch network {
	case "ws":
		if wsSettings, ok := streamSettings["wsSettings"].(map[string]interface{}); ok {
			result["wsSettings"] = wsSettings
		}
	case "tcp":
		if tcpSettings, ok := streamSettings["tcpSettings"].(map[string]interface{}); ok {
			result["tcpSettings"] = tcpSettings
		}
	case "grpc":
		if grpcSettings, ok := streamSettings["grpcSettings"].(map[string]interface{}); ok {
			result["grpcSettings"] = grpcSettings
		}
	case "httpupgrade":
		if httpupgradeSettings, ok := streamSettings["httpupgradeSettings"].(map[string]interface{}); ok {
			result["httpupgradeSettings"] = httpupgradeSettings
		}
	}

	// 安全设置
	if security, ok := streamSettings["security"].(string); ok {
		result["security"] = security

		if security == "tls" {
			if tlsSettings, ok := streamSettings["tlsSettings"].(map[string]interface{}); ok {
				clientTLS := map[string]interface{}{
					"allowInsecure": false,
				}
				if sni, ok := tlsSettings["serverName"].(string); ok {
					clientTLS["serverName"] = sni
				}
				if alpn, ok := tlsSettings["alpn"].([]interface{}); ok {
					clientTLS["alpn"] = alpn
				}
				result["tlsSettings"] = clientTLS
			}
		}
	} else {
		result["security"] = "none"
	}

	return result
}

// GenerateClashConfig 生成 Clash 配置
func (s *ClientConfigService) GenerateClashConfig(inbound *model.Inbound) (string, error) {
	serverIP := s.GetServerIP()
	currentTime := time.Now().Format("2006-01-02 15:04:05")

	// 基础 Clash 配置
	config := fmt.Sprintf(`# Clash 配置文件
# 生成时间: %s

port: 7890
socks-port: 7891
allow-lan: false
mode: rule
log-level: info

proxies:
  - name: "yun-proxy"
    type: %s
    server: %s
    port: %d
`, currentTime, string(inbound.Protocol), serverIP, inbound.Port)

	// 根据协议添加特定配置
	var settings map[string]interface{}
	json.Unmarshal([]byte(inbound.Settings), &settings)

	switch inbound.Protocol {
	case model.VMESS:
		if clients, ok := settings["clients"].([]interface{}); ok && len(clients) > 0 {
			client := clients[0].(map[string]interface{})
			config += fmt.Sprintf(`    uuid: %s
    alterId: 0
    cipher: auto
`, client["id"])
		}

	case model.VLESS:
		if clients, ok := settings["clients"].([]interface{}); ok && len(clients) > 0 {
			client := clients[0].(map[string]interface{})
			config += fmt.Sprintf(`    uuid: %s
    flow: ""
`, client["id"])
		}

	case model.Trojan:
		if clients, ok := settings["clients"].([]interface{}); ok && len(clients) > 0 {
			client := clients[0].(map[string]interface{})
			config += fmt.Sprintf(`    password: %s
`, client["password"])
		}
	}

	// 添加传输层配置
	var streamSettings map[string]interface{}
	json.Unmarshal([]byte(inbound.StreamSettings), &streamSettings)

	if network, ok := streamSettings["network"].(string); ok && network != "tcp" {
		config += fmt.Sprintf(`    network: %s
`, network)

		if network == "ws" {
			if wsSettings, ok := streamSettings["wsSettings"].(map[string]interface{}); ok {
				if path, ok := wsSettings["path"].(string); ok {
					config += fmt.Sprintf(`    ws-opts:
      path: %s
`, path)
				}
			}
		}
	}

	// TLS 配置
	if security, ok := streamSettings["security"].(string); ok && security == "tls" {
		config += `    tls: true
`
		if tlsSettings, ok := streamSettings["tlsSettings"].(map[string]interface{}); ok {
			if sni, ok := tlsSettings["serverName"].(string); ok {
				config += fmt.Sprintf(`    sni: %s
`, sni)
			}
		}
	}

	// 添加代理组和规则
	config += `
proxy-groups:
  - name: "PROXY"
    type: select
    proxies:
      - yun-proxy
      - DIRECT

rules:
  - DOMAIN-SUFFIX,cn,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
`

	return config, nil
}

// GenerateSSHTunnelScript 生成 SSH 隧道脚本
func (s *ClientConfigService) GenerateSSHTunnelScript(serverIP, serverPort, username string) string {
	script := fmt.Sprintf(`#!/bin/bash
# SSH 动态端口转发脚本
# 服务器: %s

SERVER_IP="%s"
SERVER_PORT="%s"
USERNAME="%s"
LOCAL_PORT="1080"

echo "正在建立 SSH 隧道..."
echo "本地 Socks5 代理将监听在: 127.0.0.1:${LOCAL_PORT}"
echo ""
echo "使用方法："
echo "  export http_proxy=socks5://127.0.0.1:${LOCAL_PORT}"
echo "  export https_proxy=socks5://127.0.0.1:${LOCAL_PORT}"
echo ""

# 自动重连
while true; do
    ssh -D ${LOCAL_PORT} -C -N -o ServerAliveInterval=60 -o ServerAliveCountMax=3 ${USERNAME}@${SERVER_IP} -p ${SERVER_PORT}
    echo "连接断开，5秒后重连..."
    sleep 5
done
`, serverIP, serverIP, serverPort, username)

	return script
}

// GenerateQuickSetupGuide 生成快速设置指南
func (s *ClientConfigService) GenerateQuickSetupGuide(inbound *model.Inbound) string {
	serverIP := s.GetServerIP()

	guide := fmt.Sprintf(`# yun 客户端快速设置指南

## 服务器信息
- 服务器地址: %s
- 端口: %d
- 协议: %s

## 方案一：SSH 隧道（最简单，推荐）

### 在远程服务器上执行：
bash
ssh -D 1080 -C -N root@%s


### 配置代理：
bash
export http_proxy="socks5://127.0.0.1:1080"
export https_proxy="socks5://127.0.0.1:1080"


### 测试连接：
bash
curl https://www.baidu.com


---

## 方案二：V2Ray/Xray 客户端

### 1. 安装客户端
bash
# Ubuntu/Debian
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 或安装 Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install


### 2. 下载配置文件
在面板中点击"下载 V2Ray 配置"，保存为 /usr/local/etc/v2ray/config.json

### 3. 启动服务
bash
systemctl start v2ray
systemctl enable v2ray


### 4. 配置代理
bash
export http_proxy="socks5://127.0.0.1:1080"
export https_proxy="socks5://127.0.0.1:1080"


---

## 方案三：Clash 客户端

### 1. 安装 Clash
bash
# 下载 Clash
wget https://github.com/Dreamacro/clash/releases/download/v1.18.0/clash-linux-amd64-v1.18.0.gz
gunzip clash-linux-amd64-v1.18.0.gz
mv clash-linux-amd64-v1.18.0 /usr/local/bin/clash
chmod +x /usr/local/bin/clash


### 2. 下载配置文件
在面板中点击"下载 Clash 配置"，保存为 ~/.config/clash/config.yaml

### 3. 启动 Clash
bash
clash -d ~/.config/clash


### 4. 配置代理
bash
export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"


---

## 测试连接

bash
# 测试代理
curl -I https://www.baidu.com

# 查看IP
curl ipinfo.io


---

## 常见问题

### Q: SSH 隧道断开怎么办？
A: 使用 autossh 或下载面板提供的自动重连脚本

### Q: 如何后台运行？
A: 使用 systemd 服务或 screen/tmux

### Q: 如何查看日志？
A:
- V2Ray: journalctl -u v2ray -f
- SSH: ssh -v -D 1080 ...

`, serverIP, inbound.Port, string(inbound.Protocol), serverIP)

	return guide
}
