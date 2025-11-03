package session

import (
	"encoding/gob"

	"x-ui/database/model"

	"github.com/gin-contrib/sessions"
	"github.com/gin-gonic/gin"
)

const (
	loginUserKey = "LOGIN_USER"
	defaultPath  = "/"
)

func init() {
	gob.Register(model.User{})
}

func SetLoginUser(c *gin.Context, user *model.User) {
	if user == nil {
		return
	}
	s := sessions.Default(c)
	s.Set(loginUserKey, *user)
}

// isHTTPS checks if the request is using HTTPS
func isHTTPS(c *gin.Context) bool {
	// Check scheme
	if c.Request.TLS != nil {
		return true
	}
	// Check X-Forwarded-Proto header (for reverse proxies)
	if proto := c.GetHeader("X-Forwarded-Proto"); proto == "https" {
		return true
	}
	// Check scheme in request
	if c.Request.URL.Scheme == "https" {
		return true
	}
	return false
}

func SetMaxAge(c *gin.Context, maxAge int) {
	s := sessions.Default(c)
	s.Options(sessions.Options{
		Path:     defaultPath,
		MaxAge:   maxAge,
		HttpOnly: true,
		Secure:   isHTTPS(c), // Auto-detect HTTPS
		SameSite: 3, // SameSiteStrictMode
	})
}

func GetLoginUser(c *gin.Context) *model.User {
	s := sessions.Default(c)
	obj := s.Get(loginUserKey)
	if obj == nil {
		return nil
	}
	user, ok := obj.(model.User)
	if !ok {

		s.Delete(loginUserKey)
		return nil
	}
	return &user
}

func IsLogin(c *gin.Context) bool {
	return GetLoginUser(c) != nil
}

func ClearSession(c *gin.Context) {
	s := sessions.Default(c)
	s.Clear()
	s.Options(sessions.Options{
		Path:     defaultPath,
		MaxAge:   -1,
		HttpOnly: true,
		Secure:   isHTTPS(c), // Auto-detect HTTPS
		SameSite: 3, // SameSiteStrictMode
	})
}
