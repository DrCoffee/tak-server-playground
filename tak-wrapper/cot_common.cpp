#include "cot_common.h"

namespace CoTCommon {

// MIL-STD-2525 implementation
std::string MilStd2525::generateSIDC(
    Affiliation affiliation,
    BattleDimension dimension,
    Status status,
    FunctionID function,
    Echelon echelon,
    int country
) {
    std::stringstream sidc;
    sidc << "10";  // Version (1) and Context (0) - Standard Identity
    sidc << static_cast<int>(affiliation);     // Affiliation (1 digit)
    sidc << static_cast<int>(dimension);       // Battle Dimension (1 digit)
    sidc << static_cast<int>(status);          // Status (1 digit)
    sidc << std::setfill('0') << std::setw(6) << static_cast<int>(function);  // Function ID (6 digits)
    sidc << std::setfill('0') << std::setw(2) << static_cast<int>(echelon);   // Echelon (2 digits)
    sidc << std::setfill('0') << std::setw(3) << country;     // Country (3 digits)
    sidc << "0000";  // Symbol Modifier Extension (4 digits to make total 20)
    return sidc.str();
}

std::string MilStd2525::sidcToCoTType(const std::string& sidc) {
    if (sidc.length() < 10) return "a-f-G-U-C";  // Default friendly
    
    char affiliation = sidc[2];
    char dimension = sidc[3];
    std::string functionStr = sidc.substr(5, 6);
    
    std::string cotType = "a-";
    
    // Affiliation mapping
    switch (affiliation) {
        case '3': cotType += "f-"; break;  // Friend
        case '6': cotType += "h-"; break;  // Hostile
        case '4': cotType += "n-"; break;  // Neutral
        case '1': cotType += "u-"; break;  // Unknown
        case '2': cotType += "f-"; break;  // Assumed Friend -> Friend
        case '5': cotType += "s-"; break;  // Suspect
        default:  cotType += "f-"; break;  // Default to friend
    }
    
    // Dimension and function mapping
    switch (dimension) {
        case '1': // Land Unit
            if (functionStr.substr(0, 4) == "1101") cotType += "G-U-C";      // Ground Unit Combat
            else if (functionStr.substr(0, 4) == "1102") cotType += "G-U-CS";   // Ground Unit Combat Support
            else if (functionStr.substr(0, 4) == "1108") cotType += "G-U-CD";   // Ground Unit Combat Engineer
            else if (functionStr.substr(0, 4) == "1120") cotType += "G-U-CSS";  // Ground Unit Combat Service Support
            else if (functionStr.substr(0, 4) == "1205") cotType += "G-U-CSS";  // Medical
            else cotType += "G-U-C";
            break;
        case '2': // Land Equipment
            cotType += "G-E-V-C";  // Ground Equipment Vehicle Combat
            break;
        case '5': // Air
            if (functionStr.substr(0, 4) == "1111") cotType += "A-F-A";      // Air Fixed Wing Attack
            else if (functionStr.substr(0, 4) == "1112") cotType += "A-W-A";  // Air Rotary Wing Attack
            else if (functionStr.substr(0, 4) == "1113") cotType += "A-W-U";  // Air Rotary Wing Utility
            else if (functionStr.substr(0, 4) == "1114") cotType += "A-F-T";  // Air Fixed Wing Transport
            else cotType += "A-F-A";
            break;
        case '3': // Sea Surface
            cotType += "S-S-C";  // Sea Surface Combatant
            break;
        case '4': // Sea Subsurface
            cotType += "S-U-C";  // Sea Subsurface Combatant
            break;
        case '6': // Space
            cotType += "P-S";    // Space
            break;
        default:
            cotType += "G-U-C";
            break;
    }
    
    return cotType;
}

std::string MilStd2525::describeSIDC(const std::string& sidc) {
    if (!isValidSIDC(sidc)) return "Invalid SIDC";
    
    std::stringstream desc;
    
    // Parse components
    char affiliation = sidc[2];
    char dimension = sidc[3];
    char status = sidc[4];
    std::string functionStr = sidc.substr(5, 6);
    std::string echelonStr = sidc.substr(11, 2);
    
    // Affiliation
    switch (affiliation) {
        case '0': desc << "Pending "; break;
        case '1': desc << "Unknown "; break;
        case '2': desc << "Assumed Friend "; break;
        case '3': desc << "Friend "; break;
        case '4': desc << "Neutral "; break;
        case '5': desc << "Suspect "; break;
        case '6': desc << "Hostile "; break;
        default: desc << "Unknown Affiliation "; break;
    }
    
    // Dimension
    switch (dimension) {
        case '1': desc << "Land Unit"; break;
        case '2': desc << "Land Equipment"; break;
        case '3': desc << "Sea Surface"; break;
        case '4': desc << "Sea Subsurface"; break;
        case '5': desc << "Air"; break;
        case '6': desc << "Space"; break;
        default: desc << "Unknown Dimension"; break;
    }
    
    // Basic function mapping
    if (functionStr.substr(0, 4) == "1101") desc << " Infantry";
    else if (functionStr.substr(0, 4) == "1102") desc << " Armor";
    else if (functionStr.substr(0, 4) == "1103") desc << " Mechanized";
    else if (functionStr.substr(0, 4) == "1105") desc << " Artillery";
    else if (functionStr.substr(0, 4) == "1108") desc << " Engineer";
    else if (functionStr.substr(0, 4) == "1109") desc << " Air Defense";
    else if (functionStr.substr(0, 4) == "1110") desc << " Reconnaissance";
    else if (functionStr.substr(0, 4) == "1111") desc << " Aircraft";
    else if (functionStr.substr(0, 4) == "1205") desc << " Medical";
    else desc << " Unit";
    
    // Echelon
    if (echelonStr == "12") desc << " Squad";
    else if (echelonStr == "14") desc << " Platoon";
    else if (echelonStr == "15") desc << " Company";
    else if (echelonStr == "16") desc << " Battalion";
    else if (echelonStr == "18") desc << " Brigade";
    else if (echelonStr == "21") desc << " Division";
    
    // Status
    switch (status) {
        case '1': desc << " (Exercise)"; break;
        case '2': desc << " (Simulation)"; break;
        default: break; // Reality - no suffix
    }
    
    return desc.str();
}

bool MilStd2525::isValidSIDC(const std::string& sidc) {
    // Check length
    if (sidc.length() != 20) return false;
    
    // Check all characters are digits
    for (char c : sidc) {
        if (!std::isdigit(c)) return false;
    }
    
    // Check version and context (must be "10")
    if (sidc.substr(0, 2) != "10") return false;
    
    // Check affiliation (positions 2)
    char affiliation = sidc[2];
    if (affiliation < '0' || affiliation > '6') return false;
    
    // Check dimension (position 3)
    char dimension = sidc[3];
    if (dimension < '0' || dimension > '6') return false;
    
    // Check status (position 4)
    char status = sidc[4];
    if (status < '0' || status > '2') return false;
    
    return true;
}

// Helper functions for common military units
std::string MilStd2525::friendlyInfantry(Echelon echelon) {
    return generateSIDC(Affiliation::FRIEND, BattleDimension::LAND_UNIT, 
                       Status::REALITY, FunctionID::INFANTRY, echelon);
}

std::string MilStd2525::hostileArmor(Echelon echelon) {
    return generateSIDC(Affiliation::HOSTILE, BattleDimension::LAND_UNIT,
                       Status::REALITY, FunctionID::ARMOR, echelon);
}

std::string MilStd2525::neutralMedical(Echelon echelon) {
    return generateSIDC(Affiliation::NEUTRAL, BattleDimension::LAND_UNIT,
                       Status::REALITY, FunctionID::MEDICAL, echelon);
}

std::string MilStd2525::friendlyAircraft(FunctionID aircraft) {
    return generateSIDC(Affiliation::FRIEND, BattleDimension::AIR,
                       Status::REALITY, aircraft);
}

std::string MilStd2525::hostileNaval(FunctionID ship) {
    return generateSIDC(Affiliation::HOSTILE, BattleDimension::SEA_SURFACE,
                       Status::REALITY, ship);
}

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
      hae(height), callsign(call), team(team_name), persistent(true) {
    uid = generate_uuid();
    timestamp = std::chrono::system_clock::now();
}

CoTObject::CoTObject(const std::string& sidc_code,
          double lat, double lon, double height,
          const std::string& call, const std::string& team_name,
          const std::string& how_val, bool is_persistent)
    : sidc(sidc_code), how(how_val), latitude(lat), longitude(lon), 
      hae(height), callsign(call), team(team_name), persistent(is_persistent) {
    uid = generate_uuid();
    timestamp = std::chrono::system_clock::now();
    
    // Convert SIDC to CoT type
    type = MilStd2525::sidcToCoTType(sidc_code);
}

void CoTObject::update_timestamp() {
    timestamp = std::chrono::system_clock::now();
}

void CoTObject::set_sidc(const std::string& sidc_code) {
    sidc = sidc_code;
    type = MilStd2525::sidcToCoTType(sidc_code);
}

std::string CoTObject::get_sidc_description() const {
    if (sidc.empty()) return "";
    return MilStd2525::describeSIDC(sidc);
}

std::string CoTObject::to_xml() const {
    auto current_time = std::chrono::system_clock::now();
    auto stale_time = persistent ? 
        current_time + std::chrono::hours(24) :  // 24-hour stale time for persistent tactical objects
        current_time + std::chrono::minutes(10); // 10-minute stale time for live tracking
    
    std::stringstream xml;
    xml << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    xml << "<event version=\"2.0\" uid=\"" << uid << "\" type=\"" << type << "\" how=\"" << how << "\"\n";
    xml << "       time=\"" << format_timestamp(current_time) << "\"\n";
    xml << "       start=\"" << format_timestamp(current_time) << "\"\n";
    xml << "       stale=\"" << format_timestamp(stale_time) << "\"";
    
    // Add SIDC as event attribute for better TAK recognition
    if (!sidc.empty()) {
        xml << "\n       sidc=\"" << sidc << "\"";
    }
    
    xml << ">\n";
    xml << "  <point\n";
    xml << "    lat=\"" << std::fixed << std::setprecision(6) << latitude << "\"\n";
    xml << "    lon=\"" << std::fixed << std::setprecision(6) << longitude << "\"\n";
    xml << "    ce=\"9999999\"\n";
    xml << "    hae=\"" << std::fixed << std::setprecision(2) << hae << "\"\n";
    xml << "    le=\"9999999\"\n";
    xml << "  >\n";
    xml << "  </point>\n";
    xml << "  <detail>\n";
    xml << "    <contact callsign=\"" << callsign << "\" endpoint=\"*:-1:stcp\" phone=\"\" />\n";
    xml << "    <__group name=\"" << team << "\" role=\"Team Member\"/>\n";
    xml << "    <uid Droid=\"tactical-wrapper\"/>\n";
    
    // Include SIDC information if available (TAK format)
    if (!sidc.empty()) {
        xml << "    <status readiness=\"true\"/>\n";
        xml << "    <takv device=\"tactical-wrapper\" platform=\"Linux\" os=\"Linux\" version=\"1.0\"/>\n";
        xml << "    <track speed=\"0.00000000\" course=\"0.00000000\"/>\n";
        
        // TAK MIL-STD-2525 format (simplified)
        xml << "    <usericon iconsetpath=\"34ae1613-9645-4222-a9d2-e5f243dea2865/Military/2525C-mil-std-2525c/" << type << "\"/>\n";
        xml << "    <_flow-tags_ marti:tags=\"2525c-mil-std-2525c\"/>\n";
    }
    
    // Mark persistent tactical objects
    if (persistent) {
        xml << "    <remarks>Persistent tactical object</remarks>\n";
        xml << "    <archive/>\n";  // TAK archive marker for persistence
        xml << "    <link relation=\"p-p\" type=\"a-f-G-U-C\" uid=\"ANDROID-\" />\n";  // Link to persistent mission data
        xml << "    <precisionlocation altsrc=\"DTED0\" geopointsrc=\"USER\" />\n";
    }
    
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