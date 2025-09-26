#ifndef COT_COMMON_H
#define COT_COMMON_H

#include <iostream>
#include <string>
#include <sstream>
#include <chrono>
#include <thread>
#include <random>
#include <iomanip>
#include <cstring>
#include <vector>
#include <memory>
#include <map>
#include <regex>

// Network includes
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>

// OpenSSL includes
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/bio.h>

namespace CoTCommon {

class CoTObject {
private:
    std::string uid;
    std::string type;
    std::string how;
    double latitude;
    double longitude;
    double hae;  // Height Above Ellipsoid
    std::string callsign;
    std::string team;
    std::chrono::system_clock::time_point timestamp;
    
    std::string generate_uuid();
    std::string format_timestamp(const std::chrono::system_clock::time_point& tp) const;

public:
    CoTObject(const std::string& obj_type = "a-f-G-U-C", 
              const std::string& how_val = "h-g-i-g-o",
              double lat = 0.0, double lon = 0.0, double height = 0.0,
              const std::string& call = "CppCoT", const std::string& team_name = "Blue");
    
    void update_timestamp();
    std::string to_xml() const;
    const std::string& get_callsign() const { return callsign; }
    const std::string& get_uid() const { return uid; }
};

class CoTParser {
private:
    std::string extract_attribute(const std::string& xml, const std::string& element, const std::string& attr);
    std::string extract_element_content(const std::string& xml, const std::string& element);

public:
    struct CoTMessage {
        std::string uid;
        std::string type;
        std::string how;
        std::string time;
        std::string start;
        std::string stale;
        double latitude = 0.0;
        double longitude = 0.0;
        double hae = 0.0;
        std::string callsign;
        std::string team;
        std::string raw_xml;
        
        void print() const;
        void print_compact() const;
    };
    
    CoTMessage parse(const std::string& xml);
};

class TAKServerConnection {
private:
    std::string host;
    int port;
    std::string cert_file;
    std::string key_file;
    std::string ca_file;
    std::string passphrase;
    SSL_CTX* ssl_ctx;
    SSL* ssl;
    int socket_fd;
    bool connected;
    bool verbose;
    
    bool init_ssl();
    bool create_connection();
    bool setup_ssl_connection();

public:
    TAKServerConnection(const std::string& hostname, int tcp_port, 
                       const std::string& cert_path = "", const std::string& key_path = "",
                       const std::string& ca_path = "", const std::string& pass = "",
                       bool verb = false);
    
    ~TAKServerConnection();
    
    bool connect();
    void disconnect();
    bool is_connected() const { return connected; }
    
    // For sending data
    bool send_data(const std::string& data);
    
    // For receiving data
    int receive_data(char* buffer, size_t buffer_size);
    
    // Get last SSL error
    int get_last_ssl_error(int result);
};

} // namespace CoTCommon

#endif // COT_COMMON_H