package collector

import (
	"errors"
	"strings"

	"github.com/fsouza/go-dockerclient"
)

const appLabel = "collectd_docker_app"
const taskLabel = "collectd_docker_task"
const taskLocationLabel = "collectd_docker_task_label"

const appEnvPrefix = "COLLECTD_DOCKER_APP="
const taskEnvPrefix = "COLLECTD_DOCKER_TASK="
const taskEnvLocationPrefix = "COLLECTD_DOCKER_TASK_ENV="
const taskEnvLocationTrimPrefix = "COLLECTD_DOCKER_TASK_ENV_TRIM_PREFIX="

const defaultTask = "default"

// ErrNoNeedToMonitor is used to skip containers
// that shouldn't be monitored by collectd
var ErrNoNeedToMonitor = errors.New("container is not supposed to be monitored")

// MonitorDockerClient represents restricted interface for docker client
// that is used in monitor, docker.Client is a subset of this interface
type MonitorDockerClient interface {
	InspectContainer(id string) (*docker.Container, error)
	Stats(opts docker.StatsOptions) error
}

// Monitor is responsible for monitoring of a single container (task)
type Monitor struct {
	client   MonitorDockerClient
	id       string
	app      string
	task     string
	interval int
}

// NewMonitor creates new monitor with specified docker client,
// container id and stat updating interval
func NewMonitor(c MonitorDockerClient, id string, interval int) (*Monitor, error) {
	container, err := c.InspectContainer(id)
	if err != nil {
		return nil, err
	}

	app := sanitizeForGraphite(extractApp(container))
	if app == "" {
		return nil, ErrNoNeedToMonitor
	}

	task := sanitizeForGraphite(extractTask(container))

	return &Monitor{
		client:   c,
		id:       container.ID,
		app:      app,
		task:     task,
		interval: interval,
	}, nil
}

func (m *Monitor) handle(ch chan<- Stats) error {
	in := make(chan *docker.Stats)

	go func() {
		i := 0
		for s := range in {
			if i%m.interval != 0 {
				i++
				continue
			}

			ch <- Stats{
				App:   m.app,
				Task:  m.task,
				Stats: *s,
			}

			i++
		}
	}()

	return m.client.Stats(docker.StatsOptions{
		ID:     m.id,
		Stats:  in,
		Stream: true,
	})
}

func extractApp(c *docker.Container) string {
	return extractMetadata(c, appLabel, appEnvPrefix, "")
}

func extractTask(c *docker.Container) string {
	task := defaultTask

	location := extractMetadata(c, taskLocationLabel, taskEnvLocationPrefix, "")
	if location != "" {
		task = extractMetadata(c, location, location+"=", defaultTask)
	} else {
		task = extractMetadata(c, taskLabel, taskEnvPrefix, defaultTask)
	}

	prefix := extractEnv(c, taskEnvLocationTrimPrefix)
	if prefix != "" {
		return strings.TrimPrefix(task, prefix)
	}

	return task
}

func extractMetadata(c *docker.Container, label, envPrefix, missing string) string {
	if app, ok := c.Config.Labels[label]; ok {
		return app
	}

	env := extractEnv(c, envPrefix)
	if env != "" {
		return env
	}

	return missing
}

func extractEnv(c *docker.Container, envPrefix string) string {
	for _, e := range c.Config.Env {
		if strings.HasPrefix(e, envPrefix) {
			return strings.TrimPrefix(e, envPrefix)
		}
	}

	return ""
}

func sanitizeForGraphite(s string) string {
	return strings.Replace(s, ".", "_", -1)
}
