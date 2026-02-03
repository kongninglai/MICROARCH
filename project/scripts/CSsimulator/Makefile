# ---- toolchain ----
CC      := gcc
CFLAGS  := -std=c11 -O2 -g -Wall -Wextra -Wshadow -Wconversion -Wpedantic
CPPFLAGS:= -I.
LDFLAGS :=

# ---- target ----
TARGET  := cssim

# ---- sources ----
SRCS := cssim.c gp_regfile.c mem.c
OBJS := $(SRCS:.c=.o)
DEPS := $(OBJS:.o=.d)

.PHONY: all clean run

all: $(TARGET)

# link
$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# compile + auto dependency (.d)
%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MP -c $< -o $@

-include $(DEPS)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) $(OBJS) $(DEPS)
