#include "cot_common.h"

namespace CoTCommon {

// CoTObject implementation
std::string CoTObject::generate_uuid() {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, 15);
    std::uniform_int_distribution<> dis2(8, 11);
    
    std::stringstream ss;
    ss << std::hex;
    for (int i = 0; i < 8; i++) ss << dis(gen);
    ss << "-";
    for (int i = 0; i < 4; i++) ss << dis(gen);
    ss << "-4";
    for (int i = 0; i < 3; i++) ss << dis(gen);
    ss << "-";
    ss << dis2(gen);
    for (int i = 0; i < 3; i++) ss << dis(gen);
    ss << "-";
    for (int i = 0; i < 12; i++) ss << dis(gen);
    return ss.str();
}

std::string CoTObject::format_timestamp(const std::chrono::system_clock::time_point& tp) const {
    auto tt = std::chrono::system_clock::to_time_t(tp);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(tp.time_since_epoch()) % 1000;
    
    std::stringstream ss;
    ss << std::put_time(std::gmtime(&tt), "%Y-%m-%dT%H:%M:%S");
    ss << "." << std::setfill('0') << std::setw(3) << ms.count() << "Z";
    return ss.str();
}

CoTObject::CoTObject(const std::string& obj_type, 
          const std::string& how_val,
          double lat, double lon, double height,
          const std::string& call, const std::string& team_name)
    : type(obj_type), how(how_val), latitude(lat), longitude(lon), 
      hae(height), callsign(call), team(team_name) {
    uid = generate_uuid();
    timestamp = std::chrono::system_clock::now();
}

void CoTObject::update_timestamp() {
    timestamp = std::chrono::system_clock::now();
}

std::string CoTObject::to_xml() const {
    auto current_time = std::chrono::system_clock::now();
    auto stale_time = current_time + std::chrono::minutes(10);
    
    std::stringstream xml;
    xml << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    xml << "<event version=\"2.0\" uid=\"" << uid << "\" type=\"" << type << "\" how=\"" << how << "\"\n";
    xml << "       time=\"" << format_timestamp(current_time) << "\"\n";
    xml << "       start=\"" << format_timestamp(current_time) << "\"\n";
    xml << "       stale=\"" << format_timestamp(stale_time) << "\">\n";
    xml << "  <point lat=\"" << std::fixed << std::setprecision(6) << latitude << "\"\n";
    xml << "         lon=\"" << std::fixed << std::setprecision(6) << longitude << "\"\n";
    xml << "         hae=\"" << std::fixed << std::setprecision(2) << hae << "\"\n";
    xml << "         ce=\"10.0\" le=\"10.0\"/>\n";
    xml << "  <detail>\n";
    xml << "    <contact callsign=\"" << callsign << "\"/>\n";
    xml << "    <__group name=\"" << team << "\" role=\"Team Member\"/>\n";
    xml << "  </detail>\n";
    xml << "</event>\n";
    
    return xml.str();
}

// CoTParser implementation
std::string CoTParser::extract_attribute(const std::string& xml, const std::string& element, const std::string& attr) {
    std::string pattern = "<" + element + "[^>]*" + attr + "=\"([^\"]+)\"";
    std::regex regex_pattern(pattern);
    std::smatch match;
    
    if (std::regex_search(xml, match, regex_pattern)) {
        return match[1].str();
    }
    return "";
}

std::string CoTParser::extract_element_content(const std::string& xml, const std::string& element) {
    std::string pattern = "<" + element + "[^>]*>([^<]*)</" + element + ">";
    std::regex regex_pattern(pattern);
    std::smatch match;
    
    if (std::regex_search(xml, match, regex_pattern)) {
        return match[1].str();
    }
    return "";
}

void CoTParser::CoTMessage::print() const {
    std::cout << "═══════════════════════════════════════" << std::endl;
    std::cout << "CoT Message Received" << std::endl;
    std::cout << "═══════════════════════════════════════" << std::endl;
    std::cout << "UID:       " << uid << std::endl;
    std::cout << "Type:      " << type << std::endl;
    std::cout << "How:       " << how << std::endl;
    std::cout << "Time:      " << time << std::endl;
    std::cout << "Position:  " << std::fixed << std::setprecision(6) 
              << latitude << ", " << longitude << " (HAE: " << hae << "m)" << std::endl;
    if (!callsign.empty()) {
        std::cout << "Callsign:  " << callsign << std::endl;
    }
    if (!team.empty()) {
        std::cout << "Team:      " << team << std::endl;
    }
    std::cout << "Stale:     " << stale << std::endl;
    std::cout << "═══════════════════════════════════════" << std::endl;
}

void CoTParser::CoTMessage::print_compact() const {
    std::cout << "[" << time.substr(11, 8) << "] " 
              << std::setw(12) << std::left << callsign 
              << " | " << std::setw(10) << type 
              << " | " << std::fixed << std::setprecision(4)
              << std::setw(10) << latitude << "," << std::setw(11) << longitude
              << " | " << team << std::endl;
}

CoTParser::CoTMessage CoTParser::parse(const std::string& xml) {
    CoTMessage msg;
    msg.raw_xml = xml;
    
    // Extract event attributes
    msg.uid = extract_attribute(xml, "event", "uid");
    msg.type = extract_attribute(xml, "event", "type");
    msg.how = extract_attribute(xml, "event", "how");
    msg.time = extract_attribute(xml, "event", "time");
    msg.start = extract_attribute(xml, "event", "start");
    msg.stale = extract_attribute(xml, "event", "stale");
    
    // Extract point attributes
    std::string lat_str = extract_attribute(xml, "point", "lat");
    std::string lon_str = extract_attribute(xml, "point", "lon");
    std::string hae_str = extract_attribute(xml, "point", "hae");
    
    if (!lat_str.empty()) msg.latitude = std::stod(lat_str);
    if (!lon_str.empty()) msg.longitude = std::stod(lon_str);
    if (!hae_str.empty()) msg.hae = std::stod(hae_str);
    
    // Extract contact callsign
    msg.callsign = extract_attribute(xml, "contact", "callsign");
    
    // Extract team/group name
    msg.team = extract_attribute(xml, "__group", "name");
    
    return msg;
}

// TAKServerConnection implementation
TAKServerConnection::TAKServerConnection(const std::string& hostname, int tcp_port, 
                   const std::string& cert_path, const std::string& key_path,
                   const std::string& ca_path, const std::string& pass,
                   bool verb) 
    : host(hostname), port(tcp_port), cert_file(cert_path), key_file(key_path),
      ca_file(ca_path), passphrase(pass), ssl_ctx(nullptr), ssl(nullptr), 
      socket_fd(-1), connected(false), verbose(verb) {
}

TAKServerConnection::~TAKServerConnection() {
    disconnect();
    if (ssl_ctx) {
        SSL_CTX_free(ssl_ctx);
    }
}

bool TAKServerConnection::init_ssl() {
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();
    
    ssl_ctx = SSL_CTX_new(TLS_client_method());
    if (!ssl_ctx) {
        std::cerr << "Error creating SSL context\n";
        ERR_print_errors_fp(stderr);
        return false;
    }
    
    // Load client certificate if provided
    if (!cert_file.empty() && !key_file.empty()) {
        if (SSL_CTX_use_certificate_file(ssl_ctx, cert_file.c_str(), SSL_FILETYPE_PEM) <= 0) {
            std::cerr << "Error loading client certificate: " << cert_file << std::endl;
            ERR_print_errors_fp(stderr);
            return false;
        }
        
        // Set up passphrase callback if passphrase is provided
        if (!passphrase.empty()) {
            SSL_CTX_set_default_passwd_cb_userdata(ssl_ctx, (void*)passphrase.c_str());
            SSL_CTX_set_default_passwd_cb(ssl_ctx, [](char *buf, int size, int rwflag, void *userdata) -> int {
                (void)rwflag;  // Suppress unused parameter warning
                const char* pass = static_cast<const char*>(userdata);
                int len = strlen(pass);
                if (len > size - 1) len = size - 1;
                memcpy(buf, pass, len);
                buf[len] = '\0';
                return len;
            });
        }
        
        if (SSL_CTX_use_PrivateKey_file(ssl_ctx, key_file.c_str(), SSL_FILETYPE_PEM) <= 0) {
            std::cerr << "Error loading private key: " << key_file << std::endl;
            ERR_print_errors_fp(stderr);
            return false;
        }
        
        if (!SSL_CTX_check_private_key(ssl_ctx)) {
            std::cerr << "Private key does not match certificate\n";
            return false;
        }
        
        if (verbose) std::cout << "Loaded client certificate: " << cert_file << std::endl;
    }
    
    // Load CA certificate if provided
    if (!ca_file.empty()) {
        if (!SSL_CTX_load_verify_locations(ssl_ctx, ca_file.c_str(), nullptr)) {
            std::cerr << "Error loading CA certificate: " << ca_file << std::endl;
            ERR_print_errors_fp(stderr);
            return false;
        }
        SSL_CTX_set_verify(ssl_ctx, SSL_VERIFY_PEER, nullptr);
        if (verbose) std::cout << "Loaded CA certificate: " << ca_file << std::endl;
    } else {
        // Disable certificate verification if no CA provided
        SSL_CTX_set_verify(ssl_ctx, SSL_VERIFY_NONE, nullptr);
        if (verbose) std::cout << "Warning: Certificate verification disabled\n";
    }
    
    return true;
}

bool TAKServerConnection::create_connection() {
    struct hostent* server = gethostbyname(host.c_str());
    if (!server) {
        std::cerr << "Error resolving hostname: " << host << std::endl;
        return false;
    }
    
    socket_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (socket_fd < 0) {
        std::cerr << "Error creating socket\n";
        return false;
    }
    
    struct sockaddr_in serv_addr;
    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(port);
    memcpy(&serv_addr.sin_addr.s_addr, server->h_addr, server->h_length);
    
    if (::connect(socket_fd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) < 0) {
        std::cerr << "Error connecting to " << host << ":" << port << std::endl;
        close(socket_fd);
        return false;
    }
    
    return true;
}

bool TAKServerConnection::setup_ssl_connection() {
    ssl = SSL_new(ssl_ctx);
    if (!ssl) {
        std::cerr << "Error creating SSL structure\n";
        return false;
    }
    
    SSL_set_fd(ssl, socket_fd);
    
    int ssl_result = SSL_connect(ssl);
    if (ssl_result != 1) {
        std::cerr << "SSL connection failed\n";
        ERR_print_errors_fp(stderr);
        return false;
    }
    
    return true;
}

bool TAKServerConnection::connect() {
    if (!init_ssl()) {
        return false;
    }
    
    if (!create_connection()) {
        return false;
    }
    
    if (!setup_ssl_connection()) {
        close(socket_fd);
        return false;
    }
    
    connected = true;
    if (verbose) std::cout << "Connected to TAK server at " << host << ":" << port << std::endl;
    return true;
}

void TAKServerConnection::disconnect() {
    connected = false;
    
    if (ssl) {
        SSL_shutdown(ssl);
        SSL_free(ssl);
        ssl = nullptr;
    }
    
    if (socket_fd >= 0) {
        close(socket_fd);
        socket_fd = -1;
    }
    
    if (verbose) std::cout << "Disconnected from TAK server\n";
}

bool TAKServerConnection::send_data(const std::string& data) {
    if (!connected) {
        std::cerr << "Not connected to TAK server\n";
        return false;
    }
    
    int bytes_sent = SSL_write(ssl, data.c_str(), data.length());
    if (bytes_sent <= 0) {
        std::cerr << "Error sending data to TAK server\n";
        ERR_print_errors_fp(stderr);
        return false;
    }
    
    return true;
}

int TAKServerConnection::receive_data(char* buffer, size_t buffer_size) {
    if (!connected) {
        std::cerr << "Not connected to TAK server\n";
        return -1;
    }
    
    return SSL_read(ssl, buffer, buffer_size - 1);
}

int TAKServerConnection::get_last_ssl_error(int result) {
    if (!ssl) {
        return -1;
    }
    return SSL_get_error(ssl, result);
}

} // namespace CoTCommon