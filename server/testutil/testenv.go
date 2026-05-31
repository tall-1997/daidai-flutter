package testutil

import (
	"path/filepath"
	"testing"
	"time"

	"daidai-panel/config"
	"daidai-panel/database"
	"daidai-panel/middleware"
	"daidai-panel/model"
	"daidai-panel/pkg/crypto"

	"github.com/gin-gonic/gin"
)

func closeExistingDB() {
	if database.DB == nil {
		return
	}

	sqlDB, err := database.DB.DB()
	if err == nil {
		_ = sqlDB.Close()
	}
}

func SetupTestEnv(t *testing.T) string {
	t.Helper()

	root := t.TempDir()
	dataDir := filepath.Join(root, "data")

	gin.SetMode(gin.TestMode)
	closeExistingDB()

	config.C = &config.Config{
		Server: config.ServerConfig{
			Port: 5701,
			Mode: "test",
		},
		Database: config.DatabaseConfig{
			Path: filepath.Join(root, "test.db"),
		},
		JWT: config.JWTConfig{
			Secret:             "test-secret",
			AccessTokenExpire:  time.Hour,
			RefreshTokenExpire: 2 * time.Hour,
		},
		Data: config.DataConfig{
			Dir:        dataDir,
			ScriptsDir: filepath.Join(dataDir, "scripts"),
			LogDir:     filepath.Join(dataDir, "logs"),
		},
		CORS: config.CORSConfig{
			Origins: []string{"https://allowed.example.com"},
		},
	}

	database.Init(&config.C.Database)
	database.AutoMigrate(
		&model.User{},
		&model.TokenBlocklist{},
		&model.Task{},
		&model.TaskLog{},
		&model.SystemConfig{},
		&model.EnvVar{},
		&model.ScriptVersion{},
		&model.Subscription{},
		&model.SubLog{},
		&model.NotifyChannel{},
		&model.SSHKey{},
		&model.LoginLog{},
		&model.LoginAttempt{},
		&model.UserSession{},
		&model.IPWhitelist{},
		&model.SecurityAudit{},
		&model.TwoFactorAuth{},
		&model.OpenApp{},
		&model.ApiCallLog{},
		&model.Platform{},
		&model.PlatformToken{},
		&model.PlatformTokenLog{},
		&model.Dependency{},
		&model.TaskView{},
	)
	model.InitDefaultConfigs()

	t.Cleanup(func() {
		closeExistingDB()
		config.C = nil
	})

	return root
}

func MustCreateUser(t *testing.T, username, role string) *model.User {
	t.Helper()

	user := &model.User{
		Username: username,
		Password: "test-password-hash",
		Role:     role,
		Enabled:  true,
	}

	if err := database.DB.Create(user).Error; err != nil {
		t.Fatalf("create user: %v", err)
	}

	return user
}

func MustCreateLoginUser(t *testing.T, username, role, password string) *model.User {
	t.Helper()

	hash, err := crypto.HashPassword(password)
	if err != nil {
		t.Fatalf("hash password: %v", err)
	}

	user := &model.User{
		Username: username,
		Password: hash,
		Role:     role,
		Enabled:  true,
	}

	if err := database.DB.Create(user).Error; err != nil {
		t.Fatalf("create login user: %v", err)
	}

	return user
}

func MustCreateAccessToken(t *testing.T, username, role string) string {
	t.Helper()

	token, err := middleware.GenerateAccessToken(username, role)
	if err != nil {
		t.Fatalf("generate access token: %v", err)
	}

	return token
}

func MustCreateRefreshToken(t *testing.T, username, role string) string {
	t.Helper()

	token, err := middleware.GenerateRefreshToken(username, role)
	if err != nil {
		t.Fatalf("generate refresh token: %v", err)
	}

	return token
}

func MustCreateOpenApp(t *testing.T, appKey, scopes string) *model.OpenApp {
	t.Helper()

	app := &model.OpenApp{
		Name:      appKey,
		AppKey:    appKey,
		AppSecret: "secret-" + appKey,
		Scopes:    scopes,
		Enabled:   true,
		RateLimit: 1000,
	}

	if err := database.DB.Create(app).Error; err != nil {
		t.Fatalf("create open app: %v", err)
	}

	return app
}

func MustCreateAppToken(t *testing.T, appKey, scopes string) string {
	t.Helper()

	MustCreateOpenApp(t, appKey, scopes)
	return MustCreateAccessToken(t, "app:"+appKey, "app:"+scopes)
}
