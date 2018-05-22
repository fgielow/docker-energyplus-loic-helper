NAME=fgielow/energyplus
DOTOKEN=""
PROCESSOR=eplus-processor

build-img:
	docker build -t $(NAME) . -f Dockerfile

push-img:
	docker push $(NAME)

install:
	npm install

run:
	$(RM) test-out/* 
	cp test-in/* test-out/
	docker run -it --rm -v $(CURDIR)/test-out:/var/simdata $(NAME) EnergyPlus --idd /usr/local/EnergyPlus-8-9-0/Energy+.idd -r -x -m

processor-up:
	docker-machine create --driver digitalocean \
	    --digitalocean-image  ubuntu-16-04-x64 \
	    --digitalocean-region lon1 \
	    --digitalocean-size s-4vcpu-8gb \
	    --swarm-master \
	    --digitalocean-access-token $(DOTOKEN) $(PROCESSOR)

processor-down:
	(echo y) | docker-machine rm $(PROCESSOR)
	sleep 3
	(echo y) | docker-machine rm -f $(PROCESSOR)

ssh:
	docker-machine ssh $(PROCESSOR)

process-tagged-input:
	$(RM) -r input-files/raw/* 
	node tools/local/tag-replacer.js

transfer-input-files: copy-dependencies
	docker-machine ssh $(PROCESSOR) rm -rf /root/input-files
	docker-machine scp -r ./input-files/raw $(PROCESSOR):/root/input-files
	docker-machine scp -r ./input-files/tagged/in.epw $(PROCESSOR):/root/

copy-dependencies:
	docker-machine scp -r ./tools/remote/parallel-process-sync.sh $(PROCESSOR):/root/
	docker-machine scp -r ./tools/remote/parallel-process-bg.sh $(PROCESSOR):/root/
	docker-machine scp -r ./tools/remote/get-current-processing-tasks.sh $(PROCESSOR):/root/
	docker-machine scp -r ./tools/remote/get-current-processing-tasks-status.sh $(PROCESSOR):/root/
	docker-machine scp -r ./tools/remote/kill-all.sh $(PROCESSOR):/root/

parallel-simulate: copy-dependencies
	docker-machine ssh $(PROCESSOR) /root/parallel-process-sync.sh
	docker-machine ssh $(PROCESSOR) screen -d -m /root/parallel-process-bg.sh

process-transfer-and-simulate: process-tagged-input transfer-input-files parallel-simulate
	echo "Executing"

get-processing:
	docker-machine ssh $(PROCESSOR) /root/get-current-processing-tasks.sh

get-status:
	docker-machine ssh $(PROCESSOR) /root/get-current-processing-tasks-status.sh

retrieve-results: get-status
	echo "Note that if there are any processing tasks, this means results are not ready!"
	docker-machine scp -r $(PROCESSOR):/root/input-files/* ./output-files/

kill-current-sims:
	docker-machine ssh $(PROCESSOR) /bin/bash /root/kill-all.sh



