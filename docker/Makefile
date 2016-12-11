ifeq ($(NAME),)
all:
	@echo Dont run make here
else
all: build
	docker run -v ${PWD}/..:/data -ti $(NAME)

sh:
	docker run -v ${PWD}/..:/data -ti $(NAME) /bin/bash

build:
	docker build -t $(NAME) .

endif
