package controller

import (
	"fmt"
	"net/http"
	"text/template"
	"time"

	"x-ui/logger"
	"x-ui/web/middleware"
	"x-ui/web/service"
	"x-ui/web/session"

	"github.com/gin-contrib/sessions"
	"github.com/gin-gonic/gin"
)

type LoginForm struct {
	Username    	string `json:"username" form:"username"`
	Password    	string `json:"password" form:"password"`
	TwoFactorCode	string `json:"twoFactorCode" form:"twoFactorCode"`
}

type IndexController struct {
	BaseController

	settingService service.SettingService
	userService    service.UserService
	tgbot          service.Tgbot
	rateLimiter    *middleware.LoginRateLimiter
}

func NewIndexController(g *gin.RouterGroup) *IndexController {
	a := &IndexController{
		// 5 attempts per 15 minutes, block for 15 minutes
		rateLimiter: middleware.NewLoginRateLimiter(5, 15*time.Minute, 15*time.Minute),
	}
	a.initRouter(g)
	return a
}

func (a *IndexController) initRouter(g *gin.RouterGroup) {
	g.GET("/", a.index)
	g.POST("/login", a.login)
	g.GET("/logout", a.logout)
	g.POST("/getTwoFactorEnable", a.getTwoFactorEnable)
}

func (a *IndexController) index(c *gin.Context) {
	if session.IsLogin(c) {
		c.Redirect(http.StatusTemporaryRedirect, "panel/")
		return
	}
	html(c, "login.html", "pages.login.title", nil)
}

func (a *IndexController) login(c *gin.Context) {
	clientIP := c.ClientIP()

	// Check if IP is blocked
	if blocked, remaining := a.rateLimiter.IsBlocked(clientIP); blocked {
		pureJsonMsg(c, http.StatusTooManyRequests, false,
			I18nWeb(c, "pages.login.toasts.tooManyAttempts") +
			" Please try again in " + formatDuration(remaining))
		return
	}

	var form LoginForm

	if err := c.ShouldBind(&form); err != nil {
		pureJsonMsg(c, http.StatusOK, false, I18nWeb(c, "pages.login.toasts.invalidFormData"))
		return
	}
	if form.Username == "" {
		pureJsonMsg(c, http.StatusOK, false, I18nWeb(c, "pages.login.toasts.emptyUsername"))
		return
	}
	if form.Password == "" {
		pureJsonMsg(c, http.StatusOK, false, I18nWeb(c, "pages.login.toasts.emptyPassword"))
		return
	}

	user := a.userService.CheckUser(form.Username, form.Password, form.TwoFactorCode)
	timeStr := time.Now().Format("2006-01-02 15:04:05")
	safeUser := template.HTMLEscapeString(form.Username)

	if user == nil {
		// Record failed attempt
		a.rateLimiter.RecordAttempt(clientIP, false)

		logger.Warningf("wrong username: \"%s\", IP: \"%s\"", safeUser, getRemoteIp(c))
		a.tgbot.UserLoginNotify(safeUser, ``, getRemoteIp(c), timeStr, 0)
		pureJsonMsg(c, http.StatusOK, false, I18nWeb(c, "pages.login.toasts.wrongUsernameOrPassword"))
		return
	}

	// Record successful attempt
	a.rateLimiter.RecordAttempt(clientIP, true)

	logger.Infof("%s logged in successfully, Ip Address: %s\n", safeUser, getRemoteIp(c))
	a.tgbot.UserLoginNotify(safeUser, ``, getRemoteIp(c), timeStr, 1)

	sessionMaxAge, err := a.settingService.GetSessionMaxAge()
	if err != nil {
		logger.Warning("Unable to get session's max age from DB")
	}

	session.SetMaxAge(c, sessionMaxAge*60)
	session.SetLoginUser(c, user)
	if err := sessions.Default(c).Save(); err != nil {
		logger.Warning("Unable to save session: ", err)
		return
	}

	logger.Infof("%s logged in successfully", safeUser)
	jsonMsg(c, I18nWeb(c, "pages.login.toasts.successLogin"), nil)
}

// Helper function to format duration
func formatDuration(d time.Duration) string {
	minutes := int(d.Minutes())
	seconds := int(d.Seconds()) % 60
	if minutes > 0 {
		return fmt.Sprintf("%d minutes %d seconds", minutes, seconds)
	}
	return fmt.Sprintf("%d seconds", seconds)
}

func (a *IndexController) logout(c *gin.Context) {
	user := session.GetLoginUser(c)
	if user != nil {
		logger.Infof("%s logged out successfully", user.Username)
	}
	session.ClearSession(c)
	if err := sessions.Default(c).Save(); err != nil {
		logger.Warning("Unable to save session after clearing:", err)
	}
	c.Redirect(http.StatusTemporaryRedirect, c.GetString("base_path"))
}

func (a *IndexController) getTwoFactorEnable(c *gin.Context) {
	status, err := a.settingService.GetTwoFactorEnable()
	if err == nil {
		jsonObj(c, status, nil)
	}
}
