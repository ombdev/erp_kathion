package service

import (
	co "immortalcrab.com/sales/internal/controllers"
	"immortalcrab.com/sales/internal/rsapi"

	"github.com/gorilla/mux"
	"github.com/kelseyhightower/envconfig"
	"github.com/sirupsen/logrus"
)

var apiSettings rsapi.RestAPISettings

func init() {

	envconfig.Process("rsapi", &apiSettings)
}

// Engages the RESTful API
func Engage(logger *logrus.Logger) (merr error) {

	{

		/* The connection of both components occurs through
		   the router glue and its adaptive functions */
		glue := func(api *rsapi.RestAPI) *mux.Router {

			router := mux.NewRouter()

			v1 := router.PathPrefix("/v1").Subrouter()

			mgmt := v1.PathPrefix("/sales").Subrouter()

			mgmt.HandleFunc("/ebid", co.EditBid()).Methods("POST")
			return router
		}

		api := rsapi.NewRestAPI(logger, &apiSettings, glue)

		api.PowerOn()
	}

	return nil
}
