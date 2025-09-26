#include "cot_common.h"
#include <signal.h>


class TAKServerListener {
private:
    CoTCommon::TAKServerConnection connection;
    CoTCommon::CoTParser parser;
    bool verbose;
    

public:
    TAKServerListener(const std::string& hostname, int tcp_port, 
                     const std::string& cert_path = "", const std::string& key_path = "",
                     const std::string& ca_path = "", const std::string& pass = "",
                     bool verb = false) 
        : connection(hostname, tcp_port, cert_path, key_path, ca_path, pass, verb), verbose(verb) {
    }
    
    ~TAKServerListener() {
        disconnect();
    }
    
    bool connect() {
        return connection.connect();
    }
    
    void listen(bool compact_mode = false, const std::string& filter_type = "") {
        if (!connection.is_connected()) {
            std::cerr << "Not connected to TAK server\n";
            return;
        }
        
        std::cout << "\n=== TAK Server CoT Listener Active ===\n";
        if (compact_mode) {
            std::cout << "Time     | Callsign     | Type       | Position (Lat,Lon)      | Team\n";
            std::cout << "---------|--------------|------------|-------------------------|----------\n";
        }
        std::cout.flush();
        
        char buffer[8192];
        std::string message_buffer;
        
        while (connection.is_connected()) {
            int bytes_received = connection.receive_data(buffer, sizeof(buffer));
            
            if (bytes_received <= 0) {
                int ssl_error = connection.get_last_ssl_error(bytes_received);
                if (ssl_error == SSL_ERROR_WANT_READ || ssl_error == SSL_ERROR_WANT_WRITE) {
                    // Non-blocking operation, try again
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
                    continue;
                } else {
                    std::cerr << "\nConnection lost or error reading from server\n";
                    if (verbose) {
                        std::cerr << "SSL Error: " << ssl_error << std::endl;
                        ERR_print_errors_fp(stderr);
                    }
                    break;
                }
            }
            
            buffer[bytes_received] = '\0';
            message_buffer += std::string(buffer, bytes_received);
            
            // Process complete XML messages
            size_t start_pos = 0;
            while (true) {
                // Look for XML declaration or event start
                size_t xml_start = message_buffer.find("<?xml", start_pos);
                if (xml_start == std::string::npos) {
                    xml_start = message_buffer.find("<event", start_pos);
                }
                
                if (xml_start == std::string::npos) {
                    break;
                }
                
                // Find the end of the event
                size_t event_end = message_buffer.find("</event>", xml_start);
                if (event_end == std::string::npos) {
                    break; // Incomplete message, wait for more data
                }
                
                // Extract complete message
                std::string complete_message = message_buffer.substr(xml_start, event_end - xml_start + 8);
                
                // Parse and display the message
                try {
                    CoTCommon::CoTParser::CoTMessage msg = parser.parse(complete_message);
                    
                    // Apply filter if specified
                    bool should_display = true;
                    if (!filter_type.empty()) {
                        should_display = (msg.type.find(filter_type) != std::string::npos);
                    }
                    
                    if (should_display) {
                        if (compact_mode) {
                            msg.print_compact();
                        } else {
                            msg.print();
                        }
                        
                        if (verbose) {
                            std::cout << "\nRaw XML:\n" << complete_message << "\n" << std::endl;
                        }
                    }
                } catch (const std::exception& e) {
                    if (verbose) {
                        std::cerr << "Error parsing CoT message: " << e.what() << std::endl;
                        std::cerr << "Raw message: " << complete_message << std::endl;
                    }
                }
                
                start_pos = event_end + 8;
            }
            
            // Remove processed messages from buffer
            if (start_pos > 0) {
                message_buffer = message_buffer.substr(start_pos);
            }
            
            // Prevent buffer from growing too large
            if (message_buffer.length() > 16384) {
                message_buffer.clear();
            }
        }
    }
    
    void disconnect() {
        connection.disconnect();
    }
    
    bool is_connected() const {
        return connection.is_connected();
    }
};

void print_usage(const char* program_name) {
    std::cout << "Usage: " << program_name << " [options]\n";
    std::cout << "Options:\n";
    std::cout << "  --host <hostname>     TAK server hostname (default: localhost)\n";
    std::cout << "  --port <port>         TAK server TCP port (default: 8089)\n";
    std::cout << "  --cert <file>         Client certificate file (.pem)\n";
    std::cout << "  --key <file>          Client private key file (.pem)\n";
    std::cout << "  --ca <file>           CA certificate file (.pem)\n";
    std::cout << "  --passphrase <pass>   Private key passphrase\n";
    std::cout << "  --compact             Use compact display format\n";
    std::cout << "  --filter <type>       Filter messages by type (e.g., 'a-f' for friendly)\n";
    std::cout << "  --verbose             Show detailed information and raw XML\n";
    std::cout << "  --help               Show this help message\n";
    std::cout << "\nCoT Type Examples:\n";
    std::cout << "  a-f-*    Friendly units\n";
    std::cout << "  a-h-*    Hostile units\n";
    std::cout << "  a-n-*    Neutral units\n";
    std::cout << "  a-u-*    Unknown units\n";
}

int main(int argc, char* argv[]) {
    std::string host = "localhost";
    int port = 8089;
    std::string cert_file;
    std::string key_file;
    std::string ca_file;
    std::string passphrase;
    bool compact_mode = false;
    bool verbose = false;
    std::string filter_type;
    
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
        } else if (std::string(argv[i]) == "--compact") {
            compact_mode = true;
        } else if (std::string(argv[i]) == "--filter" && i + 1 < argc) {
            filter_type = argv[++i];
        } else if (std::string(argv[i]) == "--verbose") {
            verbose = true;
        } else if (std::string(argv[i]) == "--help") {
            print_usage(argv[0]);
            return 0;
        }
    }
    
    std::cout << "TAK Server CoT Listener (C++)\n";
    std::cout << "=============================\n";
    std::cout << "Target: " << host << ":" << port << std::endl;
    if (!filter_type.empty()) {
        std::cout << "Filter: " << filter_type << std::endl;
    }
    std::cout << "Mode: " << (compact_mode ? "Compact" : "Detailed") << std::endl;
    std::cout << "Press Ctrl+C to stop listening\n" << std::endl;
    
    // Create TAK server listener
    TAKServerListener listener(host, port, cert_file, key_file, ca_file, passphrase, verbose);
    
    // Connect to server
    if (!listener.connect()) {
        std::cerr << "Failed to connect to TAK server\n";
        return 1;
    }
    
    // Set up signal handler for graceful shutdown
    signal(SIGINT, [](int) {
        std::cout << "\n\nShutting down listener...\n";
        exit(0);
    });
    
    try {
        // Start listening for messages
        listener.listen(compact_mode, filter_type);
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}