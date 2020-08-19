package persistence

import (
	"github.com/sirupsen/logrus"
	"go.mongodb.org/mongo-driver/bson"
)

type SaleProcess struct {
	string folio
	string tipo
	string observaciones
}

type UpdateLTS func(ltsPtr *LongTermStorage) error

func updateSteady(logger *logrus.Logger, hUpd UpdateLTS) error {

	var err error
	var ltsPtr *LongTermStorage

	if ltsPtr, err = ConnectLTS(logger); err != nil {

		goto culminate
	}

	defer ltsPtr.Disconnect()

	err = hUpd

culminate:

	return err
}
