TEST_EXEC := testrun
BUILD_DIR := ./build

SRCS := $(shell find . -maxdepth 1 -name '*.c3')

$(BUILD_DIR)/$(TEST_EXEC): $(SRCS)
	c3c compile-test --suppress-run $(SRCS) -o $@ $(CFLAGS)

.PHONY: clean
clean:
	rm -r ./build

.PHONY: test
test: $(BUILD_DIR)/$(TEST_EXEC)
	$(BUILD_DIR)/$(TEST_EXEC)
