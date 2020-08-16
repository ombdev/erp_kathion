package controllers

import (
	"net/http"
)

func EditBid() func(w http.ResponseWriter, r *http.Request) {

	return func(w http.ResponseWriter, r *http.Request) {

		w.WriteHeader(http.StatusOK)
	}
}
