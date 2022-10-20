#include <SFML/Graphics.hpp>
#include <SFML/Network.hpp>

extern "C" {
void network();
void graphics();
}

int main(int argc, char** argv) {
    network();
    graphics();
    return 0;
}

