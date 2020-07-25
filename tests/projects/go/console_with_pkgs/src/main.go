package main

import (
  log "github.com/sirupsen/logrus"
)

func main() {
  log.WithFields(log.Fields{"animal": "walrus"}).Info("A walrus appears")
}
