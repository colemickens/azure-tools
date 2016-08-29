IMAGE_NAME?=docker.io/colemickens/azure-tools
IMAGE_VERSION?=latest

all:

docker-build:
	docker build -t $(IMAGE_NAME):$(IMAGE_VERSION) .

docker-dev: docker-build
	docker run -it \
		-v ~/.azure:/root/.azure \
		-v `pwd`/context:/opt/azure-tools \
		$(IMAGE_NAME):$(IMAGE_VERSION)

docker-push: docker-build
	docker push $(IMAGE_NAME):$(IMAGE_VERSION)
