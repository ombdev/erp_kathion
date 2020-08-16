GOCMD=go
GOBUILD=$(GOCMD) build -ldflags="-w -s" 

SALES_EXE=/sales

all: build

build: fmt
	CGO_ENABLED=0 \
	GOOS=linux \
	GOARCH=amd64 \
	$(GOBUILD) -o $(SALES_EXE) cmd/http/run.go

fmt:
	$(GOCMD) fmt ./...

clean:
	rm -f $(SALES_EXE)
