CXX = g++
RM = rm -f
CXXFLAGS = -Wall -std=c++11
TARGET = densemult

all: $(TARGET)

$(TARGET): $(TARGET).cpp
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(TARGET).cpp

clean:
	$(RM) $(TARGET) *.diff *.stdout *.stderr TIMEOUT COMPILE.err *.out
