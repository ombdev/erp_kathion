package persistence

import (
	"context"
	"strings"
	"time"

	"github.com/kelseyhightower/envconfig"
	"github.com/sirupsen/logrus"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type (
	MgDBSettings struct {
		Uri     string `default:"uri"`
	}
)

var mdbSettings MgDBSettings

func init() {

	envconfig.Process("mongo", &mdbSettings)
}

// It represents the long term storage mechanism
type LongTermStorage struct {
	cli     *mongo.Client
	logger  *logrus.Logger
	metrics struct {
		insertions    int64
		modifications int64
		deletions     int64
	}
}

func setMdbClientUp(mcli **mongo.Client, uri string) error {

	var err error = nil
	var cli *mongo.Client = nil

	cli, err = mongo.NewClient(options.Client().ApplyURI(uri))

	if err != nil {
		goto culminate
	}

	{
		ctxConn, cancelConn := context.WithTimeout(context.Background(),
			10*time.Second)

		/* It'll be even called if succeeded just to
		   release resources of timing */
		defer cancelConn()

		if err = cli.Connect(ctxConn); err != nil {
			goto culminate
		}

		/* Due to Connect never blocked for server discovery.
		   To know if a MongoDB server has been found and connected to,
		   Ping is brought to the table */
		ctx, cancelPing := context.WithTimeout(context.Background(),
			2*time.Second)

		/* It'll be even called if succeeded just to
		   release resources of timing */
		defer cancelPing()

		if err = cli.Ping(ctx, readpref.Primary()); err == nil {
			*mcli = cli
		}
	}

culminate:

	return err
}

// Connects the long term storage
func ConnectLTS(logger *logrus.Logger) (*LongTermStorage, error) {

	lts := &LongTermStorage{}
	lts.logger = logger

	if err := setMdbClientUp(&lts.cli, mdbSettings.Uri); err != nil {

		return nil, err
	}

	return lts, nil
}

// Releases stuff that was required during the long term storage usage
func (lts *LongTermStorage) Disconnect() {

	{
		ctx, cancelDisconn := context.WithTimeout(context.Background(), 2*time.Second)
		lts.cli.Disconnect(ctx)

		/* It'll be even called if succeeded just to
		release resources of timing */
		defer cancelDisconn()
	}

	lts.logger.Printf(
		"Bot id %s on Long Term Storage applied insertions: %d, updates: %d, deletions: %d",
		lts.botID, lts.metrics.insertions, lts.metrics.modifications,
		lts.metrics.deletions)
}
