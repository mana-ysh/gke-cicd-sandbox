SRC_PORT := 4600
DST_PORT := 8000

##### docker
IMAGE_NAME := exampleapp
CONTAINER_NAME := ${IMAGE_NAME}-container

build-image:
	docker build -t ${IMAGE_NAME} ./

run-container:
	docker run -it -d \
		--name ${CONTAINER_NAME} \
		-p ${SRC_PORT}:${DST_PORT} \
		${IMAGE_NAME}


##### ci
ci: typecheck test lint

typecheck:
	@echo check types
	mypy ./exampleapp 

lint:
	@echo check style
	flake8 --show-source --statistics

test:
	@echo testing
	pytest -rf --cov=./exampleapp 

##### gcp
# NOTE: please set your configulation
PROJECT_ID := dummy
GKE_CLUSTER := dummy
GKE_ZONE := dummy
TAG := latest
CONTAINER_HOST := gcr.io/${PROJECT_ID}/${IMAGE_NAME}

init-gcp:
	gcloud --quiet auth configure-docker
	gcloud container clusters get-credentials ${GKE_CLUSTER} --zone ${GKE_ZONE}

push-image:
	docker tag ${IMAGE_NAME} ${CONTAINER_HOST}:${TAG}
	docker push ${CONTAINER_HOST}:${TAG}

##### k8s
MANIFEST_PATH = $(shell pwd)/k8s
ENVIRONMENT := local
# path to kustomize cmd binary
KUSTOMIZE := kustomize

deploy:
	cd ${MANIFEST_PATH}/overlays/${ENVIRONMENT}/ && ${KUSTOMIZE} edit set image ${CONTAINER_HOST}=${CONTAINER_HOST}:${TAG}
	${KUSTOMIZE} build ${MANIFEST_PATH}/overlays/${ENVIRONMENT}/ | kubectl apply -f -

destory:
	kubectl delete -k ${MANIFEST_PATH}/overlays/${ENVIRONMENT}/

port-forward:
	kubectl port-forward service/exampleapp-service ${SRC_PORT}:${DST_PORT}

##### application
launch:
	uvicorn app:app --host 0.0.0.0 --port ${DST_PORT}

launch-develop:
	python app.py
