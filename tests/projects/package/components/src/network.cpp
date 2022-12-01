#include <SFML/Network.hpp>

extern "C" {
void network() {
    sf::UdpSocket socket;
    socket.bind(54000);

    char data[100];
    std::size_t received;
    sf::IpAddress sender;
    unsigned short port;
    socket.receive(data, 100, received, sender, port);
}
}
