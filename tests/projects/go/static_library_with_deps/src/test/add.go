package module

import (
  log "github.com/sirupsen/logrus"
)

func Add(a int, b int) int {
    log.WithFields(log.Fields{"animal": "walrus"}).Info("A walrus appears")
    return a + b;
}

