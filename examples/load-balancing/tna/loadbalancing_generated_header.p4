#define ETHERTYPE_CHECKER 0x5678

header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bool balanced; 
  bit<7> _pad;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
    bit<8> is_uplink_var0;
    bool is_uplink;
    bool reject0;
    bit<8> left_port;
    bit<8> right_port;
    bit<16> thresh;
    bit<16> left_load;
    bit<16> right_load;
}