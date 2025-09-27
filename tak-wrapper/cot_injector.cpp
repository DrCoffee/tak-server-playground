#include "cot_common.h"


class TAKServerClient {
private:
    CoTCommon::TAKServerConnection connection;

public:
    TAKServerClient(const std::string& hostname, int tcp_port, 
                   const std::string& cert_path = "", const std::string& key_path = "",
                   const std::string& ca_path = "", const std::string& pass = "") 
        : connection(hostname, tcp_port, cert_path, key_path, ca_path, pass, true) {
    }
    
    bool connect() {
        return connection.connect();
    }
    
    bool send_cot(const CoTCommon::CoTObject& cot_obj) {
        if (!connection.is_connected()) {
            std::cerr << "Not connected to TAK server\n";
            return false;
        }
        
        std::string xml_data = cot_obj.to_xml();
        
        std::cout << "Sending CoT XML:\n" << xml_data << std::endl;
        
        if (!connection.send_data(xml_data)) {
            return false;
        }
        
        std::cout << "Sent CoT object " << cot_obj.get_uid() << " (" << cot_obj.get_callsign() << ")\n";
        return true;
    }
    
    void disconnect() {
        connection.disconnect();
    }
    
    bool is_connected() const {
        return connection.is_connected();
    }
};

// Generate random coordinates within Australia
std::pair<double, double> generate_random_australia_coords() {
    std::random_device rd;
    std::mt19937 gen(rd());
    
    // Australia bounds (approximate)
    std::uniform_real_distribution<double> lat_dist(-44.0, -10.0);  // South to North
    std::uniform_real_distribution<double> lon_dist(113.0, 154.0);  // West to East
    
    return std::make_pair(lat_dist(gen), lon_dist(gen));
}

std::vector<CoTCommon::CoTObject> create_sample_units() {
    std::vector<CoTCommon::CoTObject> units;
    
    // Generate random coordinates for each unit
    auto alpha_coords = generate_random_australia_coords();
    auto bravo_coords = generate_random_australia_coords();
    auto charlie_coords = generate_random_australia_coords();
    auto enemy_coords = generate_random_australia_coords();
    auto neutral_coords = generate_random_australia_coords();
    auto aircraft_coords = generate_random_australia_coords();
    
    // Friendly infantry squad using SIDC  
    units.emplace_back(
        CoTCommon::MilStd2525::friendlyInfantry(CoTCommon::MilStd2525::Echelon::SQUAD),
        alpha_coords.first, alpha_coords.second, 100.0, "Alpha-1", "Blue", "h-p-i"  // h-p-i = human-posted-internet
    );
    
    // Friendly armor platoon using SIDC  
    units.emplace_back(
        CoTCommon::MilStd2525::generateSIDC(CoTCommon::MilStd2525::Affiliation::FRIEND, 
                                           CoTCommon::MilStd2525::BattleDimension::LAND_UNIT,
                                           CoTCommon::MilStd2525::Status::REALITY,
                                           CoTCommon::MilStd2525::FunctionID::ARMOR,
                                           CoTCommon::MilStd2525::Echelon::PLATOON),
        bravo_coords.first, bravo_coords.second, 150.0, "Bravo-2", "Blue", "h-p-i"
    );
    
    // Friendly medical unit using SIDC
    units.emplace_back(
        CoTCommon::MilStd2525::neutralMedical(),
        charlie_coords.first, charlie_coords.second, 75.0, "Charlie-Med", "Blue", "h-p-i"
    );
    
    // Hostile armor unit using SIDC
    units.emplace_back(
        CoTCommon::MilStd2525::hostileArmor(CoTCommon::MilStd2525::Echelon::COMPANY),
        enemy_coords.first, enemy_coords.second, 200.0, "Enemy-1", "Red", "h-p-i"
    );
    
    // Neutral unit using legacy constructor  
    units.emplace_back("a-n-G-U-C", "h-p-i", neutral_coords.first, neutral_coords.second, 75.0, "Neutral-1", "White");
    
    // Friendly fighter aircraft using SIDC
    units.emplace_back(
        CoTCommon::MilStd2525::friendlyAircraft(CoTCommon::MilStd2525::FunctionID::FIGHTER),
        aircraft_coords.first, aircraft_coords.second, 3000.0, "Eagle-1", "Blue", "h-p-i"
    );
    
    return units;
}

void print_usage(const char* program_name) {
    std::cout << "Usage: " << program_name << " [options]\n";
    std::cout << "Options:\n";
    std::cout << "  --host <hostname>     TAK server hostname (default: localhost)\n";
    std::cout << "  --port <port>         TAK server TCP port (default: 8089)\n";
    std::cout << "  --cert <file>         Client certificate file (.pem)\n";
    std::cout << "  --key <file>          Client private key file (.pem)\n";
    std::cout << "  --ca <file>           CA certificate file (.pem)\n";
    std::cout << "  --passphrase <pass>   Private key passphrase\n";
    std::cout << "  --count <number>      Number of iterations (default: 1)\n";
    std::cout << "  --interval <seconds>  Interval between sends (default: 1.0)\n";
    std::cout << "  --help               Show this help message\n";
}

int main(int argc, char* argv[]) {
    std::string host = "localhost";
    int port = 8089;
    std::string cert_file;
    std::string key_file;
    std::string ca_file;
    std::string passphrase;
    int count = 1;
    double interval = 1.0;
    
    // Simple argument parsing
    for (int i = 1; i < argc; i++) {
        if (std::string(argv[i]) == "--host" && i + 1 < argc) {
            host = argv[++i];
        } else if (std::string(argv[i]) == "--port" && i + 1 < argc) {
            port = std::stoi(argv[++i]);
        } else if (std::string(argv[i]) == "--cert" && i + 1 < argc) {
            cert_file = argv[++i];
        } else if (std::string(argv[i]) == "--key" && i + 1 < argc) {
            key_file = argv[++i];
        } else if (std::string(argv[i]) == "--ca" && i + 1 < argc) {
            ca_file = argv[++i];
        } else if (std::string(argv[i]) == "--passphrase" && i + 1 < argc) {
            passphrase = argv[++i];
        } else if (std::string(argv[i]) == "--count" && i + 1 < argc) {
            count = std::stoi(argv[++i]);
        } else if (std::string(argv[i]) == "--interval" && i + 1 < argc) {
            interval = std::stod(argv[++i]);
        } else if (std::string(argv[i]) == "--help") {
            print_usage(argv[0]);
            return 0;
        }
    }
    
    std::cout << "TAK Server CoT Injector (C++)\n";
    std::cout << "==============================\n";
    std::cout << "Target: " << host << ":" << port << std::endl;
    std::cout << "Count: " << count << ", Interval: " << interval << "s\n\n";
    
    // Create TAK server client
    TAKServerClient client(host, port, cert_file, key_file, ca_file, passphrase);
    
    // Connect to server
    if (!client.connect()) {
        std::cerr << "Failed to connect to TAK server\n";
        return 1;
    }
    
    try {
        // Create sample units
        auto units = create_sample_units();
        
        for (int i = 0; i < count; i++) {
            std::cout << "=== Batch " << (i + 1) << " of " << count << " ===\n";
            
            for (auto& unit : units) {
                if (!client.send_cot(unit)) {
                    std::cerr << "Failed to send unit " << unit.get_callsign() << std::endl;
                }
                
                // Wait between sends within a batch
                if (interval > 0 && &unit != &units.back()) {
                    std::this_thread::sleep_for(std::chrono::duration<double>(interval / 4));
                }
            }
            
            // Wait between batches
            if (interval > 0 && i < count - 1) {
                std::this_thread::sleep_for(std::chrono::duration<double>(interval));
            }
        }
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    std::cout << "\nCoT injection completed successfully\n";
    return 0;
}