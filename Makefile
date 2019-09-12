CC=g++
CCFLAGS=-std=gnu++11 -O3

TST=./cpu/tst
RES=./cpu/res
BIN=./cpu/bin
LOG=./cpu/log
EXT=./cpu/ext
NES=python3 ./cpu/main.py

TESTS=$(addprefix ${BIN}/, $(notdir $(patsubst %.s,%,$(sort $(wildcard ${TST}/*.s)))))
CROSS_AS=${EXT}/asm6/asm6

all: ${BIN} ${LOG}

${BIN}:
	@mkdir -p ${BIN}

${BIN}/%: ${TST}/%.s
	${CROSS_AS} $^ $@

${LOG}:
	@mkdir -p ${LOG}

test: ${BIN} ${LOG} ${TESTS}
	@{  echo "************************* Tests ******************************"; \
		test_failed=0; \
		test_passed=0; \
		for test in ${TESTS}; do \
			result="${LOG}/$$(basename $$test).log"; \
			expected="${RES}/$$(basename $$test).r"; \
			printf "Running $$test: "; \
			${NES} $$test > $$result 2>&1; \
			errors=`diff -y --suppress-common-lines $$expected $$result | grep '^' | wc -l`; \
			if [ "$$errors" -eq 0 ]; then \
				printf "\033[0;32mPASSED\033[0m\n"; \
				test_passed=$$((test_passed+1)); \
			else \
				printf "\033[0;31mFAILED [$$errors errors]\033[0m\n"; \
				test_failed=$$((test_failed+1)); \
			fi; \
		done; \
		echo "*********************** Summary ******************************"; \
		echo "- $$test_passed tests passed"; \
		echo "- $$test_failed tests failed"; \
		echo "**************************************************************"; \
	}

setup:
	sudo apt-get install python3.6 python3-pip;
	pip3 install -r ./cpu/requirements.txt;

clean:
	rm -rf ${BIN}/* ${LOG}/*
