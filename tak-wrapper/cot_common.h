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

// MIL-STD-2525D SIDC utility class
class MilStd2525 {
public:
    // Affiliation codes (Position 2)
    enum class Affiliation {
        PENDING = 0,         // Pending
        UNKNOWN = 1,         // Unknown  
        ASSUMED_FRIEND = 2,  // Assumed Friend
        FRIEND = 3,          // Friend
        NEUTRAL = 4,         // Neutral
        SUSPECT = 5,         // Suspect
        HOSTILE = 6          // Hostile
    };
    
    // Battle dimension codes (Position 3)
    enum class BattleDimension {
        UNKNOWN = 0,         // Unknown
        LAND_UNIT = 1,       // Land Unit
        LAND_EQUIPMENT = 2,  // Land Equipment
        SEA_SURFACE = 3,     // Sea Surface
        SEA_SUBSURFACE = 4,  // Sea Subsurface
        AIR = 5,             // Air
        SPACE = 6            // Space
    };
    
    // Status codes (Position 4)  
    enum class Status {
        REALITY = 0,         // Reality
        EXERCISE = 1,        // Exercise
        SIMULATION = 2       // Simulation
    };
    
    // Function ID for common unit types (Positions 5-10)
    enum class FunctionID {
        // Land Units
        INFANTRY = 110100,           // Infantry
        ARMOR = 110200,              // Armor/Tank
        MECHANIZED = 110300,         // Mechanized Infantry
        ARTILLERY = 110500,          // Artillery
        ENGINEER = 110800,           // Engineer
        AIR_DEFENSE = 110900,        // Air Defense
        RECONNAISSANCE = 111000,     // Reconnaissance
        HEADQUARTERS = 110000,       // Headquarters
        
        // Combat Support
        LOGISTICS = 120000,          // Combat Service Support
        MEDICAL = 120500,            // Medical
        TRANSPORTATION = 120600,     // Transportation
        MAINTENANCE = 120700,        // Maintenance
        SUPPLY = 120800,             // Supply
        
        // Land Equipment
        TANK_M1 = 110201,           // Tank (M1 Abrams type)
        APC = 110301,               // Armored Personnel Carrier
        IFV = 110302,               // Infantry Fighting Vehicle
        HOWITZER = 110501,          // Howitzer
        SAM_LAUNCHER = 110901,      // Surface-to-Air Missile
        
        // Air Units
        FIGHTER = 111100,           // Fighter Aircraft
        ATTACK_HELO = 111200,       // Attack Helicopter
        TRANSPORT_HELO = 111300,    // Transport Helicopter
        TRANSPORT_FIXED = 111400,   // Transport Fixed Wing
        BOMBER = 111500,            // Bomber
        CARGO_AIRCRAFT = 111600,    // Cargo Aircraft
        
        // Naval Units
        DESTROYER = 111100,         // Destroyer
        FRIGATE = 111200,          // Frigate
        CRUISER = 111300,          // Cruiser
        CARRIER = 111400,          // Aircraft Carrier
        SUBMARINE = 111100,        // Attack Submarine (Sea Subsurface)
        
        // Special Operations
        SPECIAL_FORCES = 111700,    // Special Operations Forces
        COMMANDO = 111701          // Commando Unit
    };
    
    // Echelon/Mobility codes (Position 11-12)
    enum class Echelon {
        NONE = 0,              // No echelon
        TEAM_CREW = 11,        // Team/Crew
        SQUAD = 12,            // Squad
        SECTION = 13,          // Section
        PLATOON = 14,          // Platoon
        COMPANY = 15,          // Company/Battery/Troop
        BATTALION = 16,        // Battalion/Squadron
        REGIMENT = 17,         // Regiment/Group
        BRIGADE = 18,          // Brigade
        DIVISION = 21,         // Division
        CORPS = 22,            // Corps/MEF
        ARMY = 23,             // Army
        ARMY_GROUP = 24,       // Army Group/Front
        REGION = 25            // Region/Theater
    };
    
    // Generate 20-digit MIL-STD-2525D SIDC
    static std::string generateSIDC(
        Affiliation affiliation = Affiliation::FRIEND,
        BattleDimension dimension = BattleDimension::LAND_UNIT,
        Status status = Status::REALITY,
        FunctionID function = FunctionID::INFANTRY,
        Echelon echelon = Echelon::NONE,
        int country = 0
    );
    
    // Convert SIDC to CoT type for TAK compatibility
    static std::string sidcToCoTType(const std::string& sidc);
    
    // Get human-readable description of SIDC
    static std::string describeSIDC(const std::string& sidc);
    
    // Validate SIDC format
    static bool isValidSIDC(const std::string& sidc);
    
    // Helper functions for common military units
    static std::string friendlyInfantry(Echelon echelon = Echelon::SQUAD);
    static std::string hostileArmor(Echelon echelon = Echelon::PLATOON);
    static std::string neutralMedical(Echelon echelon = Echelon::NONE);
    static std::string friendlyAircraft(FunctionID aircraft = FunctionID::FIGHTER);
    static std::string hostileNaval(FunctionID ship = FunctionID::DESTROYER);
};

class CoTObject {
private:
    std::string uid;
    std::string type;
    std::string how;
    std::string sidc;  // MIL-STD-2525D Symbol Identification Code
    double latitude;
    double longitude;
    double hae;  // Height Above Ellipsoid
    std::string callsign;
    std::string team;
    bool persistent;  // Whether this is a persistent tactical object
    std::chrono::system_clock::time_point timestamp;
    
    std::string generate_uuid();
    std::string format_timestamp(const std::chrono::system_clock::time_point& tp) const;

public:
    // Constructor with CoT type (legacy)
    CoTObject(const std::string& obj_type = "a-f-G-U-C", 
              const std::string& how_val = "h-g-i-g-o",
              double lat = 0.0, double lon = 0.0, double height = 0.0,
              const std::string& call = "CppCoT", const std::string& team_name = "Blue");
    
    // Constructor with SIDC (preferred)
    CoTObject(const std::string& sidc_code,
              double lat = 0.0, double lon = 0.0, double height = 0.0,
              const std::string& call = "CppCoT", const std::string& team_name = "Blue",
              const std::string& how_val = "h-g-i-g-o", bool is_persistent = true);
    
    void update_timestamp();
    std::string to_xml() const;
    
    // Getters
    const std::string& get_callsign() const { return callsign; }
    const std::string& get_uid() const { return uid; }
    const std::string& get_sidc() const { return sidc; }
    const std::string& get_type() const { return type; }
    
    // SIDC utilities
    void set_sidc(const std::string& sidc_code);
    std::string get_sidc_description() const;
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