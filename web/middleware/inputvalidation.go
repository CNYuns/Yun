package middleware

import (
	"net/http"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
)

// SQL injection patterns
var sqlInjectionPatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?i)(union\s+select|select\s+.*\s+from|insert\s+into|delete\s+from|drop\s+table|update\s+.*\s+set|exec\s*\(|execute\s*\()`),
	regexp.MustCompile(`(?i)(--|;|\/\*|\*\/|xp_|sp_|0x[0-9a-f]+)`),
	regexp.MustCompile("(?i)('|\"|`)" + `\s*(or|and)\s*` + "('|\"|`)" + `\s*` + "('|\"|`)?" + `\s*=\s*` + "('|\"|`)?"),
}

// XSS patterns
var xssPatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?i)(<script|<iframe|<object|<embed|<applet|javascript:|onerror\s*=|onload\s*=)`),
	regexp.MustCompile(`(?i)(eval\s*\(|expression\s*\(|vbscript:|data:text/html)`),
}

// Path traversal patterns
var pathTraversalPatterns = []*regexp.Regexp{
	regexp.MustCompile(`\.\.[\\/]`),
	regexp.MustCompile(`[\\/]\.\.[\\/]`),
	regexp.MustCompile(`%2e%2e[\\/]`),
	regexp.MustCompile(`\.\.[\/\\]`),
}

// ValidateInput checks input for common attack patterns
func ValidateInput() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Skip validation for certain paths (like file uploads)
		if strings.HasSuffix(c.Request.URL.Path, "/importDB") ||
			strings.Contains(c.Request.URL.Path, "/upload") {
			c.Next()
			return
		}

		// Get all form values and query parameters
		values := make([]string, 0)

		// Check form values
		if err := c.Request.ParseForm(); err == nil {
			for _, v := range c.Request.Form {
				values = append(values, v...)
			}
		}

		// Check query parameters
		for _, v := range c.Request.URL.Query() {
			values = append(values, v...)
		}

		// Validate each value
		for _, value := range values {
			if isSQLInjection(value) {
				c.JSON(http.StatusBadRequest, gin.H{
					"success": false,
					"msg":     "Invalid input detected: potential SQL injection attempt",
				})
				c.Abort()
				return
			}

			if isXSS(value) {
				c.JSON(http.StatusBadRequest, gin.H{
					"success": false,
					"msg":     "Invalid input detected: potential XSS attempt",
				})
				c.Abort()
				return
			}

			if isPathTraversal(value) {
				c.JSON(http.StatusBadRequest, gin.H{
					"success": false,
					"msg":     "Invalid input detected: potential path traversal attempt",
				})
				c.Abort()
				return
			}
		}

		c.Next()
	}
}

func isSQLInjection(input string) bool {
	for _, pattern := range sqlInjectionPatterns {
		if pattern.MatchString(input) {
			return true
		}
	}
	return false
}

func isXSS(input string) bool {
	for _, pattern := range xssPatterns {
		if pattern.MatchString(input) {
			return true
		}
	}
	return false
}

func isPathTraversal(input string) bool {
	for _, pattern := range pathTraversalPatterns {
		if pattern.MatchString(input) {
			return true
		}
	}
	return false
}
