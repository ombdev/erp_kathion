package persistence

import (
	"context"

	"github.com/sirupsen/logrus"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type SaleProcess struct {
	string Folio
	string Tipo
	string Observaciones
}

type ActOnEphemeral func(cliPtr *mongo.Client) error

// Enable an Ephemeral connection to carry out collection methods
func actOnEphemeralConn(logger *logrus.Logger, actOn ActOnEphemeral) error {

	var err error
	var ltsPtr *LongTermStorage

	if ltsPtr, err = ConnectLTS(logger); err != nil {

		goto culminate
	}

	defer ltsPtr.Disconnect()

	err = actOn(ltsPtr.cli)

culminate:

	return err
}
