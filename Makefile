CONTAINER_ID = $(shell docker container create swm)

./swm: image
	docker cp $(CONTAINER_ID):/swm bin/swm
	docker rm $(CONTAINER_ID)

image:
	docker build -t swm .
