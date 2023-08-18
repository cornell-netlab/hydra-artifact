#define ETHERTYPE_CHECKER 0x5678

header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bit<8> prev_vlan;
  bool vlan_valid;
  bit<7> _pad;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
 bool reject0; 
 bit<8> switch_vlan;
}